MUSIC STREAMING PLATFORM - DATABASE PROJECT FILES
=================================================

01_tables.sql        8 tables with PK, FK, NOT NULL, UNIQUE, CHECK, DEFAULT
02_data.sql          sample data (10+ rows in every table)
03_plsql.sql         2 functions, 3 procedures (1 with a cursor), 3 triggers
04_queries.sql       18 SQL queries
05_dml.sql           INSERT / UPDATE / DELETE demos and constraint checks
06_transactions.sql  7 real-world transactions (same as the Python app)
run_all.sql          runs 01 to 06 and saves the output to /tmp/run_output.txt
setup.sql            rebuilds the fresh database (01 to 03) - run before the demo
app.py               Python menu app (terminal version)
web_app.py           Python web app (browser version) - use this for the demo

STEP 1  Copy the folder into the Oracle container
        docker cp ~/Desktop/music_db oracle-db:/tmp/music_db

STEP 2  Run everything
        docker exec -it -w /tmp/music_db oracle-db sqlplus music/music123@FREEPDB1 @run_all.sql

STEP 3  Copy the output back to your Mac
        docker cp oracle-db:/tmp/run_output.txt ~/Downloads/run_output.txt

BEFORE THE DEMO  reset to the fresh data
        docker exec -it -w /tmp/music_db oracle-db sqlplus music/music123@FREEPDB1 @setup.sql

WEB APP (first time)
        cd ~/Desktop/music_db
        python3 -m venv venv
        source venv/bin/activate
        pip install streamlit oracledb
        python -m streamlit run web_app.py

WEB APP (every time after)
        cd ~/Desktop/music_db && source venv/bin/activate && python -m streamlit run web_app.py
