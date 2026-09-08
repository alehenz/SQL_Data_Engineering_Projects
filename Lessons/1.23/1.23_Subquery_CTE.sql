-- CTE
WITH valid_salaries AS (
    SELECT *
    FROM job_postings_fact
    WHERE salary_year_avg IS NOT NULL
    OR salary_hour_avg IS NOT NULL
)
SELECT *
FROM valid_salaries
LIMIT 10;

-- Scenario 1 - Subquery in 'SELECT'
-- Show each job's salary next to the overal market median
SELECT
    job_title_short,
    salary_year_avg,
    (
        SELECT
            MEDIAN(salary_year_avg) -- SUBQUERY IN SELECT REQUIRES A SCALAR VALUE
        FROM job_postings_fact
    ) AS market_median_salary
FROM job_postings_fact
WHERE salary_year_avg IS NOT NULL
LIMIT 10;

-- Scenario 2 - Subquery in FROM
-- Stage only jobs that are remote before aggregating to determine the remote median salary per job:
SELECT
    job_title_short,
    MEDIAN(salary_year_avg) AS median_salary,
    (
        SELECT
            MEDIAN(salary_year_avg)
        FROM job_postings_fact
        WHERE job_work_from_home = True
    ) AS market_remote_median_salary
FROM (
    SELECT
        job_title_short,
        salary_year_avg
    FROM job_postings_fact
    WHERE job_work_from_home = True
) AS clean_jobs
/*WHERE salary_year_avg IS NOT NULL*/
GROUP BY job_title_short
LIMIT 10;

-- Scenario 3 - Subquery in HAVING
-- Keep only job titles whose median salary is above the overall median:
SELECT
    job_title_short,
    MEDIAN(salary_year_avg) AS median_salary,
    (
        SELECT
            MEDIAN(salary_year_avg)
        FROM job_postings_fact
        WHERE job_work_from_home = True
    ) AS market_remote_median_salary
FROM (
    SELECT
        job_title_short,
        salary_year_avg
    FROM job_postings_fact
    WHERE job_work_from_home = True
) AS clean_jobs
GROUP BY job_title_short
--we essentially copy what's inside the market_remote_median_salary
HAVING MEDIAN(salary_year_avg) > (
    SELECT
            MEDIAN(salary_year_avg)
        FROM job_postings_fact
        WHERE job_work_from_home = True
)
LIMIT 10;

-- CTE example
-- Compare hoy much more (or less) remote roles pay compared to onsite roles for each job title.
-- Use a CTE to calculate the median salary by the title and work arrangement, then compare those medians.
WITH title_median AS (    
    SELECT
        job_title_short,
        job_work_from_home,
        MEDIAN(salary_year_avg)::INT AS median_salary
    FROM job_postings_fact
    WHERE job_country = 'Canada'
    GROUP BY
        job_title_short,
        job_work_from_home
)

SELECT
    r.job_title_short,
    r.median_salary AS remote_median_salary,
    o.median_salary AS onsite_median_salary,
    (r.median_salary - o.median_salary) AS remote_premium
FROM title_median AS r
INNER JOIN title_median AS o
    ON r.job_title_short = o.job_title_short
WHERE r.job_work_from_home = TRUE
    AND o.job_work_from_home = FALSE
ORDER BY remote_premium DESC;

-- Existence Filtering
SELECT *
FROM range(3) AS src(key)
WHERE EXISTS (
    SELECT 1
    FROM range(2) AS tgt(key)
    WHERE tgt.key = src.key
);

SELECT *
FROM range(3) AS src(key)
WHERE NOT EXISTS (
    SELECT 1
    FROM range(2) AS tgt(key)
    WHERE tgt.key = src.key
);

-- Identify the job postings that have no associated skills before loading them into a data mart
SELECT *
FROM job_postings_fact
ORDER BY job_id
LIMIT 10;

SELECT *
FROM skills_job_dim
ORDER BY job_id
LIMIT 40;

-- The following query uses existence filtering to find all job postings from job_postings_fact that are not in skills_job_dim (hence, don't have associated skills)
SELECT * 
FROM job_postings_fact AS tgt
WHERE NOT EXISTS (
    SELECT 1
    FROM skills_job_dim AS src
    WHERE tgt.job_id = src.job_id
)
ORDER BY job_id;

-- The following query is to check the amount and see that they both add up to the toal job postings
SELECT * 
FROM job_postings_fact AS tgt
WHERE EXISTS (
    SELECT 1
    FROM skills_job_dim AS src
    WHERE tgt.job_id = src.job_id
)
ORDER BY job_id;
