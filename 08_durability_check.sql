-- =====================================================================
-- Music Streaming Platform  |  08_durability_check.sql
-- Run after:  docker restart oracle-db
-- The row committed by 07_acid_concurrency.sql must still be there.
-- =====================================================================
SET LINESIZE 200 PAGESIZE 100
ALTER SESSION SET NLS_DATE_FORMAT = 'DD-MON-YYYY';
COLUMN name  FORMAT A20
COLUMN email FORMAT A30
PROMPT
PROMPT ===== D. DURABILITY CHECK after restarting the database =====
SELECT user_id, name, email, join_date FROM Users WHERE email = 'durability.test@gmail.com';
PROMPT The committed row survived the restart.
DELETE FROM Users WHERE email = 'durability.test@gmail.com';
COMMIT;
PROMPT (test row removed)
EXIT
