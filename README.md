# Bank Customer, Loan & Credit Card Analysis

---

## 1. Project Overview

A mid-size bank's data was scattered across 5 raw sheets (Customers, Branches,
KYC, Loans, Credit Cards) with inconsistent formatting, missing values, and
mixed date formats. This project:

1. **Cleans** the raw data (Excel-based cleaning logic, documented step by step)
2. **Models** it as a relational schema and answers 20 business questions in **SQL**
3. **Visualizes** it in a formula-driven **Excel dashboard** (KPI cards + charts)

**Tools used:** Microsoft Excel (formulas, tables, charts) and SQL only.

---

## 2. Files in this Project

| File | Description |
|---|---|
| `Bank_Data_Cleaned_Dashboard.xlsx` | Cleaned data + interactive dashboard (see structure below) |
| `sql/bank_analysis.sql` | Table schema (`CREATE TABLE`) + 20 analysis queries |
| `sql/csv/*.csv` | Cleaned tables as CSV, ready to import into any SQL database |
| `README.md` | This file |

### Structure of `Bank_Data_Cleaned_Dashboard.xlsx`

| Sheet | Contents |
|---|---|
| **Dashboard** | KPI cards + 6 charts — the main report |
| **Summary_Tables** | Helper tables (`COUNTIF`/`SUMIF`/`SUMPRODUCT` formulas) that feed the charts |
| **Customer_Data** | 1,050 cleaned customer records |
| **Branches_Data** | 30 branches |
| **KYC_Data** | 945 KYC records |
| **Loan_Data** | 600 loan records |
| **Creditcard_Data** | 500 credit card records |
| **Data_Quality_Log** | Every issue found in the raw data and the exact action taken |

All KPI and chart values are **live Excel formulas** referencing the cleaned
data sheets — if a row is edited, the dashboard recalculates automatically.

---

## 3. Data Cleaning — What Was Wrong and How It Was Fixed

The raw file had the typical mess of a real-world dataset. Full detail is in
the **Data_Quality_Log** sheet; the key issues:

| Issue | Where | Fix Applied |
|---|---|---|
| Dates stored in 4+ formats (`DD-MM-YYYY`, `DD Mon YYYY`, `MM/DD/YYYY`, `YYYY-MM-DD`) | All date columns | Parsed and standardized to one date format across every sheet |
| Gender entered as `M`, `m`, `Male`, `MALE`, `male` | Customer_Data | Standardized to `Male` / `Female` |
| PAN numbers with stray spaces / wrong pattern | Customer_Data, KYC_Data | Cleaned formatting; added a `PAN_Valid` flag (Yes/No/Missing) instead of silently dropping bad values |
| Aadhaar numbers not always 12 digits | Customer_Data, KYC_Data | Stripped non-digits; added an `Aadhaar_Valid` flag |
| `AnnualIncome` missing for ~49% of customers | Customer_Data | Left blank rather than guessed/imputed (imputing half a column would distort income analysis); flagged with `AnnualIncome_Status` |
| 41 customers with a Date of Birth in the future | Customer_Data | Flagged with `DOB_Valid`; Age left blank instead of showing a negative number |
| 43 customers whose account was opened before their DOB | Customer_Data | Flagged with `AccountOpenDate_Valid` for manual review |
| 100 customers sharing the same name & DOB (possible duplicate entries under different CustomerIDs) | Customer_Data | Flagged with `DuplicateFlag`; not auto-deleted since each has a distinct CustomerID and could be a genuine coincidence |
| `LoanStatus` value `NPA` turned into `Npa` by text-casing | Loan_Data | Corrected back to the standard acronym `NPA` |
| 11 loans missing `OutstandingAmount` | Loan_Data | Set to 0 for Closed loans (matches the pattern of every other closed loan); the remaining Active/NPA cases left blank and flagged `Needs Review` — a real bank would not guess this number |
| 68 credit cards missing `LastPaymentDate` | Creditcard_Data | Left blank and flagged `No Payment Recorded` (likely a card that has never been used) |
| Missing Phone (30) / Email (57) / KYC PAN & Aadhaar (176) / KYCDate (139) | Various | Left blank rather than fabricated; visible via null counts in each sheet |

**Principle followed throughout:** never invent a value. Every gap is either
left blank or filled only when the surrounding data logically implies the
answer (e.g., a Closed loan's outstanding balance is 0), and every fix is
flagged in a column so it stays auditable.

---

## 4. Dashboard KPIs & Charts

**KPI cards:** Total Customers · Active Customers · Total Branches · Total
Loans Disbursed · Loans Outstanding · NPA + Default Loans · Total Credit
Cards · Card Outstanding

**Charts:** Loan Count & Amount by Status · Total Loan Amount by Loan Type ·
KYC Status Breakdown · Credit Card Status Breakdown · Customers by Region ·
Total Credit Limit by Card Type

---

## 5. Key Insights

- **1,050 customers**, of whom **866 (82%) are Active**.
- The loan book totals **≈₹11.5 Cr disbursed**, with **≈₹3.6 Cr still
  outstanding**.
- **92 loans (15% of all loans)** are classified NPA or Default — worth a
  closer look by loan type and branch.
- **Home Loans** carry the largest total disbursed amount of any loan type,
  followed by Business Loans.
- KYC is **Verified** for the large majority of customers, but a meaningful
  slice sits in Pending/Rejected — a direct operational to-do list (see SQL
  Q11).
- Roughly **half of customers have no disclosed Annual Income**, which limits
  how far income-based segmentation can go without follow-up data collection.
- **100 customer records share a name and DOB** with another record — a
  data-entry/dedup issue worth resolving before this data is used for credit
  decisions.

---

## 6. SQL Component

`sql/bank_analysis.sql` contains:
- `CREATE TABLE` statements for all 5 tables with primary/foreign keys
- 20 business questions answered in SQL, grouped by theme:
  - Customer profile & segmentation (Q1, Q2, Q14, Q15, Q19)
  - Branch & region performance (Q3, Q4, Q8, Q16)
  - Loan portfolio & risk (Q5, Q6, Q7, Q20)
  - Cross-sell & KYC operations (Q9, Q10, Q11, Q13)
  - Credit card portfolio (Q12)
  - Data-quality audit queries (Q17, Q18)

To run it: create a database, execute the `CREATE TABLE` statements, import
the CSVs from `sql/csv/` into the matching tables, then run the queries.

---

## 7. Skills Demonstrated

- Data cleaning: standardizing dates, categorical values, and identifiers
- Data validation: format checks (PAN/Aadhaar), logical checks (future DOB,
  account-before-birth), duplicate detection
- Excel: `SUMIF`/`COUNTIF`/`SUMPRODUCT` formulas, Tables, KPI dashboard design,
  chart building
- SQL: schema design, joins across 5 tables, aggregation, subqueries, `CASE`
  logic, business-question framing

---

## 8. Limitations & Next Steps

- Income data is missing for ~49% of customers — a targeted data-collection
  effort would substantially improve income-based analysis.
- 100 possible-duplicate customer records and 43 date-logic errors are
  flagged, not resolved — this needs a human decision (e.g., contacting the
  branch) rather than an automated guess.
