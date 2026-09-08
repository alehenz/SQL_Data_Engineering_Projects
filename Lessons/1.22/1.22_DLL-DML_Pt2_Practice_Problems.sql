/*Section B: CTAS
Write a CREATE OR REPLACE TABLE called staging.high_salary_jobs that pulls job_id, job_title_short, and salary_year_avg from data_jobs.job_postings_fact, filtered to only rows where salary_year_avg is greater than 150000.*/

CREATE OR REPLACE TABLE staging.high_salary_jobs AS
SELECT  
    jpf.job_id,
    jpf.job_title_short,
    jpf.salary_year_avg
FROM
    data_jobs.job_postings_fact AS jpf
WHERE
    salary_year_avg > 150_000;

/*Write a query to confirm how many rows landed in staging.high_salary_jobs.*/

SELECT 
    COUNT(*) AS job_count
FROM
    staging.high_salary_jobs;

/*Section C: Views
Write a CREATE OR REPLACE VIEW called staging.remote_jobs_view that selects all columns from staging.job_postings_flat where job_work_from_home is true.*/

CREATE OR REPLACE VIEW staging.remote_jobs_view AS
SELECT *
FROM staging.job_postings_flat
WHERE job_work_from_home = True;

/*Suppose someone runs DELETE FROM staging.job_postings_flat WHERE job_country != 'United States' after you've created the view above. Without rerunning anything, what would querying staging.remote_jobs_view show now, the old data or the filtered-down data? Explain why.
-Filtered down data, as with VIEW the query runs at read time. The reason it's slower than CTA is because it has to run every time its queried

Would that same scenario (a DELETE on the source table) affect a CTAS table the same way it affects a view? Why or why not?
Section D: Temp Tables
Write a CREATE OR REPLACE TEMPORARY TABLE called entry_level_temp that selects everything from staging.job_postings_flat where job_no_degree_mention is true.*/

CREATE OR REPLACE TEMP TABLE entry_level_temp AS
SELECT *
FROM staging.job_postings_flat
WHERE job_no_degree_mention;

/*You close your terminal, reopen DuckDB, and reconnect to the same database. You try SELECT * FROM entry_level_temp;. What happens, and why?
Give one realistic scenario from your own work (job search data, resume data, whatever) where you'd reach for a temp table instead of a permanent staging table.
/*Section E: DELETE vs. TRUNCATE
Write a DELETE statement that removes rows from staging.job_postings_flat where salary_year_avg IS NULL.
Write a TRUNCATE TABLE statement for staging.job_postings_flat. After running it, would SELECT * FROM staging.job_postings_flat; return an error, or an empty result? Why?
You need to remove exactly the rows posted before 2023. Which command, DELETE or TRUNCATE, is the right tool, and why is the other one not an option here?
Conceptually: why is TRUNCATE typically much faster than DELETE on a large table, even though both end up removing rows?
/*Challenge: Full Workflow Script
Write one script, idempotent, that:
Creates staging.contract_jobs as a CTAS from data_jobs.job_postings_fact, filtered to job_schedule_type = 'Contractor'
Creates a view staging.contract_jobs_us_view on top of it, filtered further to job_country = 'United States'
Creates a temp table contract_jobs_high_pay_temp from the view, filtered to salary_year_avg > 100000
Deletes rows from staging.contract_jobs where salary_year_avg IS NULL
Ends with three SELECT COUNT(*) statements, one per object, to prove the final state