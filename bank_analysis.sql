/* ============================================================================
   BANK CUSTOMER, LOAN & CREDIT CARD ANALYSIS
   Project   : Data Cleaning & Dashboard (Excel + SQL)
   Author    : Fresher Data Analyst Portfolio Project
   Purpose   : 1) Recreate the cleaned tables in a relational database
               2) Answer common business questions with SQL

   NOTE ON DIALECT
   ----------------
   Written for MySQL 8 / PostgreSQL 13+ (works in both with minor tweaks).
   - MySQL:  keep DATE, VARCHAR, AUTO_INCREMENT-free PKs (IDs come from source)
   - Postgres: TIMESTAMP works the same as DATE comparisons used here.
   Import the sheets from "Bank_Data_Cleaned_Dashboard.xlsx" (Customer_Data,
   Branches_Data, KYC_Data, Loan_Data, Creditcard_Data) as CSV into the
   tables below, or load via your DB client's "Import from Excel/CSV" tool.
   ============================================================================ */


/* ============================================================================
   1. SCHEMA - CREATE TABLES
   ============================================================================ */

DROP TABLE IF EXISTS CreditCards;
DROP TABLE IF EXISTS Loans;
DROP TABLE IF EXISTS KYC;
DROP TABLE IF EXISTS Customers;
DROP TABLE IF EXISTS Branches;

CREATE TABLE Branches (
    BranchID        VARCHAR(10)   PRIMARY KEY,
    BranchName      VARCHAR(100)  NOT NULL,
    City            VARCHAR(50),
    State           VARCHAR(50),
    Region          VARCHAR(20),
    Manager         VARCHAR(100),
    OpeningDate     DATE
);

CREATE TABLE Customers (
    CustomerID              VARCHAR(10)   PRIMARY KEY,
    CustomerName            VARCHAR(100)  NOT NULL,
    DOB                     DATE,
    DOB_Valid                VARCHAR(20),      -- 'Yes' / 'No - Future Date'
    Age                     INT,
    Gender                  VARCHAR(10),
    Phone                   VARCHAR(15),
    Email                   VARCHAR(100),
    Address                 VARCHAR(200),
    City                    VARCHAR(50),
    State                   VARCHAR(50),
    PAN                     VARCHAR(10),
    PAN_Valid                VARCHAR(10),      -- Yes / No / Missing
    Aadhaar                 VARCHAR(12),
    Aadhaar_Valid            VARCHAR(10),      -- Yes / No / Missing
    Occupation               VARCHAR(50),
    AnnualIncome             DECIMAL(14,2),
    AnnualIncome_Status      VARCHAR(20),      -- Disclosed / Not Disclosed
    AccountOpenDate          DATE,
    AccountOpenDate_Valid    VARCHAR(20),      -- Yes / No - Before DOB
    BranchID                 VARCHAR(10),
    CustomerStatus           VARCHAR(10),      -- Active / Inactive
    DuplicateFlag            VARCHAR(20),      -- Unique / Possible Duplicate
    CONSTRAINT fk_cust_branch FOREIGN KEY (BranchID) REFERENCES Branches(BranchID)
);

CREATE TABLE KYC (
    KYCID           VARCHAR(10)   PRIMARY KEY,
    CustomerID      VARCHAR(10),
    PAN             VARCHAR(10),
    Aadhaar         VARCHAR(12),
    KYCStatus       VARCHAR(20),   -- Verified / Pending / Rejected
    KYCDate         DATE,
    DocumentType    VARCHAR(30),
    CONSTRAINT fk_kyc_cust FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
);

CREATE TABLE Loans (
    LoanID                      VARCHAR(10)   PRIMARY KEY,
    CustomerID                  VARCHAR(10),
    LoanType                    VARCHAR(30),
    LoanAmount                  DECIMAL(14,2),
    InterestRate                DECIMAL(5,2),
    TenureMonths                INT,
    SanctionDate                DATE,
    LoanStatus                  VARCHAR(20),  -- Active / Closed / NPA / Default
    OutstandingAmount           DECIMAL(14,2),
    BranchID                    VARCHAR(10),
    OutstandingAmount_Status    VARCHAR(20),  -- OK / Needs Review
    CONSTRAINT fk_loan_cust   FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID),
    CONSTRAINT fk_loan_branch FOREIGN KEY (BranchID)   REFERENCES Branches(BranchID)
);

CREATE TABLE CreditCards (
    CardID                      VARCHAR(10)   PRIMARY KEY,
    CustomerID                  VARCHAR(10),
    CardType                    VARCHAR(20),
    CardLimit                   DECIMAL(14,2),
    CurrentOutstanding          DECIMAL(14,2),
    IssueDate                   DATE,
    CardStatus                  VARCHAR(20),  -- Active / Closed / Blocked
    LastPaymentDate              DATE,
    LastPaymentDate_Status       VARCHAR(30), -- OK / No Payment Recorded
    CONSTRAINT fk_cc_cust FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
);


/* ============================================================================
   2. BUSINESS QUESTIONS - ANALYSIS QUERIES
   ============================================================================ */

-- Q1. How many customers do we have, and how many are Active vs Inactive?
SELECT CustomerStatus, COUNT(*) AS TotalCustomers
FROM Customers
GROUP BY CustomerStatus;

-- Q2. Customer count and average annual income by occupation (only disclosed incomes)
SELECT Occupation,
       COUNT(*)                AS TotalCustomers,
       ROUND(AVG(AnnualIncome),2) AS AvgIncome
FROM Customers
WHERE AnnualIncome_Status = 'Disclosed'
GROUP BY Occupation
ORDER BY AvgIncome DESC;

-- Q3. Branch-wise customer count, sorted highest first
SELECT b.BranchID, b.BranchName, b.City, COUNT(c.CustomerID) AS TotalCustomers
FROM Branches b
LEFT JOIN Customers c ON b.BranchID = c.BranchID
GROUP BY b.BranchID, b.BranchName, b.City
ORDER BY TotalCustomers DESC;

-- Q4. Region-wise customer distribution
SELECT b.Region, COUNT(c.CustomerID) AS TotalCustomers
FROM Branches b
LEFT JOIN Customers c ON b.BranchID = c.BranchID
GROUP BY b.Region
ORDER BY TotalCustomers DESC;

-- Q5. Total loans disbursed and outstanding amount, by loan status
SELECT LoanStatus,
       COUNT(*)                    AS NumberOfLoans,
       SUM(LoanAmount)             AS TotalDisbursed,
       SUM(OutstandingAmount)      AS TotalOutstanding
FROM Loans
GROUP BY LoanStatus
ORDER BY TotalDisbursed DESC;

-- Q6. Loan default/NPA rate (%) - a key risk KPI
SELECT
    ROUND(100.0 * SUM(CASE WHEN LoanStatus IN ('NPA','Default') THEN 1 ELSE 0 END) / COUNT(*), 2) AS NPA_Default_Rate_Pct
FROM Loans;

-- Q7. Average loan amount and interest rate by loan type
SELECT LoanType,
       COUNT(*)                     AS NumberOfLoans,
       ROUND(AVG(LoanAmount),2)     AS AvgLoanAmount,
       ROUND(AVG(InterestRate),2)   AS AvgInterestRate
FROM Loans
GROUP BY LoanType
ORDER BY AvgLoanAmount DESC;

-- Q8. Top 10 branches by total loan amount disbursed
SELECT b.BranchID, b.BranchName, SUM(l.LoanAmount) AS TotalLoanAmount
FROM Loans l
JOIN Branches b ON l.BranchID = b.BranchID
GROUP BY b.BranchID, b.BranchName
ORDER BY TotalLoanAmount DESC
LIMIT 10;

-- Q9. Customers holding both a loan AND a credit card (cross-sell base)
SELECT c.CustomerID, c.CustomerName
FROM Customers c
JOIN Loans l       ON c.CustomerID = l.CustomerID
JOIN CreditCards cc ON c.CustomerID = cc.CustomerID
GROUP BY c.CustomerID, c.CustomerName;

-- Q10. KYC status breakdown and rejection rate
SELECT KYCStatus, COUNT(*) AS TotalRecords,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM KYC), 2) AS PctOfTotal
FROM KYC
GROUP BY KYCStatus;

-- Q11. Customers whose KYC is Rejected or Pending (follow-up list for Ops team)
SELECT c.CustomerID, c.CustomerName, c.Phone, k.KYCStatus, k.DocumentType
FROM Customers c
JOIN KYC k ON c.CustomerID = k.CustomerID
WHERE k.KYCStatus IN ('Rejected','Pending');

-- Q12. Credit card portfolio - total limit and outstanding by card type
SELECT CardType,
       COUNT(*)                        AS TotalCards,
       SUM(CardLimit)                  AS TotalLimit,
       SUM(CurrentOutstanding)         AS TotalOutstanding,
       ROUND(100.0*SUM(CurrentOutstanding)/SUM(CardLimit),2) AS UtilizationPct
FROM CreditCards
GROUP BY CardType
ORDER BY TotalOutstanding DESC;

-- Q13. Credit cards with no payment ever recorded (possible dormant / risk accounts)
SELECT CardID, CustomerID, CardType, CardStatus
FROM CreditCards
WHERE LastPaymentDate_Status = 'No Payment Recorded'
  AND CardStatus = 'Active';

-- Q14. Age-band segmentation of the active customer base
SELECT
  CASE
    WHEN Age < 25 THEN '18-24'
    WHEN Age BETWEEN 25 AND 34 THEN '25-34'
    WHEN Age BETWEEN 35 AND 44 THEN '35-44'
    WHEN Age BETWEEN 45 AND 59 THEN '45-59'
    WHEN Age >= 60 THEN '60+'
    ELSE 'Unknown'
  END AS AgeBand,
  COUNT(*) AS TotalCustomers
FROM Customers
WHERE CustomerStatus = 'Active'
GROUP BY 1
ORDER BY 1;

-- Q15. Gender-wise customer split
SELECT Gender, COUNT(*) AS TotalCustomers
FROM Customers
GROUP BY Gender;

-- Q16. Branches opened before 2010 vs 2010 onward, with customer counts (branch maturity vs size)
SELECT
  CASE WHEN b.OpeningDate < '2010-01-01' THEN 'Before 2010' ELSE '2010 Onward' END AS BranchVintage,
  COUNT(DISTINCT b.BranchID) AS Branches,
  COUNT(c.CustomerID)        AS TotalCustomers
FROM Branches b
LEFT JOIN Customers c ON b.BranchID = c.BranchID
GROUP BY 1;

-- Q17. Data-quality check: customers flagged as possible duplicates
SELECT CustomerID, CustomerName, DOB, BranchID
FROM Customers
WHERE DuplicateFlag = 'Possible Duplicate'
ORDER BY CustomerName;

-- Q18. Data-quality check: records that still need manual review
SELECT 'Invalid DOB' AS IssueType, CustomerID AS RecordID FROM Customers WHERE DOB_Valid <> 'Yes'
UNION ALL
SELECT 'AccountOpenDate before DOB', CustomerID FROM Customers WHERE AccountOpenDate_Valid <> 'Yes'
UNION ALL
SELECT 'Outstanding amount needs review', LoanID FROM Loans WHERE OutstandingAmount_Status = 'Needs Review';

-- Q19. Top 10 highest-income customers with disclosed income (VIP relationship list)
SELECT CustomerID, CustomerName, Occupation, AnnualIncome, City
FROM Customers
WHERE AnnualIncome_Status = 'Disclosed'
ORDER BY AnnualIncome DESC
LIMIT 10;

-- Q20. Loan-to-income ratio (basic credit risk check) for customers with an active loan and disclosed income
SELECT c.CustomerID, c.CustomerName, c.AnnualIncome, l.LoanAmount,
       ROUND(l.LoanAmount / c.AnnualIncome, 2) AS LoanToIncomeRatio
FROM Customers c
JOIN Loans l ON c.CustomerID = l.CustomerID
WHERE c.AnnualIncome_Status = 'Disclosed'
  AND l.LoanStatus = 'Active'
ORDER BY LoanToIncomeRatio DESC
LIMIT 20;
