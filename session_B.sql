-- =====================================================================
-- LIVE DEMO, WINDOW B  (start this after window A's step 1)
-- =====================================================================
SET LINESIZE 200 PAGESIZE 100
COLUMN email FORMAT A30
COLUMN name  FORMAT A20
PROMPT
PROMPT ===== WINDOW B, STEP 1: read Arthur's email =====
SELECT user_id, name, email FROM Users WHERE user_id = 1;
PROMPT Window B still sees the OLD email, because A has not committed. (ISOLATION)
PROMPT
PAUSE >>> Press Enter to try updating the same row.
PROMPT
PROMPT ===== WINDOW B, STEP 2: update the same row =====
PROMPT This will FREEZE until window A commits, because A holds the row lock. (CONCURRENCY CONTROL)
PROMPT Go to window A and press Enter there.
UPDATE Users SET email = 'arthur.morgan@gmail.com' WHERE user_id = 1;
PROMPT The lock was released and B's update went through.
COMMIT;
SELECT user_id, name, email FROM Users WHERE user_id = 1;
PROMPT B has committed. Go back to window A and press Enter.
EXIT
