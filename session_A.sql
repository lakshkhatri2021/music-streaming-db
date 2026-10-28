-- =====================================================================
-- LIVE DEMO, WINDOW A  (run session_B.sql in a second terminal window)
-- Shows isolation and row locking between two real users.
-- =====================================================================
SET LINESIZE 200 PAGESIZE 100
COLUMN email FORMAT A30
COLUMN name  FORMAT A20
PROMPT
PROMPT ===== WINDOW A, STEP 1: change Arthur's email but do NOT commit =====
UPDATE Users SET email = 'arthur@vanderlinde.gang' WHERE user_id = 1;
SELECT user_id, name, email FROM Users WHERE user_id = 1;
PROMPT Window A sees the new email. It is not committed, and A now holds a lock on Arthur's row.
PROMPT
PAUSE >>> Now start session_B.sql in window B and do its step 1. Then come back and press Enter.
PROMPT
PROMPT ===== WINDOW A, STEP 2: commit =====
PAUSE >>> Window B should be frozen on its UPDATE. Press Enter to COMMIT and release the lock.
COMMIT;
PROMPT Committed. Window B's UPDATE now goes through. Go and look at window B.
PROMPT
PAUSE >>> When window B has finished, press Enter to see the final value.
SELECT user_id, name, email FROM Users WHERE user_id = 1;
PROMPT Window A now sees Window B's committed change: arthur.morgan@gmail.com is back.
EXIT
