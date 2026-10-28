"""
Music Streaming Platform - interactive database application
BCSE302L Database Systems course project

Connects to Oracle with python-oracledb (thin mode, no Oracle client needed)
and runs the platform's transactions through SQL and PL/SQL.

Install once:   pip3 install oracledb
Run:            python3 app.py
"""
import os
import sys
from datetime import date

try:
    import oracledb
except ImportError:
    sys.exit("python-oracledb is not installed. Run:  pip3 install oracledb")

# ------------------------------------------------------------------ settings
DB_USER = os.environ.get("MUSIC_DB_USER", "music")
DB_PASSWORD = os.environ.get("MUSIC_DB_PASSWORD", "music123")
DB_DSN = os.environ.get("MUSIC_DB_DSN", "localhost:1521/FREEPDB1")

LINE = "-" * 70


# ------------------------------------------------------------------ helpers
def connect():
    try:
        conn = oracledb.connect(user=DB_USER, password=DB_PASSWORD, dsn=DB_DSN)
    except oracledb.DatabaseError as e:
        sys.exit(f"Could not connect to {DB_DSN} as {DB_USER}: {e}")
    cur = conn.cursor()
    cur.callproc("dbms_output.enable", [None])   # so procedure messages can be shown
    return conn


def show_dbms_output(conn):
    """Print whatever the PL/SQL code wrote with DBMS_OUTPUT.PUT_LINE."""
    cur = conn.cursor()
    line = cur.var(str)
    status = cur.var(int)
    while True:
        cur.callproc("dbms_output.get_line", (line, status))
        if status.getvalue() != 0:
            break
        print("   " + (line.getvalue() or ""))


def print_rows(cur, rows=None):
    """Print a query result as a simple aligned table."""
    rows = cur.fetchall() if rows is None else rows
    headers = [d[0].lower() for d in cur.description]
    if not rows:
        print("   (no rows)")
        return

    def fmt(v):
        if v is None:
            return ""
        if hasattr(v, "strftime"):
            return v.strftime("%d-%b-%Y")
        if isinstance(v, float):
            return f"{v:.2f}"
        return str(v)

    table = [[fmt(v) for v in r] for r in rows]
    widths = [max(len(h), *(len(r[i]) for r in table)) for i, h in enumerate(headers)]
    print("   " + "  ".join(h.ljust(w) for h, w in zip(headers, widths)))
    print("   " + "  ".join("-" * w for w in widths))
    for r in table:
        print("   " + "  ".join(c.ljust(w) for c, w in zip(r, widths)))


def query(conn, sql, params=None):
    cur = conn.cursor()
    cur.execute(sql, params or {})
    print_rows(cur)


def behind_the_scenes(operation, tables, component, effect):
    """The five things the guidelines ask us to explain for every transaction."""
    print("\n   Behind the scenes")
    print(f"   Operation : {operation}")
    print(f"   Tables    : {tables}")
    print(f"   Component : {component}")
    print(f"   Effect    : {effect}")


def explain_error(e):
    err = e.args[0]
    code = getattr(err, "code", 0)
    msg = str(getattr(err, "message", err)).split("\n")[0]
    if 20001 <= code <= 20099:
        print(f"\n   BLOCKED by the database: {msg.split(': ', 1)[-1]}")
    elif code == 1:
        print("\n   REJECTED: that value already exists (UNIQUE / PRIMARY KEY constraint)")
    elif code == 2291:
        print("\n   REJECTED: that ID does not exist (FOREIGN KEY constraint)")
    elif code == 2290:
        print("\n   REJECTED: value not allowed (CHECK constraint)")
    elif code == 1400:
        print("\n   REJECTED: a required value is missing (NOT NULL constraint)")
    else:
        print(f"\n   Database error: {msg}")


def ask(prompt, cast=str, default=None):
    while True:
        raw = input(f"   {prompt}" + (f" [{default}]" if default is not None else "") + ": ").strip()
        if not raw and default is not None:
            return default
        try:
            return cast(raw)
        except ValueError:
            print("   Please enter a valid value.")


def pick_song(conn):
    term = ask("Search song title")
    cur = conn.cursor()
    cur.execute("""SELECT s.song_id, s.title, a.name AS artist, s.duration_sec, s.play_count
                   FROM   Songs s JOIN Artists a ON a.artist_id = s.artist_id
                   WHERE  LOWER(s.title) LIKE '%' || LOWER(:t) || '%'
                   ORDER  BY s.title FETCH FIRST 10 ROWS ONLY""", t=term)
    rows = cur.fetchall()
    print_rows(cur, rows)
    if not rows:
        return None
    return ask("Song ID", int, rows[0][0])


# ------------------------------------------------------------------ menu actions
def view_users(conn):
    print("\n   Users and their subscription today")
    query(conn, """
        SELECT u.user_id, u.name, u.country,
               NVL(s.plan_name, '-') AS plan,
               CASE WHEN is_subscription_active(u.user_id) = 1 THEN 'Active' ELSE 'No' END AS can_play,
               s.end_date
        FROM   Users u
        LEFT   JOIN Subscriptions s
               ON  s.user_id = u.user_id AND s.status = 'Active'
               AND TRUNC(SYSDATE) BETWEEN s.start_date AND s.end_date
        ORDER  BY u.user_id""")


def register_user(conn):
    name = ask("Name")
    email = ask("Email")
    country = ask("Country", default="India")
    cur = conn.cursor()
    new_id = cur.var(int)
    try:
        cur.execute("""INSERT INTO Users (name, email, country) VALUES (:n, :e, :c)
                       RETURNING user_id INTO :id""", n=name, e=email, c=country, id=new_id)
        conn.commit()
        print(f"\n   Registered {name} with user ID {new_id.getvalue()[0]}")
        behind_the_scenes("Register a new user", "Users",
                          "INSERT with UNIQUE (email), NOT NULL and DEFAULT (join_date) constraints",
                          "One new row in Users")
    except oracledb.DatabaseError as e:
        conn.rollback()
        explain_error(e)


def subscribe(conn):
    view_users(conn)
    uid = ask("User ID", int)
    plan = ask("Plan (Basic Rs 99 / Premium Rs 199 / Family Rs 299)", default="Premium")
    try:
        conn.cursor().callproc("subscribe_user", [uid, plan])
        print()
        show_dbms_output(conn)
        query(conn, """SELECT sub_id, plan_name, price_paid, start_date, end_date, status
                       FROM Subscriptions WHERE user_id = :u ORDER BY sub_id""", {"u": uid})
        behind_the_scenes("Subscribe or change plan", "Users, Subscriptions",
                          "PROCEDURE subscribe_user",
                          "Old Active subscription set to Cancelled/Expired, new Active row inserted")
    except oracledb.DatabaseError as e:
        explain_error(e)


def play_song(conn):
    uid = ask("User ID", int)
    sid = pick_song(conn)
    if sid is None:
        return
    cur = conn.cursor()
    cur.execute("SELECT title, play_count, duration_sec FROM Songs WHERE song_id = :s", s=sid)
    title, before, dur = cur.fetchone()
    try:
        cur.execute("""INSERT INTO Play_History (user_id, song_id, seconds_played)
                       VALUES (:u, :s, :sec)""", u=uid, s=sid, sec=dur)
        conn.commit()
        cur.execute("SELECT play_count FROM Songs WHERE song_id = :s", s=sid)
        after = cur.fetchone()[0]
        print(f"\n   Now playing '{title}'.  Play count: {before} -> {after}")
        behind_the_scenes("Play a song", "Play_History, Subscriptions, Songs",
                          "TRIGGER trg_check_play (uses FUNCTION is_subscription_active), "
                          "TRIGGER trg_update_play_count",
                          "Play recorded in Play_History; Songs.play_count increased by 1")
    except oracledb.DatabaseError as e:
        conn.rollback()
        explain_error(e)
        behind_the_scenes("Play a song", "Play_History, Subscriptions",
                          "TRIGGER trg_check_play (uses FUNCTION is_subscription_active)",
                          "Nothing saved: the trigger rejected the insert")


def create_playlist(conn):
    uid = ask("User ID", int)
    name = ask("Playlist name")
    cur = conn.cursor()
    new_id = cur.var(int)
    try:
        cur.execute("""INSERT INTO Playlists (user_id, name) VALUES (:u, :n)
                       RETURNING playlist_id INTO :id""", u=uid, n=name, id=new_id)
        conn.commit()
        print(f"\n   Created playlist '{name}' with ID {new_id.getvalue()[0]}")
        behind_the_scenes("Create a playlist", "Playlists", "INSERT with FOREIGN KEY to Users",
                          "One new row in Playlists")
    except oracledb.DatabaseError as e:
        conn.rollback()
        explain_error(e)


def list_playlists(conn):
    query(conn, """SELECT p.playlist_id, p.name AS playlist, u.name AS owner,
                          (SELECT COUNT(*) FROM Playlist_Songs ps WHERE ps.playlist_id = p.playlist_id) AS songs
                   FROM Playlists p JOIN Users u ON u.user_id = p.user_id
                   ORDER BY p.playlist_id""")


def add_to_playlist(conn):
    list_playlists(conn)
    pid = ask("Playlist ID", int)
    sid = pick_song(conn)
    if sid is None:
        return
    try:
        conn.cursor().execute("INSERT INTO Playlist_Songs (playlist_id, song_id) VALUES (:p, :s)",
                              p=pid, s=sid)
        conn.commit()
        print("\n   Song added to the playlist")
        behind_the_scenes("Add a song to a playlist", "Playlist_Songs, Playlists, Subscriptions",
                          "TRIGGER trg_playlist_limit (uses FUNCTION is_subscription_active)",
                          "One new row in Playlist_Songs")
    except oracledb.DatabaseError as e:
        conn.rollback()
        explain_error(e)
        behind_the_scenes("Add a song to a playlist", "Playlist_Songs, Playlists, Subscriptions",
                          "TRIGGER trg_playlist_limit",
                          "Nothing saved: the trigger or a constraint rejected the insert")


def view_playlist(conn):
    list_playlists(conn)
    pid = ask("Playlist ID", int)
    query(conn, """SELECT s.title, a.name AS artist, s.duration_sec
                   FROM Playlist_Songs ps JOIN Songs s ON s.song_id = ps.song_id
                   JOIN Artists a ON a.artist_id = s.artist_id
                   WHERE ps.playlist_id = :p ORDER BY ps.added_on, s.title""", {"p": pid})
    cur = conn.cursor()
    secs = cur.callfunc("get_playlist_duration", int, [pid])
    print(f"\n   Total length: {secs // 60} min {secs % 60} s  (FUNCTION get_playlist_duration)")


def royalty_run(conn):
    month = ask("Month to pay (YYYY-MM)", default=date.today().strftime("%Y-%m"))
    try:
        y, m = (int(x) for x in month.split("-"))
        first = date(y, m, 1)
    except ValueError:
        print("   Use the format YYYY-MM")
        return
    try:
        conn.cursor().callproc("run_monthly_royalties", [first])
        print()
        show_dbms_output(conn)
        behind_the_scenes("Month-end royalty run", "Artists, Songs, Play_History, Royalty_Payments",
                          "PROCEDURE run_monthly_royalties (explicit CURSOR over Artists) "
                          "calling PROCEDURE calc_artist_royalty",
                          "One Royalty_Payments row per artist with streams; "
                          "UNIQUE (artist_id, period_month) stops double payment")
    except oracledb.DatabaseError as e:
        explain_error(e)


def delete_menu(conn):
    print("\n   1. Delete a playlist\n   2. Delete a user account")
    choice = ask("Choose", default="1")
    cur = conn.cursor()
    try:
        if choice == "1":
            list_playlists(conn)
            pid = ask("Playlist ID", int)
            cur.execute("DELETE FROM Playlists WHERE playlist_id = :p", p=pid)
            n = cur.rowcount
            conn.commit()
            print(f"\n   Deleted {n} playlist(s); its songs were removed from Playlist_Songs by ON DELETE CASCADE")
            behind_the_scenes("Delete a playlist", "Playlists, Playlist_Songs",
                              "DELETE with ON DELETE CASCADE", "Playlist and its song links removed")
        else:
            uid = ask("User ID", int)
            cur.execute("""SELECT (SELECT COUNT(*) FROM Subscriptions WHERE user_id = :u),
                                  (SELECT COUNT(*) FROM Play_History  WHERE user_id = :u),
                                  (SELECT COUNT(*) FROM Playlists     WHERE user_id = :u) FROM dual""", u=uid)
            s, p, pl = cur.fetchone()
            cur.execute("DELETE FROM Users WHERE user_id = :u", u=uid)
            n = cur.rowcount
            conn.commit()
            print(f"\n   Deleted {n} user; cascade also removed {s} subscription(s), {p} play(s), {pl} playlist(s)")
            behind_the_scenes("Delete a user account", "Users, Subscriptions, Play_History, Playlists, Playlist_Songs",
                              "DELETE with ON DELETE CASCADE", "User and everything that belongs to them removed")
    except oracledb.DatabaseError as e:
        conn.rollback()
        explain_error(e)


REPORTS = {
    "1": ("Top 10 most played songs", """
        SELECT s.title, a.name AS artist, s.genre, s.play_count
        FROM Songs s JOIN Artists a ON a.artist_id = s.artist_id
        ORDER BY s.play_count DESC, s.title FETCH FIRST 10 ROWS ONLY"""),
    "2": ("Revenue per plan", """
        SELECT plan_name, COUNT(*) AS subscriptions, SUM(price_paid) AS revenue_rs
        FROM Subscriptions GROUP BY plan_name ORDER BY revenue_rs DESC"""),
    "3": ("Royalties paid per artist", """
        SELECT a.name AS artist, SUM(r.total_streams) AS streams, SUM(r.amount) AS total_paid_rs
        FROM Royalty_Payments r JOIN Artists a ON a.artist_id = r.artist_id
        GROUP BY a.name ORDER BY total_paid_rs DESC"""),
    "4": ("Royalty payments by month", """
        SELECT TO_CHAR(r.period_month, 'Mon YYYY') AS month, a.name AS artist, r.total_streams, r.amount
        FROM Royalty_Payments r JOIN Artists a ON a.artist_id = r.artist_id
        ORDER BY r.period_month, r.amount DESC"""),
    "5": ("Listening per genre", """
        SELECT s.genre, COUNT(*) AS plays, ROUND(AVG(p.seconds_played)) AS avg_seconds
        FROM Play_History p JOIN Songs s ON s.song_id = p.song_id
        GROUP BY s.genre ORDER BY plays DESC"""),
    "6": ("Subscriptions ending in the next 7 days", """
        SELECT u.name, u.email, s.plan_name, s.end_date
        FROM Subscriptions s JOIN Users u ON u.user_id = s.user_id
        WHERE s.status = 'Active' AND s.end_date BETWEEN TRUNC(SYSDATE) AND TRUNC(SYSDATE) + 7
        ORDER BY s.end_date"""),
    "7": ("Recent plays", """
        SELECT p.play_id, u.name AS user_name, s.title, p.played_at, p.seconds_played
        FROM Play_History p JOIN Users u ON u.user_id = p.user_id JOIN Songs s ON s.song_id = p.song_id
        ORDER BY p.played_at DESC FETCH FIRST 10 ROWS ONLY"""),
}


def reports(conn):
    for k, (title, _) in REPORTS.items():
        print(f"   {k}. {title}")
    k = ask("Report", default="1")
    if k in REPORTS:
        print(f"\n   {REPORTS[k][0]}")
        query(conn, REPORTS[k][1])


MENU = [
    ("View users and who can play", view_users),
    ("Register a new user", register_user),
    ("Subscribe / change plan", subscribe),
    ("Play a song", play_song),
    ("Create a playlist", create_playlist),
    ("Add a song to a playlist", add_to_playlist),
    ("View a playlist", view_playlist),
    ("Run month-end royalties", royalty_run),
    ("Reports", reports),
    ("Delete a playlist or account", delete_menu),
]


def main():
    conn = connect()
    print(f"\nConnected to Oracle {conn.version} as {DB_USER}")
    while True:
        print("\n" + LINE + "\n   MUSIC STREAMING PLATFORM\n" + LINE)
        for i, (label, _) in enumerate(MENU, 1):
            print(f"   {i:>2}. {label}")
        print("    0. Exit")
        choice = input("\n   Choose an option: ").strip()
        if choice == "0":
            break
        if choice.isdigit() and 1 <= int(choice) <= len(MENU):
            label, action = MENU[int(choice) - 1]
            print("\n" + LINE + f"\n   {label}\n" + LINE)
            try:
                action(conn)
            except (KeyboardInterrupt, EOFError):
                print("\n   Cancelled")
        else:
            print("   Not an option")
    conn.close()
    print("Goodbye")


if __name__ == "__main__":
    main()
