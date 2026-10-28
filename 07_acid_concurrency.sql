-- =====================================================================
-- Music Streaming Platform  |  07_acid_concurrency.sql
-- Shows the ACID properties and concurrency control on the project data.
--
-- A second user is simulated with AUTONOMOUS TRANSACTIONS: a function
-- marked PRAGMA AUTONOMOUS_TRANSACTION runs as a completely separate
-- transaction, exactly like another person connected at the same time.
-- It cannot see this session's uncommitted changes and it has to wait
-- for this session's locks.
--
-- Every test change is rolled back or undone, so the data is left as it was.
-- Durability is checked separately with 08_durability_check.sql.
-- =====================================================================
SET SERVEROUTPUT ON
SET LINESIZE 200 PAGESIZE 100 FEEDBACK OFF
ALTER SESSION SET NLS_DATE_FORMAT = 'DD-MON-YYYY';
COLUMN email     FORMAT A30
COLUMN country   FORMAT A10
COLUMN plan_name FORMAT A8
COLUMN status    FORMAT A10
COLUMN name      FORMAT A20

-- ---------------------------------------------------------------------
-- Helpers: each one runs as "another session"
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION other_session_email (p_user_id IN NUMBER) RETURN VARCHAR2 IS
  PRAGMA AUTONOMOUS_TRANSACTION;
  v_email Users.email%TYPE;
BEGIN
  SELECT email INTO v_email FROM Users WHERE user_id = p_user_id;
  COMMIT;
  RETURN v_email;
END;
/
CREATE OR REPLACE FUNCTION other_session_lock_nowait (p_user_id IN NUMBER) RETURN VARCHAR2 IS
  PRAGMA AUTONOMOUS_TRANSACTION;
  v_id NUMBER;
BEGIN
  SELECT user_id INTO v_id FROM Users WHERE user_id = p_user_id FOR UPDATE NOWAIT;
  ROLLBACK;
  RETURN 'got the lock';
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    RETURN 'could not get the lock -> ' || SQLERRM;
END;
/
CREATE OR REPLACE FUNCTION other_session_update_and_wait (p_user_id IN NUMBER) RETURN VARCHAR2 IS
  PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
  UPDATE Users SET country = country WHERE user_id = p_user_id;   -- waits for the row lock
  ROLLBACK;
  RETURN 'updated';
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    RETURN SQLERRM;
END;
/
CREATE OR REPLACE FUNCTION other_session_lock_song (p_title IN VARCHAR2) RETURN VARCHAR2 IS
  PRAGMA AUTONOMOUS_TRANSACTION;
  v_count NUMBER;
BEGIN
  SELECT play_count INTO v_count FROM Songs WHERE title = p_title FOR UPDATE NOWAIT;
  ROLLBACK;
  RETURN 'got the lock';
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    RETURN 'could not get the lock -> ' || SQLERRM;
END;
/
CREATE OR REPLACE PROCEDURE other_session_set_country (p_user_id IN NUMBER, p_country IN VARCHAR2) IS
  PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
  UPDATE Users SET country = p_country WHERE user_id = p_user_id;
  COMMIT;
END;
/
SHOW ERRORS

COMMIT;

-- =====================================================================
PROMPT
PROMPT ===== A. ATOMICITY 1: a two-step change where step 2 fails =====
PROMPT Arthur's subscriptions before:
SELECT sub_id, plan_name, status FROM Subscriptions WHERE user_id = 1 ORDER BY sub_id;
BEGIN
  UPDATE Subscriptions SET status = 'Cancelled' WHERE user_id = 1 AND status = 'Active';
  DBMS_OUTPUT.PUT_LINE('Step 1 done: ' || SQL%ROWCOUNT || ' Active subscription set to Cancelled (not committed yet)');
  INSERT INTO Subscriptions (user_id, plan_name, price_paid, end_date)
  VALUES (1, 'Gold', 249, SYSDATE + 30);            -- 'Gold' breaks the CHECK constraint
  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('Step 2 failed: ' || SQLERRM);
    DBMS_OUTPUT.PUT_LINE('ROLLBACK: step 1 was undone too, so nothing was half-done');
END;
/
PROMPT Arthur's subscriptions after (unchanged):
SELECT sub_id, plan_name, status FROM Subscriptions WHERE user_id = 1 ORDER BY sub_id;

PROMPT
PROMPT ===== A. ATOMICITY 2: SAVEPOINT undoes only part of a transaction =====
UPDATE Artists SET royalty_per_stream = 0.50 WHERE name = 'The 1975';
SAVEPOINT after_first_change;
UPDATE Artists SET royalty_per_stream = 0.90 WHERE name = 'One Direction';
PROMPT Inside the transaction, before ROLLBACK TO SAVEPOINT:
SELECT name, royalty_per_stream FROM Artists WHERE name IN ('The 1975', 'One Direction') ORDER BY name;
ROLLBACK TO SAVEPOINT after_first_change;
PROMPT After ROLLBACK TO SAVEPOINT (only the second change is undone):
SELECT name, royalty_per_stream FROM Artists WHERE name IN ('The 1975', 'One Direction') ORDER BY name;
ROLLBACK;
PROMPT After a full ROLLBACK (both back to their original rates):
SELECT name, royalty_per_stream FROM Artists WHERE name IN ('The 1975', 'One Direction') ORDER BY name;

-- =====================================================================
PROMPT
PROMPT ===== C. CONSISTENCY: changes that would break the rules are refused =====
DECLARE
  v_before NUMBER;
  v_after  NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_before FROM Play_History;
  BEGIN
    INSERT INTO Play_History (user_id, song_id, seconds_played) VALUES (3, 1, 100);   -- Micah, expired
  EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Micah plays a song        -> ' || SQLERRM);
  END;
  BEGIN
    INSERT INTO Royalty_Payments (artist_id, period_month, total_streams, amount)
    VALUES (1, DATE '2026-08-01', 99, 99);                                            -- August already paid
  EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Pay The 1975 again for Aug -> ' || SQLERRM);
  END;
  BEGIN
    INSERT INTO Users (name, email) VALUES ('Copy of Arthur', 'arthur.morgan@gmail.com');
  EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Duplicate email           -> ' || SQLERRM);
  END;
  ROLLBACK;
  SELECT COUNT(*) INTO v_after FROM Play_History;
  DBMS_OUTPUT.PUT_LINE('Plays before: ' || v_before || ', plays after: ' || v_after);
END;
/
PROMPT Rule checks on the whole database (both must return no rows):
PROMPT 1) artists paid twice for the same month
SELECT artist_id, period_month, COUNT(*) AS payments
FROM   Royalty_Payments GROUP BY artist_id, period_month HAVING COUNT(*) > 1;
PROMPT 2) users with more than one Active subscription
SELECT user_id, COUNT(*) AS active_subs
FROM   Subscriptions WHERE status = 'Active' GROUP BY user_id HAVING COUNT(*) > 1;

-- =====================================================================
PROMPT
PROMPT ===== I. ISOLATION: another session cannot see uncommitted changes =====
UPDATE Users SET email = 'arthur@vanderlinde.gang' WHERE user_id = 1;
DECLARE
  v_mine Users.email%TYPE;
BEGIN
  SELECT email INTO v_mine FROM Users WHERE user_id = 1;
  DBMS_OUTPUT.PUT_LINE('Session 1 (made the change, not committed) sees: ' || v_mine);
  DBMS_OUTPUT.PUT_LINE('Session 2 (another user) sees                 : ' || other_session_email(1));
END;
/
ROLLBACK;
PROMPT After ROLLBACK the change is gone for everyone:
SELECT user_id, name, email FROM Users WHERE user_id = 1;

PROMPT
PROMPT ===== I. ISOLATION LEVEL SERIALIZABLE: a transaction keeps one consistent snapshot =====
COMMIT;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
PROMPT Session 1 starts a SERIALIZABLE transaction and reads Arthur's country:
SELECT user_id, name, country FROM Users WHERE user_id = 1;
PROMPT Session 2 now changes Arthur's country to Mexico and COMMITS:
EXEC other_session_set_country(1, 'Mexico')
PROMPT Session 1 reads again inside the same transaction (still sees its snapshot):
SELECT user_id, name, country FROM Users WHERE user_id = 1;
COMMIT;
PROMPT Session 1 ends its transaction and reads again (now sees the committed change):
SELECT user_id, name, country FROM Users WHERE user_id = 1;
EXEC other_session_set_country(1, 'USA')
PROMPT (Arthur's country set back to USA)

-- =====================================================================
PROMPT
PROMPT ===== CONCURRENCY 1: row-level locking =====
UPDATE Users SET country = 'USA' WHERE user_id = 1;
PROMPT Session 1 has updated Arthur's row and not committed, so it holds the row lock.
BEGIN
  DBMS_OUTPUT.PUT_LINE('Session 2 locks Arthur (row 1) with NOWAIT : ' || other_session_lock_nowait(1));
  DBMS_OUTPUT.PUT_LINE('Session 2 locks Mary-Beth (row 2) NOWAIT   : ' || other_session_lock_nowait(2));
END;
/
PROMPT Only the row being changed is locked; other users' rows are free.

PROMPT
PROMPT ===== CONCURRENCY 2: deadlock detection =====
PROMPT Session 2 tries a normal UPDATE on Arthur's row. It must wait for Session 1,
PROMPT but Session 1 is waiting for Session 2 to finish, so Oracle detects a deadlock:
BEGIN
  DBMS_OUTPUT.PUT_LINE('Session 2 result -> ' || other_session_update_and_wait(1));
END;
/
ROLLBACK;
PROMPT Session 1 rolls back and releases its lock. Session 2 tries again:
BEGIN
  DBMS_OUTPUT.PUT_LINE('Session 2 locks Arthur (row 1) with NOWAIT : ' || other_session_lock_nowait(1));
END;
/

PROMPT
PROMPT ===== CONCURRENCY 3: SELECT ... FOR UPDATE prevents a lost update =====
DECLARE
  v_count Songs.play_count%TYPE;
BEGIN
  SELECT play_count INTO v_count FROM Songs WHERE title = 'Creep' FOR UPDATE;
  DBMS_OUTPUT.PUT_LINE('Session 1 read Creep play_count = ' || v_count || ' and locked the row');
  DBMS_OUTPUT.PUT_LINE('Session 2 tries to lock the same row        -> ' || other_session_lock_song('Creep'));
END;
/
PROMPT Session 2 cannot read-and-change the count until Session 1 commits, so neither
PROMPT session can overwrite the other's update (no lost update).
ROLLBACK;

-- =====================================================================
PROMPT
PROMPT ===== D. DURABILITY: committed data survives a restart =====
DELETE FROM Users WHERE email = 'durability.test@gmail.com';
INSERT INTO Users (name, email, country) VALUES ('Durability Test', 'durability.test@gmail.com', 'USA');
COMMIT;
SELECT user_id, name, email, join_date FROM Users WHERE email = 'durability.test@gmail.com';
PROMPT Committed. Now restart the database with:  docker restart oracle-db
PROMPT then run 08_durability_check.sql. The row will still be there.

-- ---------------------------------------------------------------------
-- remove the helper objects
-- ---------------------------------------------------------------------
DROP FUNCTION other_session_email;
DROP FUNCTION other_session_lock_nowait;
DROP FUNCTION other_session_update_and_wait;
DROP FUNCTION other_session_lock_song;
DROP PROCEDURE other_session_set_country;
SET FEEDBACK ON
