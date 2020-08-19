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