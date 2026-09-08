/*
DDL (Data Definition Language)
DDL commands define and modify the physical structure or schema of the database.
*/
CREATE DATABASE job_mart; -- create a new database with a specific name

SHOW DATABASES; --shows existing databases

CREATE DATABASE job_mart; -- trying to create a database with the same name will return an error

CREATE DATABASE IF NOT EXISTS job_mart; --in case of writing scripts, this is a better command in order not to get an error

DROP DATABASE job_mart; --deletes the database

SHOW DATABASES; --confirms the database has been deleted

DROP DATABASE IF EXISTS job_mart; --again, in case writing a script and avoid getting an error, this deletes the database only if it exists

/*
Once we have created our database, we must now create a schema
*/

SELECT *
FROM information_schema.schemata;
-- by default, duckdb will create our database with one schema of main, but we want to create an additional "staging" schema

CREATE SCHEMA job_mart.staging; -- adding the database name before the schema is necessary in case we are connected to another database, otherwise it would create the schema on the worng database

USE job_mart; -- this command is available only in particular servers

CREATE SCHEMA IF NOT EXISTS staging; --again, in case writing a script and avoid getting an error, this creates the schema only if it does not already exists

DROP SCHEMA staging;

/*
Once we have our necessary schema, we now create our tables
*/

CREATE TABLE IF NOT EXISTS table_name (
    id_column INTEGER PRIMARY KEY,
    column_name2 datatype,
    column_name3 datatype,
    foreign_key_column datatype,
    FOREIGN KEY (foreign_key_column) REFERENCES parent_table()
);

/*Creates a table inside the staging schema*/
CREATE TABLE IF NOT EXISTS staging.preferred_roles (
    role_id INTEGER PRIMARY KEY,
    role_name VARCHAR
);

/*Check the table was created*/
SELECT *
FROM information_schema.tables 
WHERE table_catalog = 'job_mart';

-- Dropping a table
DROP TABLE IF EXISTS main.preferred_roles; --the schema before the table is not necessary but recommended. The IF EXISTS clause is not necessary either but recommended if runnign a script

/*
INSERT and UPDATE
*/
--INSERT INTO adds new rows to a table
--VALUES lets you insert one or many rows at once
INSERT INTO table_name (col1, col2, ...)
VALUES (cal1, cal2, ...);

INSERT INTO staging.preferred_roles(role_id, role_name)
VALUES
    (1, 'Data Engineer'),
    (2, 'Senior Data Engineer');

SELECT *
FROM staging.preferred_roles;

INSERT INTO staging.preferred_roles(role_id, role_name)
VALUES
    (3, 'Software Engineer');

/*
Altering tables to add or drop columns
*/

ALTER TABLE staging.preferred_roles
ADD COLUMN preferred_role BOOLEAN;

ALTER TABLE staging.preferred_roles
DROP COLUMN preferred_role;

/*
Update
UPDATE changes existing rows
SET defines new values
WHERE controls which rows to change
*/

UPDATE table_name
SET column_name = value
WHERE some_condition;

UPDATE staging.preferred_roles
SET preferred_role = True
WHERE role_id = 1 OR role_id = 2;

UPDATE staging.preferred_roles
SET preferred_role = False
WHERE role_id = 3;


-- Rename changes the name of a table
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