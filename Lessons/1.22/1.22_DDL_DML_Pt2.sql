/* CTA: Create Table As: a physical table stored on disk, that behaves like a persistent snapshot. 
If there any future changes in the source tables, this kind of table is not updated (snapshot).
Use when you need fast reads and stable results

In the following example, we'll create a flat table of job postings joined with company information.
We will join to existing tables and create a new table form them (hence the 'create table as')*/

CREATE OR REPLACE TABLE staging.job_postings_flat AS -- the OR REPLACE condition is options, and useful to create idempotent scripts
SELECT
    jpf.job_id,
    jpf.job_title_short,
    jpf.job_title,
    jpf.job_location,
    jpf.job_via,
    jpf.job_schedule_type,
    jpf.job_work_from_home,
    jpf.search_location,
    jpf.job_posted_date,
    jpf.job_no_degree_mention,
    jpf.job_health_insurance,
    jpf.job_country,
    jpf.salary_rate,
    jpf.salary_year_avg,
    jpf.salary_hour_avg,
    cd.name AS company_name,
FROM data_jobs.job_postings_fact AS jpf
LEFT JOIN data_jobs.company_dim AS cd
    ON jpf.company_id = cd.company_id;

--Run the following query to verify all rows are there
SELECT COUNT(*)
FROM staging.job_postings_flat;

/* VIEW: a virtual tables where no data is stored. The query runs at read time, and always reflects
the latest data (real time updates as source tables update). Can be slower as it recomputes.

In the following example we'll create a VIEW for all job postings with priority level 1
Use when you need the latest data */
CREATE OR REPLACE VIEW staging.priority_jobs_flat_view AS -- the OR REPLACE condition is options, and useful to create idempotent scripts
SELECT 
    jpf.*
FROM staging.job_postings_flat AS jpf
JOIN staging.priority_roles AS r
    ON jpf.job_title_short = r.role_name
WHERE r.priority_lvl = 1;

SELECT
    job_title_short,
    COUNT(*) AS job_count
FROM staging.priority_jobs_flat_view
GROUP BY job_title_short
ORDER BY job_count DESC;

/* TEMP TABLE: session-scoped table, so as soon as we log out from our session, it disappears forever.
Use for testing and debugging*/
CREATE OR REPLACE TEMPORARY TABLE senior_jobs_flat_temp AS -- TEMP OR TEMPORARY work, but TEMPORARY is common convention. Temp tables don't require schema (will reject if preceded by a schema) because it's not stored in any schema
SELECT *
FROM staging.priority_jobs_flat_view
WHERE job_title_short = 'Senior Data Engineer';

SELECT
    job_title_short,
    COUNT(*) AS job_count
FROM senior_jobs_flat_temp
GROUP BY job_title_short
ORDER BY job_count DESC;

/* DELETE: Row-level removal. Keeps schema, optional WHERE, slower on huge tables, best for targeted deletes*/

SELECT COUNT(*) FROM staging.job_postings_flat;
SELECT COUNT(*) FROM staging.priority_jobs_flat_view;
SELECT COUNT(*) FROM senior_jobs_flat_temp;

DELETE FROM staging.job_postings_flat
WHERE job_posted_date < '2024-01-01';

-- Only the temp table will not be affected in this case
SELECT COUNT(*) FROM staging.job_postings_flat;
SELECT COUNT(*) FROM staging.priority_jobs_flat_view;
SELECT COUNT(*) FROM senior_jobs_flat_temp;

/* TRUNCATE:  keeps schema, no WHERE (all rows), very fast, resets table to empty*/

-- First we go to the tables initial state
CREATE OR REPLACE TABLE staging.job_postings_flat AS -- the OR REPLACE condition is options, and useful to create idempotent scripts
SELECT
    jpf.job_id,
    jpf.job_title_short,
    jpf.job_title,
    jpf.job_location,
    jpf.job_via,
    jpf.job_schedule_type,
    jpf.job_work_from_home,
    jpf.search_location,
    jpf.job_posted_date,
    jpf.job_no_degree_mention,
    jpf.job_health_insurance,
    jpf.job_country,
    jpf.salary_rate,
    jpf.salary_year_avg,
    jpf.salary_hour_avg,
    cd.name AS company_name,
FROM data_jobs.job_postings_fact AS jpf
LEFT JOIN data_jobs.company_dim AS cd
    ON jpf.company_id = cd.company_id;

-- We truncate the table to delete all its contents
TRUNCATE TABLE staging.job_postings_flat;

-- Schema remains there
SELECT * FROM staging.job_postings_flat;

INSERT INTO staging.job_postings_flat
SELECT
    jpf.job_id,
    jpf.job_title_short,
    jpf.job_title,
    jpf.job_location,
    jpf.job_via,
    jpf.job_schedule_type,
    jpf.job_work_from_home,
    jpf.search_location,
    jpf.job_posted_date,
    jpf.job_no_degree_mention,
    jpf.job_health_insurance,
    jpf.job_country,
    jpf.salary_rate,
    jpf.salary_year_avg,
    jpf.salary_hour_avg,
    cd.name AS company_name,
FROM data_jobs.job_postings_fact AS jpf
LEFT JOIN data_jobs.company_dim AS cd
    ON jpf.company_id = cd.company_id
WHERE job_posted_date >= '2024-01-01';

-- Verify
SELECT COUNT(*) FROM staging.job_postings_flat;
SELECT COUNT(*) FROM staging.priority_jobs_flat_view;
SELECT COUNT(*) FROM senior_jobs_flat_temp;

