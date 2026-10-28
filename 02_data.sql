-- =====================================================================
-- Music Streaming Platform  |  02_data.sql
-- Sample data: at least 10 meaningful rows in every table.
-- Run AFTER 01_tables.sql and BEFORE 03_plsql.sql (the triggers are
-- created after the data, so historical plays load without being checked
-- against today's date).  Amounts are in Indian Rupees.
-- =====================================================================
SET DEFINE OFF
SET FEEDBACK OFF
ALTER SESSION SET NLS_DATE_FORMAT = 'DD-MON-YYYY';

-- ---------- Users (12) ----------
INSERT INTO Users (user_id, name, email, country, join_date) VALUES (1, 'Arthur Morgan', 'arthur.morgan@gmail.com', 'USA', DATE '2026-08-05');
INSERT INTO Users (user_id, name, email, country, join_date) VALUES (2, 'Mary-Beth Gaskill', 'marybeth.gaskill@gmail.com', 'USA', DATE '2026-08-05');
INSERT INTO Users (user_id, name, email, country, join_date) VALUES (3, 'Micah Bell', 'micah.bell@yahoo.com', 'USA', DATE '2026-09-15');
INSERT INTO Users (user_id, name, email, country, join_date) VALUES (4, 'Hosea Matthews', 'hosea.matthews@outlook.com', 'USA', DATE '2026-10-02');
INSERT INTO Users (user_id, name, email, country, join_date) VALUES (5, 'John Marston', 'john.marston@gmail.com', 'USA', DATE '2026-09-10');
INSERT INTO Users (user_id, name, email, country, join_date) VALUES (6, 'Abigail Roberts', 'abigail.roberts@gmail.com', 'USA', DATE '2026-10-10');
INSERT INTO Users (user_id, name, email, country, join_date) VALUES (7, 'Javier Escuella', 'javier.escuella@hotmail.com', 'Mexico', DATE '2026-10-08');
INSERT INTO Users (user_id, name, email, country, join_date) VALUES (8, 'Sadie Adler', 'sadie.adler@gmail.com', 'USA', DATE '2026-10-01');
INSERT INTO Users (user_id, name, email, country, join_date) VALUES (9, 'Dutch van der Linde', 'dutch.vanderlinde@gmail.com', 'USA', DATE '2026-08-15');
INSERT INTO Users (user_id, name, email, country, join_date) VALUES (10, 'Tilly Jackson', 'tilly.jackson@gmail.com', 'USA', DATE '2026-10-12');
INSERT INTO Users (user_id, name, email, country, join_date) VALUES (11, 'Sean MacGuire', 'sean.macguire@eircom.net', 'Ireland', DATE '2026-09-25');
INSERT INTO Users (user_id, name, email, country, join_date) VALUES (12, 'Karen Jones', 'karen.jones@gmail.com', 'USA', DATE '2026-10-18');

-- ---------- Subscriptions (14): Active, Expired and Cancelled; some on discounted prices ----------
INSERT INTO Subscriptions (sub_id, user_id, plan_name, price_paid, start_date, end_date, status) VALUES (1, 1, 'Premium', 199, DATE '2026-08-05', DATE '2026-09-04', 'Expired');
INSERT INTO Subscriptions (sub_id, user_id, plan_name, price_paid, start_date, end_date, status) VALUES (2, 1, 'Premium', 199, DATE '2026-09-05', DATE '2026-10-04', 'Expired');
INSERT INTO Subscriptions (sub_id, user_id, plan_name, price_paid, start_date, end_date, status) VALUES (3, 1, 'Premium', 199, DATE '2026-10-05', DATE '2026-11-04', 'Active');
INSERT INTO Subscriptions (sub_id, user_id, plan_name, price_paid, start_date, end_date, status) VALUES (4, 2, 'Basic', 99, DATE '2026-08-05', DATE '2026-09-04', 'Expired');
INSERT INTO Subscriptions (sub_id, user_id, plan_name, price_paid, start_date, end_date, status) VALUES (5, 2, 'Basic', 99, DATE '2026-10-06', DATE '2026-11-05', 'Active');
INSERT INTO Subscriptions (sub_id, user_id, plan_name, price_paid, start_date, end_date, status) VALUES (6, 3, 'Family', 299, DATE '2026-09-15', DATE '2026-10-14', 'Expired');
INSERT INTO Subscriptions (sub_id, user_id, plan_name, price_paid, start_date, end_date, status) VALUES (7, 4, 'Premium', 179, DATE '2026-10-02', DATE '2026-11-01', 'Active');
INSERT INTO Subscriptions (sub_id, user_id, plan_name, price_paid, start_date, end_date, status) VALUES (8, 5, 'Basic', 99, DATE '2026-09-10', DATE '2026-10-09', 'Expired');
INSERT INTO Subscriptions (sub_id, user_id, plan_name, price_paid, start_date, end_date, status) VALUES (9, 6, 'Family', 299, DATE '2026-10-10', DATE '2026-11-09', 'Active');
INSERT INTO Subscriptions (sub_id, user_id, plan_name, price_paid, start_date, end_date, status) VALUES (10, 7, 'Premium', 199, DATE '2026-10-08', DATE '2026-11-07', 'Active');
INSERT INTO Subscriptions (sub_id, user_id, plan_name, price_paid, start_date, end_date, status) VALUES (11, 8, 'Basic', 99, DATE '2026-10-01', DATE '2026-10-31', 'Active');
INSERT INTO Subscriptions (sub_id, user_id, plan_name, price_paid, start_date, end_date, status) VALUES (12, 9, 'Premium', 199, DATE '2026-08-15', DATE '2026-09-14', 'Cancelled');
INSERT INTO Subscriptions (sub_id, user_id, plan_name, price_paid, start_date, end_date, status) VALUES (13, 10, 'Basic', 99, DATE '2026-10-12', DATE '2026-11-11', 'Active');
INSERT INTO Subscriptions (sub_id, user_id, plan_name, price_paid, start_date, end_date, status) VALUES (14, 11, 'Premium', 149, DATE '2026-09-25', DATE '2026-10-24', 'Active');

-- ---------- Artists (14) ----------
INSERT INTO Artists (artist_id, name, country, royalty_per_stream) VALUES (1, 'The 1975', 'UK', 0.35);
INSERT INTO Artists (artist_id, name, country, royalty_per_stream) VALUES (2, 'One Direction', 'UK', 0.40);
INSERT INTO Artists (artist_id, name, country, royalty_per_stream) VALUES (3, 'Harry Styles', 'UK', 0.45);
INSERT INTO Artists (artist_id, name, country, royalty_per_stream) VALUES (4, 'Zayn', 'UK', 0.35);
INSERT INTO Artists (artist_id, name, country, royalty_per_stream) VALUES (5, '5 Seconds of Summer', 'Australia', 0.35);
INSERT INTO Artists (artist_id, name, country, royalty_per_stream) VALUES (6, 'Billie Eilish', 'USA', 0.45);
INSERT INTO Artists (artist_id, name, country, royalty_per_stream) VALUES (7, 'Phoebe Bridgers', 'USA', 0.30);
INSERT INTO Artists (artist_id, name, country, royalty_per_stream) VALUES (8, 'Radiohead', 'UK', 0.40);
INSERT INTO Artists (artist_id, name, country, royalty_per_stream) VALUES (9, 'Niall Horan', 'Ireland', 0.35);
INSERT INTO Artists (artist_id, name, country, royalty_per_stream) VALUES (10, 'Olivia Rodrigo', 'USA', 0.45);
INSERT INTO Artists (artist_id, name, country, royalty_per_stream) VALUES (11, 'The Beatles', 'UK', 0.40);
INSERT INTO Artists (artist_id, name, country, royalty_per_stream) VALUES (12, 'Lizzy McAlpine', 'USA', 0.25);
INSERT INTO Artists (artist_id, name, country, royalty_per_stream) VALUES (13, 'Taylor Swift', 'USA', 0.45);
INSERT INTO Artists (artist_id, name, country, royalty_per_stream) VALUES (14, 'Ariana Grande', 'USA', 0.45);

-- ---------- Songs (70: 5 per artist) ----------
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (1, 1, 'Somebody Else', 'I Like It When You Sleep', 'Pop Rock', 347);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (2, 1, 'Robbers', 'The 1975', 'Pop Rock', 254);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (3, 1, 'Chocolate', 'The 1975', 'Pop Rock', 224);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (4, 1, 'About You', 'Being Funny in a Foreign Language', 'Pop Rock', 326);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (5, 1, 'The Sound', 'I Like It When You Sleep', 'Pop Rock', 248);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (6, 2, 'Story of My Life', 'Midnight Memories', 'Pop', 245);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (7, 2, 'Night Changes', 'Four', 'Pop', 227);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (8, 2, 'What Makes You Beautiful', 'Up All Night', 'Pop', 199);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (9, 2, 'Drag Me Down', 'Made in the A.M.', 'Pop', 192);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (10, 2, 'Perfect', 'Made in the A.M.', 'Pop', 230);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (11, 3, 'As It Was', 'Harry''s House', 'Pop', 167);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (12, 3, 'Watermelon Sugar', 'Fine Line', 'Pop', 174);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (13, 3, 'Sign of the Times', 'Harry Styles', 'Pop', 341);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (14, 3, 'Adore You', 'Fine Line', 'Pop', 207);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (15, 3, 'Matilda', 'Harry''s House', 'Pop', 245);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (16, 4, 'Pillowtalk', 'Mind of Mine', 'R&B', 203);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (17, 4, 'Dusk Till Dawn', 'Dusk Till Dawn', 'R&B', 239);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (18, 4, 'Let Me', 'Icarus Falls', 'R&B', 184);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (19, 4, 'Vibez', 'Nobody Is Listening', 'R&B', 163);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (20, 4, 'It''s You', 'Mind of Mine', 'R&B', 249);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (21, 5, 'Youngblood', 'Youngblood', 'Pop Rock', 203);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (22, 5, 'She Looks So Perfect', '5 Seconds of Summer', 'Pop Rock', 202);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (23, 5, 'Amnesia', '5 Seconds of Summer', 'Pop Rock', 237);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (24, 5, 'Teeth', 'Calm', 'Pop Rock', 204);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (25, 5, 'Want You Back', 'Youngblood', 'Pop Rock', 173);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (26, 6, 'bad guy', 'When We All Fall Asleep, Where Do We Go?', 'Alternative', 194);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (27, 6, 'Birds of a Feather', 'Hit Me Hard and Soft', 'Alternative', 210);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (28, 6, 'Happier Than Ever', 'Happier Than Ever', 'Alternative', 298);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (29, 6, 'ocean eyes', 'Don''t Smile at Me', 'Alternative', 200);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (30, 6, 'What Was I Made For?', 'Barbie The Album', 'Alternative', 222);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (31, 7, 'Motion Sickness', 'Stranger in the Alps', 'Indie', 230);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (32, 7, 'Kyoto', 'Punisher', 'Indie', 184);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (33, 7, 'Garden Song', 'Punisher', 'Indie', 220);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (34, 7, 'Scott Street', 'Stranger in the Alps', 'Indie', 305);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (35, 7, 'I Know the End', 'Punisher', 'Indie', 344);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (36, 8, 'Creep', 'Pablo Honey', 'Rock', 239);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (37, 8, 'No Surprises', 'OK Computer', 'Rock', 229);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (38, 8, 'Karma Police', 'OK Computer', 'Rock', 264);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (39, 8, 'Let Down', 'OK Computer', 'Rock', 299);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (40, 8, 'Weird Fishes/Arpeggi', 'In Rainbows', 'Rock', 318);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (41, 9, 'Slow Hands', 'Flicker', 'Pop', 188);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (42, 9, 'This Town', 'Flicker', 'Pop', 232);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (43, 9, 'Heaven', 'The Show', 'Pop', 214);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (44, 9, 'Nice to Meet Ya', 'Heartbreak Weather', 'Pop', 172);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (45, 9, 'Too Much to Ask', 'Flicker', 'Pop', 223);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (46, 10, 'drivers license', 'SOUR', 'Pop', 242);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (47, 10, 'good 4 u', 'SOUR', 'Pop', 178);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (48, 10, 'vampire', 'GUTS', 'Pop', 220);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (49, 10, 'deja vu', 'SOUR', 'Pop', 215);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (50, 10, 'traitor', 'SOUR', 'Pop', 229);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (51, 11, 'Here Comes the Sun', 'Abbey Road', 'Rock', 185);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (52, 11, 'Let It Be', 'Let It Be', 'Rock', 243);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (53, 11, 'Hey Jude', 'Hey Jude', 'Rock', 431);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (54, 11, 'Yesterday', 'Help!', 'Rock', 125);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (55, 11, 'Come Together', 'Abbey Road', 'Rock', 259);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (56, 12, 'ceilings', 'five seconds flat', 'Indie', 182);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (57, 12, 'doomsday', 'five seconds flat', 'Indie', 200);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (58, 12, 'Pancakes for Dinner', 'Give Me A Minute', 'Indie', 204);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (59, 12, 'Older', 'Older', 'Indie', 201);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (60, 12, 'All Falls Down', 'Older', 'Indie', 215);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (61, 13, 'Anti-Hero', 'Midnights', 'Pop', 200);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (62, 13, 'Cruel Summer', 'Lover', 'Pop', 178);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (63, 13, 'Love Story', 'Fearless', 'Pop', 235);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (64, 13, 'Blank Space', '1989', 'Pop', 231);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (65, 13, 'Cardigan', 'Folklore', 'Indie', 239);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (66, 14, 'thank u, next', 'thank u, next', 'Pop', 207);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (67, 14, '7 rings', 'thank u, next', 'Pop', 178);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (68, 14, 'positions', 'Positions', 'Pop', 172);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (69, 14, 'we can''t be friends', 'eternal sunshine', 'Pop', 228);
INSERT INTO Songs (song_id, artist_id, title, album_title, genre, duration_sec) VALUES (70, 14, 'Into You', 'Dangerous Woman', 'Pop', 244);

-- ---------- Play_History (45 plays across August, September and October 2026) ----------
INSERT INTO Play_History (play_id, user_id, song_id, played_at, seconds_played) VALUES (1, 1, 22, TO_DATE('2026-08-06 22:10', 'YYYY-MM-DD HH24:MI'), 200);
INSERT INTO Play_History (play_id, user_id, song_id, played_at, seconds_played) VALUES (2, 1, 23, TO_DATE('2026-08-06 22:14', 'YYYY-MM-DD HH24:MI'), 230);
INSERT INTO Play_History (play_id, user_id, song_id, played_at, seconds_played) VALUES (3, 1, 36, TO_DATE('2026-08-09 08:30', 'YYYY-MM-DD HH24:MI'), 233);
INSERT INTO Play_History (play_id, user_id, song_id, played_at, seconds_played) VALUES (4, 2, 1, TO_DATE('2026-08-06 19:05', 'YYYY-MM-DD HH24:MI'), 262);
INSERT INTO Play_History (play_id, user_id, song_id, played_at, seconds_played) VALUES (5, 2, 4, TO_DATE('2026-08-06 19:10', 'YYYY-MM-DD HH24:MI'), 268);
INSERT INTO Play_History (play_id, user_id, song_id, played_at, seconds_played) VALUES (6, 2, 29, TO_DATE('2026-08-14 21:40', 'YYYY-MM-DD HH24:MI'), 200);
INSERT INTO Play_History (play_id, user_id, song_id, played_at, seconds_played) VALUES (7, 9, 8, TO_DATE('2026-08-16 17:20', 'YYYY-MM-DD HH24:MI'), 199);
INSERT INTO Play_History (play_id, user_id, song_id, played_at, seconds_played) VALUES (8, 9, 9, TO_DATE('2026-08-16 17:24', 'YYYY-MM-DD HH24:MI'), 120);
INSERT INTO Play_History (play_id, user_id, song_id, played_at, seconds_played) VALUES (9, 9, 64, TO_DATE('2026-08-20 23:00', 'YYYY-MM-DD HH24:MI'), 231);
INSERT INTO Play_History (play_id, user_id, song_id, played_at, seconds_played) VALUES (10, 1, 15, TO_DATE('2026-08-25 18:45', 'YYYY-MM-DD HH24:MI'), 245);
INSERT INTO Play_History (play_id, user_id, song_id, played_at, seconds_played) VALUES (11, 2, 43, TO_DATE('2026-08-28 07:55', 'YYYY-MM-DD HH24:MI'), 214);
INSERT INTO Play_History (play_id, user_id, song_id, played_at, seconds_played) VALUES (12, 9, 50, TO_DATE('2026-08-30 20:30', 'YYYY-MM-DD HH24:MI'), 203);
INSERT INTO Play_History (play_id, user_id, song_id, played_at, seconds_played) VALUES (13, 1, 24, TO_DATE('2026-09-06 22:00', 'YYYY-MM-DD HH24:MI'), 204);
INSERT INTO Play_History (play_id, user_id, song_id, played_at, seconds_played) VALUES (14, 1, 57, TO_DATE('2026-09-07 19:30', 'YYYY-MM-DD HH24:MI'), 186);
INSERT INTO Play_History (play_id, user_id, song_id, played_at, seconds_played) VALUES (15, 5, 58, TO_DATE('2026-09-11 08:10', 'YYYY-MM-DD HH24:MI'), 187);
INSERT INTO Play_History (play_id, user_id, song_id, played_at, seconds_played) VALUES (16, 5, 60, TO_DATE('2026-09-11 08:14', 'YYYY-MM-DD HH24:MI'), 215);
INSERT INTO Play_History (play_id, user_id, song_id, played_at, seconds_played) VALUES (17, 5, 2, TO_DATE('2026-09-12 23:20', 'YYYY-MM-DD HH24:MI'), 254);
INSERT INTO Play_History (play_id, user_id, song_id, played_at, seconds_played) VALUES (18, 3, 65, TO_DATE('2026-09-16 18:00', 'YYYY-MM-DD HH24:MI'), 239);
INSERT INTO Play_History (play_id, user_id, song_id, played_at, seconds_played) VALUES (19, 3, 66, TO_DATE('2026-09-16 18:05', 'YYYY-MM-DD HH24:MI'), 207);
INSERT INTO Play_History (play_id, user_id, song_id, played_at, seconds_played) VALUES (20, 3, 30, TO_DATE('2026-09-20 21:10', 'YYYY-MM-DD HH24:MI'), 222);
INSERT INTO Play_History (play_id, user_id, song_id, played_at, seconds_played) VALUES (21, 11, 37, TO_DATE('2026-09-26 10:00', 'YYYY-MM-DD HH24:MI'), 229);
INSERT INTO Play_History (play_id, user_id, song_id, played_at, seconds_played) VALUES (22, 11, 51, TO_DATE('2026-09-27 22:30', 'YYYY-MM-DD HH24:MI'), 183);
INSERT INTO Play_History (play_id, user_id, song_id, played_at, seconds_played) VALUES (23, 1, 16, TO_DATE('2026-09-29 17:00', 'YYYY-MM-DD HH24:MI'), 176);
INSERT INTO Play_History (play_id, user_id, song_id, played_at, seconds_played) VALUES (24, 5, 44, TO_DATE('2026-09-30 09:15', 'YYYY-MM-DD HH24:MI'), 150);
INSERT INTO Play_History (play_id, user_id, song_id, played_at, seconds_played) VALUES (25, 1, 22, TO_DATE('2026-10-01 22:05', 'YYYY-MM-DD HH24:MI'), 200);
INSERT INTO Play_History (play_id, user_id, song_id, played_at, seconds_played) VALUES (26, 1, 26, TO_DATE('2026-10-03 23:10', 'YYYY-MM-DD HH24:MI'), 194);
INSERT INTO Play_History (play_id, user_id, song_id, played_at, seconds_played) VALUES (27, 8, 43, TO_DATE('2026-10-02 09:00', 'YYYY-MM-DD HH24:MI'), 214);
INSERT INTO Play_History (play_id, user_id, song_id, played_at, seconds_played) VALUES (28, 8, 46, TO_DATE('2026-10-02 09:05', 'YYYY-MM-DD HH24:MI'), 213);
INSERT INTO Play_History (play_id, user_id, song_id, played_at, seconds_played) VALUES (29, 4, 5, TO_DATE('2026-10-03 20:00', 'YYYY-MM-DD HH24:MI'), 248);
INSERT INTO Play_History (play_id, user_id, song_id, played_at, seconds_played) VALUES (30, 4, 34, TO_DATE('2026-10-03 20:05', 'YYYY-MM-DD HH24:MI'), 280);
INSERT INTO Play_History (play_id, user_id, song_id, played_at, seconds_played) VALUES (31, 2, 1, TO_DATE('2026-10-06 19:00', 'YYYY-MM-DD HH24:MI'), 262);
INSERT INTO Play_History (play_id, user_id, song_id, played_at, seconds_played) VALUES (32, 2, 10, TO_DATE('2026-10-07 18:30', 'YYYY-MM-DD HH24:MI'), 230);
INSERT INTO Play_History (play_id, user_id, song_id, played_at, seconds_played) VALUES (33, 7, 15, TO_DATE('2026-10-09 21:00', 'YYYY-MM-DD HH24:MI'), 245);
INSERT INTO Play_History (play_id, user_id, song_id, played_at, seconds_played) VALUES (34, 7, 61, TO_DATE('2026-10-09 21:05', 'YYYY-MM-DD HH24:MI'), 200);
INSERT INTO Play_History (play_id, user_id, song_id, played_at, seconds_played) VALUES (35, 6, 70, TO_DATE('2026-10-11 15:00', 'YYYY-MM-DD HH24:MI'), 244);
INSERT INTO Play_History (play_id, user_id, song_id, played_at, seconds_played) VALUES (36, 6, 36, TO_DATE('2026-10-11 15:05', 'YYYY-MM-DD HH24:MI'), 233);
INSERT INTO Play_History (play_id, user_id, song_id, played_at, seconds_played) VALUES (37, 10, 47, TO_DATE('2026-10-13 23:30', 'YYYY-MM-DD HH24:MI'), 165);
INSERT INTO Play_History (play_id, user_id, song_id, played_at, seconds_played) VALUES (38, 10, 48, TO_DATE('2026-10-14 00:10', 'YYYY-MM-DD HH24:MI'), 186);
INSERT INTO Play_History (play_id, user_id, song_id, played_at, seconds_played) VALUES (39, 11, 52, TO_DATE('2026-10-15 19:45', 'YYYY-MM-DD HH24:MI'), 185);
INSERT INTO Play_History (play_id, user_id, song_id, played_at, seconds_played) VALUES (40, 1, 4, TO_DATE('2026-10-16 08:20', 'YYYY-MM-DD HH24:MI'), 268);
INSERT INTO Play_History (play_id, user_id, song_id, played_at, seconds_played) VALUES (41, 4, 6, TO_DATE('2026-10-17 22:00', 'YYYY-MM-DD HH24:MI'), 245);
INSERT INTO Play_History (play_id, user_id, song_id, played_at, seconds_played) VALUES (42, 7, 18, TO_DATE('2026-10-18 20:10', 'YYYY-MM-DD HH24:MI'), 178);
INSERT INTO Play_History (play_id, user_id, song_id, played_at, seconds_played) VALUES (43, 2, 50, TO_DATE('2026-10-19 18:00', 'YYYY-MM-DD HH24:MI'), 203);
INSERT INTO Play_History (play_id, user_id, song_id, played_at, seconds_played) VALUES (44, 8, 68, TO_DATE('2026-10-19 10:00', 'YYYY-MM-DD HH24:MI'), 172);
INSERT INTO Play_History (play_id, user_id, song_id, played_at, seconds_played) VALUES (45, 6, 38, TO_DATE('2026-10-20 11:30', 'YYYY-MM-DD HH24:MI'), 258);

-- play_count on Songs must match the plays loaded above
UPDATE Songs s SET play_count = (SELECT COUNT(*) FROM Play_History p WHERE p.song_id = s.song_id);

-- ---------- Playlists (11) ----------
INSERT INTO Playlists (playlist_id, user_id, name, created_on) VALUES (1, 1, 'Late Night Rides', DATE '2026-08-12');
INSERT INTO Playlists (playlist_id, user_id, name, created_on) VALUES (2, 1, 'Bounty Hunting Mix', DATE '2026-09-07');
INSERT INTO Playlists (playlist_id, user_id, name, created_on) VALUES (3, 2, 'Basic Favourites', DATE '2026-10-06');
INSERT INTO Playlists (playlist_id, user_id, name, created_on) VALUES (4, 2, 'Rainy Day Reading', DATE '2026-10-07');
INSERT INTO Playlists (playlist_id, user_id, name, created_on) VALUES (5, 4, 'Campfire Classics', DATE '2026-10-03');
INSERT INTO Playlists (playlist_id, user_id, name, created_on) VALUES (6, 6, 'Family Road Trip', DATE '2026-10-11');
INSERT INTO Playlists (playlist_id, user_id, name, created_on) VALUES (7, 7, 'Guitar by the Fire', DATE '2026-10-09');
INSERT INTO Playlists (playlist_id, user_id, name, created_on) VALUES (8, 8, 'Focus', DATE '2026-10-02');
INSERT INTO Playlists (playlist_id, user_id, name, created_on) VALUES (9, 10, 'Chill Indie', DATE '2026-10-13');
INSERT INTO Playlists (playlist_id, user_id, name, created_on) VALUES (10, 11, 'Pop Party', DATE '2026-09-27');
INSERT INTO Playlists (playlist_id, user_id, name, created_on) VALUES (11, 3, 'Old Favourites', DATE '2026-09-20');

-- ---------- Playlist_Songs ----------
INSERT INTO Playlist_Songs (playlist_id, song_id, added_on) VALUES (1, 22, DATE '2026-08-12');
INSERT INTO Playlist_Songs (playlist_id, song_id, added_on) VALUES (1, 23, DATE '2026-08-12');
INSERT INTO Playlist_Songs (playlist_id, song_id, added_on) VALUES (1, 24, DATE '2026-08-12');
INSERT INTO Playlist_Songs (playlist_id, song_id, added_on) VALUES (1, 26, DATE '2026-08-12');
INSERT INTO Playlist_Songs (playlist_id, song_id, added_on) VALUES (2, 15, DATE '2026-09-07');
INSERT INTO Playlist_Songs (playlist_id, song_id, added_on) VALUES (2, 57, DATE '2026-09-07');
INSERT INTO Playlist_Songs (playlist_id, song_id, added_on) VALUES (2, 58, DATE '2026-09-07');
INSERT INTO Playlist_Songs (playlist_id, song_id, added_on) VALUES (2, 60, DATE '2026-09-07');
INSERT INTO Playlist_Songs (playlist_id, song_id, added_on) VALUES (4, 30, DATE '2026-10-07');
INSERT INTO Playlist_Songs (playlist_id, song_id, added_on) VALUES (4, 43, DATE '2026-10-07');
INSERT INTO Playlist_Songs (playlist_id, song_id, added_on) VALUES (4, 46, DATE '2026-10-07');
INSERT INTO Playlist_Songs (playlist_id, song_id, added_on) VALUES (5, 1, DATE '2026-10-03');
INSERT INTO Playlist_Songs (playlist_id, song_id, added_on) VALUES (5, 2, DATE '2026-10-03');
INSERT INTO Playlist_Songs (playlist_id, song_id, added_on) VALUES (5, 5, DATE '2026-10-03');
INSERT INTO Playlist_Songs (playlist_id, song_id, added_on) VALUES (5, 29, DATE '2026-10-03');
INSERT INTO Playlist_Songs (playlist_id, song_id, added_on) VALUES (5, 34, DATE '2026-10-03');
INSERT INTO Playlist_Songs (playlist_id, song_id, added_on) VALUES (6, 64, DATE '2026-10-11');
INSERT INTO Playlist_Songs (playlist_id, song_id, added_on) VALUES (6, 65, DATE '2026-10-11');
INSERT INTO Playlist_Songs (playlist_id, song_id, added_on) VALUES (6, 70, DATE '2026-10-11');
INSERT INTO Playlist_Songs (playlist_id, song_id, added_on) VALUES (7, 15, DATE '2026-10-09');
INSERT INTO Playlist_Songs (playlist_id, song_id, added_on) VALUES (7, 16, DATE '2026-10-09');
INSERT INTO Playlist_Songs (playlist_id, song_id, added_on) VALUES (7, 57, DATE '2026-10-09');
INSERT INTO Playlist_Songs (playlist_id, song_id, added_on) VALUES (7, 61, DATE '2026-10-09');
INSERT INTO Playlist_Songs (playlist_id, song_id, added_on) VALUES (8, 43, DATE '2026-10-02');
INSERT INTO Playlist_Songs (playlist_id, song_id, added_on) VALUES (8, 46, DATE '2026-10-02');
INSERT INTO Playlist_Songs (playlist_id, song_id, added_on) VALUES (8, 47, DATE '2026-10-02');
INSERT INTO Playlist_Songs (playlist_id, song_id, added_on) VALUES (9, 43, DATE '2026-10-13');
INSERT INTO Playlist_Songs (playlist_id, song_id, added_on) VALUES (9, 44, DATE '2026-10-13');
INSERT INTO Playlist_Songs (playlist_id, song_id, added_on) VALUES (9, 47, DATE '2026-10-13');
INSERT INTO Playlist_Songs (playlist_id, song_id, added_on) VALUES (9, 48, DATE '2026-10-13');
INSERT INTO Playlist_Songs (playlist_id, song_id, added_on) VALUES (10, 8, DATE '2026-09-27');
INSERT INTO Playlist_Songs (playlist_id, song_id, added_on) VALUES (10, 36, DATE '2026-09-27');
INSERT INTO Playlist_Songs (playlist_id, song_id, added_on) VALUES (10, 50, DATE '2026-09-27');
INSERT INTO Playlist_Songs (playlist_id, song_id, added_on) VALUES (10, 51, DATE '2026-09-27');
INSERT INTO Playlist_Songs (playlist_id, song_id, added_on) VALUES (11, 65, DATE '2026-09-20');
INSERT INTO Playlist_Songs (playlist_id, song_id, added_on) VALUES (11, 66, DATE '2026-09-20');
-- Mary-Beth's 'Basic Favourites' playlist is filled to the Basic plan limit of 50 songs,
-- so the playlist-limit trigger can be demonstrated.
INSERT INTO Playlist_Songs (playlist_id, song_id, added_on)
  SELECT 3, song_id, DATE '2026-10-06' FROM Songs WHERE song_id <= 50;

-- ---------- Royalty_Payments: August and September already paid ----------
-- Calculated from the plays above: streams x the artist's rate per stream.
INSERT INTO Royalty_Payments (artist_id, period_month, total_streams, amount, paid_on)
  SELECT s.artist_id, DATE '2026-08-01', COUNT(*), ROUND(COUNT(*) * a.royalty_per_stream, 2), DATE '2026-09-01'
  FROM   Play_History p JOIN Songs s ON s.song_id = p.song_id JOIN Artists a ON a.artist_id = s.artist_id
  WHERE  p.played_at >= DATE '2026-08-01' AND p.played_at < DATE '2026-09-01'
  GROUP  BY s.artist_id, a.royalty_per_stream;

INSERT INTO Royalty_Payments (artist_id, period_month, total_streams, amount, paid_on)
  SELECT s.artist_id, DATE '2026-09-01', COUNT(*), ROUND(COUNT(*) * a.royalty_per_stream, 2), DATE '2026-10-01'
  FROM   Play_History p JOIN Songs s ON s.song_id = p.song_id JOIN Artists a ON a.artist_id = s.artist_id
  WHERE  p.played_at >= DATE '2026-09-01' AND p.played_at < DATE '2026-10-01'
  GROUP  BY s.artist_id, a.royalty_per_stream;

-- ---------- Move the ID counters past the IDs used above ----------
ALTER TABLE Users            MODIFY user_id     GENERATED BY DEFAULT AS IDENTITY (START WITH LIMIT VALUE);
ALTER TABLE Subscriptions    MODIFY sub_id      GENERATED BY DEFAULT AS IDENTITY (START WITH LIMIT VALUE);
ALTER TABLE Artists          MODIFY artist_id   GENERATED BY DEFAULT AS IDENTITY (START WITH LIMIT VALUE);
ALTER TABLE Songs            MODIFY song_id     GENERATED BY DEFAULT AS IDENTITY (START WITH LIMIT VALUE);
ALTER TABLE Play_History     MODIFY play_id     GENERATED BY DEFAULT AS IDENTITY (START WITH LIMIT VALUE);
ALTER TABLE Playlists        MODIFY playlist_id GENERATED BY DEFAULT AS IDENTITY (START WITH LIMIT VALUE);

COMMIT;
SET FEEDBACK ON

-- ---------- Check: rows in every table ----------
SELECT 'Users' AS table_name, COUNT(*) AS rows_loaded FROM Users
UNION ALL SELECT 'Subscriptions',    COUNT(*) FROM Subscriptions
UNION ALL SELECT 'Artists',          COUNT(*) FROM Artists
UNION ALL SELECT 'Songs',            COUNT(*) FROM Songs
UNION ALL SELECT 'Play_History',     COUNT(*) FROM Play_History
UNION ALL SELECT 'Royalty_Payments', COUNT(*) FROM Royalty_Payments
UNION ALL SELECT 'Playlists',        COUNT(*) FROM Playlists
UNION ALL SELECT 'Playlist_Songs',   COUNT(*) FROM Playlist_Songs;
