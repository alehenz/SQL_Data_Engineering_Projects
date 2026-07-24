/*
Left join shows the content of the first column joined with the intersecting data from the right table
*/

SELECT
    jpf.*,
    cd.*
FROM
    job_postings_fact AS jpf
LEFT JOIN company_dim AS cd
    ON jpf.company_id = cd.company_id
LIMIT 10;

/*
It's good practice to specify which table each colum belongs to using dot notation (in this cases, aliases where used as well)
*/

SELECT
    jpf.job_id,
    jpf.job_title_short,
    cd.name AS company_name,
    jpf.job_location
FROM
    job_postings_fact AS jpf
LEFT JOIN company_dim AS cd
    ON jpf.company_id = cd.company_id
LIMIT 10;

/*
In this case we removed the liit to verify all data from table A was preserved
*/

SELECT
    jpf.job_id,
    jpf.job_title_short,
    cd.name AS company_name,
    jpf.job_location
FROM
    job_postings_fact AS jpf
LEFT JOIN company_dim AS cd
    ON jpf.company_id = cd.company_id;


/*
INNER JOIN returns the intersection of both tables. Note that INNER JOIN is the default so using only JOIN returns the same result
*/

SELECT
    jpf.job_id,
    jpf.job_title_short,
    cd.name AS company_name,
    jpf.job_location
FROM
    job_postings_fact AS jpf
INNER JOIN company_dim AS cd
    ON jpf.company_id = cd.company_id;

/*
FULL OUTER JOIN returns all rows from the two tables where there is a match
*/
SELECT
    jpf.job_id,
    jpf.job_title_short,
    cd.name AS company_name,
    jpf.job_location
FROM
    job_postings_fact AS jpf
FULL OUTER JOIN company_dim AS cd
    ON jpf.company_id = cd.company_id;

/* 
This example joins the job_postings_fact table with the skill_jobs_dim bridge table
*/
SELECT
    jpf.job_id,
    jpf.job_title_short,
    sjd.skill_id,
FROM job_postings_fact AS jpf
LEFT JOIN skills_job_dim AS sjd
    ON jpf.job_id = sjd.job_id
LIMIT 50;

/* 
This exmaple joins the job_postings_fact table with the skill_jobs_dim bridge table
and the bridge table with the skills table (two joins in one query)
*/
SELECT
    jpf.job_id,
    jpf.job_title_short,
    sjd.skill_id,
    sd.skills
FROM job_postings_fact AS jpf
LEFT JOIN skills_job_dim AS sjd
    ON jpf.job_id = sjd.job_id
LEFT JOIN skills_dim AS sd
    ON sjd.skill_id = sd.skill_id
LIMIT 50;

/*
When removing the limit, we can see the left join keeps all data from 
the first column regardless of it having data associated in the 
additional columns. Essentially, job postings will be listed even if they
dont have an associated skill.
*/
SELECT
    jpf.job_id,
    jpf.job_title_short,
    sjd.skill_id,
    sd.skills
FROM job_postings_fact AS jpf
LEFT JOIN skills_job_dim AS sjd
    ON jpf.job_id = sjd.job_id
LEFT JOIN skills_dim AS sd
    ON sjd.skill_id = sd.skill_id;

/*
This following query uses an inner join, so it removes job postings 
that don't have an associated skill
*/
SELECT
    jpf.job_id,
    jpf.job_title_short,
    sjd.skill_id,
    sd.skills
FROM job_postings_fact AS jpf
INNER JOIN skills_job_dim AS sjd
    ON jpf.job_id = sjd.job_id
INNER JOIN skills_dim AS sd
    ON sjd.skill_id = sd.skill_id;


SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE table_catalog = 'data_jobs'
ORDER BY table_name, ordinal_position;

/*
1. Get a list of job postings with their company name, only including 
postings where the company is actually known (i.e., skip anything 
with a missing company match).
*/
SELECT
    jpf.job_title_short,
    jpf.job_title,
    cd.name
FROM 
    job_postings_fact AS jpf
INNER JOIN --use inner join to eliminate all postings where company name has a missing match
    company_dim AS cd
ON
    jpf.company_id = cd.company_id;

/*
2. List every company in company_dim, along with a count of how many job 
postings reference them, including companies that have zero postings. 
Which join type keeps companies with no matches?
*/
SELECT
    cd.name,
    COUNT(jpf.job_id) AS posting_count
FROM 
    company_dim AS cd -- company_dim is the left table in order to keep potential 0 posting companies
LEFT JOIN
    job_postings_fact AS jpf
ON
    cd.company_id = jpf.company_id
GROUP BY
    cd.company_id, cd.name -- best to group by id instead of only name in case two company's have the same name (generics)
ORDER BY posting_count ASC;

/*
3. Run the LEFT JOIN from problem 2, but filter to only show companies 
where the posting count is 0 (hint: you'll need IS NULL on the joined 
side before aggregating, or HAVING COUNT(...) = 0 after).
*/
SELECT
    cd.name,
    COUNT(jpf.job_id) AS posting_count
FROM 
    company_dim AS cd -- company_dim is the left table in order to keep potential 0 posting companies
LEFT JOIN
    job_postings_fact AS jpf
ON
    cd.company_id = jpf.company_id
GROUP BY
    cd.company_id, cd.name -- best to group by id instead of only name in case two company's have the same name (generics)
HAVING COUNT(jpf.job_id) = 0
ORDER BY posting_count ASC;

/*
4. Rewrite problem 1 (the INNER JOIN) as a RIGHT JOIN instead. Which 
table needs to go first for the result to stay logically identical? 
Confirm both queries actually differ or match by checking row counts.
*/
SELECT
    jpf.job_title_short,
    jpf.job_title,
    cd.name
FROM
    job_postings_fact AS jpf
RIGHT JOIN
    company_dim AS cd
ON
    cd.company_id = jpf.company_id
WHERE
    jpf.company_id IS NOT NULL;

/*
5. List all job postings with their company name AND every skill 
required, using job_postings_fact, company_dim, and the skills bridge 
tables. Should any of these joins be LEFT instead of INNER, in case a 
job posting has no listed skills or no matched company?
*/

SELECT
    jpf.job_id,
    jpf.job_title,
    cd.name,
    sd.skills
FROM
    job_postings_fact AS jpf
INNER JOIN
    company_dim AS cd
ON
    jpf.company_id = cd.company_id
LEFT JOIN
    skills_job_dim AS sjd
ON
    jpf.job_id = sjd.job_id
LEFT JOIN
    skills_dim AS sd
ON
    sjd.skill_id = sd.skill_id;
    

/*
6. Using company_dim and job_postings_fact, write a FULL OUTER JOIN 
that would surface both companies with no postings AND postings with 
no valid company match, all in a single result set. Then explain in 
your own words why this differs from doing a LEFT JOIN and a RIGHT 
JOIN separately.
*/

SELECT
    cd.company_id,
    cd.name,
    jpf.job_id,
    jpf.job_title
FROM
    company_dim AS cd
FULL OUTER JOIN
    job_postings_fact AS jpf
ON
    cd.company_id = jpf.company_id;

/*
7. Find pairs of job postings that were posted by the same company on the 
exact same day (hint: join job_postings_fact to itself on company_id 
and job_posted_date, being careful to avoid matching a row to itself 
or double-counting reversed pairs).
*/

SELECT
    jpf1.job_id,
    jpf1.company_id,
    jpf1.job_posted_date,
    jpf2.job_id,
    jpf2.company_id,
    jpf2.job_posted_date
FROM 
    job_postings_fact AS jpf1
INNER JOIN
    job_postings_fact AS jpf2
ON  
    jpf1.company_id = jpf2.company_id AND jpf1.job_posted_date = jpf2.job_posted_date
WHERE
    jpf1.job_id < jpf2.job_id; -- "<" instead of "!=" keeps the same pairs from appearing twice


/*
8. Write a CROSS JOIN between skills_dim and a small subset of 
job_title_short values (like just 'Data Analyst' and 'Data Engineer'), 
producing every possible combination. Then explain why this isn't 
useful for real analysis here, versus when a CROSS JOIN would 
actually make sense.
*/

SELECT
    sd.skills,
    jpf.job_title_short
FROM
    skills_dim AS sd
CROSS JOIN
    (SELECT DISTINCT -- Distinct keeps cross join from combining with repeated short job names
        job_title_short 
    FROM 
        job_postings_fact 
    WHERE 
        job_title_short IN ('Data Analyst', 'Data Engineer')) AS jpf;

/*
9. You want a report showing every skill in skills_dim, and how many job 
postings require it, including skills that have never been requested 
by any posting. Don't look ahead, decide which join type this needs 
and justify your choice before writing the query.
*/

SELECT
    sd.skills,
    COUNT(jpf.job_id) AS posting_count
FROM
    skills_dim AS sd
LEFT JOIN -- Left Join allows skills that are not in any job postings to be listed
    skills_job_dim AS sjd
ON 
    sd.skill_id = sjd.skill_id
INNER JOIN
    job_postings_fact AS jpf
ON
    sjd.job_id = jpf.job_id
GROUP BY
    sd.skills
ORDER BY
    posting_count DESC;