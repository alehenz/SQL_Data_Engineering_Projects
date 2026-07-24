/*
Question: What are the most optimal skills for data engineers balancing both demand and
salary?
- Create a ranking column that combines demand count and median salary to identify the
  most valuable skills.
- Focus only on remote Data Engineer positions with specified annual salaries.
- Why?
    - The approach highlights skills that balance market demand and financial reward. It
      weigh core skills appropriately.
*/
SELECT
    sd.skills,
    ROUND(MEDIAN(jpf.salary_year_avg), 0) AS median_salary,
    COUNT(jpf.*) AS demand_count,
    ROUND(PERCENT_RANK() OVER (ORDER BY MEDIAN(jpf.salary_year_avg)), 3) AS salary_percentile,
    ROUND(PERCENT_RANK() OVER (ORDER BY COUNT(jpf.*)), 3) AS demand_percentile,
    ROUND((0.9 * demand_percentile + 0.1 * salary_percentile), 3) AS optimal_score
FROM
    job_postings_fact AS jpf
INNER JOIN skills_job_dim AS sjd ON jpf.job_id = sjd.job_id
INNER JOIN skills_dim AS sd ON sjd.skill_id = sd.skill_id
WHERE
    jpf.job_title_short = 'Data Engineer'
    AND jpf.job_work_from_home = True
    AND jpf.salary_year_avg IS NOT NULL
GROUP BY
    sd.skills
HAVING
    COUNT(jpf.job_id) > 100
ORDER BY
    optimal_score DESC
LIMIT 25;


SELECT
    sd.skills,
    MEDIAN(jpf.salary_year_avg) AS median_salary,
    COUNT(jpf.*) AS demand_count,
    ROUND(PERCENT_RANK() OVER (ORDER BY MEDIAN(jpf.salary_year_avg)), 3) AS salary_percentile,
    ROUND(PERCENT_RANK() OVER (ORDER BY COUNT(jpf.*)), 3) AS demand_percentile,
    ROUND((0.4 * demand_percentile + 0.6 * salary_percentile), 3) AS optimal_score
FROM
    job_postings_fact AS jpf
INNER JOIN skills_job_dim AS sjd ON jpf.job_id = sjd.job_id
INNER JOIN skills_dim AS sd ON sjd.skill_id = sd.skill_id
WHERE
    jpf.job_title_short = 'Data Engineer'
    AND jpf.job_work_from_home = True
    AND jpf.salary_year_avg IS NOT NULL
GROUP BY
    sd.skills
HAVING
    COUNT(jpf.job_id) > 100
ORDER BY
    optimal_score DESC
LIMIT 25;

/*
Methodology note

Salary and demand count are measured in completely different units, dollars versus number of postings, 
so they can't be combined directly without one variable mechanically dominating the other. To solve 
this, each skill's median salary and demand count were converted into percentile ranks using PERCENT_RANK(), 
which reframes each raw value as "what fraction of skills rank below this one" on a scale from 0 to 1. 
A skill at the 90th percentile for salary, for instance, out-earns 90% of the other skills in the set, 
regardless of its actual dollar figure. With both variables now expressed on the same 0-to-1 scale, 
they can be combined through a simple weighted average, (weight_a * demand_percentile) + 
(weight_b * salary_percentile), where the weights reflect how much each factor should matter for a 
given decision. This is a more transparent and defensible approach than a formula involving arbitrary 
transforms like logarithms, since the weighting is explicit and can be tuned directly to match the 
reader's actual priorities, rather than being an accidental side effect of the math.

Where the two versions differ

The entry-level version weights demand at 90% and salary at 10%, reflecting that someone breaking into 
the field benefits most from skills with the broadest hiring pool, since getting any offer matters 
more than optimizing pay on a first role. The experienced version flips that to 60% salary and 40% 
demand, reflecting that someone with an established track record is typically choosing between roles 
they're already qualified for, so maximizing compensation carries more weight than casting the widest 
possible net.

Entry-level ranking (90% demand / 10% salary)
This ranking weights demand heavily, reflecting the priority of someone entering the field: 
getting hired matters more than optimizing starting pay. Python leads by a wide margin, and 
the top of the list is dominated by broad, foundational tools rather than specialized ones.
┌────────────┬───────────────┬──────────────┬───────────────────┬───────────────────┬───────────────┐
│   skills   │ median_salary │ demand_count │ salary_percentile │ demand_percentile │ optimal_score │
│  varchar   │    double     │    int64     │      double       │      double       │    double     │
├────────────┼───────────────┼──────────────┼───────────────────┼───────────────────┼───────────────┤
│ python     │      135000.0 │         1133 │             0.419 │               1.0 │         0.942 │
│ aws        │   137320.3125 │          783 │             0.742 │             0.935 │         0.916 │
│ sql        │      130000.0 │         1128 │             0.226 │             0.968 │         0.894 │
│ spark      │      140000.0 │          503 │             0.774 │             0.903 │          0.89 │
│ airflow    │      150000.0 │          386 │             0.935 │             0.806 │         0.819 │
│ snowflake  │      135500.0 │          438 │             0.613 │             0.839 │         0.816 │
│ azure      │      128000.0 │          475 │             0.194 │             0.871 │         0.803 │
│ kafka      │      145000.0 │          292 │             0.903 │             0.742 │         0.758 │
│ java       │      135000.0 │          303 │             0.419 │             0.774 │         0.739 │
│ redshift   │      130000.0 │          274 │             0.226 │              0.71 │         0.662 │
│ scala      │ 137290.484375 │          247 │              0.71 │             0.645 │         0.652 │
│ databricks │      132750.0 │          266 │             0.323 │             0.677 │         0.642 │
│ git        │      140000.0 │          208 │             0.774 │             0.613 │         0.629 │
│ hadoop     │      135000.0 │          198 │             0.419 │             0.581 │         0.565 │
│ gcp        │      136000.0 │          196 │             0.677 │             0.548 │         0.561 │
│ terraform  │      184000.0 │          193 │               1.0 │             0.484 │         0.536 │
│ nosql      │      134415.0 │          193 │             0.355 │             0.484 │         0.471 │
│ pyspark    │      140000.0 │          152 │             0.774 │             0.419 │         0.455 │
│ kubernetes │      150500.0 │          147 │             0.968 │             0.387 │         0.445 │
│ tableau    │      115000.0 │          164 │               0.0 │             0.452 │         0.407 │
│ docker     │      135000.0 │          144 │             0.419 │             0.355 │         0.361 │
│ mongodb    │      135750.0 │          136 │             0.645 │              0.29 │         0.326 │
│ sql server │      120000.0 │          139 │             0.032 │             0.323 │         0.294 │
│ r          │      134775.0 │          133 │             0.387 │             0.258 │         0.271 │
│ github     │      135000.0 │          127 │             0.419 │             0.161 │         0.187 │
└────────────┴───────────────┴──────────────┴───────────────────┴───────────────────┴───────────────┘
  25 rows                                                                                 6 columns
 
 Key takeways:
 1. Python and SQL anchor the top of the list, both driven almost entirely by demand percentile 
 (1.0 and 0.968), confirming these as the two skills with the widest job market reach for 
 someone starting out.
 2. AWS holds a strong third position by combining high demand (0.935) with a real salary edge 
 (0.742), making it a rare case that performs well even under a demand-heavy weighting.
 3. Terraform and Kubernetes fall to the bottom half (ranks 16 and 19) despite being the two 
 highest-salary skills in the dataset, confirming they're poor entry-level bets, narrow demand 
 pools mean fewer opportunities to break in regardless of eventual pay.
 4. Tableau appears here but not in the balanced or salary-weighted lists, entering only because
 its demand (0.452 percentile) outweighs its below-market salary (0 percentile, the lowest of 
 any skill in the set), worth treating as a demand-only signal rather than a strong overall 
 pick.
 5. Airflow, Spark, and Snowflake cluster together in the middle (ranks 5-6), each balancing 
 solid demand with above-average salary, a reasonable second wave to learn after the foundational
  languages and one core cloud platform are in place.

Experienced-level ranking (60% salary / 40% demand)
This ranking weights salary heavily, reflecting the priority of someone already established in 
the field: maximizing compensation among roles they're already qualified for matters more than 
casting the widest possible net. Airflow leads, and the list overall shifts sharply away from 
the high-volume foundational languages toward specialized infrastructure and pipeline tools.
┌────────────┬───────────────┬──────────────┬───────────────────┬───────────────────┬───────────────┐
│   skills   │ median_salary │ demand_count │ salary_percentile │ demand_percentile │ optimal_score │
│  varchar   │    double     │    int64     │      double       │      double       │    double     │
├────────────┼───────────────┼──────────────┼───────────────────┼───────────────────┼───────────────┤
│ airflow    │      150000.0 │          386 │             0.935 │             0.806 │         0.883 │
│ kafka      │      145000.0 │          292 │             0.903 │             0.742 │         0.839 │
│ spark      │      140000.0 │          503 │             0.774 │             0.903 │         0.826 │
│ aws        │   137320.3125 │          783 │             0.742 │             0.935 │         0.819 │
│ terraform  │      184000.0 │          193 │               1.0 │             0.484 │         0.794 │
│ kubernetes │      150500.0 │          147 │             0.968 │             0.387 │         0.736 │
│ git        │      140000.0 │          208 │             0.774 │             0.613 │          0.71 │
│ snowflake  │      135500.0 │          438 │             0.613 │             0.839 │         0.703 │
│ scala      │ 137290.484375 │          247 │              0.71 │             0.645 │         0.684 │
│ python     │      135000.0 │         1133 │             0.419 │               1.0 │         0.651 │
│ pyspark    │      140000.0 │          152 │             0.774 │             0.419 │         0.632 │
│ gcp        │      136000.0 │          196 │             0.677 │             0.548 │         0.625 │
│ java       │      135000.0 │          303 │             0.419 │             0.774 │         0.561 │
│ sql        │      130000.0 │         1128 │             0.226 │             0.968 │         0.523 │
│ mongodb    │      135750.0 │          136 │             0.645 │              0.29 │         0.503 │
│ go         │      140000.0 │          113 │             0.774 │             0.097 │         0.503 │
│ hadoop     │      135000.0 │          198 │             0.419 │             0.581 │         0.484 │
│ azure      │      128000.0 │          475 │             0.194 │             0.871 │         0.465 │
│ databricks │      132750.0 │          266 │             0.323 │             0.677 │         0.465 │
│ redshift   │      130000.0 │          274 │             0.226 │              0.71 │          0.42 │
│ nosql      │      134415.0 │          193 │             0.355 │             0.484 │         0.407 │
│ docker     │      135000.0 │          144 │             0.419 │             0.355 │         0.393 │
│ r          │      134775.0 │          133 │             0.387 │             0.258 │         0.335 │
│ github     │      135000.0 │          127 │             0.419 │             0.161 │         0.316 │
│ bigquery   │      135000.0 │          123 │             0.419 │             0.129 │         0.303 │
└────────────┴───────────────┴──────────────┴───────────────────┴───────────────────┴───────────────┘
  25 rows                                                                                 6 columns

Key takeways:
1. Airflow, Kafka, and Terraform now dominate the top four, each carrying a high salary percentile 
(0.90+) even where demand is comparatively modest, confirming these as the strongest pure pay 
differentiators in the dataset.
2. Python drops from first to tenth, and SQL falls further still to fourteenth, both undercut by weak 
salary percentiles (0.419 and 0.226) once salary carries the majority of the weight, reinforcing that 
these are baseline, near-universal skills rather than premium ones.
3. Kubernetes climbs sharply into the top six, moving up from a demand-weighted rank of 19th, its high 
salary percentile (0.968) finally gets proper credit once demand is no longer the dominant factor.
4. Go appears in this list but not the entry-level one, entering purely on the strength of its salary 
percentile (0.774) despite very low demand (0.097, second-lowest in the set), a clear example of a 
specialist skill only worth prioritizing once a track record already exists to make up for its narrow 
market.
5. Azure and Databricks fall out of the top half (ranks 18-19) despite strong demand percentiles 
(0.871 and 0.677), showing that broad adoption alone doesn't guarantee a pay premium, useful context 
for someone weighing whether to deepen an existing cloud specialty versus branch into higher-paying 
infrastructure tools.


*/

