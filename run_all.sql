-- Runs every script in order and saves all output to /tmp/run_output.txt
-- inside the container.  Use this once to test everything.
SET ECHO OFF
SPOOL /tmp/run_output.txt
PROMPT ############ 01_tables.sql ############
@@01_tables.sql
PROMPT ############ 02_data.sql ############
@@02_data.sql
PROMPT ############ 03_plsql.sql ############
@@03_plsql.sql
PROMPT ############ 04_queries.sql ############
@@04_queries.sql
PROMPT ############ 05_dml.sql ############
@@05_dml.sql
PROMPT ############ 06_transactions.sql ############
@@06_transactions.sql
SPOOL OFF
EXIT
