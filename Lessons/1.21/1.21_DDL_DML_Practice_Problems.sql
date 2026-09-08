/*
Section A: Databases and Schemas
1. Write a single idempotent statement that creates a database called hr_analytics without erroring if it already exists.
*/

DROP DATABASE IF EXISTS hr_analytics;
CREATE DATABASE IF NOT EXISTS hr_analytics;

/*
2. Write the statement to switch your active connection to hr_analytics.*/

USE hr_analytics;

/*
3. Inside hr_analytics, create a schema called raw idempotently.*/

CREATE SCHEMA IF NOT EXISTS hr_analytics.raw;

/*
4. Write a query against information_schema.schemata that returns only the schemas belonging to hr_analytics (not every database on your connection).*/

SELECT *
FROM information_schema.schemata
WHERE catalog_name = 'hr_analytics';

/*
5. Write an idempotent statement to drop the raw schema. Then explain in one sentence why DuckDB might refuse this if the schema still has tables in it, and give the fix.
*/

DROP SCHEMA IF EXISTS hr_analytics.raw;

/*
the previous option deletes the schema if it doesn't contain tables (requires tables to be dropped first). the following one includes tables in the drop
*/

DROP SCHEMA IF EXISTS hr_analytics.raw CASCADE;

/*
Section B: Tables and Constraints
6. Inside hr_analytics.raw, create a table employees with:
    - employee_id as an integer primary key
    - full_name as a required (non-null) text field
    - department_id as an integer
    - hire_date as a date
*/

CREATE TABLE IF NOT EXISTS hr_analytics.raw.employees (
    employee_id INTEGER PRIMARY KEY,
    full_name TEXT NOT NULL,
    department_id INTEGER,
    hire_date DATE
);

/*
7. Create a second table departments with department_id (primary key) and department_name. Then rewrite the employees table definition from problem 6 so department_id is a foreign key referencing departments.
*/

CREATE TABLE IF NOT EXISTS hr_analytics.raw.departments (
    department_id INTEGER PRIMARY KEY,
    department_name TEXT
);

DROP TABLE IF EXISTS hr_analytics.raw.employees;

CREATE TABLE IF NOT EXISTS hr_analytics.raw.employees (
    employee_id INTEGER PRIMARY KEY,
    full_name TEXT NOT NULL,
    department_id INTEGER,
    hire_date DATE,
    FOREIGN KEY (department_id) REFERENCES raw.departments(department_id)
);

/*
8. Write a query against information_schema.tables to confirm both tables exist, filtered to just the raw schema.
*/

SELECT *
FROM information_schema.tables
WHERE table_catalog = 'hr_analytics'
AND table_schema = 'raw';

SELECT *
FROM information_schema.columns
WHERE table_catalog = 'hr_analytics'
AND table_schema = 'raw';
/*
9. Write an idempotent DROP TABLE statement for employees, including the schema name.
*/

DROP TABLE IF EXISTS hr_analytics.raw.employees;

/*
Section C: Insert and Update
10. Insert three departments of your choosing into departments in a single statement.
*/

INSERT INTO hr_analytics.raw.departments(department_id, department_name)
VALUES
    (1, 'Sales'),
    (2, 'Operations'),
    (3, 'Engineering');

/*
11. Insert two employees into employees, referencing valid department_id values from problem 10.
*/

INSERT INTO hr_analytics.raw.employees(employee_id, full_name, department_id, hire_date)
VALUES
    (1, 'Alec Basrejour', 1, '2023-03-31'),
    (2, 'Charles Daniels', 3, '2023-05-15'),
    (3, 'Edgar Fontaine', 2, '2024-06-20'),
    (4, 'Gale Hendricks', 1, '2025-02-28');

/*
12. Try inserting an employee with a department_id that doesn't exist in departments. What error would you expect, and why does the foreign key constraint cause it?
*/

INSERT INTO hr_analytics.raw.employees(employee_id, full_name, department_id, hire_date)
VALUES
    (5, 'Alec Basrejour', 4, '2023-03-31');

/*
13. Write an UPDATE that gives every employee in one specific department a new department_id (a transfer). Use WHERE correctly so you don't move everyone.
*/

UPDATE raw.employees
SET department_id = 2
WHERE department_id = 1;

/*
Section D: Altering Tables
14. Add a salary column (numeric type) to employees.
*/

ALTER TABLE raw.employees
ADD COLUMN salary DECIMAL(10, 2);

/*
15. Rename employees to staff.
*/

ALTER TABLE raw.employees
RENAME TO staff;

/*
16. Rename the full_name column on staff to employee_name.
*/

ALTER TABLE raw.staff
RENAME COLUMN full_name TO employee_name;

/*
17. Change the salary column's type from your original choice to INTEGER. If this fails, explain why, and what DuckDB requires before a type change like that will succeed (hint: think about what happened with the boolean-to-integer change in your notes, and why numeric-to-integer isn't automatically as safe).
*/

ALTER TABLE raw.staff
ALTER COLUMN salary TYPE INTEGER;

/*
Challenge: Full Idempotent Script
18. Combine everything above into one script that could run top to bottom, twice in a row, with zero errors either time. It must:
    - Drop and recreate hr_analytics cleanly
*/
USE sample_data;
DROP DATABASE IF EXISTS hr_analytics;
CREATE DATABASE IF NOT EXISTS hr_analytics;
USE hr_analytics;
/*
    - Create the raw schema
*/
CREATE SCHEMA IF NOT EXISTS hr_analytics.raw;
/*
    - Create departments and staff (with the foreign key)
*/
CREATE TABLE IF NOT EXISTS hr_analytics.raw.departments (
    department_id INTEGER PRIMARY KEY,
    department_name TEXT
);

CREATE TABLE IF NOT EXISTS hr_analytics.raw.staff (
    employee_id INTEGER PRIMARY KEY,
    full_name TEXT NOT NULL,
    department_id INTEGER,
    hire_date DATE,
    salary DECIMAL(10, 2),
    FOREIGN KEY (department_id) REFERENCES raw.departments(department_id)
);
/*
    - Insert your sample data
*/
INSERT INTO hr_analytics.raw.departments(department_id, department_name)
VALUES
    (1, 'Sales'),
    (2, 'Operations'),
    (3, 'Engineering');

INSERT INTO hr_analytics.raw.staff(employee_id, full_name, department_id, hire_date, salary)
VALUES
    (1, 'Alec Basrejour', 1, '2023-03-31', 100000.00),
    (2, 'Charles Daniels', 3, '2023-05-15', 90000.00),
    (3, 'Edgar Fontaine', 2, '2024-06-20', 95000.00),
    (4, 'Gale Hendricks', 1, '2025-02-28', 100000.00);
/*
    - Include one ALTER TABLE and one UPDATE
*/
UPDATE raw.staff
SET department_id = 2
WHERE department_id = 1;

ALTER TABLE raw.staff
ALTER COLUMN salary TYPE INTEGER;
/*
    - End with a SELECT proving the final state
*/

SELECT
    employee_id,
    full_name,
    hire_date,
    salary,
    staff.department_id,
    department_name
FROM raw.staff
JOIN raw.departments
ON staff.department_id = departments.department_id; 