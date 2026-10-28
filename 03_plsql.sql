-- =====================================================================
-- Music Streaming Platform  |  03_plsql.sql
-- 2 functions, 3 procedures (one of them uses an explicit cursor),
-- 3 triggers.  Each block ends with "/" and SHOW ERRORS so any
-- compile problem is printed straight away.
-- =====================================================================
SET SERVEROUTPUT ON

-- ---------------------------------------------------------------------
-- FUNCTION 1: is_subscription_active
-- Returns 1 if the user has an Active subscription covering the given
-- date (today by default), otherwise 0.
-- Used by: trg_check_play, trg_playlist_limit, the Python app.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION is_subscription_active (
  p_user_id  IN NUMBER,
  p_on_date  IN DATE DEFAULT SYSDATE
) RETURN NUMBER
IS
  v_count NUMBER;
BEGIN
  SELECT COUNT(*)
  INTO   v_count
  FROM   Subscriptions
  WHERE  user_id = p_user_id
  AND    status  = 'Active'
  AND    TRUNC(p_on_date) BETWEEN start_date AND end_date;

  IF v_count > 0 THEN
    RETURN 1;
  ELSE
    RETURN 0;
  END IF;
END is_subscription_active;
/
SHOW ERRORS

-- ---------------------------------------------------------------------
-- FUNCTION 2: get_playlist_duration
-- Returns the total length in seconds of all songs in a playlist.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_playlist_duration (
  p_playlist_id IN NUMBER
) RETURN NUMBER
IS
  v_total NUMBER;
BEGIN
  SELECT NVL(SUM(s.duration_sec), 0)
  INTO   v_total
  FROM   Playlist_Songs ps
  JOIN   Songs s ON s.song_id = ps.song_id
  WHERE  ps.playlist_id = p_playlist_id;

  RETURN v_total;
END get_playlist_duration;
/
SHOW ERRORS

-- ---------------------------------------------------------------------
-- PROCEDURE 1: subscribe_user
-- Ends the user's current subscription (Expired if its end date has
-- passed, otherwise Cancelled) and starts a new one-month subscription
-- on the chosen plan at the current list price.
-- ---------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE subscribe_user (
  p_user_id   IN NUMBER,
  p_plan_name IN VARCHAR2
)
IS
  v_plan    Subscriptions.plan_name%TYPE := INITCAP(TRIM(p_plan_name));
  v_price   Subscriptions.price_paid%TYPE;
  v_name    Users.name%TYPE;
  v_ended   NUMBER;
BEGIN
  -- 1. the user must exist
  BEGIN
    SELECT name INTO v_name FROM Users WHERE user_id = p_user_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20010, 'User ' || p_user_id || ' does not exist');
  END;

  -- 2. current list price of the plan
  v_price := CASE v_plan
               WHEN 'Basic'   THEN 99
               WHEN 'Premium' THEN 199
               WHEN 'Family'  THEN 299
             END;
  IF v_price IS NULL THEN
    RAISE_APPLICATION_ERROR(-20011, 'Plan must be Basic, Premium or Family');
  END IF;

  -- 3. close the old subscription
  UPDATE Subscriptions
  SET    status = CASE WHEN end_date < TRUNC(SYSDATE) THEN 'Expired' ELSE 'Cancelled' END
  WHERE  user_id = p_user_id
  AND    status  = 'Active';
  v_ended := SQL%ROWCOUNT;

  -- 4. open the new one for one month
  INSERT INTO Subscriptions (user_id, plan_name, price_paid, start_date, end_date, status)
  VALUES (p_user_id, v_plan, v_price, TRUNC(SYSDATE), ADD_MONTHS(TRUNC(SYSDATE), 1) - 1, 'Active');

  COMMIT;
  DBMS_OUTPUT.PUT_LINE(v_name || ' is now on ' || v_plan || ' (Rs ' || v_price || ') until '
                       || TO_CHAR(ADD_MONTHS(TRUNC(SYSDATE), 1) - 1, 'DD-Mon-YYYY')
                       || '. Old subscriptions closed: ' || v_ended);
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE;
END subscribe_user;
/
SHOW ERRORS

-- ---------------------------------------------------------------------
-- PROCEDURE 2: calc_artist_royalty
-- Counts one artist's streams in a month, multiplies by the artist's
-- rate per stream and records the payment.  The UNIQUE constraint on
-- (artist_id, period_month) stops an artist being paid twice.
-- ---------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE calc_artist_royalty (
  p_artist_id IN NUMBER,
  p_month     IN DATE
)
IS
  v_month    DATE := TRUNC(p_month, 'MM');
  v_name     Artists.name%TYPE;
  v_rate     Artists.royalty_per_stream%TYPE;
  v_streams  NUMBER;
  v_amount   Royalty_Payments.amount%TYPE;
BEGIN
  SELECT name, royalty_per_stream
  INTO   v_name, v_rate
  FROM   Artists
  WHERE  artist_id = p_artist_id;

  SELECT COUNT(*)
  INTO   v_streams
  FROM   Play_History p
  JOIN   Songs s ON s.song_id = p.song_id
  WHERE  s.artist_id  = p_artist_id
  AND    p.played_at >= v_month
  AND    p.played_at <  ADD_MONTHS(v_month, 1);

  IF v_streams = 0 THEN
    DBMS_OUTPUT.PUT_LINE(RPAD(v_name, 20) || ' no streams, nothing to pay');
    RETURN;
  END IF;

  v_amount := ROUND(v_streams * v_rate, 2);

  INSERT INTO Royalty_Payments (artist_id, period_month, total_streams, amount, paid_on)
  VALUES (p_artist_id, v_month, v_streams, v_amount, TRUNC(SYSDATE));

  COMMIT;
  DBMS_OUTPUT.PUT_LINE(RPAD(v_name, 20) || ' ' || v_streams || ' streams x Rs '
                       || TO_CHAR(v_rate, 'FM0.00') || ' = Rs ' || TO_CHAR(v_amount, 'FM999990.00'));
EXCEPTION
  WHEN DUP_VAL_ON_INDEX THEN
    DBMS_OUTPUT.PUT_LINE(RPAD(v_name, 20) || ' already paid for ' || TO_CHAR(v_month, 'Mon YYYY') || ', skipped');
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20020, 'Artist ' || p_artist_id || ' does not exist');
END calc_artist_royalty;
/
SHOW ERRORS

-- ---------------------------------------------------------------------
-- PROCEDURE 3 (CURSOR): run_monthly_royalties
-- Month-end run.  An explicit cursor goes through every artist one row
-- at a time and calls calc_artist_royalty for each.
-- ---------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE run_monthly_royalties (
  p_month IN DATE
)
IS
  CURSOR c_artists IS
    SELECT artist_id, name
    FROM   Artists
    ORDER  BY artist_id;

  v_artist   c_artists%ROWTYPE;
  v_done     NUMBER := 0;
  v_total    NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Royalty run for ' || TO_CHAR(TRUNC(p_month, 'MM'), 'FMMonth YYYY'));
  DBMS_OUTPUT.PUT_LINE('----------------------------------------------');

  OPEN c_artists;
  LOOP
    FETCH c_artists INTO v_artist;
    EXIT WHEN c_artists%NOTFOUND;
    calc_artist_royalty(v_artist.artist_id, p_month);
    v_done := v_done + 1;
  END LOOP;
  CLOSE c_artists;

  SELECT NVL(SUM(amount), 0)
  INTO   v_total
  FROM   Royalty_Payments
  WHERE  period_month = TRUNC(p_month, 'MM');

  DBMS_OUTPUT.PUT_LINE('----------------------------------------------');
  DBMS_OUTPUT.PUT_LINE(v_done || ' artists processed. Total paid for the month: Rs '
                       || TO_CHAR(v_total, 'FM999990.00'));
END run_monthly_royalties;
/
SHOW ERRORS

-- ---------------------------------------------------------------------
-- TRIGGER 1: trg_check_play  (BEFORE INSERT on Play_History)
-- Blocks a play when the user has no active subscription.
-- ---------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_check_play
BEFORE INSERT ON Play_History
FOR EACH ROW
BEGIN
  IF is_subscription_active(:NEW.user_id, NVL(:NEW.played_at, SYSDATE)) = 0 THEN
    RAISE_APPLICATION_ERROR(-20001,
      'Play blocked: user ' || :NEW.user_id || ' has no active subscription');
  END IF;
END;
/
SHOW ERRORS

-- ---------------------------------------------------------------------
-- TRIGGER 2: trg_update_play_count  (AFTER INSERT on Play_History)
-- Adds 1 to the song's play_count after every recorded play.
-- ---------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_update_play_count
AFTER INSERT ON Play_History
FOR EACH ROW
BEGIN
  UPDATE Songs
  SET    play_count = play_count + 1
  WHERE  song_id = :NEW.song_id;
END;
/
SHOW ERRORS

-- ---------------------------------------------------------------------
-- TRIGGER 3: trg_playlist_limit  (BEFORE INSERT on Playlist_Songs)
-- Blocks adding a song when the playlist owner has no active
-- subscription, or when a Basic plan playlist already has 50 songs.
-- (Songs are added one at a time with INSERT ... VALUES, so reading
--  Playlist_Songs inside this row trigger is allowed.)
-- ---------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_playlist_limit
BEFORE INSERT ON Playlist_Songs
FOR EACH ROW
DECLARE
  c_basic_limit CONSTANT NUMBER := 50;
  v_user   Playlists.user_id%TYPE;
  v_plan   Subscriptions.plan_name%TYPE;
  v_count  NUMBER;
BEGIN
  SELECT user_id INTO v_user
  FROM   Playlists
  WHERE  playlist_id = :NEW.playlist_id;

  IF is_subscription_active(v_user) = 0 THEN
    RAISE_APPLICATION_ERROR(-20002,
      'Cannot add song: the playlist owner has no active subscription');
  END IF;

  SELECT MAX(plan_name) INTO v_plan
  FROM   Subscriptions
  WHERE  user_id = v_user
  AND    status  = 'Active'
  AND    TRUNC(SYSDATE) BETWEEN start_date AND end_date;

  IF v_plan = 'Basic' THEN
    SELECT COUNT(*) INTO v_count
    FROM   Playlist_Songs
    WHERE  playlist_id = :NEW.playlist_id;

    IF v_count >= c_basic_limit THEN
      RAISE_APPLICATION_ERROR(-20003,
        'Cannot add song: Basic plan playlists are limited to ' || c_basic_limit || ' songs');
    END IF;
  END IF;
END;
/
SHOW ERRORS

-- ---------- Check: everything compiled ----------
COLUMN object_name FORMAT A24
COLUMN object_type FORMAT A12
COLUMN status      FORMAT A8
SELECT object_name, object_type, status
FROM   user_objects
WHERE  object_type IN ('FUNCTION', 'PROCEDURE', 'TRIGGER')
ORDER  BY object_type, object_name;
