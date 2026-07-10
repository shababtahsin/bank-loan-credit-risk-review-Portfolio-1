# Data Dictionary — Bank Loan Credit Risk & Pricing Integrity Review

**Source:** Kaggle Loan_Default.csv
**Rows:** 148,670
**Columns:** 34 raw + 4 derived

---

## Raw Columns (34)

| Column | Type | Description | Nulls | Cleaning Decision |
|---|---|---|---|---|
| ID | INT | Unique loan identifier | 0 | No action |
| year | INT | Loan origination year | 0 | All 2019 — no action |
| loan_limit | VARCHAR | Loan limit category (cf/ncf) | 3,344 | NULLs replaced with 'Unknown' |
| Gender | VARCHAR | Borrower gender (Male/Female/Joint/Sex Not Available) | 0 | No action |
| approv_in_adv | VARCHAR | Whether loan was pre-approved | 0 | No action |
| loan_type | VARCHAR | Loan type category (type1/type2/type3) | 0 | No action |
| loan_purpose | VARCHAR | Loan purpose code (p1/p2/p3/p4) | 0 | No action |
| Credit_Worthiness | VARCHAR | Credit worthiness band (l1/l2) | 0 | No action |
| open_credit | VARCHAR | Open credit indicator | 0 | No action |
| business_or_commercial | VARCHAR | Business/commercial loan flag | 0 | No action |
| loan_amount | INT | Loan amount in dollars | 0 | No action |
| rate_of_interest | DECIMAL | Interest rate charged (%) | 36,439 | Left NULL — too many to impute (24.5% of portfolio). Excluded from rate-based analysis where NULL |
| Interest_rate_spread | DECIMAL | Spread over benchmark rate | 36,639 | Left NULL — same pattern as rate_of_interest |
| Upfront_charges | DECIMAL | Upfront fees charged | 39,642 | Left NULL — too many to impute (26.7% of portfolio) |
| term | INT | Loan term in months | 41 | 41 NULLs imputed with mode = 360 (30-year mortgage) |
| Neg_ammortization | VARCHAR | Negative amortisation flag | 0 | No action |
| interest_only | VARCHAR | Interest-only loan flag | 0 | No action |
| lump_sum_payment | VARCHAR | Lump sum payment flag | 0 | No action |
| property_value | DECIMAL | Property value in dollars | 15,098 | NULLs imputed with regional median (Central $378K, North $418K, North-East $378K, South $438K) |
| construction_type | VARCHAR | Construction type (sb/mh) | 0 | No action |
| occupancy_type | VARCHAR | Occupancy type (pr/sr/ir) | 0 | No action |
| Secured_by | VARCHAR | Security type (home/land) | 0 | No action |
| total_units | VARCHAR | Number of units (1U/2U/3U/4U) | 0 | No action |
| income | DECIMAL | Borrower monthly income | 9,150 | NULLs imputed with regional median → stored as income_clean |
| credit_type | VARCHAR | Credit bureau type (EXP/CIB/CRIF/EQUI) | 0 | No action |
| Credit_Score | INT | Credit score (500–900) | 0 | No action |
| co-applicant_credit_type | VARCHAR | Co-applicant credit bureau type | 0 | No action |
| age | VARCHAR | Borrower age band (25-34/35-44/45-54/55-64/65-74/>74) | 0 | Stored as text — age range, not numeric |
| submission_of_application | VARCHAR | Application submission method | 0 | No action |
| LTV | DECIMAL | Raw loan-to-value ratio (%) | 15,098 | Replaced by LTV_clean (recalculated from loan_amount / property_value_clean) |
| Region | VARCHAR | Geographic region | 0 | Casing standardised: 'south' → 'South', 'central' → 'Central' |
| Security_Type | VARCHAR | Security type (direct/Indirect) | 0 | No action |
| Status | INT | Default flag — 1 = defaulted, 0 = performing | 0 | No action — target variable |
| dtir1 | DECIMAL | Debt-to-income ratio (%) | 24,121 | Left NULL — 16.2% missing. Used where available for H3 income shock analysis |

---

## Derived Columns (4) — Added During Cleaning

| Column | Type | Description | Logic |
|---|---|---|---|
| property_value_clean | DECIMAL | Cleaned property value | Raw value if available; else regional median imputed |
| income_clean | DECIMAL | Cleaned income | Raw value if available; else regional median imputed |
| LTV_clean | DECIMAL | Recalculated LTV | (loan_amount / property_value_clean) × 100 |
| LTV_reliability_flag | VARCHAR | Flags rows with unrealistic LTV | 'Unreliable' if LTV_clean > 150%; else 'Reliable'. ~1,019 rows flagged. All LTV-based analysis filtered to Reliable rows only. |
| credit_score_band | VARCHAR | 50-point credit score bands | 500-549 / 550-599 / 600-649 / 650-699 / 700-749 / 750-799 / 800-849 / 850-900 |
| LTV_band | VARCHAR | 20-point LTV bands | 0-20 / 20-40 / 40-60 / 60-80 / 80-100 / 100-120 / >120 |

---

## Regional Medians Used for Imputation

| Region | Median Property Value | Median Income |
|---|---|---|
| Central | $378,000 | $5,460 |
| North | $418,000 | $5,760 |
| North-East | $378,000 | $4,920 |
| South | $438,000 | $5,880 |

---

## Status Column — Target Variable

| Value | Meaning | Count | % of Portfolio |
|---|---|---|---|
| 0 | Performing (no default) | 112,052 | 75.36% |
| 1 | Defaulted | 36,618 | 24.64% |

---

## Notes

- All LTV-based analysis (H3) is filtered to `LTV_reliability_flag = 'Reliable'` to exclude rows where property_value data was unrealistic (resulted in LTV > 150% after imputation)
- North-East region contains only 1,235 loans (0.83% of portfolio) — all North-East findings are flagged as statistically unreliable due to small sample size
- `rate_of_interest`, `Interest_rate_spread`, and `Upfront_charges` were left NULL rather than imputed — imputing 24-27% of a column introduces too much noise and would distort hypothesis testing
