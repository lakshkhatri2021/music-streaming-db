-- Rebuilds the database to its fresh starting state (tables, data,
-- PL/SQL).  Run this before the live demo.
SET ECHO OFF
@@01_tables.sql
@@02_data.sql
@@03_plsql.sql
EXIT
