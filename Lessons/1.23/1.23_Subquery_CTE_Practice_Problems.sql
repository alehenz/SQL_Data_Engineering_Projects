--Section B: Subquery in SELECT
--Write a query that shows each job_title_short and salary_hour_avg, alongside a column showing the overall market's average salary_hour_avg (not median this time, average), for rows where salary_hour_avg IS NOT NULL. Limit to 10.
SELECT
    job_title_short,
    salary_hour_avg,
    (
        SELECT
            AVG(salary_hour_avg)
        FROM 
            job_postings_fact        
    ) AS average_market_salary
FROM job_postings_fact
WHERE salary_hour_avg IS NOT NULL
LIMIT 10;
    
--Section C: Subquery in FROM
--Write a query that stages only jobs where job_country = 'United States', then, from that staged subquery, calculates the median 
--salary_year_avg grouped by job_title_short. Limit to 10.

SELECT
    job_title_short,
    MEDIAN(salary_year_avg)::INT AS median_year_salary
FROM (
    SELECT
        job_title_short,
        salary_year_avg
    FROM
        job_postings_fact
    WHERE
        job_country = 'United States'
    )
GROUP BY
    job_title_short
LIMIT 10;

--Now add a second column to that same query showing the overall (not staged, not filtered by country) market median salary_year_avg, 
--using a subquery in SELECT alongside the one in FROM. This combines what you practiced in problems 5 and 6 into one query.

SELECT
    job_title_short,
    MEDIAN(salary_year_avg)::INT AS US_median_salary,
    (
        SELECT
            MEDIAN(salary_year_avg)
        FROM
            job_postings_fact
    ) AS overall_median_salary
FROM (
        SELECT
            job_title_short,
            salary_year_avg
        FROM
            job_postings_fact
        WHERE
            job_country = 'United States'
    )
GROUP BY
    job_title_short
LIMIT 10;

--Section D: Subquery in HAVING
--Write a query that groups job_postings_fact by job_title_short, calculates the average salary_year_avg per title, and keeps only 
--titles where that average is above the overall market average (calculated via a subquery in HAVING, not a hardcoded number).

SELECT
    job_title_short,
    AVG(salary_year_avg)::INT AS avg_yearly_salary
FROM
    job_postings_fact
GROUP BY job_title_short
HAVING
    AVG(salary_year_avg) > (
        SELECT
            AVG(salary_year_avg)
        FROM
            job_postings_fact
    )
ORDER BY AVG(salary_year_avg) DESC;

--Section E: CTEs
--Using a CTE, calculate the median salary_year_avg grouped by job_title_short and job_schedule_type. Then, in the main query, 
--compare 'Full-time' vs 'Contractor' medians for each title side by side (same join pattern as the remote vs. onsite example in 
--your notes), and add a column for the difference.
WITH title_type_median AS (
    SELECT
        job_title_short,
        job_schedule_type,
        MEDIAN(salary_year_avg)::INT AS median_salary
    FROM
        job_postings_fact
    GROUP BY
        job_title_short,
        job_schedule_type
)

SELECT 
    ft.job_title_short,
    ft.median_salary AS fulltime_median_salary,
    c.median_salary AS contractor_median_salary,
    (ft.median_salary - c.median_salary) AS full_time_salary_premium
FROM
    title_type_median AS ft
INNER JOIN
    title_type_median AS c
ON ft.job_title_short = c.job_title_short
WHERE
    ft.job_schedule_type = 'Full-time'
AND
    c.job_schedule_type = 'Contractor'
ORDER BY full_time_salary_premium DESC;

--Using a CTE, calculate the median salary_year_avg grouped by job_title_short and job_work_from_home 
--(true/false), same as the original remote-vs-onsite example in your notes, but this time filter to only 
--job_country = 'United States' inside the CTE before grouping.

WITH job_type_median AS (
    SELECT
        job_title_short,
        job_work_from_home,
        MEDIAN(salary_year_avg)::INT AS median_yearly_salary
    FROM job_postings_fact
    WHERE job_country = 'United States'
    GROUP BY
        job_title_short,
        job_work_from_home
)

SELECT
    h.job_title_short,
    h.median_yearly_salary AS home_median_salary,
    r.median_yearly_salary AS remote_median_salary,
    (remote_median_salary - home_median_salary) AS remote_premium
FROM
    job_type_median AS h
INNER JOIN
    job_type_median AS r
ON
    h.job_title_short = r.job_title_short
WHERE
    r.job_work_from_home = TRUE AND h.job_work_from_home = FALSE
ORDER BY remote_premium DESC;

--Here it is again: compare median salary_year_avg for job_health_insurance = TRUE vs 
--job_health_insurance = FALSE, grouped by job_title_short.

WITH median_salary_ins AS (
    SELECT 
        job_title_short,
        job_health_insurance,
        MEDIAN(salary_year_avg)::INT AS median_yearly_salary
    FROM job_postings_fact
    GROUP BY
        job_title_short,
        job_health_insurance
)

SELECT 
    ins.job_title_short,
    ins.median_yearly_salary AS median_salary_with_insurance,
    nins.median_yearly_salary AS median_salary_without_insurance
FROM
    median_salary_ins AS ins
INNER JOIN
    median_salary_ins AS nins
ON
    ins.job_title_short = nins.job_title_short
WHERE
    nins.job_health_insurance = False AND ins.job_health_insurance = True;

--Why does the remote-vs-onsite example in your notes need to self-join the CTE (title_median AS r joined 
--to title_median AS o) rather than just filtering the CTE once? What would go wrong if you tried to get 
--both columns without the self-join?

--Section F: Existence Filtering
--Write a query using EXISTS to find all rows in company_dim that have at least one associated posting in 
--job_postings_fact (i.e., the company has actually posted a job).

SELECT *
FROM company_dim AS cd
WHERE EXISTS (
    SELECT 1
    FROM
        job_postings_fact AS jpf
    WHERE cd.company_id = jpf.company_id
)
ORDER BY company_id;


--Write the NOT EXISTS version of problem 11, companies with zero postings.

SELECT *
FROM company_dim AS cd
WHERE NOT EXISTS (
    SELECT 1
    FROM
        job_postings_fact AS jpf
    WHERE cd.company_id = jpf.company_id
)
ORDER BY company_id;

--Write a query using NOT EXISTS to check for job postings in job_postings_fact that reference a company_id 
--which doesn't actually exist in company_dim, essentially checking for broken foreign key references, even 
--though the constraint should prevent this.

SELECT *
FROM job_postings_fact AS jpf
WHERE NOT EXISTS (
    SELECT 1
    FROM
        company_dim AS cd
    WHERE jpf.company_id = cd.company_id
);

--Challenge: Combine Everything
--Write one query that: uses a CTE to calculate median salary_year_avg by job_title_short for remote jobs 
--only, then filters (using HAVING with a subquery, not a hardcoded value) to keep only titles whose remote 
--median is above the overall onsite median, and finally uses NOT EXISTS somewhere in the logic to exclude 
--any job title that has zero postings with associated skills in skills_job_dim.
WITH remote_median_salary AS (
    SELECT
        job_title_short,
        MEDIAN(salary_year_avg)::INT AS median_salary_year
    FROM
        job_postings_fact
    WHERE
        job_work_from_home = TRUE
    GROUP BY
        job_title_short
)

SELECT *
FROM remote_median_salary AS rms
WHERE
    median_salary_year > (
        SELECT
            MEDIAN(salary_year_avg) AS overall_median_salary
        FROM
            job_postings_fact
    )
    AND EXISTS (
        SELECT 1
        FROM job_postings_fact AS jpf
        INNER JOIN skills_job_dim AS sjd
            ON jpf.job_id = sjd.job_id
        WHERE jpf.job_title_short = rms.job_title_short
);

SELECT *
FROM skills_job_dim
LIMIT 10;



