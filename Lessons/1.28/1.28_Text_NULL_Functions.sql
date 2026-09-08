SELECT LENGTH('SQL');
SELECT CHAR_LENGTH('SQL'); -- This is an alias of the previous functions

SELECT LOWER('SQL');
SELECT UPPER('sql');

SELECT LEFT('SQL', 2); --extract the first two chars beginning from the left
SELECT RIGHT('SQL', 2); --extract the first two chars beginning from the right
SELECT SUBSTRING('SQL', 2, 1); --extract 1 character beginning from the second character from the left

/*Concatenation*/
SELECT CONCAT('SQL', '-', 'Functions');
SELECT 'SQL' || '-' || 'Functions';

/*Trimming*/
SELECT ' SQL ';
SELECT TRIM(' SQL ');
SELECT LTRIM(' SQL ');
SELECT RTRIM(' SQL ');

/*Replacement*/
SELECT REPLACE('SQL', 'Q', '_'); --Replace 'Q' with '_'

/*Extract email domain out from any email address (remove everything before @)*/
SELECT REGEXP_REPLACE('data.nerd@gmail.com', '^.*(@)', '\1');


/*Case insensitive version of query using CTE*/
WITH title_lower AS (
    SELECT
        job_title,
        LOWER(TRIM(job_title)) AS job_title_clean
    FROM job_postings_fact
)

SELECT
    job_title,
    CASE
        WHEN job_title_clean LIKE '%data%' AND job_title_clean LIKE '%analyst%' THEN 'Data Analyst'
        WHEN job_title_clean LIKE '%data%' AND job_title_clean LIKE '%scientist%' THEN 'Data Scientist'
        WHEN job_title_clean LIKE '%data%' AND job_title_clean LIKE '%engineer%' THEN 'Data Engineer'
        ELSE 'Other'
    END AS job_title_category
FROM title_lower
ORDER BY RANDOM()
LIMIT 30;


/*NULLIF returns NULL if two values are equal*/
SELECT NULLIF(10, 10);
SELECT NULLIF(10, 20);
SELECT NULLIF(10, 5 + 5);

/*Use case: if any of the slaary columns has 0 in its value*/
SELECT
    NULLIF(salary_year_avg, 0),
    NULLIF(salary_hour_avg, 0)
FROM
    job_postings_fact
WHERE salary_hour_avg IS NOT NULL OR salary_year_avg IS NOT NULL
LIMIT 10;

/*Use case: calculate median by removing 0 values*/
SELECT
    MEDIAN(NULLIF(salary_year_avg, 0)),
    MEDIAN(NULLIF(salary_hour_avg, 0))
FROM
    job_postings_fact
WHERE salary_hour_avg IS NOT NULL OR salary_year_avg IS NOT NULL
LIMIT 10;


/*COALESCE: Returns the first non-NULL value*/
SELECT COALESCE(NULL, NULL, 1 ,2);

SELECT
    salary_year_avg,
    salary_hour_avg,
    COALESCE(salary_year_avg, salary_hour_avg * 2080) --if yearly average is null, will use hourly average * 2080
FROM
    job_postings_fact
WHERE salary_hour_avg IS NOT NULL OR salary_year_avg IS NOT NULL
LIMIT 10;

/*Final Example - Simplify with COALESCE*/
SELECT
    job_title_short,
    salary_year_avg,
    salary_hour_avg,
    COALESCE(salary_year_avg, salary_hour_avg * 2080) AS standardized_salary,
    CASE
        WHEN COALESCE(salary_year_avg, salary_hour_avg * 2080) IS NULL THEN 'Missing' --Technically not required
        WHEN COALESCE(salary_year_avg, salary_hour_avg * 2080) < 75_000 THEN 'Low'
        WHEN COALESCE(salary_year_avg, salary_hour_avg * 2080) < 75_000 THEN 'Medium'
        ELSE 'High'
    END AS salary_bucket
FROM job_postings_fact
ORDER BY standardized_salary DESC;