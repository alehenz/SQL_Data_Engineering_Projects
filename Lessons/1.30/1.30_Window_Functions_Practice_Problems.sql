-- This returns a single scalar value
SELECT
    COUNT(*)
FROM
    job_postings_fact;

-- This keeps all the rows and returns the total count in every row
SELECT
    job_title_short,
    COUNT(*) OVER()
FROM
    job_postings_fact;


-- returns 10 for each row, as Window functions run after GROUP BY
SELECT
    job_title_short,
    COUNT(*) OVER()
FROM
    job_postings_fact
GROUP BY
    job_title_short;

-- Traditional GROUP BY collapses the table into unique values
SELECT
    job_title_short,
    COUNT(*)
FROM
    job_postings_fact
GROUP BY
    job_title_short;

-- PARTITION BY still calculates the aggregate value, but keeping the original rows from the table
SELECT
    job_title_short,
    COUNT(*) OVER(
        PARTITION BY job_title_short
    )
FROM
    job_postings_fact;

--Returns the same average in every column, as it calculates it according to the entire partition, once
SELECT
    job_title_short,
    job_posted_date,
    salary_hour_avg,
    AVG(salary_hour_avg) OVER(
        PARTITION BY job_title_short
    )
FROM
    job_postings_fact
WHERE salary_hour_avg IS NOT NULL AND job_title_short = 'Data Engineer';

-- Calculate a running average by adding ORDER BY inside the OVER clause
/*Add ORDER BY, and the default frame changes to something called RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW. 
In plain English: "look at every row from the very start of this partition, up through, and including, the current row, 
based on this specific ordering." Nothing after the current row is included.*/
SELECT
    job_title_short,
    job_posted_date,
    salary_hour_avg,
    AVG(salary_hour_avg) OVER(
        PARTITION BY job_title_short
        ORDER BY job_posted_date
    )
FROM
    job_postings_fact
WHERE salary_hour_avg IS NOT NULL AND job_title_short = 'Data Engineer';

/*Problem 7: write a query showing job_id, job_title_short, salary_year_avg, and the average salary_year_avg across the 
entire table (no partitioning), using a window function. Filter out NULL salaries, limit to 10.*/

SELECT
    job_id,
    job_title_short,
    salary_year_avg,
    AVG(salary_year_avg) over() AS avg_year_salary
FROM
    job_postings_fact
WHERE
    salary_year_avg IS NOT NULL
LIMIT 10;

/*Problem 8: write a query showing job_id, job_title_short, job_country, salary_year_avg, and the average salary_year_avg 
partitioned by both job_title_short and job_country. Filter NULL salaries, limit to 15.*/

SELECT
    job_id,
    job_title_short,
    job_country,
    salary_year_avg,
    AVG(salary_year_avg) over(
        PARTITION BY
            job_title_short,
            job_country
    ) AS countrywide_avg_year_salary
FROM
    job_postings_fact
WHERE
    salary_year_avg IS NOT NULL
LIMIT 15;

/*Problem 9: write a query that computes a running total (not average) of salary_year_avg for 'Data Analyst' postings, ordered 
by job_posted_date. Use SUM() instead of AVG().*/

SELECT
    job_id,
    job_title_short,
    job_posted_date,
    salary_year_avg,
    SUM(salary_year_avg) OVER(
        PARTITION BY job_title_short
        ORDER BY job_posted_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW -- This eliminates the possibility of the having the same running total in consecutive columns when they have the exact same timestamp
    ) AS running_total
FROM
    job_postings_fact
WHERE job_title_short = 'Data Analyst' AND salary_year_avg IS NOT NULL;

/*Problem 10: write a query that ranks 'Senior Data Engineer' postings by salary_year_avg descending, using RANK(). Show job_id, 
salary_year_avg, and the rank. Limit to 10.*/

SELECT
    job_id,
    salary_year_avg,
    RANK() OVER(
        ORDER BY salary_year_avg DESC
    ) AS rank
FROM
    job_postings_fact
WHERE job_title_short = 'Senior Data Engineer'
    AND salary_year_avg IS NOT NULL
LIMIT 10;

/*Problem 11: your career search project wants to know, for each job_title_short, which specific posting pays the most. Write a query 
using RANK() partitioned by job_title_short, ordered by salary_year_avg descending, then filter using a CTE to keep only the rank-1 
row per title.*/

WITH ranked_rows AS (
    SELECT
        job_id,
        job_title_short,
        salary_year_avg,
        RANK() OVER(
            PARTITION BY job_title_short
            ORDER BY salary_year_avg DESC
        ) AS job_ranks
    FROM job_postings_fact
    WHERE salary_year_avg IS NOT NULL
)

SELECT
    job_id,
    job_title_short,
    salary_year_avg AS top_year_salary
FROM
    ranked_rows
WHERE job_ranks = 1
ORDER BY salary_year_avg DESC;

/*Problem 12: same scenario, but now you want the top 3 highest-paying postings per title, not just the top 1. What single change 
accomplishes this?*/

WITH ranked_rows AS (
    SELECT
        job_id,
        job_title_short,
        salary_year_avg,
        RANK() OVER(
            PARTITION BY job_title_short
            ORDER BY salary_year_avg DESC
        ) AS job_ranks
    FROM job_postings_fact
    WHERE salary_year_avg IS NOT NULL
)

SELECT
    job_id,
    job_title_short,
    salary_year_avg AS top_year_salary
FROM
    ranked_rows
WHERE job_ranks <= 3
ORDER BY job_title_short DESC, salary_year_avg DESC;

/*Problem 14: for each company, show how much the average yearly salary changed between consecutive postings, using LAG(), matching 
the lesson's pattern. Limit to 30.*/

SELECT
    company_id,
    job_id,
    job_title_short,
    job_posted_date,
    salary_year_avg,
    salary_year_avg - LAG(salary_year_avg) OVER(
        PARTITION BY company_id
        ORDER BY job_posted_date ASC
    ) AS salary_vs_prev_posting
FROM
    job_postings_fact
WHERE
    salary_year_avg IS NOT NULL
ORDER BY
    company_id ASC,
    job_posted_date ASC
LIMIT 30;

/*Problem 15: using the same setup, write a query showing the change looking forward using LEAD() instead. Conceptually, would the 
salary_change values from a LAG()-based query and a LEAD()-based query on the same data be related in a predictable way, same values 
shifted, or exact negatives? Think it through before answering.*/

SELECT
    company_id,
    job_id,
    job_title_short,
    job_posted_date,
    salary_year_avg,
    salary_year_avg - LEAD(salary_year_avg) OVER(
        PARTITION BY company_id
        ORDER BY job_posted_date ASC
    ) AS salary_vs_next_posting
FROM
    job_postings_fact
WHERE
    salary_year_avg IS NOT NULL
ORDER BY
    company_id ASC,
    job_posted_date ASC
LIMIT 30;

/*Problem 18: for each job_title_short, identify postings that pay above the average for that title, using a CTE with AVG(salary_year_avg) 
OVER (PARTITION BY job_title_short), filtered in the outer query.*/

WITH mean_salary_per_title AS (
    SELECT
        company_id,
        job_id,
        job_title_short,
        salary_year_avg,
        AVG(salary_year_avg) OVER(
            PARTITION BY job_title_short
        ) AS mean_salary
    FROM
        job_postings_fact
    WHERE
        salary_year_avg IS NOT NULL
)

SELECT
    company_id,
    job_id,
    job_title_short,
    salary_year_avg,
    mean_salary
FROM mean_salary_per_title
WHERE salary_year_avg > mean_salary;

/*Real scenario: build a "salary trend" report for 'Data Scientist' postings at a single company (pick any company_id present in your data). 
For each posting ordered by date, show: the posting's salary, a running average salary up to and including that posting, the rank of that 
posting's salary among all this company's Data Scientist postings, and the change in salary from the previous posting. This requires 
combining an aggregate window, a ranking window, and a navigation window all in one query.*/

WITH ranked_postings AS(
    SELECT
    company_id,
    job_id,
    job_posted_date,
    job_title_short,
    salary_year_avg,
    AVG(salary_year_avg) OVER(
        PARTITION BY company_id
        ORDER BY job_posted_date ASC
    ) AS running_average,
    DENSE_RANK() OVER(
        PARTITION BY company_id
        ORDER BY salary_year_avg DESC
    ) AS rank_within_company
FROM
    job_postings_fact
WHERE
    job_title_short = 'Data Scientist'
    AND salary_year_avg IS NOT NULL
    AND company_id = 4828
)

SELECT
    *,
    salary_year_avg - LAG(salary_year_avg) OVER(
        PARTITION BY company_id
        ORDER BY rank_within_company ASC
    ) AS salary_vs_previous_ranked
FROM ranked_postings;


SELECT
    company_id,
    job_id,
    job_posted_date,
    job_title_short,
    salary_year_avg,
    AVG(salary_year_avg) OVER(
        PARTITION BY company_id
        ORDER BY job_posted_date ASC
    ) AS running_average,
    DENSE_RANK() OVER(
        PARTITION BY company_id
        ORDER BY salary_year_avg DESC
    ) AS rank_within_company,
    salary_year_avg - LAG(salary_year_avg) OVER(
        PARTITION BY company_id
        ORDER BY job_posted_date ASC
    ) AS salary_vs_previous_post_by_date
FROM job_postings_fact
WHERE job_title_short = 'Data Scientist'
    AND salary_year_avg IS NOT NULL
    AND company_id = 4828
ORDER BY job_posted_date ASC;