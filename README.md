# Bank Loan Credit Risk & Pricing Integrity Review — 2019 Portfolio

[![SQL Server](https://img.shields.io/badge/SQL%20Server-SSMS-blue)](https://www.microsoft.com/en-us/sql-server)
[![Power BI](https://img.shields.io/badge/Power%20BI-Dashboard-yellow)](https://powerbi.microsoft.com/)
[![Dataset](https://img.shields.io/badge/Dataset-Kaggle-orange)](https://www.kaggle.com/)

## Project Overview

An independent credit risk review commissioned to interrogate the 2019 loan portfolio of a mortgage bank across **148,670 loans** and **$11.7B in total loss exposure**. The analysis tests three hypotheses using SQL Server for data engineering and analysis, and Power BI for a 5-page executive dashboard.

This project replicates the structure of a Big 4 consulting risk engagement — every cleaning decision is documented, every query is hypothesis-mapped, and findings are delivered through a boardroom-ready executive summary.



 
---

## Business Problem

The CRO commissioned an independent review to answer three questions:

| # | Hypothesis | Question |
|---|---|---|
| H1 | Credit Scoring Model Integrity | Is the credit scoring model actually predicting default — or are high-score borrowers defaulting at the same rate as low-score ones? |
| H2 | Regional Rate Mispricing | Are identical-risk borrowers being charged different rates by region — and is the cheapest region actually the riskiest? |
| H3 | Hidden Stress Exposure | Are high-LTV, low-income borrowers carrying disproportionate default risk invisible in the headline 24.64% default rate? |

---

## Key Findings

| Hypothesis | Verdict | Evidence |
|---|---|---|
| H1 | ✅ CONFIRMED | Default rate varies only **1.25pp** across a 400-point score range. The highest score band (850-900) defaults at **25.31%** — higher than the lowest band (500-549) at **24.55%**. Model has no predictive power. |
| H2 | ✅ CONFIRMED | South region charged the **cheapest rate (4.04%)** but carries the **second highest default rate (26.63%)** — 4.12pp above the safest region North (22.51%). Risk is systematically underpriced. |
| H3 | ✅ CONFIRMED | Default rate explodes past 100% LTV — **80.59%** at 100-120% LTV and **99.93%** above 120%. A 10% income shock puts **$7.06B** of currently performing loans at risk of breaching 50% DTI. |

---
 


---
 
## Dashboard Gallery

### 1. Portfolio Overview

![Portfolio Overview](screenshots/01_portfolio_overview.png)

What this dashboard establishes: the baseline. 148.67K loans, a 24.64% default rate, $12B in exposure, and an average credit score of 699.79 — a portfolio that looks unremarkable at face value. The regional split is heavily skewed: North (75K) and South (64K) carry 94% of loan volume between them, while Central (9K) and North-East (1K) are minor. Loan purpose is dominated by two categories (p3 at 37.6%, p4 at 36.9%), with p1 and p2 making up the remainder.
Why it matters: this page exists to be disagreed with. A 24.64% default rate and a 699 average score read as "normal mortgage book" to anyone skimming the top line. The next three pages exist specifically to show that headline is hiding three separate structural problems.

### 2. Credit Score Model Integrity

![Credit Score Model Integrity](screenshots/02_h1_credit_score.png)


What this dashboard shows: default rate broken out across eight 50-point credit score bands. If the scoring model worked, this should fall in a clean staircase — lowest scores defaulting most, highest scores defaulting least. It doesn't. The bars are essentially flat: 24.06% at the best-performing band up to 25.31% at the worst — a spread of just 1.25 percentage points across the entire 400-point range. Worse, the 850-900 band (the "best" borrowers on paper) has the highest default rate of all eight bands.
Why it matters: a working credit score model should produce a spread of 20–40 percentage points. A 1.25pp spread means the score is noise, not signal — every risk-based pricing decision built on it is currently arbitrary.

### 3. Regional Rate Mispricing

![Regional Rate Mispricing](screenshots/03_h2_rate_mispricing.png)

What this dashboard shows: average interest rate vs actual default rate by region. Rates are compressed and nearly identical (4.04%–4.10%). Default rates are not (22.51% North, up to 30.45% North-East). South is charged the cheapest rate (4.04%) despite carrying meaningfully higher default risk (26.63%) than North (22.51%) — a 4.12pp gap the pricing doesn't reflect.
Why it matters: South is 64,016 loans — 43% of the portfolio, not an edge case. The bank is under-compensated for risk on nearly half its book. North-East (1,235 loans, 0.83%) is flagged separately as too small a sample to act on.


### 4. Hidden Stress Exposure

![Hidden Stress Exposure](screenshots/04_h3_stress_exposure.png)

What this dashboard shows: default rate and loss exposure by LTV band, plus an income-shock simulator. Default rate climbs from 17–35% in normal LTV ranges to 80.69% at 100–120% LTV and 99.9% above 120%. The biggest dollar concentration isn't even in the extreme bands — it's $3.6B sitting in the 80–100% LTV band. A 10% income shock puts 21,269 currently-performing loans ($7.06B) at risk of breaching DTI.
Why it matters: the 80–100% LTV band looks "fine" on default rate alone (22.6%, near portfolio average) but is the single largest loss concentration in dollars — exactly what a headline metric hides.


### 5. Executive Summary

![Executive Summary](screenshots/05_executive_summary.png)

What this page shows: the whole engagement on one slide — three verdicts, three actions, key numbers, absorbable in under a minute.
Why it matters: the three findings compound into one story: the credit model can't tell good borrowers from bad, so pricing isn't risk-adjusted, and the riskiest loans are hiding in a normal-looking average. That's a Board-level finding, not three separate data quality notes.

---
## Portfolio KPIs

| Metric | Value |
|---|---|
| Total Loans Reviewed | 148,670 |
| Portfolio Default Rate | 24.64% |
| Total Loss Exposure | $11.7B |
| Avg Credit Score | 699 |
| Avg LTV | 73.26% |
| Avg Interest Rate | 4.05% |
| Avg DTI | 37.73% |
| Avg Income | $6,885 |

---

## Tools & Technologies

| Tool | Purpose |
|---|---|
| SQL Server / SSMS | Database setup, raw staging, data cleaning, EDA, 10 analytical queries, 2 views, 1 stored procedure |
| Power BI Desktop | Star schema (1 fact + 6 dim tables), 6 DAX measures, 5-page executive dashboard |
| T-SQL | CTEs, window functions (NTILE, ROW_NUMBER, PERCENTILE_CONT), BULK INSERT, BCP export |
| DAX | Default Rate %, Total Loss Exposure, Avg Interest Rate, Avg LTV, H1 Spread, At-Risk Exposure |

---

## Project Structure

```
bank-loan-credit-risk-review/
├── README.md
├── DATA_DICTIONARY.md
├── KEY_FINDINGS.md
├── .gitignore
├── sql/
│   └── Phase2_SQL_Analysis.sql
├── powerbi/
│   └── BankLoanCreditRisk.pbix
├── data/
│   ├── Loan_Default.csv
│   └── Clean_LoanData.csv
└── screenshots/
    ├── 01_portfolio_overview.png
    ├── 02_h1_credit_score.png
    ├── 03_h2_rate_mispricing.png
    ├── 04_h3_stress_exposure.png
    └── 05_executive_summary.png
```

---

## SQL Phase — What Was Built

The SQL script (`Phase2_SQL_Analysis.sql`) is structured as a complete, reproducible pipeline:

1. **Database Setup** — `BankLoanCreditRisk` database created from scratch
2. **Raw Staging Table** — `dbo.Raw_LoanData` mirrors the source CSV 1:1 (audit trail)
3. **BULK INSERT** — 148,670 rows imported via T-SQL script (fully reproducible)
4. **Data Cleaning** — `dbo.Clean_LoanData` created with regional median imputation, casing standardisation, LTV recalculation, and 4 derived columns (`LTV_clean`, `LTV_reliability_flag`, `credit_score_band`, `LTV_band`)
5. **Standalone EDA** — KPI reconciliation confirming SQL matches expected population
6. **10 Analytical Queries** — 3 for H1, 4 for H2, 3 for H3 — each using CTEs and window functions
7. **2 Reusable Views** — `vw_CreditScoreModelIntegrity` (H1), `vw_RegionalPricingRisk` (H2)
8. **Executive Stored Procedure** — `usp_ExecutiveRiskBriefing` — one call returns verdicts on all 3 hypotheses with income shock simulation

---

## Power BI Phase — Dashboard Pages

| Page | Title | Content |
|---|---|---|
| 1 | Portfolio Overview | 4 KPI cards, loan volume by region, default rate by region, loan purpose mix |
| 2 | Is the Credit Scoring Model Working? (H1) | Default rate by band bar chart, risk rank table, 1.25pp spread verdict card |
| 3 | Is Risk Mispriced by Region? (H2) | Rate vs default by region charts, mispricing gap table, South underpricing callout |
| 4 | Where is the Hidden Stress? (H3) | Default rate by LTV band, loss exposure by LTV band, income shock what-if slicer |
| 5 | Executive Summary — Risk Verdicts | 3 verdict cards (H1/H2/H3 CONFIRMED), key numbers, recommended actions |

---

## Data Source

**Dataset:** [Loan Default — Kaggle](https://www.kaggle.com/)
**Rows:** 148,670
**Columns:** 34
**Year:** 2019

---

## Recommended Actions

1. **H1** — Commission a full credit model review. The current model provides no differentiation across a 400-point score range and cannot be used for risk-based pricing.
2. **H2** — Reprice South region loans upward immediately. The South carries 26.63% default risk at the cheapest rate in the portfolio — a structural mispricing that is transferring risk to the bank.
3. **H3** — Place all loans above 100% LTV on enhanced monitoring. A 10% income shock alone puts $7.06B of currently performing loans at risk of breaching 50% DTI.

---

## Author

**Shabab Tahsin**
Business Data Analyst | SQL · Power BI · Python
[GitHub](https://github.com/shababtahsin)
