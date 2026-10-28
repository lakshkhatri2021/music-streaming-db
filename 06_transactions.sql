-- =====================================================================
-- Music Streaming Platform  |  06_transactions.sql
-- The real-world transactions, each showing the database before and
-- after.  These are the same operations the Python app runs.
-- Written so they work on any date: every demo user is subscribed
-- inside the script where needed.
-- =====================================================================
SET SERVEROUTPUT ON
SET LINESIZE 200 PAGESIZE 100 FEEDBACK ON
ALTER SESSION SET NLS_DATE_FORMAT = 'DD-MON-YYYY';
COLUMN name      FORMAT A20
COLUMN title     FORMAT A22
COLUMN plan_name FORMAT A8
COLUMN status    FORMAT A10
COLUMN playlist  FORMAT A18
COLUMN artist    FORMAT A20
COLUMN month     FORMAT A9

PROMPT
PROMPT ##### T1. John Marston (user 5, subscription expired) subscribes to Premium #####
PROMPT Uses: PROCEDURE subscribe_user | Tables: Users, Subscriptions
SELECT sub_id, plan_name, price_paid, start_date, end_date, status
FROM   Subscriptions WHERE user_id = 5 ORDER BY sub_id;
EXEC subscribe_user(5, 'Premium')
SELECT sub_id, plan_name, price_paid, start_date, end_date, status
FROM   Subscriptions WHERE user_id = 5 ORDER BY sub_id;

PROMPT
PROMPT ##### T2. John plays 'As It Was' #####
PROMPT Uses: TRIGGER trg_check_play (allows it) + TRIGGER trg_update_play_count | Tables: Play_History, Songs
SELECT title, play_count FROM Songs WHERE title = 'As It Was';
INSERT INTO Play_History (user_id, song_id, seconds_played)
VALUES (5, (SELECT song_id FROM Songs WHERE title = 'As It Was'), 167);
COMMIT;
SELECT title, play_count FROM Songs WHERE title = 'As It Was';

PROMPT
PROMPT ##### T3. Micah Bell (user 3, subscription expired) tries to play a song #####
PROMPT Uses: FUNCTION is_subscription_active inside TRIGGER trg_check_play | Table: Play_History
SELECT is_subscription_active(3) AS micah_active FROM dual;
BEGIN
  INSERT INTO Play_History (user_id, song_id, seconds_played) VALUES (3, 56, 182);
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Play recorded');
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('BLOCKED -> ' || SQLERRM);
END;
/
SELECT COUNT(*) AS micah_plays_today FROM Play_History WHERE user_id = 3 AND TRUNC(played_at) = TRUNC(SYSDATE);

PROMPT
PROMPT ##### T4. John creates the playlist 'Weekend Vibes' and adds two songs #####
PROMPT Uses: INSERT + TRIGGER trg_playlist_limit (allows it) + FUNCTION get_playlist_duration | Tables: Playlists, Playlist_Songs
DECLARE
  v_id Playlists.playlist_id%TYPE;
BEGIN
  INSERT INTO Playlists (user_id, name) VALUES (5, 'Weekend Vibes')
  RETURNING playlist_id INTO v_id;
  INSERT INTO Playlist_Songs (playlist_id, song_id) VALUES (v_id, 51);   -- Here Comes the Sun
  INSERT INTO Playlist_Songs (playlist_id, song_id) VALUES (v_id, 36);   -- Creep
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Playlist ' || v_id || ' created, total length '
                       || get_playlist_duration(v_id) || ' seconds');
END;
/

PROMPT
PROMPT ##### T5. Mary-Beth Gaskill (Basic plan) tries to add a 51st song to 'Basic Favourites' #####
PROMPT Uses: TRIGGER trg_playlist_limit (blocks it) | Tables: Playlists, Subscriptions, Playlist_Songs
BEGIN
  IF is_subscription_active(2) = 0 THEN     -- keeps the demo working after her plan's end date
    subscribe_user(2, 'Basic');
  END IF;
END;
/
SELECT p.name AS playlist, COUNT(*) AS songs
FROM   Playlists p JOIN Playlist_Songs ps ON ps.playlist_id = p.playlist_id
WHERE  p.playlist_id = 3 GROUP BY p.name;
BEGIN
  INSERT INTO Playlist_Songs (playlist_id, song_id) VALUES (3, 51);
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Song added');
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('BLOCKED -> ' || SQLERRM);
END;
/

PROMPT
PROMPT ##### T6. Month-end royalty run for the current month, then run again #####
PROMPT Uses: PROCEDURE run_monthly_royalties (CURSOR) calling PROCEDURE calc_artist_royalty | Tables: Artists, Songs, Play_History, Royalty_Payments
EXEC run_monthly_royalties(SYSDATE)
PROMPT
PROMPT Running it a second time: nobody is paid twice
EXEC run_monthly_royalties(SYSDATE)
SELECT a.name AS artist, r.total_streams, r.amount
FROM   Royalty_Payments r JOIN Artists a ON a.artist_id = r.artist_id
WHERE  r.period_month = TRUNC(SYSDATE, 'MM')
ORDER  BY r.amount DESC;

PROMPT
PROMPT ##### T7. Dutch van der Linde (user 9) deletes his account #####
PROMPT Uses: DELETE with ON DELETE CASCADE | Tables: Users, Subscriptions, Play_History, Playlists
SELECT (SELECT COUNT(*) FROM Subscriptions WHERE user_id = 9) AS subscriptions,
       (SELECT COUNT(*) FROM Play_History  WHERE user_id = 9) AS plays,
       (SELECT COUNT(*) FROM Playlists     WHERE user_id = 9) AS playlists
FROM dual;
DELETE FROM Users WHERE user_id = 9;
COMMIT;
SELECT (SELECT COUNT(*) FROM Users         WHERE user_id = 9) AS user_row,
       (SELECT COUNT(*) FROM Subscriptions WHERE user_id = 9) AS subscriptions,
       (SELECT COUNT(*) FROM Play_History  WHERE user_id = 9) AS plays
FROM dual;
