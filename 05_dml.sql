-- =====================================================================
-- Music Streaming Platform  |  05_dml.sql
-- INSERT, UPDATE and DELETE demonstrations, each with a before/after
-- check, plus proof that the constraints reject bad data.
-- =====================================================================
SET SERVEROUTPUT ON
SET LINESIZE 200 PAGESIZE 100 FEEDBACK ON
ALTER SESSION SET NLS_DATE_FORMAT = 'DD-MON-YYYY';
COLUMN name    FORMAT A20
COLUMN email   FORMAT A28
COLUMN country FORMAT A8
COLUMN playlist FORMAT A18

PROMPT
PROMPT ===== INSERT: a new user signs up =====
INSERT INTO Users (name, email, country) VALUES ('Lenny Summers', 'lenny.summers@gmail.com', 'USA');
SELECT user_id, name, email, country, join_date FROM Users WHERE email = 'lenny.summers@gmail.com';

PROMPT
PROMPT ===== UPDATE: Lizzy McAlpine's royalty rate goes from Rs 0.25 to Rs 0.30 =====
SELECT name, royalty_per_stream FROM Artists WHERE name = 'Lizzy McAlpine';
UPDATE Artists SET royalty_per_stream = 0.30 WHERE name = 'Lizzy McAlpine';
SELECT name, royalty_per_stream FROM Artists WHERE name = 'Lizzy McAlpine';

PROMPT
PROMPT ===== UPDATE: Micah Bell changes his email =====
UPDATE Users SET email = 'micah.bell@gmail.com' WHERE email = 'micah.bell@yahoo.com';
SELECT user_id, name, email FROM Users WHERE name = 'Micah Bell';

PROMPT
PROMPT ===== DELETE: Micah deletes his playlist 'Old Favourites' (its song links go with it) =====
SELECT p.name AS playlist, COUNT(ps.song_id) AS songs
FROM   Playlists p LEFT JOIN Playlist_Songs ps ON ps.playlist_id = p.playlist_id
WHERE  p.name = 'Old Favourites'
GROUP  BY p.name;
DELETE FROM Playlists WHERE name = 'Old Favourites';
SELECT COUNT(*) AS rows_left_for_playlist_11 FROM Playlist_Songs WHERE playlist_id = 11;

COMMIT;

PROMPT
PROMPT ===== CONSTRAINTS: bad data is rejected =====
DECLARE
  PROCEDURE try (p_label VARCHAR2, p_sql VARCHAR2) IS
  BEGIN
    EXECUTE IMMEDIATE p_sql;
    DBMS_OUTPUT.PUT_LINE(RPAD(p_label, 52) || ' ACCEPTED (unexpected)');
    ROLLBACK;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(RPAD(p_label, 52) || ' REJECTED: ' || SQLERRM);
      ROLLBACK;
  END;
BEGIN
  try('UNIQUE: duplicate email',
      q'[INSERT INTO Users (name, email) VALUES ('Fake Arthur', 'arthur.morgan@gmail.com')]');
  try('NOT NULL: user without a name',
      q'[INSERT INTO Users (email) VALUES ('noname@gmail.com')]');
  try('CHECK: plan that does not exist',
      q'[INSERT INTO Subscriptions (user_id, plan_name, price_paid, end_date) VALUES (1, 'Gold', 99, SYSDATE + 30)]');
  try('CHECK: subscription ending before it starts',
      q'[INSERT INTO Subscriptions (user_id, plan_name, price_paid, start_date, end_date) VALUES (1, 'Basic', 99, DATE '2026-10-10', DATE '2026-10-01')]');
  try('CHECK: negative royalty rate',
      q'[UPDATE Artists SET royalty_per_stream = -1 WHERE artist_id = 1]');
  try('FOREIGN KEY: song by an artist that does not exist',
      q'[INSERT INTO Songs (artist_id, title, duration_sec) VALUES (999, 'Ghost Song', 200)]');
  try('FOREIGN KEY: delete an artist with songs/payments',
      q'[DELETE FROM Artists WHERE artist_id = 1]');
  try('PRIMARY KEY: same song twice in one playlist',
      q'[INSERT INTO Playlist_Songs (playlist_id, song_id) VALUES (1, 22)]');
END;
/
