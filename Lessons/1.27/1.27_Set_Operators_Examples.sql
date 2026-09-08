CREATE TEMP TABLE jobs_2023 AS
SELECT * EXCLUDE (job_id, job_posted_date)
FROM job_postings_fact
WHERE EXTRACT(YEAR FROM job_posted_date) = 2023;

CREATE TEMP TABLE jobs_2024 AS
SELECT * EXCLUDE (job_id, job_posted_date)
FROM job_postings_fact
WHERE EXTRACT(YEAR FROM job_posted_date) = 2024;

-- Which unique job postings appeared in either 2023 or 2024?

SELECT
    'jobs_2023' AS table_name,
    COUNT(*)    AS record_count
FROM jobs_2023
UNION
SELECT
    'jobs_2024' AS table_name,
    COUNT(*)    AS record_count
FROM jobs_2024;


SELECT * FROM jobs_2023
UNION
SELECT * FROM jobs_2024;

-- Which job postings appeared across both years, counting duplicates?

SELECT * FROM jobs_2023
UNION ALL
SELECT * FROM jobs_2024;

-- Which job postings appeared in both 2023 and 2024?

SELECT * FROM jobs_2023
INTERSECT
SELECT * FROM jobs_2024;

-- Which job postings appeared in both years, preserving duplicate counts?

SELECT * FROM jobs_2023
INTERSECT ALL
SELECT * FROM jobs_2024;

--Which job postings appeared in 2023 but not in 2024?

SELECT * FROM jobs_2023
EXCEPT
SELECT * FROM jobs_2024;

-- Which job postings appeared more times in 2023 than 2024, one-for-one?

SELECT * FROM jobs_2023
EXCEPT ALL
SELECT * FROM jobs_2024;

/*write a query that returns the count of rows in jobs_2023, the count in jobs_2024, 
and the count of rows that appear in both years (via INTERSECT), as three separate 
SELECT COUNT(*) queries combined with UNION ALL and a label column, similar to the 
pattern already shown in the source script for comparing table sizes.*/

SELECT
    'jobs_2023' AS table_name,
    COUNT(*)    AS record_count
FROM jobs_2023
UNION
SELECT
    'jobs_2024' AS table_name,
    COUNT(*)    AS record_count
FROM jobs_2024
UNION
SELECT
    'intersection' AS table_name,
    COUNT(*)       AS record_count
    FROM (
        SELECT * FROM jobs_2023
        INTERSECT
        SELECT * FROM jobs_2024
    );

/*since job_id was excluded from both tables, what is EXCEPT actually comparing row 
by row? Is it really identifying the same physical job posting missing from 2024, 
or something more general?*/

