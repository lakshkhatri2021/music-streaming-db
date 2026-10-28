-- =====================================================================
-- Music Streaming Platform  |  04_queries.sql
-- 18 queries: joins, aggregation, grouping, HAVING, subqueries,
-- EXISTS / NOT EXISTS, CASE, analytic ranking and a function call.
-- =====================================================================
SET LINESIZE 200 PAGESIZE 100 FEEDBACK ON
ALTER SESSION SET NLS_DATE_FORMAT = 'DD-MON-YYYY';
COLUMN title     FORMAT A26
COLUMN artist    FORMAT A20
COLUMN name      FORMAT A20
COLUMN email     FORMAT A28
COLUMN genre     FORMAT A12
COLUMN plan_name FORMAT A8
COLUMN country   FORMAT A8
COLUMN playlist  FORMAT A20
COLUMN owner     FORMAT A20
COLUMN duration  FORMAT A8
COLUMN status    FORMAT A10
COLUMN month     FORMAT A9

PROMPT
PROMPT ===== Q1. Top 10 most played songs (JOIN, ORDER BY, FETCH FIRST) =====
SELECT s.title, a.name AS artist, s.genre, s.play_count
FROM   Songs s
JOIN   Artists a ON a.artist_id = s.artist_id
ORDER  BY s.play_count DESC, s.title
FETCH  FIRST 10 ROWS ONLY;

PROMPT
PROMPT ===== Q2. Revenue per plan (GROUP BY, SUM, COUNT, AVG) =====
SELECT plan_name,
       COUNT(*)                 AS subscriptions,
       SUM(price_paid)          AS revenue_rs,
       ROUND(AVG(price_paid),2) AS avg_price_rs
FROM   Subscriptions
GROUP  BY plan_name
ORDER  BY revenue_rs DESC;

PROMPT
PROMPT ===== Q3. Users with an active subscription today and days left (JOIN, date arithmetic) =====
SELECT u.name, s.plan_name, s.price_paid, s.end_date,
       s.end_date - TRUNC(SYSDATE) AS days_left
FROM   Users u
JOIN   Subscriptions s ON s.user_id = u.user_id
WHERE  s.status = 'Active'
AND    TRUNC(SYSDATE) BETWEEN s.start_date AND s.end_date
ORDER  BY days_left;

PROMPT
PROMPT ===== Q4. Artists nobody streamed in October 2026 (NOT EXISTS subquery) =====
SELECT a.artist_id, a.name, a.country
FROM   Artists a
WHERE  NOT EXISTS (SELECT 1
                   FROM   Play_History p JOIN Songs s ON s.song_id = p.song_id
                   WHERE  s.artist_id = a.artist_id
                   AND    p.played_at >= DATE '2026-10-01'
                   AND    p.played_at <  DATE '2026-11-01');

PROMPT
PROMPT ===== Q5. Users who have never played a song (LEFT JOIN ... IS NULL) =====
SELECT u.user_id, u.name, u.join_date
FROM   Users u
LEFT   JOIN Play_History p ON p.user_id = u.user_id
WHERE  p.play_id IS NULL;

PROMPT
PROMPT ===== Q6. Listening per genre: plays, average seconds, share of song actually heard =====
SELECT s.genre,
       COUNT(*)                                             AS plays,
       ROUND(AVG(p.seconds_played))                         AS avg_seconds,
       ROUND(AVG(p.seconds_played * 100 / s.duration_sec),1) AS pct_heard
FROM   Play_History p
JOIN   Songs s ON s.song_id = p.song_id
GROUP  BY s.genre
ORDER  BY plays DESC;

PROMPT
PROMPT ===== Q7. Playlists with song count and total length (function get_playlist_duration) =====
SELECT x.playlist, x.owner, x.songs,
       FLOOR(x.secs / 60) || ':' || LPAD(MOD(x.secs, 60), 2, '0') AS duration
FROM  (SELECT p.name AS playlist, u.name AS owner,
              COUNT(ps.song_id) AS songs,
              get_playlist_duration(p.playlist_id) AS secs
       FROM   Playlists p
       JOIN   Users u ON u.user_id = p.user_id
       LEFT   JOIN Playlist_Songs ps ON ps.playlist_id = p.playlist_id
       GROUP  BY p.playlist_id, p.name, u.name) x
ORDER  BY x.songs DESC;

PROMPT
PROMPT ===== Q8. Total royalties paid to each artist (JOIN, SUM) =====
SELECT a.name AS artist,
       SUM(r.total_streams) AS streams_paid,
       SUM(r.amount)        AS total_paid_rs
FROM   Royalty_Payments r
JOIN   Artists a ON a.artist_id = r.artist_id
GROUP  BY a.name
ORDER  BY total_paid_rs DESC;

PROMPT
PROMPT ===== Q9. Streams per artist per month (conditional aggregation with CASE) =====
SELECT a.name AS artist,
       SUM(CASE WHEN TRUNC(p.played_at, 'MM') = DATE '2026-08-01' THEN 1 ELSE 0 END) AS aug,
       SUM(CASE WHEN TRUNC(p.played_at, 'MM') = DATE '2026-09-01' THEN 1 ELSE 0 END) AS sep,
       SUM(CASE WHEN TRUNC(p.played_at, 'MM') = DATE '2026-10-01' THEN 1 ELSE 0 END) AS oct,
       COUNT(*) AS total
FROM   Play_History p
JOIN   Songs s   ON s.song_id   = p.song_id
JOIN   Artists a ON a.artist_id = s.artist_id
GROUP  BY a.name
ORDER  BY total DESC;

PROMPT
PROMPT ===== Q10. Songs played more often than the average played song (subquery with AVG) =====
SELECT s.title, a.name AS artist, s.play_count
FROM   Songs s
JOIN   Artists a ON a.artist_id = s.artist_id
WHERE  s.play_count > (SELECT AVG(play_count) FROM Songs WHERE play_count > 0)
ORDER  BY s.play_count DESC, s.title;

PROMPT
PROMPT ===== Q11. Users who listen to more than one genre (COUNT DISTINCT, HAVING) =====
SELECT u.name, COUNT(DISTINCT s.genre) AS genres, COUNT(*) AS plays
FROM   Users u
JOIN   Play_History p ON p.user_id = u.user_id
JOIN   Songs s        ON s.song_id = p.song_id
GROUP  BY u.name
HAVING COUNT(DISTINCT s.genre) > 1
ORDER  BY genres DESC, plays DESC;

PROMPT
PROMPT ===== Q12. Most played genre in each country (analytic RANK over a grouped result) =====
SELECT country, genre, plays
FROM  (SELECT u.country, s.genre, COUNT(*) AS plays,
              RANK() OVER (PARTITION BY u.country ORDER BY COUNT(*) DESC) AS rnk
       FROM   Play_History p
       JOIN   Users u ON u.user_id = p.user_id
       JOIN   Songs s ON s.song_id = p.song_id
       GROUP  BY u.country, s.genre)
WHERE  rnk = 1
ORDER  BY plays DESC, country;

PROMPT
PROMPT ===== Q13. Songs that appear in more than 2 playlists (GROUP BY, HAVING) =====
SELECT s.title, a.name AS artist, COUNT(*) AS in_playlists
FROM   Playlist_Songs ps
JOIN   Songs s   ON s.song_id   = ps.song_id
JOIN   Artists a ON a.artist_id = s.artist_id
GROUP  BY s.title, a.name
HAVING COUNT(*) > 2
ORDER  BY in_playlists DESC, s.title;

PROMPT
PROMPT ===== Q14. Full subscription history of Arthur Morgan (CASE, date arithmetic) =====
SELECT s.sub_id, s.plan_name, s.price_paid, s.start_date, s.end_date,
       s.end_date - s.start_date + 1 AS days,
       CASE WHEN s.status = 'Active' AND TRUNC(SYSDATE) BETWEEN s.start_date AND s.end_date
            THEN 'Current' ELSE s.status END AS status
FROM   Subscriptions s
WHERE  s.user_id = (SELECT user_id FROM Users WHERE email = 'arthur.morgan@gmail.com')
ORDER  BY s.start_date;

PROMPT
PROMPT ===== Q15. Artists paid more than the average artist (subquery on aggregated totals) =====
SELECT a.name AS artist, SUM(r.amount) AS total_paid_rs
FROM   Royalty_Payments r
JOIN   Artists a ON a.artist_id = r.artist_id
GROUP  BY a.name
HAVING SUM(r.amount) > (SELECT AVG(artist_total)
                        FROM  (SELECT SUM(amount) AS artist_total
                               FROM   Royalty_Payments
                               GROUP  BY artist_id))
ORDER  BY total_paid_rs DESC;

PROMPT
PROMPT ===== Q16. Subscriptions ending in the next 7 days (renewal reminders) =====
SELECT u.name, u.email, s.plan_name, s.end_date
FROM   Subscriptions s
JOIN   Users u ON u.user_id = s.user_id
WHERE  s.status = 'Active'
AND    s.end_date BETWEEN TRUNC(SYSDATE) AND TRUNC(SYSDATE) + 7
ORDER  BY s.end_date;

PROMPT
PROMPT ===== Q17. Users without an active subscription who still own playlists (EXISTS + function) =====
SELECT u.name,
       (SELECT COUNT(*) FROM Playlists p WHERE p.user_id = u.user_id) AS playlists
FROM   Users u
WHERE  is_subscription_active(u.user_id) = 0
AND    EXISTS (SELECT 1 FROM Playlists p WHERE p.user_id = u.user_id);

PROMPT
PROMPT ===== Q18. Subscription revenue by month started (TO_CHAR, GROUP BY) =====
SELECT TO_CHAR(TRUNC(start_date, 'MM'), 'Mon YYYY') AS month,
       COUNT(*)        AS new_subscriptions,
       SUM(price_paid) AS revenue_rs
FROM   Subscriptions
GROUP  BY TRUNC(start_date, 'MM')
ORDER  BY TRUNC(start_date, 'MM');
