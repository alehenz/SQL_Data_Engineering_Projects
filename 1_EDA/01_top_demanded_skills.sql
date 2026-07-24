/*
What are the most in-demand skills for data engineers?
-Identify the top 10 in-demand skills for data engineers
-Focus on remote job postings
-Why? Retrieves the top 10 skills with the highest demand
in the remote job market providing into the most valuable 
skills for data engineers seeking remote work
*/

SELECT
    sd.skills,
    COUNT(jpf.job_id) AS demand_count,
    LPAD(CAST((ROUND(COUNT(jpf.job_id) / SUM(COUNT(jpf.job_id)) OVER() * 100, 1) || ' %') AS VARCHAR), 17, ' ') AS demand_percentage
FROM job_postings_fact AS jpf
INNER JOIN skills_job_dim AS sjd
    ON jpf.job_id = sjd.job_id
INNER JOIN skills_dim AS sd
    ON sjd.skill_id = sd.skill_id
WHERE jpf.job_title_short = 'Data Engineer' AND jpf.job_work_from_home = True
GROUP BY sd.skills
ORDER BY demand_count DESC
LIMIT 10;

/*
Overview

This analysis looks at the top 10 most in-demand skills for remote Data Engineer job postings, based on how often
each skill is mentioned across the dataset. SQL and Python lead clearly, followed by a mix of cloud platforms, 
big data tools, and modern data warehousing technologies, together painting a picture of what employers actually 
expect from remote DE candidates today.

Key takeaways:
1. SQL and Python are essentially tied at the top (10.2% and 10.0%), confirming both as baseline requirements 
rather than specialized skills.
2. AWS leads cloud platforms clearly (6.2%), well ahead of Azure (4.9%) and GCP (2.2%), a useful signal for 
prioritizing cloud certifications.
3. Spark and Airflow form the core pipeline skillset (4.4% and 3.5%), distinct from language and cloud skills, 
representing the hands-on engineering craft itself.
4. Snowflake and Databricks have become standard expectations, not niche extras, both outranking Java in this 
dataset.
5. Java trails the pack (2.5%), reinforcing Python as the dominant language for this role specifically, not 
general-purpose programming languages.

┌────────────┬──────────────┬───────────────────┐
│   skills   │ demand_count │ demand_percentage │
│  varchar   │    int64     │      varchar      │
├────────────┼──────────────┼───────────────────┤
│ sql        │        29221 │            10.2 % │
│ python     │        28776 │            10.0 % │
│ aws        │        17823 │             6.2 % │
│ azure      │        14143 │             4.9 % │
│ spark      │        12799 │             4.4 % │
│ airflow    │         9996 │             3.5 % │
│ snowflake  │         8639 │             3.0 % │
│ databricks │         8183 │             2.8 % │
│ java       │         7267 │             2.5 % │
│ gcp        │         6446 │             2.2 % │
└────────────┴──────────────┴───────────────────┘
  10 rows                             3 columns
*/
