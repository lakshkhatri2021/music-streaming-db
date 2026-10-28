-- =====================================================================
-- Music Streaming Platform  |  10_security.sql
-- DCL: a read-only test account and a role, permitted and denied
-- operations, then REVOKE. Uses CONNECT to switch users, so it needs the
-- SYSTEM password of the local practice database.
-- =====================================================================
SET LINESIZE 200 PAGESIZE 100 FEEDBACK ON
COLUMN title FORMAT A26

PROMPT
PROMPT ===== 1. As SYSTEM: create a test account and a role =====
CONNECT system/YOUR_SYSTEM_PASSWORD@FREEPDB1
BEGIN
  FOR x IN (SELECT 'DROP USER report_viewer CASCADE' s FROM dba_users WHERE username = 'REPORT_VIEWER'
            UNION ALL
            SELECT 'DROP ROLE music_reader' FROM dba_roles WHERE role = 'MUSIC_READER') LOOP
    EXECUTE IMMEDIATE x.s;
  END LOOP;
END;
/
CREATE USER report_viewer IDENTIFIED BY viewer123;
GRANT CREATE SESSION TO report_viewer;
CREATE ROLE music_reader;
GRANT music_reader TO report_viewer;

PROMPT
PROMPT ===== 2. As MUSIC (owner): grant read-only access through the role =====
CONNECT music/music123@FREEPDB1
GRANT SELECT ON Songs   TO music_reader;
GRANT SELECT ON Artists TO music_reader;
GRANT SELECT ON v_artist_earnings TO report_viewer;

PROMPT
PROMPT ===== 3. As REPORT_VIEWER: permitted and denied operations =====
CONNECT report_viewer/viewer123@FREEPDB1
PROMPT Permitted: read songs
SELECT title, play_count FROM music.Songs ORDER BY play_count DESC, title FETCH FIRST 3 ROWS ONLY;
PROMPT Permitted: read the earnings view
SELECT artist, total_rs FROM music.v_artist_earnings ORDER BY total_rs DESC FETCH FIRST 3 ROWS ONLY;
PROMPT Denied: change a song (no UPDATE privilege)
UPDATE music.Songs SET play_count = 0;
PROMPT Denied: read users' personal data (no privilege on Users)
SELECT name, email FROM music.Users;
PROMPT Denied: delete an artist
DELETE FROM music.Artists;

PROMPT
PROMPT ===== 4. As MUSIC: REVOKE the role's access to Songs =====
CONNECT music/music123@FREEPDB1
REVOKE SELECT ON Songs FROM music_reader;

PROMPT
PROMPT ===== 5. As REPORT_VIEWER again: the same read is now denied =====
CONNECT report_viewer/viewer123@FREEPDB1
SELECT title FROM music.Songs FETCH FIRST 3 ROWS ONLY;
PROMPT Artists is still readable through the role:
SELECT name FROM music.Artists ORDER BY name FETCH FIRST 3 ROWS ONLY;

PROMPT
PROMPT ===== 6. As SYSTEM: remove the test account and role =====
CONNECT system/YOUR_SYSTEM_PASSWORD@FREEPDB1
DROP USER report_viewer CASCADE;
DROP ROLE music_reader;
EXIT
