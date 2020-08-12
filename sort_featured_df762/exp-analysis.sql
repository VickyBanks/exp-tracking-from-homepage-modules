
------------------------------------------------------------ Step 8 - Look at results ------------------------------------------------------------
--- Take table name specific to the experiment and make general for the analysis
SELECT * FROM central_insights_sandbox.vb_exp_sort_featured_binge LIMIT 5;
SELECT * FROM central_insights_sandbox.vb_exp_sort_featured_binge_module_impressions LIMIT 5;

--- Make current exp table into generic name for ease
--- Starts/Watches and clicks
DROP TABLE IF EXISTS central_insights_sandbox.vb_rec_exp_final;
CREATE TABLE central_insights_sandbox.vb_rec_exp_final AS
SELECT * FROM central_insights_sandbox.vb_exp_sort_featured_binge ; -- this will need to be the name of the current experiment

-- Impressions
DROP TABLE IF EXISTS central_insights_sandbox.vb_rec_impr_final;
CREATE TABLE central_insights_sandbox.vb_rec_impr_final AS
SELECT * FROM central_insights_sandbox.vb_exp_sort_featured_binge_module_impressions ; -- this will need to be the name of the current experiment

-- All users -- this includes everyone who never viewed content
DROP TABLE IF EXISTS central_insights_sandbox.vb_rec_exp_ids_hid_final;
CREATE TABLE central_insights_sandbox.vb_rec_exp_ids_hid_final AS
SELECT * FROM central_insights_sandbox.vb_exp_sort_featured_binge_hids ; -- this will need to be the name of the current experiment

---- Make sure anyone can use these tables
GRANT SELECT ON central_insights_sandbox.vb_rec_exp_final  TO GROUP dataforce_analysts;
GRANT SELECT ON central_insights_sandbox.vb_rec_impr_final TO GROUP dataforce_analysts;
GRANT SELECT ON central_insights_sandbox.vb_rec_exp_ids_hid_final TO GROUP dataforce_analysts;

------------------ Initial Checking ------------------

SELECT DISTINCT dt FROM central_insights_sandbox.vb_rec_exp_ids_hid;
SELECT age_range, count(distinct bbc_hid3) FROM central_insights_sandbox.vb_rec_exp_ids_hid_final GROUP BY 1;

-- What is the split across different frequency bands -- a high number in the less frequent bands is bad for personalisation as we can't personalise them well
SELECT frequency_band, frequency_group_aggregated, count(DISTINCT dt||visit_id) as num_visits, count(distinct bbc_hid3) as num_signed_in_users
FROM central_insights_sandbox.vb_rec_exp_ids_hid_final
GROUP BY 1,2
ORDER BY 1,2;

-- How many users in each group/platform
SELECT platform, exp_group, count(distinct bbc_hid3) AS num_users, count(distinct visit_id) AS num_visits
FROM central_insights_sandbox.vb_rec_exp_ids_hid_final
GROUP BY 1,2;

SELECT DISTINCT click_container FROM central_insights_sandbox.vb_rec_exp_final;


------------------ Summary Numbers ------------------
---- hids, visits, starts, completes to the required module
with user_stats AS (
    -- get the number of users and visits for everyone in the experiment
    SELECT
        platform,
        exp_group,
        count(distinct bbc_hid3)                   as num_hids,
        count(distinct unique_visitor_cookie_id)   as num_uv,
        count(distinct dt || bbc_hid3 || visit_id) AS num_visits
    FROM central_insights_sandbox.vb_rec_exp_ids_hid_final
    GROUP BY 1,2
),
     module_stats AS (
         -- Get the number of clicks and starts/watched from each module on homepage
         SELECT
             platform,
             exp_group,
             sum(start_flag)   AS num_starts,
             sum(watched_flag) as num_watched,
             count(visit_id)   AS num_clicks_to_module
         FROM central_insights_sandbox.vb_rec_exp_final
         WHERE click_placement = 'iplayer.tv.page' --homepage
           --AND click_container = 'module-editorial-featured'
         --AND click_container ILIKE '%binge%'
         AND click_container = 'module-recommendations-recommended-for-you'
         --AND click_container = 'module-watching-continue-watching'
         GROUP BY 1,2
     )
SELECT
    a.platform,
    a.exp_group,
    num_hids AS num_signed_in_users,
    num_visits,
    num_starts,
    num_watched,
    num_clicks_to_module
FROM user_stats a
         JOIN module_stats b ON a.exp_group = b.exp_group AND
        a.platform = b.platform
ORDER BY a.platform,
         a.exp_group
;
-------- Impressions to the specific module ---------
SELECT a.platform, exp_group, count(DISTINCT a.dt||a.visit_id) AS num_visits_saw_module
FROM central_insights_sandbox.vb_rec_impr_final a
         JOIN central_insights_sandbox.vb_rec_exp_final b
              ON a.dt = b.dt AND a.visit_id = b.visit_id AND a.platform = b.platform and a.bbc_hid3 = b.bbc_hid3
WHERE container = 'module-editorial-featured'
GROUP BY 1, 2
ORDER BY 1,2
;

-------- Same as above summary but with age splits ---------
with user_stats AS (
    -- get the number of users and visits for everyone in the experiment
    SELECT platform,
           exp_group,
           age_range,
           count(distinct bbc_hid3)                   as num_hids,
           count(distinct unique_visitor_cookie_id)   as num_uv,
           count(distinct dt || bbc_hid3 || visit_id) AS num_visits
    FROM central_insights_sandbox.vb_rec_exp_ids_hid_final
    GROUP BY 1, 2, 3
),
     module_stats AS (
         -- Get the number of clicks and starts/watched from each module on homepage
         SELECT platform,
                exp_group,
                age_range,
                sum(start_flag)   AS num_starts,
                sum(watched_flag) as num_watched,
                count(visit_id)   AS num_clicks_to_module
         FROM central_insights_sandbox.vb_rec_exp_final
         WHERE click_placement = 'iplayer.tv.page' --homepage
           AND click_container = 'module-recommendations-recommended-for-you'
         GROUP BY 1, 2, 3
     )
SELECT a.platform,
       a.exp_group,
       a.age_range,
       num_hids AS num_signed_in_users,
       num_visits,
       num_starts,
       num_watched,
       num_clicks_to_module
FROM user_stats a
         JOIN module_stats b ON a.exp_group = b.exp_group
    AND a.platform = b.platform AND a.age_range = b.age_range
WHERE a.age_range != 'under 10'
ORDER BY a.platform,
         a.exp_group,
         a.age_range
;



---------- No platform split  --------------
SELECT exp_group,
       count(DISTINCT bbc_hid3) AS num_signed_in_users,
       count(DISTINCT dt||visit_id) AS num_visits
FROM central_insights_sandbox.vb_rec_exp_ids_hid
WHERE exp_group != 'unknown'
GROUP BY 1
ORDER BY 1;

SELECT exp_group,
       sum(start_flag)   as num_starts,
       sum(watched_flag) as num_watched,
       count(visit_id) AS num_clicks
FROM central_insights_sandbox.vb_rec_exp_final
WHERE click_container = 'module-recommendations-recommended-for-you'
AND click_placement = 'iplayer.tv.page' --homepage
GROUP BY 1
ORDER BY 1;


------------------------------ Step 9: Data for R Statistical Analysis --------------------------------------------
-- Get data in right structure of stats analysis
DROP TABLE IF EXISTS vb_rec_exp_results;
CREATE TEMP TABLE vb_rec_exp_results AS
with module_metrics AS (
    SELECT exp_group,
           age_range,
           bbc_hid3,
           sum(start_flag)   AS num_starts,
           sum(watched_flag) as num_watched
    FROM central_insights_sandbox.vb_rec_exp_final
    WHERE click_container = 'module-editorial-featured'-- module of interest
      AND click_placement = 'iplayer.tv.page'
    GROUP BY 1, 2,3
)
SELECT DISTINCT a.exp_group,
                a.age_range,
                a.bbc_hid3,
                a.frequency_band,
                a.frequency_group_aggregated,
                ISNULL(b.num_starts, 0)  as num_starts,
                ISNULL(b.num_watched, 0) AS num_watched
FROM central_insights_sandbox.vb_rec_exp_ids_hid a -- get all users, even those who didn't click
         LEFT JOIN module_metrics b --Gives each user and their total starts/watched from that module
                   on a.bbc_hid3 = b.bbc_hid3 AND a.exp_group = b.exp_group AND a.age_range  = b.age_range
;

SELECT * FROM vb_rec_exp_results LIMIT 10;
-- Tables for R
--control
SELECT bbc_hid3, num_starts, num_watched FROM vb_rec_exp_results
WHERE exp_group = 'control'
--AND age_range = '35+'
;
--variation_1
SELECT bbc_hid3, num_starts, num_watched FROM vb_rec_exp_results
WHERE exp_group = 'variation_1'
--AND age_range = '35+'
;

------------------ For Test Duration Numbers ------------------
-- Only control group
-- Only one week
DROP TABLE IF EXISTS vb_exp_temp;
CREATE TEMP TABLE vb_exp_temp AS
with module_metrics AS (
    SELECT DISTINCT bbc_hid3,
           click_container,
           click_placement,
           sum(start_flag)   AS num_starts,
           sum(watched_flag) as num_watched
    FROM central_insights_sandbox.vb_rec_exp_final
    WHERE exp_group = 'control'
      AND dt BETWEEN 20200727 AND 20200802
    GROUP BY 1, 2, 3
),
     dist_users AS (
         SELECT DISTINCT bbc_hid3
         FROM central_insights_sandbox.vb_rec_exp_ids_hid
         WHERE exp_group = 'control'
           AND dt BETWEEN 20200727 AND 20200802
     )
SELECT DISTINCT b.click_container,
                b.click_placement,
                a.bbc_hid3,
                ISNULL(b.num_starts, 0)  as num_starts,
                ISNULL(b.num_watched, 0) AS num_watched
FROM dist_users a -- get all users, even those who didn't click
         LEFT JOIN module_metrics b --Gives each user and their total starts/watched from that module
                   on a.bbc_hid3 = b.bbc_hid3
;
DROP TABLE vb_test;
CREATE TEMP TABLE vb_test AS
with
     -- compltes from featured rail
     featured AS
    (
    SELECT bbc_hid3, num_watched AS num_completes_featured
    FROM vb_exp_temp
    WHERE click_container = 'module-editorial-featured'
    AND click_placement = 'iplayer.tv.page'

),
     --completes from bingewothy rails
     binge AS (
    SELECT bbc_hid3, sum(num_watched) AS num_completes_binge
    FROM vb_exp_temp
    WHERE click_container ILIKE '%binge%'
         AND click_placement = 'iplayer.tv.page'
         GROUP BY 1

),
    homepage AS (
    SELECT DISTINCT bbc_hid3, sum(num_watched) AS num_completes_homepage
    FROM vb_exp_temp
        WHERE click_placement = 'iplayer.tv.page'
        GROUP BY 1
),
     dist_users AS (
         SELECT distinct bbc_hid3 FROM vb_exp_temp
     )
SELECT  a.bbc_hid3,
       ISNULL(num_completes_featured,0) AS num_completes_featured,
       ISNULL(num_completes_binge,0) AS num_completes_binge,
       ISNULL(num_completes_homepage,0) AS num_completes_homepage
FROM dist_users a
LEFT JOIN featured b ON a.bbc_hid3 = b.bbc_hid3
LEFT JOIN binge c ON a.bbc_hid3 = c.bbc_hid3
LEFT JOIN homepage d ON a.bbc_hid3 = d.bbc_hid3

;

SELECT * FROM vb_test;

--------- Think Analytics Groups -----------------------
with module_metrics AS (
    SELECT click_think_group,
           bbc_hid3,
           sum(start_flag)   AS num_starts,
           sum(watched_flag) as num_watched
    FROM central_insights_sandbox.vb_rec_exp_final
    WHERE click_container = 'module-recommendations-recommended-for-you'
      AND click_placement = 'iplayer.tv.page'
    GROUP BY 1, 2
),
     user_stats AS (
         SELECT DISTINCT a.bbc_hid3,
                         b.click_think_group,
                         ISNULL(b.num_starts, 0)  as num_starts,
                         ISNULL(b.num_watched, 0) AS num_watched
         FROM central_insights_sandbox.vb_rec_exp_ids_hid a
                  LEFT JOIN module_metrics b
                            on a.bbc_hid3 = b.bbc_hid3)
SELECT click_think_group, count(bbc_hid3) as num_clicks, sum(num_starts) as num_starts, sum(num_watched) as num_watched
FROM user_stats
GROUP BY 1;
;

--------- How did the exp affect the whole product? ---------
with user_stats AS (
    -- get the number of users and visits for everyone in the experiment
    SELECT
        platform,
        exp_group,
        count(distinct bbc_hid3)                   as num_hids,
        count(distinct unique_visitor_cookie_id)   as num_uv,
        count(distinct dt || bbc_hid3 || visit_id) AS num_visits
    FROM central_insights_sandbox.vb_rec_exp_ids_hid_final
    GROUP BY 1,2
),
     module_stats AS (
         -- Get the number of clicks and starts/watched from each module on homepage
         SELECT
             platform,
             exp_group,
             sum(start_flag)   AS num_starts,
             sum(watched_flag) as num_watched,
             count(visit_id)   AS num_clicks
         FROM central_insights_sandbox.vb_rec_exp_final
         GROUP BY 1,2
     )
SELECT
    a.platform,
   a.exp_group,
    num_hids AS num_signed_in_users,
    num_visits,
    num_starts,
    num_watched,
    num_clicks
FROM user_stats a
         JOIN module_stats b ON a.exp_group = b.exp_group AND
        a.platform = b.platform
ORDER BY a.platform,
         a.exp_group
