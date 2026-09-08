/*CASTING as means of getting date/time*/
SELECT 
    job_posted_date,
    job_posted_date::DATE AS date,
    job_posted_date::TIME AS time,
    job_posted_date::TIMESTAMP AS timestamp,
    job_posted_date::TIMESTAMPTZ AS timestampz
FROM job_postings_fact
LIMIT 10;


/*EXTRACT*/
SELECT
    job_posted_date,
    EXTRACT(YEAR FROM job_posted_date) AS job_posted_year,
    EXTRACT(MONTH FROM job_posted_date) AS job_posted_month,
    EXTRACT(DAY FROM job_posted_date) AS job_posted_day    
FROM job_postings_fact
LIMIT 10;


SELECT
    EXTRACT(YEAR FROM job_posted_date) AS job_posted_year,
    EXTRACT(MONTH FROM job_posted_date) AS job_posted_month,
    COUNT(job_id) AS job_count
FROM job_postings_fact
WHERE job_title_short = 'Data Engineer'
GROUP BY
    EXTRACT(YEAR FROM job_posted_date),
    EXTRACT(MONTH FROM job_posted_date)
ORDER BY
    job_posted_year,
    job_posted_month;

/*DATE_TRUNC -> truncates a date ir timestamp to a specified level ofprecision (e.g. year, month, day, hour). Returns
a timestamp rounded down to the start of the specified time unit*/
SELECT
    job_posted_date,
    DATE_TRUNC('year', job_posted_date) AS job_posted_year,
    DATE_TRUNC('quarter', job_posted_date) AS job_posted_quarter,
    DATE_TRUNC('month', job_posted_date) AS job_posted_month,
    DATE_TRUNC('week', job_posted_date) AS job_posted_week, 
    DATE_TRUNC('day', job_posted_date) AS job_posted_day, 
    DATE_TRUNC('hour', job_posted_date) AS job_posted_hour   
FROM job_postings_fact
ORDER BY RANDOM()
LIMIT 10;


--the following query combines the use of date_trunc and extract
SELECT
    DATE_TRUNC('month', job_posted_date) AS job_posted_month,
    COUNT(job_id) AS job_count
FROM job_postings_fact
WHERE 
    job_title_short = 'Data Engineer' AND
    EXTRACT(YEAR FROM job_posted_date) = 2024
GROUP BY
    DATE_TRUNC('month', job_posted_date)
ORDER BY
    job_posted_month;

-- AT TIME ZONE converts to the specified time zone
-- The following query converts the text to a timestamp with time zone (my time zone)
SELECT
    '2026-01-01 00:00:00+00'::TIMESTAMPTZ;
-- Specifying the timezone
SELECT
    '2026-01-01 00:00:00+00'::TIMESTAMPTZ AT TIME ZONE'CST';

SELECT
    '2026-01-01 00:00:00+00'::TIMESTAMPTZ AT TIME ZONE'EST';

/*For timestamps wothout time zone, these are usually treated as local time in DuckDB.
Using AT TIME ZONE assumes the machine's time zone for conversion. In the following template, we
use AT TIME ZONE twice

SELECT
    column_name AT TIME ZONE 'UTC' AT TIME ZONE 'EST'
FROM
    table_name
*/

-- using just one AT TIME ZONE yields a result converting from +0 to the specified time (adding or subtracting the amount of hours)
SELECT
    job_posted_date AT TIME ZONE 'UTC'
FROM
    job_postings_fact
LIMIT 10;

-- the following is the correct version. The first AT TIME ZONE states the original time zone, and the second one the intended time zone
SELECT
    job_posted_date AT TIME ZONE 'UTC' AT TIME ZONE 'EST'
FROM
    job_postings_fact
LIMIT 10;

--

SELECT  
    job_title_short,
    job_location,
    job_posted_date AT TIME ZONE 'UTC' AT TIME ZONE 'EST'
FROM
    job_postings_fact
WHERE
    job_location LIKE 'New York, NY';

SELECT
    EXTRACT(HOUR FROM job_posted_date AT TIME ZONE 'UTC' AT TIME ZONE 'EST') AS job_posted_hour,
    COUNT(job_id)
FROM
    job_postings_fact
WHERE
    job_location LIKE 'New York, NY'
GROUP BY
   EXTRACT(HOUR FROM job_posted_date AT TIME ZONE 'UTC' AT TIME ZONE 'EST')
ORDER BY 
    job_posted_hour;
