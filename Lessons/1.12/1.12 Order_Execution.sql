/* 
Find the top 10 companies for posting jobs. They must have >3000 postings. Limit to US jobs.
*/

SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE table_catalog = 'data_jobs'
ORDER BY table_name, ordinal_position;


EXPLAIN --Doesn't actually run the query
SELECT
    DISTINCT(cd.name) AS company_name,
    COUNT(jpf.job_id) AS posting_count
FROM job_postings_fact AS jpf
JOIN company_dim AS cd
    ON jpf.company_id = cd.company_id
WHERE jpf.job_country = 'United States'
GROUP BY cd.name
HAVING COUNT(jpf.job_id) > 3000
ORDER BY COUNT(jpf.job_id) DESC
LIMIT 10;


EXPLAIN ANALYZE -- Runs quey and returns time
SELECT
    DISTINCT(cd.name) AS company_name,
    COUNT(jpf.job_id) AS posting_count
FROM job_postings_fact AS jpf
JOIN company_dim AS cd
    ON jpf.company_id = cd.company_id
WHERE jpf.job_country = 'United States'
GROUP BY cd.name
HAVING COUNT(jpf.job_id) > 3000
ORDER BY COUNT(jpf.job_id) DESC
LIMIT 10;