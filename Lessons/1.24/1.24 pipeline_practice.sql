--Section B: Manual Method
--Rewrite the INSERT statement from the manual version, but for a hypothetical scenario where you're 
--loading new rows into main.priority_jobs_snapshot from a table called src_new_postings instead of 
--src_priority_jobs, keep the same existence-filtering logic.

INSERT INTO main.priority_jobs_snapshot (
    job_id,
    job_title_short,
    company_name,
    job_posted_date,
    salary_year_avg,
    priority_lvl,
    updated_at
)
SELECT
    src.job_id,
    src.job_title_short,
    src.company_name,
    src.job_posted_date,
    src.salary_year_avg,
    src.priority_lvl,
    src.updated_at
FROM
    src_new_postings AS src
WHERE NOT EXISTS (
    SELECT 1
    FROM main.priority_jobs_snapshot AS tgt
    WHERE tgt.job_id = src.job_id
);

--Write a DELETE statement that removes rows from staging.priority_roles where the role_name no longer 
--exists in a hypothetical src_current_roles table, using the same NOT EXISTS reversed-perspective pattern 
--from problem 4.

DELETE FROM staging.priority_roles AS tgt
WHERE NOT EXISTS (
    SELECT 1
    FROM src_current_roles AS src
    WHERE src.role_name = tgt.role_name
);

--Section C: MERGE INTO
--Write a MERGE INTO statement (structurally identical to the pipeline's, but standalone) that merges a hypothetical 
--src_departments table into a hypothetical main.departments_snapshot table, keyed on department_id, updating 
--department_name when it's changed, inserting when the source has a department the target doesn't, and deleting 
--from the target when a department no longer exists in the source.
MERGE INTO main.departments_snapshot AS tgt
USING src_departments AS src
ON tgt.department_id = src.department_id

WHEN MATCHED AND tgt.department_name IS DISTINCT FROM src.department_name THEN
    UPDATE SET
        department_name = src.department_name,
        updated_at = src.updated_at

WHEN NOT MATCHED THEN
    INSERT (
        department_id,
        department_name,
        updated_at
    )
    VALUES (
        src.department_id,
        src.department_name,
        src.updated_at
    )

WHEN NOT MATCHED BY SOURCE THEN DELETE;


--In the actual pipeline's MERGE INTO, what does WHEN NOT MATCHED BY SOURCE mean, specifically, and how is it different 
--from plain WHEN NOT MATCHED? Which one corresponds to which Venn diagram zone (insert vs. delete)?



--If you removed the WHEN NOT MATCHED BY SOURCE THEN DELETE clause entirely from the pipeline's MERGE INTO, but 
--kept everything else, what would happen to main.priority_jobs_snapshot over time if roles kept getting removed 
--from staging.priority_roles? Would this show up immediately, or only become a problem later?



--Section D: Comparing the Two Methods



--Name one concrete advantage of the manual three-statement version over the single MERGE INTO, something you could 
--do with three separate statements that's harder or impossible with one MERGE INTO.



--Name one concrete advantage of MERGE INTO over the manual version, beyond just "it's shorter."



--Both versions rely on the same underlying comparison logic (matched vs. unmatched in each direction). If you had to 
--explain to someone who'd never seen either version, in plain English, what a MERGE conceptually does using the Venn 
--diagram framing (source, target, three zones), how would you describe it in 2-3 sentences?



--Section E: Debugging
--Suppose you ran the manual version's INSERT statement twice in a row without re-running the TEMP TABLE creation in between. 
--Would this cause an error, a duplicate row, or nothing at all? Why?
--Suppose the MERGE INTO statement's ON clause was accidentally written as ON tgt.job_title_short = src.job_title_short instead 
--of ON tgt.job_id = src.job_id. What would go wrong, practically, given that multiple job postings can share the same job_title_short?

--Challenge
--Write a complete idempotent script (from scratch, using main.departments_snapshot and staging.departments as example table names, 
--invent reasonable columns like department_id, department_name, priority_lvl, updated_at) that includes: an initial-load-style 
--CREATE OR REPLACE TABLE for the snapshot, a TEMP TABLE staging the source data, and a MERGE INTO that keeps the snapshot synced 
--with the source going forward.

--Intial one-time load
CREATE OR REPLACE TABLE main.departments_snapshot (
    department_id       INTEGER PRIMARY KEY,
    department_name     VARCHAR,
    priority_lvl        INTEGER,
    updated_at          TIMESTAMP
);

INSERT INTO main.departments_snapshot (
    department_id,
    department_name,
    priority_lvl,
    updated_at
)

SELECT
    d.department_id,
    d.department_name,
    d.priority_lvl,
    CURRENT_TIMESTAMP
FROM
    staging.departments AS d;

--Create TEMP table
CREATE OR REPLACE TEMP TABLE src_department_data AS
SELECT
    d.department_id,
    d.department_name,
    d.priority_lvl,
    CURRENT_TIMESTAMP AS updated_at
FROM
    staging.departments AS d;

--Merging
MERGE INTO main.departments_snapshot AS tgt
USING src_department_data AS src
ON tgt.department_id = src.department_id

WHEN MATCHED AND tgt.priority_lvl IS DISTINCT FROM src.priority_lvl THEN
    UPDATE SET
        priority_lvl = src.priority_lvl,
        updated_at = src.updated_at

WHEN NOT MATCHED THEN
    INSERT (
        department_id,
        department_name,
        priority_lvl,
        updated_at
    )
    VALUES (
        src.department_id,
        src.department_name,
        src.priority_lvl,
        src.updated_at
    )

WHEN NOT MATCHED BY SOURCE THEN DELETE;