/*
Question: What are the highest paying skills for data engineers?
- Calculate the median salary for each skill required in data engineer positions
- Focus on remote positions with specified salaries
- Include skill frequency to identify both salary and demand
- Why? Helps identify which skills command the highest compensation while also showing
  how common those skills are, providing a more complete picture for skill development
  priorities
*/

SELECT 
    sd.skills,
    CAST(ROUND(MEDIAN(jpf.salary_year_avg), 0) AS INT) AS median_salary,
    COUNT(jpf.job_id) AS demand_count
FROM 
    job_postings_fact AS jpf
INNER JOIN skills_job_dim AS sjd
    ON jpf.job_id = sjd.job_id
INNER JOIN skills_dim AS sd
    ON sjd.skill_id = sd.skill_id
WHERE 
    jpf.job_title_short = 'Data Engineer' AND jpf.job_work_from_home = True
GROUP BY 
    sd.skills
HAVING 
    COUNT(jpf.job_id) > 100
ORDER BY 
    median_salary DESC
LIMIT 25;

/*
Overview:
This looks at the 25 highest-paying skills for remote Data Engineer roles, restricted to
 skills appearing in more than 100 postings so the salary figures aren't driven by tiny 
 sample sizes. Median salary ranges from roughly $148K to $210K across this group, and 
 demand varies enormously underneath that, some of these are niche, high-paying specialties, 
 others are core, widely-required skills that also happen to pay well.

Key takeways:
1. Rust commands a clear premium at the top ($210K), but on tiny demand (232 postings), 
suggesting a scarcity premium rather than mainstream expectation, a specialist bet, not 
a core skill to build first.
2. Terraform and Kubernetes are the rare combination of high pay and high demand. Terraform
sits at $184K with over 3,200 postings, Kubernetes at $150.5K with over 4,200 postings, 
both meaningfully more common than most other entries on this list while still paying 
well above median.
3. Airflow is the clear volume leader (nearly 10,000 postings) while still landing at $150K 
median. Airflow is both widely required and solidly compensated, not a tradeoff between 
the two.
4. Several niche tools carry outsized salaries relative to their demand (neo4j, graphql, 
fastapi, crystal all sit above $150K on demand counts under 500), worth flagging as 
differentiators rather than baseline expectations, useful to mention on a resume but not 
worth prioritizing over core tools.
5. The bottom of this list still clears $147K, meaning even the "lowest" entries here 
(jupyter, ansible, vmware) represent solidly paying skills, this whole set is a list of 
premium skills relative to the broader DE market, not a spread from low to high pay 
overall.

┌────────────┬───────────────┬──────────────┐
│   skills   │ median_salary │ demand_count │
│  varchar   │     int32     │    int64     │
├────────────┼───────────────┼──────────────┤
│ rust       │        210000 │          232 │
│ terraform  │        184000 │         3248 │
│ golang     │        184000 │          912 │
│ spring     │        175500 │          364 │
│ neo4j      │        170000 │          277 │
│ gdpr       │        169616 │          582 │
│ zoom       │        168438 │          127 │
│ graphql    │        167500 │          445 │
│ mongo      │        162250 │          265 │
│ fastapi    │        157500 │          204 │
│ bitbucket  │        155000 │          478 │
│ django     │        155000 │          265 │
│ crystal    │        154224 │          129 │
│ atlassian  │        151500 │          249 │
│ c          │        151500 │          444 │
│ typescript │        151000 │          388 │
│ kubernetes │        150500 │         4202 │
│ ruby       │        150000 │          736 │
│ css        │        150000 │          262 │
│ airflow    │        150000 │         9996 │
│ node       │        150000 │          179 │
│ redis      │        149000 │          605 │
│ vmware     │        148798 │          136 │
│ ansible    │        148798 │          475 │
│ jupyter    │        147500 │          400 │
└────────────┴───────────────┴──────────────┘
  25 rows                         3 columns
*/
