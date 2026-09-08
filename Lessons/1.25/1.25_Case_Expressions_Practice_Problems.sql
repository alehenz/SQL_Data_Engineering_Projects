/* Write a query that buckets salary_year_avg into 'Entry' (< 60,000), 
'Mid' (60,000 to 120,000), and 'Senior' (> 120,000), showing job_title_short, 
salary_year_avg, and the bucket. Filter out NULL salaries. Limit to 10.*/

SELECT
    job_title_short,
    salary_year_avg,
    CASE
        WHEN salary_year_avg < 60_000 THEN 'Entry'
        WHEN salary_year_avg < 120_000 THEN 'Mid'
        ELSE 'Senior'
    END AS job_category
FROM job_postings_fact
WHERE salary_year_avg IS NOT NULL 
LIMIT 10;

/*Rewrite problem 5, but instead of filtering out NULL salaries with WHERE, 
handle them inside the CASE statement itself, labeling them 'Unknown'.*/

SELECT
    job_title_short,
    salary_year_avg,
    CASE
        WHEN salary_year_avg < 60_000 THEN 'Entry'
        WHEN salary_year_avg < 120_000 THEN 'Mid'
        WHEN salary_year_avg >= 120_000 THEN 'Senior'
        ELSE 'Unknown'
    END AS job_category
FROM job_postings_fact
LIMIT 10;

/*Using LIKE, write a CASE statement that classifies job_title into 'Manager' 
(contains "Manager"), 'Director' (contains "Director"), or 'Individual Contributor' 
(anything else). Show job_title and the new category column. Limit to 15, ordered 
randomly (like the lesson's example).*/

SELECT
    job_title,
    CASE
        WHEN job_title LIKE '%Manager%' THEN 'Manager'
        WHEN job_title LIKE '%Director%' THEN 'Director'
        ELSE 'Individual Contributor'
    END AS standardized_title
FROM
    job_postings_fact
ORDER BY RANDOM()
LIMIT 15;
