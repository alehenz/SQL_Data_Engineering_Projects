/*The following is an example of a batch processing data pipeline. In contrast to continuous processing processes
data in groups on fixed intervals. This is the most used method (continuos processing is mostly for live systems).
In our job_mart data warehouse, inside the main schema, we'll be building a table (priority_jobs_snapshot) that's a
combination of job_postings_fact, company_dim and the priority roles tables.
What we'll be demonstrating is that the business owned priority_jobs table is going to be frequently updated, which
will affect our downstream table (priority_jobs_snapshot). Every time the table is updated, our new table should be
able to handle these updates.
We'll create a script (priority_roles_snapshot-INITIAL) for the one time initial load from the job_postings_fact table, and after that we'll create an
UPDATE, INSERT DELETE batch loader script which will keep our new table updated.

The pipeline consists of the following:
Source Table | Target Table
Left Section (Source Table): UNMATCHED INCOMING ROWS
    Action: INSERT

Center Intersection (Overlap): MATCHED ROWS (keys match)
    Action: UPDATE

Right Section (Target Table): UNMATCHED EXISTING ROWS
    Action: DELETE
*/
-- Create TEMP Table
CREATE OR REPLACE TEMP TABLE src_priority_jobs AS
SELECT
    jpf.job_id,
    jpf.job_title_short,
    cd.name AS company_name,
    jpf.job_posted_date,
    jpf.salary_year_avg,
    r.priority_lvl,
    CURRENT_TIMESTAMP AS updated_at
FROM
    data_jobs.job_postings_fact AS jpf
LEFT JOIN data_jobs.company_dim AS cd
    ON jpf.company_id = cd.company_id
INNER JOIN staging.priority_roles AS r
    ON jpf.job_title_short = r.role_name; 

-- -- UPDATE statement: for when priority roles may have been changed in the staging.priority_roles table
-- UPDATE main.priority_jobs_snapshot AS tgt
-- SET
--     priority_lvl = src.priority_lvl,
--     updated_at = src.updated_at
-- FROM src_priority_jobs AS src
-- WHERE tgt.job_id = src.job_id
--     AND tgt.priority_lvl IS DISTINCT FROM src.priority_lvl;

-- -- INSERT statement (insert additional rows that aren't in the target table)

-- INSERT INTO main.priority_jobs_snapshot (
--     job_id,
--     job_title_short,
--     company_name,
--     job_posted_date,
--     salary_year_avg,
--     priority_lvl,
--     updated_at
-- )
-- SELECT
--     src.job_id,
--     src.job_title_short,
--     src.company_name,
--     src.job_posted_date,
--     src.salary_year_avg,
--     src.priority_lvl,
--     src.updated_at
-- FROM src_priority_jobs AS src
-- -- Existence filtering comes in handy to inly insert those rows from the source table that are not in the target table
-- WHERE NOT EXISTS (
--     SELECT 1
--     FROM main.priority_jobs_snapshot AS tgt
--     WHERE tgt.job_id = src.job_id
-- );

-- -- DELETE statement: in case there's jobs that were removed from the priority table, this section deletes them

-- --In this case we flipped the src and tgt tables (tgt becomes the main table)
-- DELETE FROM main.priority_jobs_snapshot AS tgt
-- WHERE NOT EXISTS (
--     SELECT 1
--     FROM src_priority_jobs AS src
--     WHERE src.job_id = tgt.job_id
-- );

-- MERGE INTO -- combines the UPDATE, INSERT and DELETE statements
MERGE INTO main.priority_jobs_snapshot AS tgt
USING src_priority_jobs AS src
ON tgt.job_id = src.job_id

WHEN MATCHED AND tgt.priority_lvl IS DISTINCT FROM src.priority_lvl THEN
    UPDATE SET
        priority_lvl = src.priority_lvl,
        updated_at = src.updated_at

WHEN NOT MATCHED THEN
    INSERT (
        job_id,
        job_title_short,
        company_name,
        job_posted_date,
        salary_year_avg,
        priority_lvl,
        updated_at
    )
    VALUES (
        src.job_id,
        src.job_title_short,
        src.company_name,
        src.job_posted_date,
        src.salary_year_avg,
        src.priority_lvl,
        src.updated_at
    )

WHEN NOT MATCHED BY SOURCE THEN DELETE;

-- Final Check Query
SELECT
    job_title_short,
    COUNT(*) AS job_count,
    MIN(priority_lvl) AS priority_lvl,
    MIN(updated_at) AS updated_at
FROM priority_jobs_snapshot
GROUP BY job_title_short
ORDER BY job_count DESC;