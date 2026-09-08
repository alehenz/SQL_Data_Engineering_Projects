/*
As engineers, we must be able to create idempotent scripts (programs that 
you can run safely many times without changing the final system state 
past the first run). the following woul be a complete run of the script
*/
-- .read Lessons/1.21/1.21_DDL_DML_script.sql
USE data_jobs; -- change default USE database in order to be able to drop, other wise it will return an error
DROP DATABASE IF EXISTS job_mart; --start by dropping the database just in case

CREATE DATABASE IF NOT EXISTS job_mart;

SHOW DATABASES;

-- DROP DATABASE IF NOT EXISTS job_mart;

SELECT *
FROM information_schema.schemata;

USE job_mart;

CREATE SCHEMA IF NOT EXISTS staging;

-- DROP SCHEMA staging;

CREATE TABLE IF NOT EXISTS staging.preferred_roles (
    role_id INTEGER PRIMARY KEY,
    role_name VARCHAR
);

SELECT *
FROM information_schema.tables
WHERE table_catalog = 'job_mart';

DROP TABLE IF EXISTS main.preferred_roles; --actual table is on the staging schema

INSERT INTO staging.preferred_roles (role_id, role_name)
VALUES  
    (1, 'Data Engineer'),
    (2, 'Senior Data Engineer'),
    (3, 'Software Engineer');

SELECT *
FROM staging.preferred_roles;

ALTER TABLE staging.preferred_roles
ADD COLUMN preferred_role BOOLEAN;

UPDATE staging.preferred_roles
SET preferred_role = True
WHERE role_id = 1 OR role_id = 2;

UPDATE staging.preferred_roles
SET preferred_role = False
WHERE role_id = 3;

ALTER TABLE staging.preferred_roles
RENAME TO priority_roles;

ALTER TABLE staging.priority_roles
RENAME COLUMN preferred_role TO priority_lvl;

ALTER TABLE staging.priority_roles
ALTER COLUMN priority_lvl TYPE INTEGER; --In this case we will be able to make the type change because boolean values are 0 or 1 behind the scenes

UPDATE staging.priority_roles
SET priority_lvl = 3
WHERE role_id = 3;

SELECT *
FROM staging.priority_roles;