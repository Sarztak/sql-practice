-- You are analyzing user flagging performance on a video platform. For each user who has had at least one of their flags reviewed by YouTube, calculate their flagging performance metrics as described below.


-- Find each user's first name, last name, total number of distinct videos they flagged that had at least one reviewed flag, total number of distinct videos they flagged that were ultimately removed, and the latest date when any of their flags were reviewed.

with tb1 as (
select a.video_id, b.reviewed_date, b.reviewed_outcome from user_flags a
join flag_review b on a.flag_id = b.flag_id
where b.reviewed_by_yt = TRUE
),
tb2 as (
select video_id, max(reviewed_date) as latest_review_date, sum(case when reviewed_outcome = 'REMOVED' then 1 else 0 end) as reviewed_outcome from tb1
group by video_id
),
tb3 as (
select a.user_firstname, a.user_lastname, a.video_id, b.latest_review_date, b.reviewed_outcome from user_flags a
join tb2 b on a.video_id = b.video_id
)
select user_firstname, user_lastname,
count(distinct video_id) as total_flagged_videos,
count(distinct case when reviewed_outcome > 0 then video_id end) as total_removed_videos,
max(latest_review_date) as latest_review_date from tb3
group by user_firstname, user_lastname