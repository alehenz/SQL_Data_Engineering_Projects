SELECT
    job_id,
    job_title_short,
    salary_year_avg,
    company_id
FROM
    job_postings_fact
LIMIT 10;

SELECT
    *
FROM
    company_dim
LIMIT 10;

SELECT
    *
FROM
    company_dim
WHERE
    NAME IN('Facebook', 'Meta');

SELECT *
FROM information_schema.columns
WHERE table_catalog ='data_jobs';

PRAGMA show_tables_expanded;

DESCRIBE job_postings_fact;

SELECT *
FROM information_schema
WHERE data_type = 'boolean';