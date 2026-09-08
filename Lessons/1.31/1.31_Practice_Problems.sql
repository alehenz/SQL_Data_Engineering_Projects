/*1. Write a query that builds an array of the numbers 10, 20, 30, 40, labeled number_array*/
SELECT [10, 20, 30, 40] AS number_array;

/*2: Using a CTE with UNION ALL, build a small table of three programming languages of your choosing, 
then aggregate them into an array using ARRAY_AGG() with an explicit ORDER BY to guarantee consistent 
ordering.*/

WITH skills AS (
    SELECT 'python' AS skill
    UNION ALL
    SELECT 'java'
    UNION ALL
    SELECT 'javascript'
)

SELECT ARRAY_AGG(skill ORDER BY skill) AS skills_array
FROM skills;

/*3: using the array from problem 8, write a query that extracts just the 2nd element.*/

WITH skills AS (
    SELECT 'python' AS skill
    UNION ALL
    SELECT 'java'
    UNION ALL
    SELECT 'javascript'
), skills_array AS (
    SELECT ARRAY_AGG(skill ORDER BY skill) AS languages
    FROM skills
)

SELECT
    languages[2] AS second_language
FROM skills_array;

/*4: Write a query that creates a single struct literal representing a job posting with two fields: 
title (a string of your choosing) and remote (a boolean). Use the { field: value } literal syntax, 
not STRUCT_PACK.*/

SELECT {title: 'Data Engineer', remote: TRUE} AS job_listing;

/*5: Rewrite problem 4 using STRUCT_PACK instead of the literal syntax.*/

SELECT
    STRUCT_PACK(
        title := 'Data Engineer',
        remote := TRUE
    ) AS job_listing;

/*6: using a CTE, wrap your struct from problem 5 and write a SELECT that pulls out just the title field using dot notation.*/
WITH job_listing AS (
    SELECT
    STRUCT_PACK(
        title := 'Data Engineer',
        remote:= TRUE
    ) AS jl
)

SELECT
    jl.title
FROM job_listing;

/*7: build a small table with skill and category columns (3 rows), then aggregate into an array of structs using ARRAY_AGG(STRUCT_PACK(...))*/

WITH skills_categories AS (
    SELECT 'java' AS skills, 'programming' AS  categories
    UNION ALL
    SELECT 'javascript', 'programming'
    UNION ALL
    SELECT 'illustrator', 'design'
) 

SELECT
    ARRAY_AGG(
        STRUCT_PACK(
            skill := skills,
            category := categories
        ) ORDER BY skills
    )
FROM skills_categories;

/*8: using the array of structs from problem 7, write a query that accesses the skill field of just the first element.*/

WITH skills_categories AS (
    SELECT 'java' AS skills, 'programming' AS  categories
    UNION ALL
    SELECT 'javascript', 'programming'
    UNION ALL
    SELECT 'illustrator', 'design'
), skill_cat_array AS (
    SELECT
        ARRAY_AGG(
            STRUCT_PACK(
                skill := skills,
                category := categories
            ) ORDER BY skills
        ) AS skill_table
    FROM skills_categories
)

SELECT
    skill_table[1].skill
FROM skill_cat_array;

/*9: using job_postings_fact, skills_job_dim, and skills_dim, build a TEMP TABLE called practice_skills_array that has one 
row per job posting, with job_id, job_title_short, salary_hour_avg, and an array-of-structs column combining skill_id and 
skills (the skill name) for each posting's associated skills.*/

CREATE OR REPLACE TEMP TABLE practice_skills_array AS (
    SELECT
        jpf.job_id,
        jpf.job_title_short,
        jpf.salary_hour_avg,
        ARRAY_AGG(
            STRUCT_PACK(
                skill_id := sjd.skill_id,
                skills := sd.skills
            )
        ) AS skills
    FROM job_postings_fact AS jpf
    LEFT JOIN skills_job_dim AS sjd
        ON jpf.job_id = sjd.job_id
    LEFT JOIN skills_dim AS sd
        ON sd.skill_id = sjd.skill_id
    GROUP BY ALL
);

/*check*/
SELECT
    *
FROM practice_skills_array;

/*10: using the practice_skills_array temp table, UNNEST the array of structs and calculate the average salary_hour_avg per individual 
skill, filtering out NULL salaries, ordered by average salary descending.*/

SELECT
    UNNEST(skills).skills AS skills,
    AVG(salary_hour_avg) AS average_hourly_salary
FROM practice_skills_array
WHERE salary_hour_avg IS NOT NULL
GROUP BY skills
ORDER BY average_hourly_salary DESC;

/*11: write a query that creates a Map literal with three key-value pairs of your choosing (e.g., three skill-to-category mappings). Label 
it skill_map.*/
SELECT MAP {'skill_1' : 'python', 'skill_2': 'java', 'skill_3' : 'javascript'} AS skill_map;

/*12: using a CTE, wrap your map from problem 11 and write a SELECT that accesses one specific value by its key, using bracket notation.*/
WITH skill_map AS (
    SELECT MAP{
        'skill_1' : 'python', 'skill_2': 'java', 'skill_3' : 'javascript'    
    } AS skill
)
SELECT
    skill['skill_2']
FROM skill_map;

/*13: write a query that casts the JSON text '{"language":"Python","level":"Advanced"}' into the JSON type, labeled skill_json.*/
SELECT
    '{"language":"Python","level":"Advanced"}'::JSON AS skill_json;

/*14: using a CTE, wrap your JSON from problem 20 and extract just the "language" value using json_extract_string.*/
WITH skill_json AS (
    SELECT
        '{"language":"Python","level":"Advanced"}'::JSON AS skills_level
)

SELECT 
    json_extract_string(skills_level, '$.language') 
FROM 
    skill_json;

/*15: write a query that takes the JSON array text '[{"language":"Python","level":"Advanced"},{"language":"SQL","level":"Intermediate"}]', 
and converts it into an array of structs using json_each and ARRAY_AGG with STRUCT_PACK, matching the lesson's "JSON to Array of Structs" 
pattern.*/

WITH raw_json AS (
    SELECT 
        '[
            {"language":"Python","level":"Advanced"},
            {"language":"SQL","level":"Intermediate"}
        ]'::JSON AS lang_level
)
SELECT
    ARRAY_AGG(
        STRUCT_PACK(
            language := json_extract_string(e.value, '$.language'),
            level := json_extract_string(e.value, '$.level')
        )
        ORDER BY json_extract_string(e.value, '$.language')
    ) AS languages
FROM raw_json, json_each(lang_level) AS e;


/*Scenario: your data engineering team wants a denormalized table that co-workers on other teams (recruiters, career-search analysts) can query 
without needing to know how to join job_postings_fact, skills_job_dim, and skills_dim together. The requirement: one row per job posting, with 
all of that posting's skills bundled into a single column, each skill carrying its name and its skill type together. Then, separately, your own 
team still needs to run skill-level analysis, so you'll need to unpack it back out.

Part 1, build the table: create a TEMP TABLE called job_skill_profiles with one row per posting, containing job_id, job_title_short, job_country, 
salary_year_avg, and a single array-of-structs column named skill_profile, where each struct in the array has two fields: skill_name (from 
skills_dim.skills) and skill_type (from skills_dim.type). Every posting should appear exactly once, even if it has zero associated skills, or 
a NULL salary, this table is meant to represent all postings, not a filtered subset.*/

CREATE OR REPLACE TEMP TABLE job_skill_profiles AS(
    SELECT
        jpf.job_id,
        jpf.job_title_short,
        jpf.job_country,
        jpf.salary_year_avg,
        ARRAY_AGG(
            STRUCT_PACK(
                skill_name := sd.skills,
                skill_type := sd.type
            )
        ) AS skills_array
    FROM job_postings_fact AS jpf
    LEFT JOIN skills_job_dim AS sjd
        ON jpf.job_id = sjd.job_id
    LEFT JOIN skills_dim AS sd
        ON sd.skill_id = sjd.skill_id
    GROUP BY ALL
    ORDER BY job_id ASC
);

/*Part 2, verify the shape: before doing any analysis, write a query that confirms your table is correct: total row count should match 
job_postings_fact's row count exactly. Then write a second query that picks any single job_id you know has multiple skills, and manually inspects 
its skill_profile array using index access (skill_profile[1].skill_name, etc.) to visually confirm the structure looks right before trusting it 
for analysis.*/

SELECT COUNT(*) FROM job_skill_profiles;
SELECT COUNT(*) FROM job_postings_fact;

SELECT
    jpf.job_id,
    jpf.job_title_short,
    jpf.job_country,
    jpf.salary_year_avg,
    sd.skill_id,
    sd.skills,
    sd.type
FROM job_postings_fact AS jpf
LEFT JOIN skills_job_dim AS sjd
    ON jpf.job_id = sjd.job_id
LEFT JOIN skills_dim AS sd
    ON sd.skill_id = sjd.skill_id 
WHERE jpf.job_id = 4593;

SELECT
    *
FROM job_skill_profiles
WHERE job_id = 4593;

/*Part 3, unpack and analyze: using job_skill_profiles, write a query that UNNESTs skill_profile and answers: for each skill_type (not skill name, 
the category), what's the median salary_year_avg across all postings requiring at least one skill of that type? Filter out NULL salaries. This 
mirrors the lesson's own final example, but built entirely on your own table from scratch.*/

WITH flat_table AS (
    SELECT
        job_id,
        job_title_short,
        job_country,
        salary_year_avg,
        UNNEST(skills_array) AS skill
    FROM job_skill_profiles
)
SELECT
    skill.skill_type,
    MEDIAN(salary_year_avg) AS median_salary
FROM flat_table
WHERE salary_year_avg IS NOT NULL
GROUP BY skill.skill_type;

/*Part 4, a harder unpacking question: still using job_skill_profiles, write a query that finds, for each job_title_short, the single most frequently 
required skill (by skill_name, not type). You'll need to UNNEST, GROUP BY title and skill name, count occurrences, then use a ranking window function 
(RANK() or ROW_NUMBER(), think back to which one guarantees exactly one row per group) to isolate just the top skill per title.*/
WITH skill_count_title AS(
    WITH flat_table AS (
        SELECT
            job_id,
            job_title_short,
            job_country,
            salary_year_avg,
            UNNEST(skills_array) AS skill
        FROM job_skill_profiles
    )
    SELECT
        job_title_short,
        skill.skill_name AS skill_name,
        COUNT(skill.skill_name) AS skill_count,
        ROW_NUMBER() OVER(
            PARTITION BY job_title_short
            ORDER BY COUNT(skill.skill_name) DESC
        ) AS count_rank
    FROM flat_table
    GROUP BY
        job_title_short,
        skill.skill_name
    ORDER BY job_title_short, COUNT(skill.skill_name) DESC
)

SELECT
    job_title_short,
    skill_name,
    skill_count
FROM skill_count_title
WHERE count_rank = 1;

--CTE within CTE was necessary in order to filter by a window function that uses an aggregate function


/*Part 5, tie it back to real decision-making: using your Part 4 result, write one sentence, no SQL, describing what a career-search analyst could 
actually do with this information, what real decision or recommendation would this table let them make that they couldn't easily make from the raw 
normalized tables alone?*/



