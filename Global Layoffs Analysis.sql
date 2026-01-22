-- SQL Data Cleaning
-- step 1 = Basic Data Checking
USE portfolio;

SELECT COUNT(*) AS total_rows FROM layoffs;
SELECT * FROM layoffs LIMIT 10;

-- STEP 2: CHECK COLUMN STRUCTURE
DESCRIBE layoffs;

-- STEP 3: REMOVE DUPLICATES
-- a. Identify duplicates
SELECT company, location, industry, total_laid_off, date, COUNT(*)
FROM layoffs
GROUP BY company, location, industry, total_laid_off, date
HAVING COUNT(*) > 1;

-- b.DELETING DUPLICATES

ALTER TABLE layoffs ADD COLUMN id INT AUTO_INCREMENT PRIMARY KEY;

DELETE l1
FROM layoffs l1
JOIN layoffs l2
ON l1.company = l2.company
AND l1.location = l2.location
AND IFNULL(l1.industry,'') = IFNULL(l2.industry,'')
AND IFNULL(l1.total_laid_off,0) = IFNULL(l2.total_laid_off,0)
AND IFNULL(l1.date,'1900-01-01') = IFNULL(l2.date,'1900-01-01')
AND l1.id > l2.id;

-- STEP 4: HANDLE NULL VALUES
-- a. Check Nulls
SELECT 
SUM(company IS NULL) AS company_nulls,
SUM(industry IS NULL) AS industry_nulls,
SUM(total_laid_off IS NULL) AS layoffs_nulls
FROM layoffs;

-- b. Remove rows with no layoff info
DELETE FROM layoffs
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- STEP 5: STANDARDIZE TEXT DATA
-- a.Remove extra spaces
UPDATE layoffs
SET company = TRIM(company),
industry = TRIM(industry),
country = TRIM(country);

-- b. Fix industry inconsistencies
UPDATE layoffs
SET industry = 'Crypto'
WHERE industry LIKE '%Crypto%';

-- STEP 6: FIX DATE FORMAT.
-- Convert Date 
SELECT date FROM layoffs LIMIT 10;

ALTER TABLE layoffs
ADD COLUMN clean_date DATE;

UPDATE layoffs
SET clean_date =
CASE
    -- Already in YYYY-MM-DD (DATE or ISO string)
    WHEN date REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
        THEN date

    -- MM/DD/YYYY
    WHEN date LIKE '%/%'
        THEN STR_TO_DATE(date, '%m/%d/%Y')

    -- DD-MM-YYYY
    WHEN date LIKE '%-%'
        THEN STR_TO_DATE(date, '%d-%m-%Y')

    ELSE NULL
END;

-- check new column
SELECT date, clean_date
FROM layoffs
LIMIT 15;

-- Replacing old date column with Clean_date--
ALTER TABLE layoffs DROP COLUMN date;
ALTER TABLE layoffs CHANGE clean_date date DATE;

DESCRIBE layoffs;
SELECT date FROM layoffs LIMIT 10;

-- STEP 7: EXPLORATORY DATA ANALYSIS (EDA)
-- Total layoffs by year

SELECT YEAR(date) AS year, SUM(total_laid_off) AS total_layoffs
FROM layoffs
GROUP BY YEAR(date)
ORDER BY year;

-- Top 10 Companies by Layoffs
SELECT company, SUM(total_laid_off) AS total_layoffs
FROM layoffs
GROUP BY company
ORDER BY total_layoffs DESC
LIMIT 10;

-- Layoffs by Industry
SELECT industry, SUM(total_laid_off) AS total_layoffs
FROM layoffs
GROUP BY industry
ORDER BY total_layoffs DESC;

-- Country-wise Layoffs
SELECT country, SUM(total_laid_off) AS total_layoffs
FROM layoffs
GROUP BY country
ORDER BY total_layoffs DESC;

-- Monthly Layoff Trend
SELECT DATE_FORMAT(date, '%Y-%m') AS month, SUM(total_laid_off) AS layoffs
FROM layoffs
GROUP BY month
ORDER BY month;

-- Startup Stage Impact
SELECT stage, SUM(total_laid_off) AS total_layoffs
FROM layoffs
GROUP BY stage
ORDER BY total_layoffs DESC;

