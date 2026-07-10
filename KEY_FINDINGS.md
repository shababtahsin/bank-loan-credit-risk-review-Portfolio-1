# Key Findings — Bank Loan Credit Risk & Pricing Integrity Review

**Portfolio:** 2019 Loan Originations
**Loans Reviewed:** 148,670
**Total Loss Exposure:** $11.7B
**Portfolio Default Rate:** 24.64%

---

## H1 — Credit Scoring Model Integrity

**Verdict: CONFIRMED — The model has no predictive power**

### Evidence

| Credit Score Band | Total Loans | Defaults | Default Rate | Risk Rank |
|---|---|---|---|---|
| 850-900 | 18,896 | 4,782 | **25.31%** | **#1 (worst)** |
| 800-849 | 18,573 | 4,649 | 25.03% | #2 |
| 550-599 | 18,685 | 4,617 | 24.71% | #3 |
| 600-649 | 18,671 | 4,601 | 24.64% | #4 |
| 500-549 | 18,505 | 4,543 | 24.55% | #5 |
| 750-799 | 18,560 | 4,549 | 24.51% | #6 |
| 650-699 | 18,529 | 4,507 | 24.32% | #7 |
| 700-749 | 18,251 | 4,391 | **24.06%** | **#8 (best)** |

### Key Numbers
- **Spread across all bands:** 1.25 percentage points
- **Standard deviation:** 0.39pp
- **Expected spread for a working model:** 20–40pp

### Interpretation
Across a 400-point credit score range (500 to 900), the default rate varies by only 1.25 percentage points. The highest score band (850-900) defaults at a **higher rate** than the lowest score band (500-549). This is a model inversion — the opposite of what a functioning risk model should produce.

### Recommended Action
Commission a full credit model review. The current model cannot be used for risk-based pricing decisions. Charging different rates based on credit scores that carry no predictive power amounts to arbitrary pricing.

---

## H2 — Regional Interest Rate Mispricing

**Verdict: CONFIRMED — South is systematically underpriced for its risk**

### Evidence

| Region | Total Loans | Avg Rate | Default Rate | vs Portfolio Avg |
|---|---|---|---|---|
| North-East | 1,235 | 4.06% | 30.45% | +3.67pp ⚠️ small sample |
| Central | 8,697 | 4.07% | 27.54% | +0.76pp |
| **South** | **64,016** | **4.04%** | **26.63%** | **-0.15pp rate / +1.85pp default** |
| North | 74,722 | 4.05% | 22.51% | -4.27pp |

### Key Numbers
- **South vs North default gap:** 4.12 percentage points
- **South rate vs North rate:** South charged 0.01pp less despite 4.12pp more default risk
- **North-East caveat:** Only 0.83% of portfolio — insufficient sample for reliable conclusions

### Interpretation
The South region is the most significant mispricing finding. It carries the **cheapest average rate** in the portfolio (4.04%) while simultaneously carrying the **second highest default rate** (26.63%). The North region — the safest by default rate — is charged more than the South. Risk and price are moving in opposite directions.

### Recommended Action
Reprice South region loans upward to reflect actual default risk. A rate adjustment of approximately 0.1–0.2pp on 64,016 South loans would meaningfully reduce the bank's uncompensated risk exposure. Exclude North-East from rate decisions until sample size is sufficient.

---

## H3 — Hidden Stress Exposure

**Verdict: CONFIRMED — Extreme default concentration above 100% LTV**

### Evidence — Default Rate by LTV Band (Reliable Rows Only)

| LTV Band | Total Loans | Defaults | Default Rate |
|---|---|---|---|
| 0-20% | 1,922 | 756 | 39.33% |
| 20-40% | 9,991 | 3,784 | 37.87% |
| 40-60% | 26,927 | 6,268 | 23.28% |
| **60-80%** | **52,605** | **9,165** | **17.42% (safest)** |
| 80-100% | 51,572 | 11,641 | 22.57% |
| **100-120%** | **3,205** | **2,583** | **80.59%** |
| **>120%** | **1,429** | **1,428** | **99.93%** |

### Evidence — Loss Exposure by LTV Band (Defaulted Loans Only)

| LTV Band | Loss Exposure | % of Total Loss |
|---|---|---|
| 80-100% | $3.69B | 34.0% |
| 60-80% | $2.96B | 27.3% |
| 40-60% | $1.70B | 15.7% |
| 100-120% | $1.04B | 9.6% |
| >120% | $0.75B | 6.9% |
| 20-40% | $0.66B | 6.1% |
| 0-20% | $0.08B | 0.7% |

### Income Shock Simulation (10% Income Reduction)
- **Currently performing loans analysed:** 104,220
- **Loans breaching 50% DTI under 10% shock:** 21,269
- **At-risk exposure:** $7.06B

### Interpretation
The headline 24.64% default rate masks catastrophic stress above 100% LTV. A borrower above 120% LTV has a 99.93% chance of defaulting — near-certain loss. Even the 80-100% LTV band carries $3.69B in defaulted loan exposure — the single largest loss concentration in the portfolio. Under a 10% income shock, $7.06B of currently performing loans would breach standard DTI stress thresholds.

### Recommended Action
1. Place all loans above 100% LTV (4,634 loans, ~$1.79B exposure) on enhanced monitoring immediately
2. Commission stress testing across the full 80-100% LTV segment ($3.69B)
3. Review underwriting criteria for high-LTV originations — the data suggests LTV above 100% should not have been approved at current income levels

---

## Portfolio Summary

| Metric | Value |
|---|---|
| Total Loans | 148,670 |
| Default Rate | 24.64% |
| Total Loss Exposure | $11.7B |
| Avg Credit Score | 699 |
| Avg LTV | 73.26% |
| Avg Interest Rate | 4.05% |
| Avg DTI | 37.73% |
| Avg Income | $6,885 |

---

## Overall Assessment

All three hypotheses are confirmed. The 2019 portfolio carries systemic risk across three independent dimensions:

- A **credit model that cannot predict default** is being used as the basis for risk-based pricing
- A **regional pricing structure** that charges the cheapest rates to the riskiest region
- A **hidden stress concentration** in high-LTV segments that the headline default rate obscures

The combination of these three findings suggests structural weaknesses in underwriting, pricing, and risk model governance that require immediate Board-level attention.

---

*Independent Risk Review — Prepared by Shabab Tahsin — June 2026*
