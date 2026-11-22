
/* ============================================================
   PROJECT: Bank Loan Credit Risk & Pricing Integrity Review
   PART 1: DATABASE SETUP & RAW DATA IMPORT

   Business Question:
   How can the bank create a dedicated database, preserve
   all 34 original loan attributes in a raw staging table,
   import the complete 2019 loan dataset without applying
   cleaning transformations, and verify that all 148,670
   records have been loaded?

   Source: Kaggle Loan_Default.csv
   Expected Records: 148,670
   Original Columns: 34
   ============================================================ */


-- ============================================================
-- 1.1 — CREATE DATABASE / USE
-- Task: Create and select the project database.
-- (Give the bank loan records their own database.)
-- ============================================================

USE master;
GO

-- Run only if starting from a clean environment.
-- DROP DATABASE BankLoanCreditRisk;

CREATE DATABASE BankLoanCreditRisk;
GO

USE BankLoanCreditRisk;
GO

-- Verify current database.
SELECT DB_NAME() AS Current_Database;
GO


-- ============================================================
-- 1.2 — CREATE TABLE / RAW STAGING
-- Task: Reproduce the original CSV's 34 columns.
-- (Keep the original loan information unchanged.)
-- ============================================================

CREATE TABLE dbo.Raw_LoanData (
    ID                          INT,
    [year]                      INT,
    loan_limit                  VARCHAR(10),
    Gender                      VARCHAR(30),
    approv_in_adv               VARCHAR(10),
    loan_type                   VARCHAR(10),
    loan_purpose                VARCHAR(10),
    Credit_Worthiness           VARCHAR(10),
    open_credit                 VARCHAR(10),
    business_or_commercial      VARCHAR(10),
    loan_amount                 INT,
    rate_of_interest            DECIMAL(6,3) NULL,
    Interest_rate_spread        DECIMAL(8,4) NULL,
    Upfront_charges             DECIMAL(10,2) NULL,
    term                        INT NULL,
    Neg_ammortization           VARCHAR(10),
    interest_only               VARCHAR(10),
    lump_sum_payment            VARCHAR(10),
    property_value              DECIMAL(12,2) NULL,
    construction_type           VARCHAR(10),
    occupancy_type              VARCHAR(10),
    Secured_by                  VARCHAR(20),
    total_units                 VARCHAR(10),
    income                      DECIMAL(12,2) NULL,
    credit_type                 VARCHAR(10),
    Credit_Score                INT,
    [co-applicant_credit_type]  VARCHAR(10),
    age                         VARCHAR(10),
    submission_of_application   VARCHAR(10),
    LTV                         DECIMAL(10,5) NULL,
    Region                      VARCHAR(20),
    Security_Type               VARCHAR(20),
    Status                      INT,
    dtir1                       DECIMAL(6,2) NULL
);
GO


-- ============================================================
-- 1.3 — BULK INSERT / LOAD CSV
-- Task: Import all original loan records.
-- (Copy the loan dataset into SQL Server.)
-- ============================================================

BULK INSERT dbo.Raw_LoanData
FROM 'F:\Data analyst IOD\Project 5 Revision\BankLoanProject\Loan_Default.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0d0a',
    TABLOCK
);
GO


-- ============================================================
-- 1.4 — IMPORT VERIFICATION
-- Task: Verify the imported row count.
-- (Make sure no loan records are missing.)
-- Business Question:
-- Were all 148,670 loan records imported successfully?
-- ============================================================

SELECT
    COUNT(*) AS RowsImported
FROM dbo.Raw_LoanData;
GO

-- ============================================================
-- PHASE 2: DATA CLEANING
-- 2.1 — INITIAL DATA QUALITY AUDIT
-- Task: Identify missing values in the raw loan dataset.
-- (Count how many empty values exist in each important column.)
--
-- Business Question:
-- Which important loan columns contain missing values,
-- how many records are affected, and what percentage
-- of the portfolio is missing information?
-- ============================================================

SELECT
    COUNT(*) AS Total_Rows,

    -- Missing financial values
    SUM(CASE WHEN rate_of_interest IS NULL THEN 1 ELSE 0 END) AS Missing_Interest_Rates,
    SUM(CASE WHEN Interest_rate_spread IS NULL THEN 1 ELSE 0 END) AS Missing_Interest_Spreads,
    SUM(CASE WHEN Upfront_charges IS NULL THEN 1 ELSE 0 END) AS Missing_Upfront_Charges,
    SUM(CASE WHEN dtir1 IS NULL THEN 1 ELSE 0 END) AS Missing_DTI,

    -- Missing property and income values
    SUM(CASE WHEN property_value IS NULL THEN 1 ELSE 0 END) AS Missing_Property_Values,
    SUM(CASE WHEN income IS NULL THEN 1 ELSE 0 END) AS Missing_Income,
    SUM(CASE WHEN LTV IS NULL THEN 1 ELSE 0 END) AS Missing_LTV,

    -- Missing categorical values
    SUM(CASE WHEN loan_limit IS NULL THEN 1 ELSE 0 END) AS Missing_Loan_Limits,
    SUM(CASE WHEN approv_in_adv IS NULL THEN 1 ELSE 0 END) AS Missing_Advance_Approvals,
    SUM(CASE WHEN submission_of_application IS NULL THEN 1 ELSE 0 END) AS Missing_Submissions,
    SUM(CASE WHEN age IS NULL THEN 1 ELSE 0 END) AS Missing_Age,
    SUM(CASE WHEN loan_purpose IS NULL THEN 1 ELSE 0 END) AS Missing_Loan_Purposes,
    SUM(CASE WHEN Neg_ammortization IS NULL THEN 1 ELSE 0 END) AS Missing_Negative_Amortization,

    -- Missing loan terms
    SUM(CASE WHEN term IS NULL THEN 1 ELSE 0 END) AS Missing_Terms

FROM dbo.Raw_LoanData;
-- ============================================================
-- PHASE 2: DATA CLEANING
-- 2.2 — DUPLICATE DETECTION
-- Task: Identify duplicate loan IDs and duplicate records.
-- (Check whether the same loan appears more than once.)
--
-- Business Question:
-- Are any loans recorded more than once, potentially
-- causing incorrect loan counts, default rates or
-- financial calculations?
-- ============================================================

-- CHECK 1: Find duplicate loan IDs.

SELECT
    ID,
    COUNT(*) AS Duplicate_Count
FROM dbo.Raw_LoanData
GROUP BY ID
HAVING COUNT(*) > 1
ORDER BY Duplicate_Count DESC;


-- CHECK 2: Identify repeated loan IDs using ROW_NUMBER().

;WITH Loan_Duplicates AS (
    SELECT
        ID,
        loan_amount,
        Credit_Score,
        Status,
        ROW_NUMBER() OVER (PARTITION BY ID ORDER BY ID) 
                                            AS Row_Number
    FROM dbo.Raw_LoanData
)

SELECT
    *
FROM Loan_Duplicates
WHERE Row_Number > 1;
 
-- ============================================================
-- PHASE 2: DATA CLEANING
-- 2.3 — REGION STANDARDISATION
-- Task: Standardise inconsistent region names.
-- (Make sure the same region always has the same name.)
--
-- Business Question:
-- Can the bank ensure all region names are consistently
-- written as Central, North, North-East, and South?
-- ============================================================

-- STEP 1: Standardise region names using a CTE.

;WITH Standardised_Regions AS (
    SELECT
        ID,
        Region,
        CASE
            WHEN LOWER(TRIM(Region)) = 'central' THEN 'Central'
            WHEN LOWER(TRIM(Region)) = 'north' THEN 'North'
            WHEN LOWER(TRIM(Region)) = 'north-east' THEN 'North-East'
            WHEN LOWER(TRIM(Region)) = 'south' THEN 'South'
            ELSE 'Unknown'
        END AS Region_Clean
    FROM dbo.Raw_LoanData
)

-- STEP 2: Verify original versus cleaned region names.

SELECT
    Region,
    Region_Clean,
    COUNT(*) AS Total_Loans
FROM Standardised_Regions
GROUP BY Region, Region_Clean
ORDER BY Region_Clean, Region;
-- ============================================================
-- PHASE 2: DATA CLEANING
-- 2.4 — CATEGORICAL DATA CLEANING
-- Task: Inspect and standardise categorical values.
-- (Replace missing category names with Unknown.)
--
-- Business Question:
-- Which categorical loan columns contain missing values,
-- and how can we standardise them without losing information?
-- ============================================================

-- STEP 1: Inspect categorical values and missing records.

SELECT loan_limit, COUNT(*) AS Total_Loans
FROM dbo.Raw_LoanData
GROUP BY loan_limit
ORDER BY loan_limit;

SELECT approv_in_adv, COUNT(*) AS Total_Loans
FROM dbo.Raw_LoanData
GROUP BY approv_in_adv
ORDER BY approv_in_adv;

SELECT loan_purpose, COUNT(*) AS Total_Loans
FROM dbo.Raw_LoanData
GROUP BY loan_purpose
ORDER BY loan_purpose;

SELECT Neg_ammortization, COUNT(*) AS Total_Loans
FROM dbo.Raw_LoanData
GROUP BY Neg_ammortization
ORDER BY Neg_ammortization;

SELECT age, COUNT(*) AS Total_Loans
FROM dbo.Raw_LoanData
GROUP BY age
ORDER BY age;

SELECT submission_of_application, COUNT(*) AS Total_Loans
FROM dbo.Raw_LoanData
GROUP BY submission_of_application
ORDER BY submission_of_application;

SELECT Gender, COUNT(*) AS Total_Loans
FROM dbo.Raw_LoanData
GROUP BY Gender
ORDER BY Gender;


-- STEP 2: Preview standardised categorical values.

;WITH Clean_Categories AS (
    SELECT
        ID,

        ISNULL(NULLIF(TRIM(loan_limit), ''), 'Unknown') AS loan_limit_clean,
        ISNULL(NULLIF(TRIM(approv_in_adv), ''), 'Unknown') AS approv_in_adv_clean,
        ISNULL(NULLIF(TRIM(loan_purpose), ''), 'Unknown') AS loan_purpose_clean,
        ISNULL(NULLIF(TRIM(Neg_ammortization), ''), 'Unknown') AS Neg_ammortization_clean,
        ISNULL(NULLIF(TRIM(age), ''), 'Unknown') AS age_clean,
        ISNULL(NULLIF(TRIM(submission_of_application), ''), 'Unknown') AS submission_clean,
        ISNULL(NULLIF(TRIM(Gender), ''), 'Unknown') AS Gender_clean

    FROM dbo.Raw_LoanData
)

SELECT TOP 10 *
FROM Clean_Categories
ORDER BY ID;

-- ============================================================
-- PHASE 2: DATA CLEANING
-- 2.5 — MISSING FINANCIAL VALUES
-- Task: Investigate missing financial information.
-- (Find missing numbers and check which loans they belong to.)
--
-- Business Question:
-- How many financial values are missing, and are these
-- missing values associated with loans that defaulted?
-- ============================================================

-- CHECK 1: Count missing financial values.

SELECT
    COUNT(*) AS Total_Loans,

    SUM(CASE WHEN rate_of_interest IS NULL THEN 1 ELSE 0 END) AS Missing_Interest_Rates,
    SUM(CASE WHEN Interest_rate_spread IS NULL THEN 1 ELSE 0 END) AS Missing_Interest_Spreads,
    SUM(CASE WHEN Upfront_charges IS NULL THEN 1 ELSE 0 END) AS Missing_Upfront_Charges,
    SUM(CASE WHEN dtir1 IS NULL THEN 1 ELSE 0 END) AS Missing_DTI

FROM dbo.Raw_LoanData;


-- CHECK 2: Compare missing values by loan status.

SELECT
    Status,
    COUNT(*) AS Total_Loans,

    SUM(CASE WHEN rate_of_interest IS NULL THEN 1 ELSE 0 END) AS Missing_Interest_Rates,
    SUM(CASE WHEN Interest_rate_spread IS NULL THEN 1 ELSE 0 END) AS Missing_Interest_Spreads,
    SUM(CASE WHEN Upfront_charges IS NULL THEN 1 ELSE 0 END) AS Missing_Upfront_Charges,
    SUM(CASE WHEN dtir1 IS NULL THEN 1 ELSE 0 END) AS Missing_DTI

FROM dbo.Raw_LoanData
GROUP BY Status
ORDER BY Status;


-- CHECK 3: Inspect affected loan records.

SELECT TOP 20
    ID,
    Status,
    loan_amount,
    rate_of_interest,
    Interest_rate_spread,
    Upfront_charges,
    dtir1
FROM dbo.Raw_LoanData
WHERE rate_of_interest IS NULL
   OR Interest_rate_spread IS NULL
   OR Upfront_charges IS NULL
   OR dtir1 IS NULL
ORDER BY ID;
-- ============================================================
-- PHASE 2: DATA CLEANING
-- 2.6 — MISSING PROPERTY VALUES AND INCOME
-- Task: Investigate missing values and calculate regional medians.
-- (Find empty numbers and the middle value for each region.)
--
-- Business Question:
-- How many property values, borrower incomes and LTV
-- ratios are missing, and what are the median property
-- values and incomes for each region?
-- ============================================================

-- CHECK 1: Count missing values.

SELECT
    COUNT(*) AS Total_Loans,
    SUM(CASE WHEN property_value IS NULL THEN 1 ELSE 0 END) AS Missing_Property_Values,
    SUM(CASE WHEN income IS NULL THEN 1 ELSE 0 END) AS Missing_Income,
    SUM(CASE WHEN LTV IS NULL THEN 1 ELSE 0 END) AS Missing_LTV
FROM dbo.Raw_LoanData;


-- CHECK 2: Compare missing values by region.

SELECT
    Region,
    COUNT(*) AS Total_Loans,
    SUM(CASE WHEN property_value IS NULL THEN 1 ELSE 0 END) AS Missing_Property_Values,
    SUM(CASE WHEN income IS NULL THEN 1 ELSE 0 END) AS Missing_Income
FROM dbo.Raw_LoanData
GROUP BY Region
ORDER BY Region;


-- CHECK 3: Calculate regional median property values and incomes.

;WITH Standardised_Regions AS (
    SELECT
        CASE
            WHEN LOWER(TRIM(Region)) = 'central' THEN 'Central'
            WHEN LOWER(TRIM(Region)) = 'north' THEN 'North'
            WHEN LOWER(TRIM(Region)) = 'north-east' THEN 'North-East'
            WHEN LOWER(TRIM(Region)) = 'south' THEN 'South'
            ELSE 'Unknown'
        END AS Region_Clean,
        property_value,
        income
    FROM dbo.Raw_LoanData
),

Regional_Medians AS (
    SELECT
        Region_Clean,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY property_value)
            OVER (PARTITION BY Region_Clean) AS Median_Property_Value,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY income)
            OVER (PARTITION BY Region_Clean) AS Median_Income
    FROM Standardised_Regions
    WHERE Region_Clean <> 'Unknown'
)

SELECT DISTINCT
    Region_Clean,
    CAST(Median_Property_Value AS DECIMAL(12,2)) AS Median_Property_Value,
    CAST(Median_Income AS DECIMAL(12,2)) AS Median_Income
FROM Regional_Medians
ORDER BY Region_Clean;
-- ============================================================
-- PHASE 2: DATA CLEANING
-- 2.7 — MISSING LOAN TERMS
-- Task: Investigate missing loan terms and preview replacements.
-- (Find missing repayment periods and fill them with 360 months.)
--
-- Business Question:
-- How many loans have missing repayment terms, what are
-- the existing loan-term durations, and can missing
-- terms be replaced with 360 months?
-- ============================================================

-- CHECK 1: Count loans by repayment term.

SELECT
    term,
    COUNT(*) AS Total_Loans
FROM dbo.Raw_LoanData
GROUP BY term
ORDER BY term;


-- CHECK 2: Inspect loans with missing terms.

SELECT
    ID,
    loan_amount,
    loan_type,
    term,
    Status
FROM dbo.Raw_LoanData
WHERE term IS NULL
ORDER BY ID;


-- CHECK 3: Preview replacement using a CTE.

;WITH Clean_Loan_Terms AS (
    SELECT
        ID,
        loan_amount,
        term,
        ISNULL(term, 360) AS term_clean
    FROM dbo.Raw_LoanData
)

SELECT
    ID,
    loan_amount,
    term,
    term_clean
FROM Clean_Loan_Terms
WHERE term IS NULL
ORDER BY ID;

-- ============================================================
-- PHASE 2: DATA CLEANING
-- 2.8 — NUMERIC VALIDATION AND LTV RECALCULATION
-- Task: Identify suspicious values and recalculate LTV.
-- (Check financial numbers and compare loans with house values.)
--
-- Business Question:
-- Are loan amounts, property values, borrower incomes,
-- credit scores and LTV ratios valid, and can we calculate
-- LTV accurately using loan amount and property value?
-- ============================================================

-- CHECK 1: Identify suspicious numerical values.

SELECT
    ID,
    loan_amount,
    property_value,
    income,
    Credit_Score,
    LTV
FROM dbo.Raw_LoanData
WHERE loan_amount <= 0
   OR property_value <= 0
   OR income <= 0
   OR Credit_Score NOT BETWEEN 500 AND 900
   OR LTV > 150
   OR LTV < 0;


-- CHECK 2: Recalculate LTV using the original property value.

SELECT TOP 20
    ID,
    loan_amount,
    property_value,
    LTV AS Original_LTV,

    CAST(
        loan_amount * 100.0 / NULLIF(property_value, 0)
        AS DECIMAL(10,5)
    ) AS Calculated_LTV

FROM dbo.Raw_LoanData
WHERE property_value IS NOT NULL
ORDER BY ID  ;


-- CHECK 3: Compare original and calculated LTV values.

;WITH LTV_Comparison AS (
    SELECT
        ID,
        LTV AS Original_LTV,

        CAST(
            loan_amount * 100.0 / NULLIF(property_value, 0)
            AS DECIMAL(10,5)
        ) AS Calculated_LTV

    FROM dbo.Raw_LoanData
)

SELECT
    COUNT(*) AS Total_Loans,

    SUM(CASE
        WHEN Original_LTV IS NULL THEN 1 ELSE 0
    END) AS Missing_Original_LTV,

    SUM(CASE
        WHEN Calculated_LTV IS NULL THEN 1 ELSE 0
    END) AS Missing_Calculated_LTV,

    SUM(CASE
        WHEN ABS(Original_LTV - Calculated_LTV) > 0.01
        THEN 1 ELSE 0
    END) AS LTV_Mismatches

FROM LTV_Comparison;

-- ============================================================
-- PHASE 2: DATA CLEANING
-- 2.9 — CREDIT SCORE AND LTV CLASSIFICATIONS
-- Task: Classify loans into meaningful risk categories.
-- (Put loans into groups based on their financial numbers.)
--
-- Business Question:
-- How can the bank classify borrowers by credit score,
-- LTV percentage and LTV reliability to identify
-- potentially risky loans?
-- ============================================================

;WITH Calculated_LTV AS (
    SELECT
        ID,
        Credit_Score,
        loan_amount,
        property_value,

        CAST(
            loan_amount * 100.0 / NULLIF(property_value, 0)
            AS DECIMAL(10,5)
        ) AS LTV_Ratio

    FROM dbo.Raw_LoanData
)

SELECT
    ID,
    Credit_Score,
    LTV_Ratio,

    -- Classification 1: Credit score bands
    CASE
        WHEN Credit_Score BETWEEN 500 AND 549 THEN '500-549'
        WHEN Credit_Score BETWEEN 550 AND 599 THEN '550-599'
        WHEN Credit_Score BETWEEN 600 AND 649 THEN '600-649'
        WHEN Credit_Score BETWEEN 650 AND 699 THEN '650-699'
        WHEN Credit_Score BETWEEN 700 AND 749 THEN '700-749'
        WHEN Credit_Score BETWEEN 750 AND 799 THEN '750-799'
        WHEN Credit_Score BETWEEN 800 AND 849 THEN '800-849'
        WHEN Credit_Score BETWEEN 850 AND 900 THEN '850-900'
        ELSE 'Other'
    END AS credit_score_band,

    -- Classification 2: LTV bands
    CASE
        WHEN LTV_Ratio IS NULL THEN 'Unknown'
        WHEN LTV_Ratio <= 20 THEN '0-20'
        WHEN LTV_Ratio <= 40 THEN '20-40'
        WHEN LTV_Ratio <= 60 THEN '40-60'
        WHEN LTV_Ratio <= 80 THEN '60-80'
        WHEN LTV_Ratio <= 100 THEN '80-100'
        WHEN LTV_Ratio <= 120 THEN '100-120'
        ELSE '>120'
    END AS LTV_band,

    -- Classification 3: LTV reliability
    CASE
        WHEN LTV_Ratio IS NULL THEN 'Unknown'
        WHEN LTV_Ratio > 150 THEN 'Unreliable'
        ELSE 'Reliable'
    END AS LTV_reliability_flag

FROM Calculated_LTV
ORDER BY ID;
-- ============================================================
-- PHASE 2: DATA CLEANING
-- 2.10 — CREATE FINAL CLEANED LOAN TABLE
-- Task: Combine all cleaning transformations.
-- (Save our cleaned loan records in a new permanent table.)
--
-- Business Question:
-- Can the bank preserve all 148,670 original loan records
-- while applying approved cleaning rules, calculating LTV,
-- and creating borrower risk classifications?
-- ============================================================

-- SAFETY: Prevent accidental replacement of an existing table.

IF OBJECT_ID('dbo.Clean_LoanData', 'U') IS NOT NULL
    THROW 51000, 'Clean_LoanData already exists.', 1;


-- ============================================================
-- CTE 1: STANDARDISE REGION AND CATEGORICAL VALUES
-- ============================================================

;WITH Standardised_Data AS (
    SELECT
        *,

        CASE
            WHEN LOWER(TRIM(Region)) = 'central' THEN 'Central'
            WHEN LOWER(TRIM(Region)) = 'north' THEN 'North'
            WHEN LOWER(TRIM(Region)) = 'north-east' THEN 'North-East'
            WHEN LOWER(TRIM(Region)) = 'south' THEN 'South'
            ELSE 'Unknown'
        END AS Region_Clean,

        ISNULL(NULLIF(TRIM(loan_limit), ''), 'Unknown') AS loan_limit_clean,
        ISNULL(NULLIF(TRIM(approv_in_adv), ''), 'Unknown') AS approv_in_adv_clean,
        ISNULL(NULLIF(TRIM(loan_purpose), ''), 'Unknown') AS loan_purpose_clean,
        ISNULL(NULLIF(TRIM(Neg_ammortization), ''), 'Unknown') AS Neg_ammortization_clean,
        ISNULL(NULLIF(TRIM(age), ''), 'Unknown') AS age_clean,
        ISNULL(NULLIF(TRIM(submission_of_application), ''), 'Unknown') AS submission_clean,
        ISNULL(NULLIF(TRIM(Gender), ''), 'Unknown') AS Gender_clean

    FROM dbo.Raw_LoanData
),

-- ============================================================
-- CTE 2: CALCULATE REGIONAL MEDIANS
-- ============================================================

Regional_Medians AS (
    SELECT DISTINCT
        Region_Clean,

        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY property_value)
            OVER (PARTITION BY Region_Clean) AS Median_Property_Value,

        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY income)
            OVER (PARTITION BY Region_Clean) AS Median_Income

    FROM Standardised_Data
    WHERE Region_Clean <> 'Unknown'
),
--<> means NOT EQUAL TO in SQL; for example, 
--Region_Clean <> 'Unknown' excludes regions labelled Unknown.
-- ============================================================
-- CTE 3: REPLACE APPROVED MISSING VALUES
-- ============================================================
/*
To replace missing loan terms, property values and borrower 
incomes using 360 months or the regional medians calculated in CTE 2.
*/
Filled_Values AS (
    SELECT
        S.*,

        ISNULL(S.term, 360) AS term_clean,

        CAST(
            ISNULL(S.property_value, M.Median_Property_Value)
            AS DECIMAL(12,2)
        ) AS property_value_clean,

        CAST(
            ISNULL(S.income, M.Median_Income)
            AS DECIMAL(12,2)
        ) AS income_clean

    FROM Standardised_Data S

    LEFT JOIN Regional_Medians M
        ON S.Region_Clean = M.Region_Clean
),

-- ============================================================
-- CTE 4: RECALCULATE LOAN-TO-VALUE RATIO
-- ============================================================

Calculated_LTV AS (
    SELECT
        *,-- from previous cte ,here cte3 

        CAST(
            loan_amount * 100.0 / NULLIF(property_value_clean, 0)
            AS DECIMAL(10,5)
        ) AS LTV_clean

    FROM Filled_Values
)

-- ============================================================
-- OUTER QUERY: CREATE FINAL CLEANED TABLE
-- ============================================================

SELECT
    -- Original and cleaned loan information
    ID,
    [year],
    loan_limit_clean AS loan_limit,
    Gender_clean AS Gender,
    approv_in_adv_clean AS approv_in_adv,
    loan_type,
    loan_purpose_clean AS loan_purpose,
    Credit_Worthiness,
    open_credit,
    business_or_commercial,
    loan_amount,
    rate_of_interest,
    Interest_rate_spread,
    Upfront_charges,
    term_clean AS term,
    Neg_ammortization_clean AS Neg_ammortization,
    interest_only,
    lump_sum_payment,
    property_value_clean,
    construction_type,
    occupancy_type,
    Secured_by,
    total_units,
    income_clean,
    credit_type,
    Credit_Score,
    [co-applicant_credit_type],
    age_clean AS age,
    submission_clean AS submission_of_application,
    Region_Clean AS Region,
    Security_Type,
    Status,
    dtir1,

    -- Derived Column 1: Clean LTV
    LTV_clean,

    -- Derived Column 2: LTV Reliability
    CASE
        WHEN LTV_clean IS NULL THEN 'Unknown'
        WHEN LTV_clean < 0 THEN 'Unreliable'
        WHEN LTV_clean > 150 THEN 'Unreliable'
        ELSE 'Reliable'
    END AS LTV_reliability_flag,

    -- Derived Column 3: Credit Score Bands
    CASE
        WHEN Credit_Score BETWEEN 500 AND 549 THEN '500-549'
        WHEN Credit_Score BETWEEN 550 AND 599 THEN '550-599'
        WHEN Credit_Score BETWEEN 600 AND 649 THEN '600-649'
        WHEN Credit_Score BETWEEN 650 AND 699 THEN '650-699'
        WHEN Credit_Score BETWEEN 700 AND 749 THEN '700-749'
        WHEN Credit_Score BETWEEN 750 AND 799 THEN '750-799'
        WHEN Credit_Score BETWEEN 800 AND 849 THEN '800-849'
        WHEN Credit_Score BETWEEN 850 AND 900 THEN '850-900'
        ELSE 'Other'
    END AS credit_score_band,

    -- Derived Column 4: LTV Bands
    CASE
        WHEN LTV_clean IS NULL THEN 'Unknown'
        WHEN LTV_clean < 0 THEN 'Invalid'
        WHEN LTV_clean <= 20 THEN '0-20'
        WHEN LTV_clean <= 40 THEN '20-40'
        WHEN LTV_clean <= 60 THEN '40-60'
        WHEN LTV_clean <= 80 THEN '60-80'
        WHEN LTV_clean <= 100 THEN '80-100'
        WHEN LTV_clean <= 120 THEN '100-120'
        ELSE '>120'
    END AS LTV_band

INTO dbo.Clean_LoanData
FROM Calculated_LTV;














/* ============================================================
   PROJECT: Bank Loan Credit Risk & Pricing Integrity Review
   PART 3: EXPLORATORY DATA ANALYSIS & KPI RECONCILIATION

   BUSINESS QUESTION:
   Can the bank verify the distribution of its 2019 loan
   portfolio across regions, calculate its key credit-risk
   and lending metrics, and reconcile SQL results against
   the original Excel KPI summary?

   SOURCE TABLE: dbo.Clean_LoanData
   EXPECTED RECORDS: 148,670

   METHOD:
   SELECT + COUNT + SUM + AVG + CAST + GROUP BY

   No CTEs required.
   ============================================================ */

USE BankLoanCreditRisk;
GO


-- ============================================================
-- 3.1 — REGION DISTRIBUTION CHECK
-- Task: Verify the cleaned regional loan distribution.
-- (Count how many loans belong to each region.)
-- Business Question:
-- How many loans were originated in each region,
-- and were all region names standardised correctly?
-- ============================================================

SELECT
    Region,
    COUNT(*) AS Total_Loans
FROM dbo.Clean_LoanData
GROUP BY Region
ORDER BY Region;


-- ============================================================
-- 3.2 — TOTAL LOANS & DEFAULT RATE
-- Task: Calculate portfolio size and overall default rate.
-- (Count all loans and find how many out of 100 defaulted.)
-- Business Question:
-- How many loans were originated in 2019, and what
-- percentage of those loans were classified as defaults?
-- ============================================================

SELECT
    COUNT(*) AS Total_Loans,
    CAST(AVG(CAST(Status AS DECIMAL(5,2))) * 100
        AS DECIMAL(5,2)) AS Default_Rate_Pct
FROM dbo.Clean_LoanData;


-- ============================================================
-- 3.3 — TOTAL DEFAULTED-LOAN EXPOSURE
-- Task: Calculate loan principal associated with defaults.
-- (Add up the amounts of loans marked as defaulted.)
-- Business Question:
-- What is the total loan amount associated with
-- borrowers whose loan Status equals 1?
-- ============================================================

SELECT
    CAST(
        SUM(
            CASE
                WHEN Status = 1 THEN CAST(loan_amount AS BIGINT)
                ELSE 0
            END
        ) AS BIGINT
    ) AS Total_Loss_Exposure
FROM dbo.Clean_LoanData;


-- ============================================================
-- 3.4 — AVERAGE CREDIT SCORE & LTV
-- Task: Calculate average borrower credit score and LTV.
-- (Find the typical score and loan-to-property percentage.)
-- Business Question:
-- What are the portfolio's average credit score
-- and average recalculated loan-to-value ratio?
-- ============================================================

SELECT
    AVG(Credit_Score) AS Avg_Credit_Score,
    CAST(AVG(LTV_clean) AS DECIMAL(5,2)) AS Avg_LTV
FROM dbo.Clean_LoanData;


-- ============================================================
-- 3.5 — AVERAGE INTEREST RATE, DTI & INCOME
-- Task: Calculate average pricing and borrower affordability.
-- (Find the typical interest rate, debt burden and income.)
-- Business Question:
-- What are the average interest rate, debt-to-income
-- ratio and borrower income across the loan portfolio?
-- ============================================================

SELECT
    CAST(AVG(rate_of_interest) AS DECIMAL(5,2)) AS Avg_Interest_Rate,
    CAST(AVG(dtir1) AS DECIMAL(5,2)) AS Avg_DTI,
    CAST(AVG(income_clean) AS DECIMAL(10,2)) AS Avg_Income
FROM dbo.Clean_LoanData;


-- ============================================================
-- 3.6 — HEADLINE KPI RECONCILIATION
-- Task: Reproduce the original eight portfolio KPIs.
-- (Put every important loan metric into one summary.)
-- Business Question:
-- Do the cleaned SQL portfolio metrics match the
-- original Excel KPI_SUMMARY reporting values?
-- ============================================================

SELECT
    COUNT(*) AS Total_Loans,

    CAST(AVG(CAST(Status AS DECIMAL(5,2))) * 100
        AS DECIMAL(5,2)) AS Default_Rate_Pct,

    CAST(
        SUM(
            CASE
                WHEN Status = 1 THEN CAST(loan_amount AS BIGINT)
                ELSE 0
            END
        ) AS BIGINT
    ) AS Total_Loss_Exposure,

    AVG(Credit_Score) AS Avg_Credit_Score,

    CAST(AVG(LTV_clean)
        AS DECIMAL(5,2)) AS Avg_LTV,

    CAST(AVG(rate_of_interest)
        AS DECIMAL(5,2)) AS Avg_Interest_Rate,

    CAST(AVG(dtir1)
        AS DECIMAL(5,2)) AS Avg_DTI,

    CAST(AVG(income_clean)
        AS DECIMAL(10,2)) AS Avg_Income

FROM dbo.Clean_LoanData;


-- ============================================================
-- END OF PART 3
-- ============================================================

/* ============================================================
   PROJECT: Bank Loan Credit Risk & Pricing Integrity Review
   PART 4: ANALYTICAL QUERIES

   BUSINESS QUESTIONS:

   H1 — CREDIT SCORE MODEL INTEGRITY
   Is the credit scoring model predicting defaults, or are
   high-score borrowers defaulting at similar rates to
   low-score borrowers?

   H2 — REGIONAL INTEREST RATE MISPRICING
   Are borrowers charged different interest rates across
   regions, and is the cheapest region experiencing higher
   default rates?

   H3 — HIDDEN STRESS EXPOSURE
   Are high-LTV, low-income borrowers experiencing
   disproportionately high default rates?

   SOURCE TABLE: dbo.Clean_LoanData
   TOTAL QUERIES: 10

   METHOD:
   GROUP BY + CASE + Window Functions + Simple CTEs
   ============================================================ */

USE BankLoanCreditRisk;
GO


/* ============================================================
   H1 — CREDIT SCORE MODEL INTEGRITY

   Business Question:
   Is the credit scoring model actually predicting default,
   or are high-score borrowers defaulting at similar rates
   to low-score borrowers?
   ============================================================ */


-- ============================================================
-- 4.1 — DEFAULT RATE BY CREDIT SCORE BAND
-- Task: Calculate default rates for each credit-score group.
-- (See which credit-score groups fail to repay more often.)
-- Business Question:
-- How many loans and defaults belong to each credit-score
-- band, and what percentage of loans defaulted?
-- ============================================================

SELECT
    credit_score_band,
    COUNT(*) AS total_loans,
    SUM(Status) AS defaults,
    CAST(AVG(CAST(Status AS DECIMAL(5,2))) * 100
        AS DECIMAL(5,2)) AS default_rate_pct
FROM dbo.Clean_LoanData
GROUP BY credit_score_band
ORDER BY credit_score_band;


-- ============================================================
-- 4.2 — WINDOW-RANKED SCORE BANDS
-- Task: Rank credit-score bands by default rate.
-- (Put the riskiest credit-score groups at the top.)
-- Business Question:
-- Which credit-score bands have the highest default rates,
-- ranked from highest to lowest?
-- ============================================================

SELECT
    credit_score_band,
    total_loans,
    defaults,
    default_rate_pct,
    ROW_NUMBER() OVER (
        ORDER BY default_rate_pct DESC
    ) AS risk_rank
FROM (
    SELECT
        credit_score_band,
        COUNT(*) AS total_loans,
        SUM(Status) AS defaults,
        CAST(AVG(CAST(Status AS DECIMAL(5,2))) * 100
            AS DECIMAL(5,2)) AS default_rate_pct
    FROM dbo.Clean_LoanData
    GROUP BY credit_score_band
) AS ScoreBands;


-- ============================================================
-- 4.3 — DEFAULT-RATE SPREAD & STANDARD DEVIATION
-- Task: Measure variation in defaults between score bands.
-- (Check whether the groups behave differently.)
-- Business Question:
-- What are the lowest, highest and average default rates
-- across credit-score bands, and how much do they vary?
-- ============================================================

;WITH BandRates AS (
    SELECT
        credit_score_band,
        CAST(AVG(CAST(Status AS DECIMAL(5,2))) * 100
            AS DECIMAL(5,2)) AS default_rate_pct
    FROM dbo.Clean_LoanData
    GROUP BY credit_score_band
)
SELECT
    MIN(default_rate_pct) AS lowest_default_rate,
    MAX(default_rate_pct) AS highest_default_rate,
    MAX(default_rate_pct) - MIN(default_rate_pct) AS spread,
    CAST(AVG(default_rate_pct) AS DECIMAL(5,2)) AS avg_across_bands,
    CAST(STDEV(default_rate_pct) AS DECIMAL(5,2)) AS std_dev
FROM BandRates;



/* ============================================================
   H2 — REGIONAL INTEREST RATE MISPRICING

   Business Question:
   Are borrowers being charged different interest rates
   across regions, and are cheaper regions experiencing
   unexpectedly high loan default rates?
   ============================================================ */


-- ============================================================
-- 4.4 — INTEREST RATE BY REGION & CREDIT SCORE BAND
-- Task: Compare average rates across regions and score bands.
-- (See what each region charges similar-score borrowers.)
-- Business Question:
-- What is the average interest rate charged in Central,
-- North, North-East and South for every credit-score band?
-- ============================================================

SELECT
    credit_score_band,
    CAST(AVG(CASE WHEN Region = 'Central'
        THEN rate_of_interest END) AS DECIMAL(5,2)) AS Central,
    CAST(AVG(CASE WHEN Region = 'North'
        THEN rate_of_interest END) AS DECIMAL(5,2)) AS North,
    CAST(AVG(CASE WHEN Region = 'North-East'
        THEN rate_of_interest END) AS DECIMAL(5,2)) AS [North-East],
    CAST(AVG(CASE WHEN Region = 'South'
        THEN rate_of_interest END) AS DECIMAL(5,2)) AS South
FROM dbo.Clean_LoanData
WHERE rate_of_interest IS NOT NULL
GROUP BY credit_score_band
ORDER BY credit_score_band;


-- ============================================================
-- 4.5 — DEFAULT RATE BY REGION
-- Task: Compare regional defaults against interest rates.
-- (Find regions that charge less but have more defaults.)
-- Business Question:
-- How many loans and defaults belong to each region,
-- and what are their default rates and average interest rates?
-- ============================================================

SELECT
    Region,
    COUNT(*) AS total_loans,
    SUM(Status) AS defaults,
    CAST(AVG(CAST(Status AS DECIMAL(5,2))) * 100
        AS DECIMAL(5,2)) AS default_rate_pct,
    CAST(AVG(rate_of_interest)
        AS DECIMAL(5,2)) AS avg_rate
FROM dbo.Clean_LoanData
GROUP BY Region
ORDER BY default_rate_pct DESC;


-- ============================================================
-- 4.6 — REGIONAL RISK VS PORTFOLIO BENCHMARK
-- Task: Compare each region against the regional averages.
-- (See which regions have worse defaults or cheaper rates.)
-- Business Question:
-- How far does each region's default rate and average
-- interest rate deviate from the average across regions?
-- ============================================================

-- Step 1: Calculate regional metrics and save temporarily.

DROP TABLE IF EXISTS #RegionRisk;

SELECT
    Region,
    COUNT(*) AS total_loans,
    CAST(AVG(CAST(Status AS DECIMAL(5,2))) * 100
        AS DECIMAL(5,2)) AS default_rate_pct,
    CAST(AVG(rate_of_interest)
        AS DECIMAL(5,2)) AS avg_rate
INTO #RegionRisk
FROM dbo.Clean_LoanData
GROUP BY Region;

-- Step 2: Calculate the same unweighted regional benchmarks
-- as the original query, then compare each region.

SELECT
    R.Region,
    R.total_loans,
    R.avg_rate,
    R.default_rate_pct,
    B.portfolio_avg_default,
    R.default_rate_pct - B.portfolio_avg_default AS default_vs_benchmark,
    R.avg_rate - B.portfolio_avg_rate AS rate_vs_benchmark
FROM #RegionRisk R
CROSS JOIN (
    SELECT
        AVG(default_rate_pct) AS portfolio_avg_default,
        AVG(avg_rate) AS portfolio_avg_rate
    FROM #RegionRisk
) B
ORDER BY R.default_rate_pct DESC;


-- ============================================================
-- 4.7 — NORTH-EAST SMALL-SAMPLE FLAG
-- Task: Identify regions with fewer than 5,000 loans.
-- (Warn the bank when a region has too little data.)
-- Business Question:
-- What percentage of the portfolio belongs to each region,
-- and which regions should be flagged because their
-- loan sample contains fewer than 5,000 records?
-- ============================================================

SELECT
    Region,
    COUNT(*) AS total_loans,
    CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER ()
        AS DECIMAL(5,2)) AS pct_of_portfolio,
    CAST(AVG(CAST(Status AS DECIMAL(5,2))) * 100
        AS DECIMAL(5,2)) AS default_rate_pct,
    CASE
        WHEN COUNT(*) < 5000
        THEN 'CAUTION: Small sample — interpret with care'
        ELSE 'Sufficient sample'
    END AS sample_flag
FROM dbo.Clean_LoanData
GROUP BY Region
ORDER BY total_loans;



/* ============================================================
   H3 — HIDDEN STRESS EXPOSURE

   Business Question:
   Is default risk concentrated among borrowers with high
   loan-to-value ratios and low incomes, beyond what the
   overall portfolio default rate reveals?
   ============================================================ */


-- ============================================================
-- 4.8 — DEFAULT RATE BY LTV BAND
-- Task: Calculate defaults across reliable LTV categories.
-- (Find which loan-to-property groups default most often.)
-- Business Question:
-- Among loans with reliable LTV values, how many loans and
-- defaults belong to each LTV band, and what percentage
-- of loans defaulted in each band?
-- ============================================================

SELECT
    LTV_band,
    COUNT(*) AS total_loans,
    SUM(Status) AS defaults,
    CAST(AVG(CAST(Status AS DECIMAL(5,2))) * 100
        AS DECIMAL(5,2)) AS default_rate_pct
FROM dbo.Clean_LoanData
WHERE LTV_reliability_flag = 'Reliable'
GROUP BY LTV_band
ORDER BY
    CASE LTV_band
        WHEN '0-20' THEN 1
        WHEN '20-40' THEN 2
        WHEN '40-60' THEN 3
        WHEN '60-80' THEN 4
        WHEN '80-100' THEN 5
        WHEN '100-120' THEN 6
        WHEN '>120' THEN 7
    END;


-- ============================================================
-- 4.9 — DEFAULTED-LOAN EXPOSURE BY LTV BAND
-- Task: Calculate defaulted principal by LTV category.
-- (Find where the largest amount of defaulted money sits.)
-- Business Question:
-- Among defaulted loans with reliable LTV values, how much
-- total loan principal belongs to each LTV band, and what
-- percentage of total defaulted principal does it represent?
-- ============================================================

SELECT
    LTV_band,
    COUNT(*) AS defaulted_loans,
    CAST(SUM(CAST(loan_amount AS BIGINT))
        AS BIGINT) AS total_loss_exposure,
    CAST(
        SUM(CAST(loan_amount AS BIGINT)) * 100.0 /
        NULLIF(SUM(SUM(CAST(loan_amount AS BIGINT))) OVER (), 0)
        AS DECIMAL(5,2)
    ) AS pct_of_total_loss
FROM dbo.Clean_LoanData
WHERE Status = 1
  AND LTV_reliability_flag = 'Reliable'
GROUP BY LTV_band
ORDER BY
    CASE LTV_band
        WHEN '0-20' THEN 1
        WHEN '20-40' THEN 2
        WHEN '40-60' THEN 3
        WHEN '60-80' THEN 4
        WHEN '80-100' THEN 5
        WHEN '100-120' THEN 6
        WHEN '>120' THEN 7
    END;


-- ============================================================
-- 4.10 — HIGH-LTV & LOW-INCOME STRESS SEGMENTS
-- Task: Group borrowers into income quartiles and LTV bands.
-- (Find whether lower-income borrowers with big loans
--  default more often.)
-- Business Question:
-- Among loans with reliable LTV values, which combinations
-- of high LTV and borrower income quartile have the
-- highest default rates, and what is their average income?
-- ============================================================

-- One CTE is necessary because NTILE() must be calculated
-- before its result can be used in GROUP BY.

;WITH IncomeQuartiles AS (
    SELECT
        *,
        NTILE(4) OVER (ORDER BY income_clean) AS income_quartile
    FROM dbo.Clean_LoanData
    WHERE LTV_reliability_flag = 'Reliable'
)
SELECT
    LTV_band,
    income_quartile,
    COUNT(*) AS total_loans,
    SUM(Status) AS defaults,
    CAST(AVG(CAST(Status AS DECIMAL(5,2))) * 100
        AS DECIMAL(5,2)) AS default_rate_pct,
    CAST(AVG(income_clean)
        AS DECIMAL(10,2)) AS avg_income
FROM IncomeQuartiles
WHERE LTV_band IN ('80-100', '100-120', '>120')
GROUP BY LTV_band, income_quartile
ORDER BY
    CASE LTV_band
        WHEN '80-100' THEN 1
        WHEN '100-120' THEN 2
        WHEN '>120' THEN 3
    END,
    income_quartile;


-- ============================================================
-- END OF PART 4
-- ============================================================

/* ============================================================
   PROJECT: Bank Loan Credit Risk & Pricing Integrity Review
   PART 5: REUSABLE SQL VIEWS

   BUSINESS QUESTIONS:

   1. Which credit-score bands have the highest default
      rates, and how do their interest rates and risk
      rankings compare?

   2. Which regions have higher-than-average default rates
      but lower-than-average interest rates, and which
      regions have small samples?

   3. Can both reports be retrieved using reusable views?

   SOURCE TABLE: dbo.Clean_LoanData

   METHOD:
   CREATE VIEW + GROUP BY + Window Functions + CROSS JOIN
   ============================================================ */

USE BankLoanCreditRisk;
GO


-- ============================================================
-- 5.1 — CREDIT SCORE MODEL INTEGRITY VIEW
-- Task: Create a reusable credit-score risk report.
-- (See which credit-score groups default most often.)
-- Business Question:
-- How many loans and defaults belong to each credit-score
-- band, what is their default rate and average interest
-- rate, and how do the bands rank by default risk?
-- ============================================================

CREATE OR ALTER VIEW dbo.vw_CreditScoreModelIntegrity
AS

SELECT
    credit_score_band,
    COUNT(*) AS total_loans,
    SUM(Status) AS defaults,

    CAST(AVG(CAST(Status AS DECIMAL(5,2))) * 100
        AS DECIMAL(5,2)) AS default_rate_pct,

    CAST(AVG(rate_of_interest)
        AS DECIMAL(5,2)) AS avg_rate,

    ROW_NUMBER() OVER (
        ORDER BY AVG(CAST(Status AS DECIMAL(5,2))) DESC
    ) AS risk_rank

FROM dbo.Clean_LoanData

GROUP BY credit_score_band;

GO


-- ============================================================
-- 5.2 — REGIONAL PRICING RISK VIEW
-- Task: Create a reusable regional pricing and risk report.
-- (Find regions with more defaults but cheaper loans.)
-- Business Question:
-- For each region, what are its loan count, portfolio
-- share, average interest rate and default rate?
-- How do its rates differ from regional benchmarks,
-- and does its sample size require caution?
-- ============================================================

CREATE OR ALTER VIEW dbo.vw_RegionalPricingRisk
AS

-- Step 1: Calculate regional metrics.
WITH RegionRisk AS (
    SELECT
        Region,
        COUNT(*) AS total_loans,

        CAST(AVG(CAST(Status AS DECIMAL(5,2))) * 100
            AS DECIMAL(5,2)) AS default_rate_pct,

        CAST(AVG(rate_of_interest)
            AS DECIMAL(5,2)) AS avg_rate,

        CAST(COUNT(*) * 100.0 /
            SUM(COUNT(*)) OVER ()
            AS DECIMAL(5,2)) AS pct_of_portfolio,

        CASE
            WHEN COUNT(*) < 5000
            THEN 'CAUTION: Small sample'
            ELSE 'Sufficient sample'
        END AS sample_flag

    FROM dbo.Clean_LoanData
    GROUP BY Region
)

-- Step 2: Compare regions against regional benchmarks.
SELECT
    R.Region,
    R.total_loans,
    R.pct_of_portfolio,
    R.avg_rate,
    R.default_rate_pct,

    CAST(R.default_rate_pct - B.portfolio_avg_default
        AS DECIMAL(8,4)) AS default_vs_benchmark,

    CAST(R.avg_rate - B.portfolio_avg_rate
        AS DECIMAL(8,4)) AS rate_vs_benchmark,

    R.sample_flag

FROM RegionRisk R

CROSS JOIN (
    SELECT
        AVG(default_rate_pct) AS portfolio_avg_default,
        AVG(avg_rate) AS portfolio_avg_rate
    FROM RegionRisk
) B;

GO


-- ============================================================
-- 5.3 — VERIFY BOTH ANALYTICAL VIEWS
-- Task: Retrieve and inspect the saved analytical reports.
-- (Check that both bank risk reports work correctly.)
-- Business Question:
-- Can the risk team retrieve the credit-score and regional
-- pricing reports directly from the database?
-- ============================================================

-- View 1: Credit score model integrity.
SELECT *
FROM dbo.vw_CreditScoreModelIntegrity
ORDER BY risk_rank;


-- View 2: Regional pricing risk.
SELECT *
FROM dbo.vw_RegionalPricingRisk
ORDER BY default_rate_pct DESC;


-- ============================================================
-- END OF PART 5
-- ============================================================

/* ============================================================
   PROJECT: Bank Loan Credit Risk & Pricing Integrity Review
   PART 6: EXECUTIVE RISK BRIEFING — FINAL CORRECTED

   ORIGINAL AUTHOR: Shabab
   ORIGINAL DATE: 2026-06-20
   DATABASE: BankLoanCreditRisk

   BUSINESS QUESTION:
   Can the bank execute one reusable stored procedure
   that summarises the 2019 loan portfolio, evaluates
   three credit-risk hypotheses, simulates a reduction
   in borrower income, and delivers an executive briefing?

   H1: Credit Score Model Integrity
   H2: Regional Interest Rate Mispricing
   H3: Hidden Stress Exposure (High LTV + Low Income)

   PROCEDURE: dbo.usp_ExecutiveRiskBriefing
   PARAMETER: @IncomeShockPct = 10.00
   RESULT SETS: 8

   METHOD:
   Stored Procedure + Views + Aggregates
   CASE + JOIN + Window Functions + 1 CTE
   ============================================================ */

USE BankLoanCreditRisk;
GO


-- ============================================================
-- 6.1 — CREATE EXECUTIVE RISK BRIEFING PROCEDURE
-- Task: Create a reusable procedure with an income parameter.
-- (Run the bank's entire risk report using one command.)
-- Business Question:
-- Can the bank produce a complete executive credit-risk
-- assessment using one reusable stored procedure?
-- ============================================================

CREATE OR ALTER PROCEDURE dbo.usp_ExecutiveRiskBriefing
    @IncomeShockPct DECIMAL(5,2) = 10.00
AS
BEGIN

    SET NOCOUNT ON;

    -- Reject invalid income-shock percentages.
    IF @IncomeShockPct IS NULL
       OR @IncomeShockPct < 0
       OR @IncomeShockPct >= 100
    BEGIN
        THROW 51001,
            'Income shock must be between 0 and 100 percent, excluding 100.',
            1;
    END;


    PRINT '========================================';
    PRINT 'EXECUTIVE RISK BRIEFING — 2019 PORTFOLIO';
    PRINT '========================================';
    PRINT '';


    -- ========================================================
    -- 6.2 — PORTFOLIO OVERVIEW
    -- RESULT SET 1
    -- Task: Calculate six headline credit-risk KPIs.
    -- (Show the bank its most important loan numbers.)
    -- Business Question:
    -- How many loans exist, what percentage defaulted,
    -- how much principal is associated with defaults,
    -- and what are the average credit score, LTV
    -- and interest rate?
    -- ========================================================

    SELECT
        COUNT(*) AS Total_Loans,

        CAST(AVG(CAST(Status AS DECIMAL(5,2))) * 100
            AS DECIMAL(5,2)) AS Default_Rate_Pct,

        CAST(SUM(CASE
            WHEN Status = 1 THEN CAST(loan_amount AS BIGINT)
            ELSE 0
        END) AS BIGINT) AS Total_Loss_Exposure,

        AVG(Credit_Score) AS Avg_Credit_Score,

        CAST(AVG(LTV_clean)
            AS DECIMAL(5,2)) AS Avg_LTV,

        CAST(AVG(rate_of_interest)
            AS DECIMAL(5,2)) AS Avg_Interest_Rate

    FROM dbo.Clean_LoanData;


    -- ========================================================
    -- 6.3 — H1: CREDIT SCORE MODEL INTEGRITY
    -- RESULT SET 2
    -- Task: Rank credit-score bands by observed default risk.
    -- (See which credit-score groups default most often.)
    -- Business Question:
    -- Which credit-score bands have the highest
    -- default rates and how are they ranked?
    -- ========================================================

    PRINT '';
    PRINT '--- H1: CREDIT SCORE MODEL INTEGRITY ---';
    PRINT '';

    SELECT
        credit_score_band,
        total_loans,
        defaults,
        default_rate_pct,
        risk_rank

    FROM dbo.vw_CreditScoreModelIntegrity

    ORDER BY risk_rank;


    -- ========================================================
    -- 6.3 — H1: DEFAULT-RATE SPREAD & VERDICT
    -- RESULT SET 3
    -- Task: Measure default-rate differences across score bands.
    -- (Check whether credit scores separate risky borrowers.)
    -- Business Question:
    -- Is the highest-to-lowest credit-score default-rate
    -- spread smaller than five percentage points,
    -- suggesting limited observed risk differentiation?
    -- ========================================================

    SELECT
        MIN(default_rate_pct) AS lowest_band_default,

        MAX(default_rate_pct) AS highest_band_default,

        MAX(default_rate_pct) -
        MIN(default_rate_pct) AS spread,

        CASE
            WHEN COUNT(*) < 2
              OR COUNT(default_rate_pct) <> COUNT(*)
            THEN 'H1 INCONCLUSIVE: Insufficient valid score bands'

            WHEN MAX(default_rate_pct) -
                 MIN(default_rate_pct) < 5
            THEN 'H1 FLAGGED: Default-rate spread below 5pp; model requires further validation'

            ELSE 'H1 NOT FLAGGED: Spread at least 5pp; predictive power remains unverified'

        END AS H1_verdict

    FROM dbo.vw_CreditScoreModelIntegrity;


    -- ========================================================
    -- 6.4 — H2: REGIONAL PRICING RISK
    -- RESULT SET 4
    -- Task: Compare regional default rates and interest rates.
    -- (Find regions with more defaults but cheaper loans.)
    -- Business Question:
    -- Which regions have higher default rates and lower
    -- interest rates relative to the regional benchmarks?
    -- ========================================================

    PRINT '';
    PRINT '--- H2: REGIONAL INTEREST RATE MISPRICING ---';
    PRINT '';

    SELECT
        Region,
        total_loans,
        pct_of_portfolio,
        avg_rate,
        default_rate_pct,
        default_vs_benchmark,
        rate_vs_benchmark,
        sample_flag

    FROM dbo.vw_RegionalPricingRisk

    ORDER BY default_rate_pct DESC;


    -- ========================================================
    -- 6.4 — H2: SOUTH VS NORTH PRICING VERDICT
    -- RESULT SET 5
    -- Task: Compare South against North.
    -- (Check whether South charges less but defaults more.)
    -- Business Question:
    -- Does South have a lower average interest rate
    -- than North despite experiencing a higher default
    -- rate, using regions with sufficient sample sizes?
    -- ========================================================

    SELECT
        S.Region AS underpriced_region,
        S.avg_rate AS its_rate,
        S.default_rate_pct AS its_default_pct,

        N.Region AS compared_to,
        N.avg_rate AS their_rate,
        N.default_rate_pct AS their_default_pct,

        CASE
            WHEN S.Region IS NULL OR N.Region IS NULL
            THEN 'H2 INCONCLUSIVE: Missing region or insufficient sample'

            WHEN S.avg_rate IS NULL OR N.avg_rate IS NULL
              OR S.default_rate_pct IS NULL
              OR N.default_rate_pct IS NULL
            THEN 'H2 INCONCLUSIVE: Missing regional metrics'

            WHEN S.avg_rate < N.avg_rate
             AND S.default_rate_pct > N.default_rate_pct

            THEN 'H2 FLAGGED: South charges less but defaults more than North; investigate risk-adjusted pricing'

            ELSE 'H2 NOT FLAGGED: Specified pricing-risk pattern not observed'

        END AS H2_verdict

    FROM (SELECT 1 AS Report_Row) A

    LEFT JOIN dbo.vw_RegionalPricingRisk S
        ON S.Region = 'South'
       AND S.sample_flag = 'Sufficient sample'

    LEFT JOIN dbo.vw_RegionalPricingRisk N
        ON N.Region = 'North'
       AND N.sample_flag = 'Sufficient sample';


    -- ========================================================
    -- 6.5 — H3: HIDDEN LTV RISK
    -- RESULT SET 6
    -- Task: Calculate defaults and exposure by LTV band.
    -- (Find which LTV groups carry the greatest risk.)
    -- Business Question:
    -- Among loans with reliable LTV values, which LTV
    -- bands have the highest default rates and how much
    -- defaulted principal is associated with each band?
    -- ========================================================

    PRINT '';
    PRINT '--- H3: HIDDEN STRESS EXPOSURE (LTV + INCOME) ---';
    PRINT 'Income shock applied: '
          + CAST(@IncomeShockPct AS VARCHAR(20)) + '%';
    PRINT '';

    SELECT
        LTV_band,
        COUNT(*) AS total_loans,
        SUM(Status) AS defaults,

        CAST(AVG(CAST(Status AS DECIMAL(5,2))) * 100
            AS DECIMAL(5,2)) AS default_rate_pct,

        CAST(SUM(CASE
            WHEN Status = 1 THEN CAST(loan_amount AS BIGINT)
            ELSE 0
        END) AS BIGINT) AS loss_exposure

    FROM dbo.Clean_LoanData

    WHERE LTV_reliability_flag = 'Reliable'

    GROUP BY LTV_band

    ORDER BY
        CASE LTV_band
            WHEN '0-20' THEN 1
            WHEN '20-40' THEN 2
            WHEN '40-60' THEN 3
            WHEN '60-80' THEN 4
            WHEN '80-100' THEN 5
            WHEN '100-120' THEN 6
            WHEN '>120' THEN 7
        END;


    -- ========================================================
    -- 6.6 — INCOME SHOCK SIMULATION
    -- RESULT SET 7
    -- Task: Simulate falling income among performing loans.
    -- (Find borrowers newly entering financial stress.)
    -- Business Question:
    -- If borrower income decreases by @IncomeShockPct,
    -- how many currently performing loans move from
    -- a DTI of 50% or less to a stressed DTI above 50%,
    -- and how much loan principal is associated with them?
    -- ========================================================

    SELECT
        COUNT(*) AS currently_performing_loans,

        SUM(CASE
            WHEN dtir1 <= 50
             AND dtir1 * (100.0 / (100.0 - @IncomeShockPct)) > 50
            THEN 1
            ELSE 0
        END) AS would_breach_50pct_DTI,

        CAST(SUM(CASE
            WHEN dtir1 <= 50
             AND dtir1 * (100.0 / (100.0 - @IncomeShockPct)) > 50
            THEN CAST(loan_amount AS BIGINT)
            ELSE 0
        END) AS BIGINT) AS at_risk_exposure,

        CAST(@IncomeShockPct AS VARCHAR(20))
            + '% income shock applied' AS scenario

    FROM dbo.Clean_LoanData

    WHERE Status = 0
      AND dtir1 IS NOT NULL
      AND LTV_reliability_flag = 'Reliable';


    -- ========================================================
    -- 6.7 — H3: HIGH-LTV & LOW-INCOME VERDICT
    -- RESULT SET 8
    -- Task: Test default concentration in high-LTV,
    --       low-income borrower groups.
    -- (Check whether poorer borrowers with large loans
    --  default at exceptionally high rates.)
    -- Business Question:
    -- Among borrowers with reliable LTV values,
    -- does the lowest income quartile contain high-LTV
    -- loans (above 100%) with a default rate above 75%,
    -- and is the overall high-LTV default rate also
    -- above the same threshold?
    -- ========================================================

    -- One CTE:
    -- Rank all eligible borrowers into four income groups.
    -- Quartile 1 contains the lowest-income borrowers.
    -- The outer query calculates both default rates.

    ;WITH IncomeQuartiles AS (
        SELECT
            Status,
            LTV_band,
            income_clean,
            NTILE(4) OVER (
                ORDER BY income_clean
            ) AS income_quartile

        FROM dbo.Clean_LoanData

        WHERE LTV_reliability_flag = 'Reliable'
          AND income_clean IS NOT NULL
    )

    SELECT
        CASE
            WHEN COUNT(CASE
                WHEN LTV_band IN ('100-120', '>120')
                THEN 1 END) = 0

              OR COUNT(CASE
                WHEN LTV_band IN ('100-120', '>120')
                 AND income_quartile = 1
                THEN 1 END) = 0

            THEN 'H3 INCONCLUSIVE: Insufficient high-LTV and low-income observations'

            WHEN AVG(CASE
                WHEN LTV_band IN ('100-120', '>120')
                THEN CAST(Status AS DECIMAL(5,2))
            END) > 0.75

             AND AVG(CASE
                WHEN LTV_band IN ('100-120', '>120')
                 AND income_quartile = 1
                THEN CAST(Status AS DECIMAL(5,2))
            END) > 0.75

            THEN 'H3 FLAGGED: High-LTV loans and the lowest-income high-LTV subgroup both exceed 75% default'

            ELSE 'H3 NOT FLAGGED: Combined high-LTV and low-income threshold conditions not met'

        END AS H3_verdict

    FROM IncomeQuartiles;


END;
GO


-- ============================================================
-- END OF PART 6 — FINAL CORRECTED RECONSTRUCTION
-- ============================================================

/* ============================================================
   PROJECT: Bank Loan Credit Risk & Pricing Integrity Review
   PART 7: FINAL EXECUTION & VALIDATION — CORRECTED

   ORIGINAL AUTHOR: Shabab
   ORIGINAL DATE: 2026-06-20
   DATABASE: BankLoanCreditRisk

   BUSINESS QUESTION:
   Can the bank execute its corrected executive risk
   briefing using a 10% income shock, verify all eight
   reporting outputs, and independently reconcile the
   loan population, cleaning results, H1, H2 and H3?

   EXPECTED LOANS: 148,670
   EXECUTIVE RESULT SETS: 8
   INCOME SHOCK: 10%

   METHOD:
   EXEC + COUNT + SUM + AVG + CASE + JOIN
   EXISTS + EXCEPT + Window Functions + 1 CTE

   IMPORTANT:
   A PASS means the specific test passed.
   It does not automatically validate every business
   interpretation or prove causal relationships.
   ============================================================ */

USE BankLoanCreditRisk;
GO


-- ============================================================
-- 7.1 — VERIFY REQUIRED DATABASE OBJECTS
-- Task: Confirm all required SQL objects exist.
-- (Check that every part needed for the report is present.)
-- Business Question:
-- Are the raw table, clean table, two analytical views
-- and executive procedure available for execution?
-- ============================================================

IF OBJECT_ID('dbo.Raw_LoanData', 'U') IS NULL
    THROW 51010, 'Missing dbo.Raw_LoanData', 1;

IF OBJECT_ID('dbo.Clean_LoanData', 'U') IS NULL
    THROW 51011, 'Missing dbo.Clean_LoanData', 1;

IF OBJECT_ID('dbo.vw_CreditScoreModelIntegrity', 'V') IS NULL
    THROW 51012, 'Missing credit-score view', 1;

IF OBJECT_ID('dbo.vw_RegionalPricingRisk', 'V') IS NULL
    THROW 51013, 'Missing regional pricing view', 1;

IF OBJECT_ID('dbo.usp_ExecutiveRiskBriefing', 'P') IS NULL
    THROW 51014, 'Missing executive briefing procedure', 1;


-- ============================================================
-- 7.2 — EXECUTE EXECUTIVE RISK BRIEFING
-- Task: Run the corrected procedure with a 10% income shock.
-- (Generate the bank's complete executive risk report.)
-- Business Question:
-- What does the bank's corrected executive briefing
-- reveal about its portfolio and all three hypotheses?
-- ============================================================

EXEC dbo.usp_ExecutiveRiskBriefing
    @IncomeShockPct = 10.00;


-- ============================================================
-- 7.3 — RECONCILE RAW AND CLEANED DATASETS
-- Task: Verify row counts, ID uniqueness and ID preservation.
-- (Make sure loans were not lost, duplicated or swapped.)
-- Business Question:
-- Were all 148,670 original loan records retained exactly
-- once in the cleaned analytical dataset?
-- ============================================================

DROP TABLE IF EXISTS #Final_Audit;

CREATE TABLE #Final_Audit (
    Check_Name VARCHAR(100),
    Actual_Result VARCHAR(100),
    Expected_Result VARCHAR(100),
    Validation_Status VARCHAR(10)
);


-- Check 1: Raw row count.
INSERT INTO #Final_Audit
SELECT
    'Raw dataset row count',
    CAST(COUNT(*) AS VARCHAR(100)),
    '148670',
    CASE WHEN COUNT(*) = 148670
         THEN 'PASS' ELSE 'REVIEW' END
FROM dbo.Raw_LoanData;


-- Check 2: Cleaned row count.
INSERT INTO #Final_Audit
SELECT
    'Clean dataset row count',
    CAST(COUNT(*) AS VARCHAR(100)),
    '148670',
    CASE WHEN COUNT(*) = 148670
         THEN 'PASS' ELSE 'REVIEW' END
FROM dbo.Clean_LoanData;


-- Check 3: Unique IDs.
INSERT INTO #Final_Audit
SELECT
    'Clean loan ID uniqueness',
    CAST(COUNT(*) - COUNT(DISTINCT ID) AS VARCHAR(100)),
    '0 duplicate or NULL IDs',
    CASE WHEN COUNT(*) = COUNT(DISTINCT ID)
         THEN 'PASS' ELSE 'REVIEW' END
FROM dbo.Clean_LoanData;


-- Check 4: Raw ID uniqueness.
INSERT INTO #Final_Audit
SELECT
    'Raw loan ID uniqueness',
    CAST(COUNT(*) - COUNT(DISTINCT ID) AS VARCHAR(100)),
    '0 duplicate or NULL IDs',
    CASE WHEN COUNT(*) = COUNT(DISTINCT ID)
         THEN 'PASS' ELSE 'REVIEW' END
FROM dbo.Raw_LoanData;


-- Check 5: Missing or unexpected loan IDs.
INSERT INTO #Final_Audit
SELECT
    'Raw versus clean ID preservation',
    CAST(COUNT(*) AS VARCHAR(100)),
    '0 unmatched IDs',
    CASE WHEN COUNT(*) = 0
         THEN 'PASS' ELSE 'REVIEW' END

FROM (
    SELECT ID FROM dbo.Raw_LoanData
    EXCEPT
    SELECT ID FROM dbo.Clean_LoanData

    UNION ALL

    SELECT ID FROM dbo.Clean_LoanData
    EXCEPT
    SELECT ID FROM dbo.Raw_LoanData
) AS ID_Differences;


-- Check 6: Preserve unmodified financial attributes.
-- This checks source loan amount, credit score and Status.
INSERT INTO #Final_Audit
SELECT
    'Unmodified loan attribute preservation',
    CAST(COUNT(*) AS VARCHAR(100)),
    '0 changed or unmatched records',
    CASE WHEN COUNT(*) = 0
         THEN 'PASS' ELSE 'REVIEW' END

FROM dbo.Raw_LoanData R
FULL OUTER JOIN dbo.Clean_LoanData C
    ON R.ID = C.ID

WHERE R.ID IS NULL
   OR C.ID IS NULL
   OR R.loan_amount <> C.loan_amount
   OR R.Credit_Score <> C.Credit_Score
   OR R.Status <> C.Status
   OR (R.loan_amount IS NULL AND C.loan_amount IS NOT NULL)
   OR (R.loan_amount IS NOT NULL AND C.loan_amount IS NULL)
   OR (R.Credit_Score IS NULL AND C.Credit_Score IS NOT NULL)
   OR (R.Credit_Score IS NOT NULL AND C.Credit_Score IS NULL)
   OR (R.Status IS NULL AND C.Status IS NOT NULL)
   OR (R.Status IS NOT NULL AND C.Status IS NULL);


-- ============================================================
-- 7.4 — VALIDATE CLEANING AND CLASSIFICATIONS
-- Task: Inspect cleaned values and risk classification rules.
-- (Check that the bank's cleaned loan data makes sense.)
-- Business Question:
-- Are required cleaned values populated, LTV values
-- correctly calculated, and risk classifications valid?
-- ============================================================

-- Check 7: Missing critical fields.
INSERT INTO #Final_Audit
SELECT
    'Missing critical cleaned values',

    CAST(
        SUM(CASE WHEN property_value_clean IS NULL THEN 1 ELSE 0 END)
      + SUM(CASE WHEN income_clean IS NULL THEN 1 ELSE 0 END)
      + SUM(CASE WHEN LTV_clean IS NULL THEN 1 ELSE 0 END)
      + SUM(CASE WHEN term IS NULL THEN 1 ELSE 0 END)
        AS VARCHAR(100)),

    '0 missing values',

    CASE
        WHEN COUNT(property_value_clean) = COUNT(*)
         AND COUNT(income_clean) = COUNT(*)
         AND COUNT(LTV_clean) = COUNT(*)
         AND COUNT(term) = COUNT(*)
        THEN 'PASS' ELSE 'REVIEW'
    END

FROM dbo.Clean_LoanData;


-- Check 8: Original column structure.
INSERT INTO #Final_Audit
SELECT
    'Clean table column count',
    CAST(COUNT(*) AS VARCHAR(100)),
    '37',
    CASE WHEN COUNT(*) = 37
         THEN 'PASS' ELSE 'REVIEW' END

FROM INFORMATION_SCHEMA.COLUMNS

WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'Clean_LoanData';


-- Check 9: Valid default status values.
INSERT INTO #Final_Audit
SELECT
    'Binary default status',
    CAST(SUM(CASE
        WHEN Status NOT IN (0,1) OR Status IS NULL
        THEN 1 ELSE 0 END) AS VARCHAR(100)),
    '0 invalid statuses',
    CASE
        WHEN SUM(CASE
            WHEN Status NOT IN (0,1) OR Status IS NULL
            THEN 1 ELSE 0 END) = 0
        THEN 'PASS' ELSE 'REVIEW'
    END
FROM dbo.Clean_LoanData;


-- Check 10: LTV formula reconciliation.
INSERT INTO #Final_Audit
SELECT
    'LTV calculation accuracy',
    CAST(COUNT(*) AS VARCHAR(100)),
    '0 incorrect LTV values',
    CASE WHEN COUNT(*) = 0
         THEN 'PASS' ELSE 'REVIEW' END

FROM dbo.Clean_LoanData

WHERE LTV_clean IS NULL
   OR ABS(
        LTV_clean -
        CAST(loan_amount * 100.0 /
             NULLIF(property_value_clean, 0)
             AS DECIMAL(10,5))
      ) > 0.00001;


-- Check 11: LTV reliability classification.
INSERT INTO #Final_Audit
SELECT
    'LTV reliability classification',
    CAST(COUNT(*) AS VARCHAR(100)),
    '0 incorrect flags',
    CASE WHEN COUNT(*) = 0
         THEN 'PASS' ELSE 'REVIEW' END

FROM dbo.Clean_LoanData

WHERE LTV_reliability_flag <>
    CASE WHEN LTV_clean > 150
         THEN 'Unreliable'
         ELSE 'Reliable' END
   OR LTV_reliability_flag IS NULL;


-- Check 12: Credit-score classifications.
INSERT INTO #Final_Audit
SELECT
    'Credit-score band classification',
    CAST(COUNT(*) AS VARCHAR(100)),
    '0 incorrect bands',
    CASE WHEN COUNT(*) = 0
         THEN 'PASS' ELSE 'REVIEW' END

FROM dbo.Clean_LoanData

WHERE credit_score_band <>
    CASE
        WHEN Credit_Score BETWEEN 500 AND 549 THEN '500-549'
        WHEN Credit_Score BETWEEN 550 AND 599 THEN '550-599'
        WHEN Credit_Score BETWEEN 600 AND 649 THEN '600-649'
        WHEN Credit_Score BETWEEN 650 AND 699 THEN '650-699'
        WHEN Credit_Score BETWEEN 700 AND 749 THEN '700-749'
        WHEN Credit_Score BETWEEN 750 AND 799 THEN '750-799'
        WHEN Credit_Score BETWEEN 800 AND 849 THEN '800-849'
        WHEN Credit_Score BETWEEN 850 AND 900 THEN '850-900'
        ELSE 'Other'
    END
   OR credit_score_band IS NULL;


-- ============================================================
-- 7.5 — VERIFY H1: CREDIT SCORE MODEL INTEGRITY
-- Task: Independently reconcile credit-score reporting.
-- (Check that the score-band calculations are correct.)
-- Business Question:
-- Do the credit-score view's populations, defaults
-- and default rates match the cleaned loan records?
-- ============================================================

-- Check 13: H1 population and default reconciliation.
INSERT INTO #Final_Audit
SELECT
    'H1 view population and default reconciliation',
    CAST(COUNT(*) AS VARCHAR(100)),
    '0 mismatched score bands',
    CASE WHEN COUNT(*) = 0
         THEN 'PASS' ELSE 'REVIEW' END

FROM (
    SELECT
        credit_score_band,
        COUNT(*) AS total_loans,
        SUM(Status) AS defaults,
        CAST(AVG(CAST(Status AS DECIMAL(5,2))) * 100
            AS DECIMAL(5,2)) AS default_rate_pct
    FROM dbo.Clean_LoanData
    GROUP BY credit_score_band

    EXCEPT

    SELECT
        credit_score_band,
        total_loans,
        defaults,
        default_rate_pct
    FROM dbo.vw_CreditScoreModelIntegrity

    UNION ALL

    SELECT
        credit_score_band,
        total_loans,
        defaults,
        default_rate_pct
    FROM dbo.vw_CreditScoreModelIntegrity

    EXCEPT

    SELECT
        credit_score_band,
        COUNT(*) AS total_loans,
        SUM(Status) AS defaults,
        CAST(AVG(CAST(Status AS DECIMAL(5,2))) * 100
            AS DECIMAL(5,2)) AS default_rate_pct
    FROM dbo.Clean_LoanData
    GROUP BY credit_score_band
) AS H1_Differences;


-- Independently report the H1 spread and verdict.
SELECT
    MIN(default_rate_pct) AS lowest_band_default,
    MAX(default_rate_pct) AS highest_band_default,
    MAX(default_rate_pct) - MIN(default_rate_pct) AS spread,

    CASE
        WHEN COUNT(*) < 2
          OR COUNT(default_rate_pct) <> COUNT(*)
        THEN 'H1 INCONCLUSIVE'

        WHEN MAX(default_rate_pct) -
             MIN(default_rate_pct) < 5
        THEN 'H1 FLAGGED: Limited observed risk separation'

        ELSE 'H1 NOT FLAGGED: Further model validation required'
    END AS Independent_H1_Assessment

FROM (
    SELECT
        credit_score_band,
        CAST(AVG(CAST(Status AS DECIMAL(5,2))) * 100
            AS DECIMAL(5,2)) AS default_rate_pct
    FROM dbo.Clean_LoanData
    GROUP BY credit_score_band
) AS H1_Bands;


-- ============================================================
-- 7.6 — VERIFY H2: REGIONAL PRICING RISK
-- Task: Reconcile the regional pricing view.
-- (Check whether the regional report uses the right numbers.)
-- Business Question:
-- Do the regional loan counts, default rates, interest rates
-- and portfolio shares match the cleaned loan population?
-- ============================================================

-- Check 14: Regional view reconciliation.
INSERT INTO #Final_Audit
SELECT
    'H2 regional view reconciliation',
    CAST(COUNT(*) AS VARCHAR(100)),
    '0 mismatched regions',
    CASE WHEN COUNT(*) = 0
         THEN 'PASS' ELSE 'REVIEW' END

FROM (
    SELECT
        Region,
        COUNT(*) AS total_loans,
        CAST(AVG(CAST(Status AS DECIMAL(5,2))) * 100
            AS DECIMAL(5,2)) AS default_rate_pct,
        CAST(AVG(rate_of_interest)
            AS DECIMAL(5,2)) AS avg_rate,
        CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER ()
            AS DECIMAL(5,2)) AS pct_of_portfolio
    FROM dbo.Clean_LoanData
    GROUP BY Region

    EXCEPT

    SELECT
        Region,
        total_loans,
        default_rate_pct,
        avg_rate,
        pct_of_portfolio
    FROM dbo.vw_RegionalPricingRisk

    UNION ALL

    SELECT
        Region,
        total_loans,
        default_rate_pct,
        avg_rate,
        pct_of_portfolio
    FROM dbo.vw_RegionalPricingRisk

    EXCEPT

    SELECT
        Region,
        COUNT(*) AS total_loans,
        CAST(AVG(CAST(Status AS DECIMAL(5,2))) * 100
            AS DECIMAL(5,2)) AS default_rate_pct,
        CAST(AVG(rate_of_interest)
            AS DECIMAL(5,2)) AS avg_rate,
        CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER ()
            AS DECIMAL(5,2)) AS pct_of_portfolio
    FROM dbo.Clean_LoanData
    GROUP BY Region
) AS H2_Differences;


-- Independently check South against North.
SELECT
    S.Region AS Region_Compared,
    S.avg_rate AS South_Average_Rate,
    S.default_rate_pct AS South_Default_Rate,

    N.avg_rate AS North_Average_Rate,
    N.default_rate_pct AS North_Default_Rate,

    CASE
        WHEN S.Region IS NULL OR N.Region IS NULL
        THEN 'H2 INCONCLUSIVE: Missing region or insufficient sample'

        WHEN S.avg_rate IS NULL OR N.avg_rate IS NULL
          OR S.default_rate_pct IS NULL
          OR N.default_rate_pct IS NULL
        THEN 'H2 INCONCLUSIVE: Missing regional metrics'

        WHEN S.avg_rate < N.avg_rate
         AND S.default_rate_pct > N.default_rate_pct
        THEN 'H2 FLAGGED: Pricing-risk pattern observed'

        ELSE 'H2 NOT FLAGGED'
    END AS Independent_H2_Assessment

FROM (SELECT 1 AS Report_Row) A

LEFT JOIN dbo.vw_RegionalPricingRisk S
    ON S.Region = 'South'
   AND S.sample_flag = 'Sufficient sample'

LEFT JOIN dbo.vw_RegionalPricingRisk N
    ON N.Region = 'North'
   AND N.sample_flag = 'Sufficient sample';


-- ============================================================
-- 7.7 — VERIFY H3: HIGH-LTV AND LOW-INCOME RISK
-- Task: Independently calculate the corrected H3 verdict.
-- (Check the default rate for low-income, high-LTV borrowers.)
-- Business Question:
-- Do both the overall high-LTV population and the
-- lowest-income high-LTV subgroup exceed 75% defaults?
-- ============================================================

-- Use the same eligible population and quartile definition
-- as the corrected Part 6.

;WITH IncomeQuartiles AS (
    SELECT
        Status,
        LTV_band,
        income_clean,

        NTILE(4) OVER (
            ORDER BY income_clean
        ) AS income_quartile

    FROM dbo.Clean_LoanData

    WHERE LTV_reliability_flag = 'Reliable'
      AND income_clean IS NOT NULL
)

SELECT
    COUNT(CASE
        WHEN LTV_band IN ('100-120', '>120')
        THEN 1
    END) AS High_LTV_Loans,

    COUNT(CASE
        WHEN LTV_band IN ('100-120', '>120')
         AND income_quartile = 1
        THEN 1
    END) AS Low_Income_High_LTV_Loans,

    CAST(AVG(CASE
        WHEN LTV_band IN ('100-120', '>120')
        THEN CAST(Status AS DECIMAL(5,2))
    END) * 100 AS DECIMAL(5,2)) AS High_LTV_Default_Rate,

    CAST(AVG(CASE
        WHEN LTV_band IN ('100-120', '>120')
         AND income_quartile = 1
        THEN CAST(Status AS DECIMAL(5,2))
    END) * 100 AS DECIMAL(5,2)) AS Low_Income_High_LTV_Default_Rate,

    CASE
        WHEN COUNT(CASE
            WHEN LTV_band IN ('100-120', '>120')
            THEN 1 END) = 0

          OR COUNT(CASE
            WHEN LTV_band IN ('100-120', '>120')
             AND income_quartile = 1
            THEN 1 END) = 0

        THEN 'H3 INCONCLUSIVE'

        WHEN AVG(CASE
            WHEN LTV_band IN ('100-120', '>120')
            THEN CAST(Status AS DECIMAL(5,2))
        END) > 0.75

         AND AVG(CASE
            WHEN LTV_band IN ('100-120', '>120')
             AND income_quartile = 1
            THEN CAST(Status AS DECIMAL(5,2))
        END) > 0.75

        THEN 'H3 FLAGGED: Both high-LTV conditions exceed 75%'

        ELSE 'H3 NOT FLAGGED'
    END AS Independent_H3_Assessment

FROM IncomeQuartiles;


-- ============================================================
-- 7.8 — VALIDATE INCOME SHOCK SIMULATION
-- Task: Recalculate DTI stress using a 10% income reduction.
-- (Check exactly how many loans newly become stressed.)
-- Business Question:
-- How many performing loans were already above 50% DTI,
-- how many newly cross 50%, and what principal is
-- associated with those newly breached loans?
-- ============================================================

DECLARE @IncomeShockPct DECIMAL(5,2) = 10.00;

SELECT
    COUNT(*) AS currently_performing_loans,

    SUM(CASE
        WHEN dtir1 > 50
        THEN 1 ELSE 0
    END) AS Already_Above_50pct_DTI,

    SUM(CASE
        WHEN dtir1 * (100.0 / (100.0 - @IncomeShockPct)) > 50
        THEN 1 ELSE 0
    END) AS All_Above_50pct_After_Shock,

    SUM(CASE
        WHEN dtir1 <= 50
         AND dtir1 * (100.0 / (100.0 - @IncomeShockPct)) > 50
        THEN 1 ELSE 0
    END) AS Newly_Breaching_Loans,

    CAST(SUM(CASE
        WHEN dtir1 <= 50
         AND dtir1 * (100.0 / (100.0 - @IncomeShockPct)) > 50
        THEN CAST(loan_amount AS BIGINT)
        ELSE 0
    END) AS BIGINT) AS Newly_At_Risk_Exposure

FROM dbo.Clean_LoanData

WHERE Status = 0
  AND dtir1 IS NOT NULL
  AND LTV_reliability_flag = 'Reliable';


-- ============================================================
-- 7.9 — FINAL VALIDATION REPORT
-- Task: Summarise all completed automated checks.
-- (Show which checks passed and which need attention.)
-- Business Question:
-- Which database, cleaning and analytical reconciliation
-- checks passed, and which require further investigation?
-- ============================================================

-- Display individual audit results.
SELECT
    Check_Name,
    Actual_Result,
    Expected_Result,
    Validation_Status

FROM #Final_Audit

ORDER BY
    CASE Validation_Status
        WHEN 'REVIEW' THEN 1
        WHEN 'PASS' THEN 2
        ELSE 3
    END,
    Check_Name;


-- Display consolidated status.
SELECT
    COUNT(*) AS Total_Checks,

    SUM(CASE
        WHEN Validation_Status = 'PASS'
        THEN 1 ELSE 0
    END) AS Passed_Checks,

    SUM(CASE
        WHEN Validation_Status = 'REVIEW'
        THEN 1 ELSE 0
    END) AS Review_Checks,

    CASE
        WHEN COUNT(*) > 0
         AND SUM(CASE
             WHEN Validation_Status <> 'PASS'
             THEN 1 ELSE 0
         END) = 0

        THEN 'AUTOMATED CHECKS PASSED: Review executive outputs and analytical limitations'

        ELSE 'REVIEW REQUIRED: Investigate failed reconciliation checks'

    END AS Final_Validation_Status

FROM #Final_Audit;


-- ============================================================
-- END OF PART 7 — CORRECTED RECONSTRUCTION
-- ============================================================
 
