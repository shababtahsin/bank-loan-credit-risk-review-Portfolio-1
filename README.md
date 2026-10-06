# Bank Loan Credit Risk & Pricing Integrity Review — 2019 Portfolio

[![SQL Server](https://img.shields.io/badge/SQL%20Server-SSMS-blue)](https://www.microsoft.com/en-us/sql-server)
[![Power BI](https://img.shields.io/badge/Power%20BI-Dashboard-yellow)](https://powerbi.microsoft.com/)
[![Dataset](https://img.shields.io/badge/Dataset-Kaggle-orange)](https://www.kaggle.com/)

## Project Overview

This project reviews a 2019 mortgage loan portfolio containing **148,670 loans** and approximately **$11.7B in defaulted-loan exposure**.

The aim was to look beyond the headline portfolio numbers and investigate three areas of credit risk:

- whether credit scores meaningfully separated higher- and lower-risk borrowers,
- whether interest rates were aligned with observed regional default risk,
- and whether high-LTV borrowers were creating hidden stress in the portfolio.

I used **SQL Server** for data cleaning, validation and analysis, then built a **5-page Power BI dashboard** to present the main findings.

---

## Business Problem

The analysis focused on three questions:

| # | Hypothesis | Question |
|---|---|---|
| H1 | Credit Scoring Model Integrity | Are higher credit scores actually associated with lower default rates? |
| H2 | Regional Pricing Alignment | Are interest rates aligned with observed default risk across regions? |
| H3 | Hidden Stress Exposure | Are high-LTV borrowers carrying substantially more risk than the overall portfolio default rate suggests? |

---

## Key Findings

| Hypothesis | Result | Evidence |
|---|---|---|
| H1 — Higher credit scores are associated with lower default rates | ❌ NOT SUPPORTED | Default rates vary by only **1.25 percentage points** across a 400-point credit score range. The 850–900 band records a **25.31%** default rate, compared with **24.55%** for the 500–549 band. Credit score bands show very little separation in observed default risk. |
| H2 — Regional pricing is aligned with observed default risk | ❌ NOT SUPPORTED | South has the **lowest average interest rate (4.04%)** but a **26.63% default rate**, 4.12 percentage points above North at 22.51%. The observed pricing does not closely track regional default risk. |
| H3 — High-LTV borrowers contain hidden stress exposure | ✅ SUPPORTED | Default rates rise sharply above 100% LTV — **80.59%** at 100–120% LTV and **99.93%** above 120%. Under a 10% income-shock scenario, **$7.06B** of currently performing loans would move above a 50% DTI threshold. |

---

## Dashboard Gallery

### 1. Portfolio Overview

![Portfolio Overview](screenshots/01_portfolio_overview.png.png)

This page gives the starting point for the analysis: **148.67K loans**, a **24.64% default rate**, approximately **$11.7B in defaulted-loan exposure**, and an average credit score of **699.79**.

The portfolio is heavily concentrated in North and South, which together account for around 94% of total loan volume. Loan purpose is also concentrated in categories p3 and p4.

The purpose of this page is to establish the overall portfolio before looking at the risk patterns underneath the averages.

---

### 2. Credit Score Model Integrity

![Credit Score Model Integrity](screenshots/02_h1_credit_score.png.png)

This page compares default rates across eight 50-point credit score bands.

If credit score were strongly separating risk in this dataset, lower-score groups should generally show higher default rates than higher-score groups.

Instead, the results are almost flat.

Default rates range from approximately **24.06% to 25.31%**, a spread of only **1.25 percentage points** across the full 400-point score range.

The 850–900 band also records the highest default rate of the eight groups.

The result suggests that credit score provides **very little discriminatory power for default risk in this dataset**.

---

### 3. Regional Pricing Alignment

![Regional Rate Mispricing](screenshots/03_h2_rate_mispricing.png.png)

This page compares average interest rates with observed default rates by region.

Average interest rates are tightly grouped between approximately **4.04% and 4.10%**, while default rates vary much more widely.

South has the lowest average rate at **4.04%**, but its default rate is **26.63%**, compared with **22.51%** in North.

South also contains **64,016 loans**, so this is not a small segment of the portfolio.

North-East records an even higher default rate, but with only **1,235 loans**, the sample is much smaller and should be interpreted more carefully.

The main finding is that **regional interest rates do not appear closely aligned with observed regional default risk**.

---

### 4. Hidden Stress Exposure

![Hidden Stress Exposure](screenshots/04_h3_stress_exposure.png.png)

This page looks at default risk and defaulted-loan exposure by loan-to-value band.

Default rates rise sharply once LTV moves above 100%, reaching **80.59%** in the 100–120% band and **99.93%** above 120%.

However, the largest dollar concentration of defaulted loans is actually in the **80–100% LTV band**, with approximately **$3.69B** in exposure.

The page also includes an income-shock scenario.

With a **10% fall in income**, 21,269 currently performing loans representing approximately **$7.06B** in loan exposure would move above a 50% DTI threshold.

This shows why looking only at the headline default rate can miss important concentrations of risk.

---

## 🧭 Executive Summary — Credit Risk Review

> **2019 Mortgage Portfolio · 148,670 Loans · 24.64% Default Rate · $11.7B Defaulted-Loan Exposure**

The analysis tested three areas of portfolio risk: **credit-score separation, regional pricing alignment, and high-LTV stress exposure**.

---

### 🔴 H1 — Credit Score Risk Separation

![H1](https://img.shields.io/badge/H1-NOT%20SUPPORTED-red)

**Higher credit scores did not correspond with meaningfully lower default rates.**

- Default-rate spread across the full 500–900 score range: **1.25 percentage points**
- **850–900 score:** 25.31% default
- **500–549 score:** 24.55% default
- The highest score band actually recorded a slightly **higher** default rate than the lowest score band

📌 **Finding:** Credit score provided very little separation between lower- and higher-default groups in this portfolio.

💡 **Recommended Review:** Test whether additional borrower and loan characteristics could improve risk segmentation.

---

### 🟠 H2 — Regional Pricing Alignment

![H2](https://img.shields.io/badge/H2-NOT%20SUPPORTED-orange)

**Interest rates did not closely track observed regional default risk.**

- **South average rate:** 4.04%
- **South default rate:** 26.63%
- **North default rate:** 22.51%
- South therefore defaulted **4.12 percentage points more** than North while receiving a slightly lower average rate

📌 **Finding:** Regional pricing appears weakly aligned with observed default risk.

💡 **Recommended Review:** Perform a fuller risk-adjusted pricing analysis before making regional pricing changes.

---

### 🟢 H3 — High-LTV Stress Exposure

![H3](https://img.shields.io/badge/H3-SUPPORTED-brightgreen)

**Default risk increased sharply once LTV moved above 100%.**

- **100–120% LTV:** 80.59% default
- **Above 120% LTV:** 99.93% default
- **80–100% LTV:** approximately $3.69B in defaulted-loan exposure
- Under a **10% income shock**, 21,269 currently performing loans representing approximately **$7.06B in exposure** would move above a 50% DTI threshold

📌 **Finding:** Very high-LTV borrowers show substantial stress compared with the overall portfolio.

💡 **Recommended Review:** Increase monitoring of high-LTV loans and perform further stress testing.

---

## 📊 Key Numbers at a Glance

| Metric | Result |
|---|---:|
| 🏦 Loans Reviewed | **148,670** |
| 📉 Portfolio Default Rate | **24.64%** |
| 💰 Defaulted-Loan Exposure | **$11.7B** |
| 🎯 Average Credit Score | **699** |
| 📏 H1 Default-Rate Spread | **1.25pp** |
| 🌎 South vs North Default Gap | **4.12pp** |
| ⚠️ 100–120% LTV Default Rate | **80.59%** |
| 🚨 >120% LTV Default Rate | **99.93%** |
| 🧪 Exposure Breaching 50% DTI Under 10% Income Shock | **$7.06B** |

> **Note:** Defaulted-loan exposure represents the loan amount associated with loans marked as defaulted. It is not the same as realised accounting loss because recovery and loss-given-default data are not available.

---

## 🎯 Overall Assessment

The portfolio shows **three important risk patterns**:

🔴 **Credit scores provide very little separation in observed default rates.**  
🟠 **Regional interest rates do not closely align with observed regional default risk.**  
🟢 **Default rates rise dramatically once LTV exceeds 100%.**

Together, the findings suggest that **credit-risk segmentation, regional pricing alignment, and high-LTV exposure should be reviewed together rather than treated as separate issues.**

---

### 👤 Prepared by

**Shah Tahsin**  
*Business Data Analyst · SQL · Power BI*

---

## Power BI Data Model

![Power BI Star Schema](screenshots/06_powerbi_data_model.png.png)

The Power BI model uses a star-schema structure, with the main loan dataset connected to supporting dimension tables.

This keeps filtering consistent across the dashboard and separates descriptive fields from the main analytical loan table.

---

## Portfolio KPIs

| Metric | Value |
|---|---|
| Total Loans Reviewed | 148,670 |
| Portfolio Default Rate | 24.64% |
| Defaulted Loan Exposure | $11.7B |
| Avg Credit Score | 699 |
| Avg LTV | 73.26% |
| Avg Interest Rate | 4.05% |
| Avg DTI | 37.73% |
| Avg Income | $6,885 |

> **Defaulted Loan Exposure** represents the total loan amount associated with loans marked as defaulted in the dataset. It should not be interpreted as realised accounting loss because recovery and loss-given-default data are not available.

---

## Tools & Technologies

| Tool | Purpose |
|---|---|
| SQL Server / SSMS | Database setup, staging, cleaning, validation, EDA and analytical queries |
| Power BI Desktop | Star schema, DAX measures and 5-page dashboard |
| T-SQL | CTEs, subqueries, window functions, statistical functions and `BULK INSERT` |
| DAX | Default Rate %, Defaulted Loan Exposure, Avg Interest Rate, Avg LTV, H1 Spread and At-Risk Exposure |

---

## Project Structure

```text
bank-loan-credit-risk-review-Portfolio-1/
├── README.md
├── DATA_DICTIONARY.md
├── KEY_FINDINGS.md
├── LICENSE
├── Phase2_SQL_Analysis with headers.sql
├── BankLoanCreditRisk.pbix
│
├── data/
│   ├── Loan_Default.csv
│   └── Cleaned dataset LoanData with headers.csv
│
└── screenshots/
    ├── 01_portfolio_overview.png.png
    ├── 02_h1_credit_score.png.png
    ├── 03_h2_rate_mispricing.png.png
    ├── 04_h3_stress_exposure.png.png
    ├── 05_executive_summary.png.png
    └── 06_powerbi_data_model.png.png
```

---

## SQL Phase — What Was Built

The SQL script (`Phase2_SQL_Analysis with headers.sql`) covers the full workflow from raw data to analysis:

1. **Database Setup** — creates the `BankLoanCreditRisk` database
2. **Raw Staging Table** — `dbo.Raw_LoanData` preserves the source structure
3. **BULK INSERT** — loads all 148,670 records into SQL Server
4. **Data Cleaning** — creates `dbo.Clean_LoanData` with imputation, text standardisation and derived fields
5. **EDA and Validation** — checks row counts, nulls, distributions and headline KPIs
6. **10 Analytical Queries** — 3 for H1, 4 for H2 and 3 for H3
7. **2 Reusable Views** — `vw_CreditScoreModelIntegrity` and `vw_RegionalPricingRisk`
8. **Stored Procedure** — `usp_ExecutiveRiskBriefing` returns the main portfolio findings and income-shock results

---

## SQL Data Pipeline & Analysis

The T-SQL script analyses **148,670 loans across 34 raw source columns**.

### Data Ingestion & Audit

- Creates the `BankLoanCreditRisk` database.
- Builds `dbo.Raw_LoanData` as a staging table matching the source file.
- Uses `BULK INSERT` to load the dataset.
- Checks row counts, null values and categorical consistency before cleaning.

---

### Data Cleaning & Feature Engineering

The main cleaning steps include:

- standardising regional naming
- replacing missing `loan_limit` values with `Unknown`
- imputing missing loan terms using the mode
- imputing missing property values using regional medians
- imputing missing income using regional medians
- recalculating loan-to-value from cleaned property values
- flagging LTV values above 150% as unreliable
- creating 50-point credit score bands
- creating 20-point LTV bands
- validating row counts and derived fields after cleaning

The analysis deliberately leaves fields such as `rate_of_interest` and `dtir1` as NULL where appropriate rather than heavily imputing them and potentially distorting the results.

---

## Hypothesis-Driven SQL Analysis

| Hypothesis | SQL Analysis |
|---|---|
| H1 — Credit Score Model Integrity | Default rate by score band, risk ranking using `ROW_NUMBER()`, and flat-curve testing using spread and `STDEV` |
| H2 — Regional Pricing Alignment | Interest rate by region and score band, regional default comparison, benchmark-gap analysis using CTEs, and small-sample checks |
| H3 — Hidden Stress Exposure | Default rate and defaulted-loan exposure by LTV band, plus high-LTV and income segmentation using `NTILE(4)` |

---

## SQL Techniques Used

- **CTEs and subqueries** for benchmark and segmented analysis
- **Window functions:** `ROW_NUMBER`, `NTILE` and `SUM() OVER()`
- **Statistical functions:** `PERCENTILE_CONT` and `STDEV`
- **Conditional aggregation:** `CASE WHEN` and grouped KPI calculations
- **Defensive SQL:** `ISNULL`, `NULLIF`, explicit casting and validation queries
- **Decision logic:** `CASE` and `EXISTS`
- **Data ingestion:** `BULK INSERT`

---

## SQL Objects

| Object | Purpose |
|---|---|
| `vw_CreditScoreModelIntegrity` | Reusable view showing score-band default rates, pricing and risk ranking |
| `vw_RegionalPricingRisk` | Regional pricing and default-risk comparison with portfolio benchmarks |
| `usp_ExecutiveRiskBriefing` | Returns portfolio KPIs, H1–H3 evidence and income-shock results |

---

## Executive Risk Procedure

The stored procedure accepts an income-shock percentage and returns the main portfolio results.

Example:

```sql
EXEC dbo.usp_ExecutiveRiskBriefing @IncomeShockPct = 10.00;
```

The 10% scenario recalculates DTI for currently performing loans and identifies borrowers that would move above a **50% DTI threshold**.

---

## Power BI Phase — Dashboard Pages

| Page | Title | Content |
|---|---|---|
| 1 | Portfolio Overview | KPI cards, loan volume by region, default rate by region and loan purpose mix |
| 2 | Is the Credit Scoring Model Working? | Default rate by score band, risk ranking and score-band spread |
| 3 | Is Pricing Aligned With Regional Risk? | Interest rate vs default rate, regional comparison and South analysis |
| 4 | Where is the Hidden Stress? | Default rate by LTV band, exposure by LTV band and income-shock scenario |
| 5 | Executive Summary | Summary of findings, key numbers and areas for further review |

---

## Data Source

**Dataset:** [Loan Default — Kaggle](https://www.kaggle.com/)  
**Rows:** 148,670  
**Raw Columns:** 34  
**Year:** 2019

---

## Recommended Actions

Based on the analysis, three areas would be worth reviewing further:

1. **Review the credit scoring approach**  
   Default rates show very little separation across the eight score bands, suggesting that credit score alone is not providing strong risk differentiation in this dataset.

2. **Review regional pricing, particularly South**  
   South shows a higher observed default rate than North while receiving a slightly lower average interest rate. A deeper risk-adjusted pricing analysis would be needed before making actual pricing changes.

3. **Increase monitoring of very high-LTV loans**  
   Loans above 100% LTV show much higher default rates, while the income-shock scenario also highlights substantial exposure among borrowers that could move above a 50% DTI threshold.

These recommendations are based on patterns observed in this dataset and would require further validation before being used for real lending, underwriting or pricing decisions.

---

## Overall Conclusion

The analysis found that the portfolio's headline numbers hide several important risk patterns.

Credit score bands provide very little separation in default rates, regional pricing does not appear closely aligned with observed regional default risk, and default rates increase sharply among borrowers above 100% LTV.

The main conclusion is therefore that **credit-risk segmentation, pricing alignment and high-LTV exposure should be reviewed together rather than treated as separate issues**.

---

## Author

**Shah Tahsin**  
Business Data Analyst | SQL · Power BI · Python

[GitHub](https://github.com/shababtahsin)
