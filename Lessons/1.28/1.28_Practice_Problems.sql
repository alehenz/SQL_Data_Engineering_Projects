/*Write a query that extracts the first 4 characters of job_title_short 
and labels the column title_prefix. Limit to 10.*/
SELECT
    LEFT(job_title_short, 4) AS title_prefix
FROM job_postings_fact
LIMIT 10;

/*Write a query using TRIM, LOWER, and LENGTH together, on a hardcoded 
string '  Data Engineer  ', that outputs the cleaned, lowercased string 
and its length after cleaning. (Hint: length should reflect the string 
after trimming, not before.)*/

WITH cleaned AS (
    SELECT LOWER(TRIM('  Data Engineer  ')) AS cleaned_string
)
SELECT
    cleaned_string,
    LENGTH(cleaned_string) AS cleaned_length
FROM cleaned;

/*Using CONCAT (not ||), write a query that builds a single readable string 
from job_title_short and job_location for each posting, formatted like 'Data 
Analyst — Toronto, ON' (use an em dash or plain hyphen as the separator, 
whichever your notes' convention suggests). Limit to 5.*/
SELECT
    CONCAT(job_title_short, ' - ', job_location)
FROM job_postings_fact
LIMIT 5;

/*Write a query using REGEXP_REPLACE that extracts just the domain (everything 
after the @) from the hardcoded email 'jane.doe@northeastern.edu', without the
 @ itself. Hint: your notes' example keeps the @, adjust the pattern so it's 
 excluded from the output.*/
SELECT REGEXP_REPLACE('jane.doe@northeastern.edu', '^.*@', '');

/*Write a query that shows job_title_short, salary_hour_avg, and a third column 
that returns NULL wherever salary_hour_avg is exactly 0, otherwise the actual 
value. Limit to 10.*/
SELECT
    job_title_short,
    salary_hour_avg,
    NULLIF(salary_hour_avg, 0) AS salary_hour_avg_clean
FROM    
    job_postings_fact
ORDER BY RANDOM()
LIMIT 10;