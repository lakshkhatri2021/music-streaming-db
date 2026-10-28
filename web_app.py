"""
Music Streaming Platform - web application
BCSE302L Database Systems course project

A browser front end for the Oracle database. Every button runs real SQL or
PL/SQL against Oracle, and after each action a "Behind the scenes" panel shows
the operation, the tables, the component that ran, how the database changed
and the result.

Install once (inside the venv):   pip install streamlit oracledb
Run:                              streamlit run web_app.py
"""
import os
from datetime import date, datetime

import pandas as pd
import streamlit as st

try:
    import oracledb
except ImportError as e:
    st.error(f"Could not load python-oracledb ({e}). In the terminal run:  "
             "source venv/bin/activate && pip install oracledb   then start the app with:  "
             "python -m streamlit run web_app.py")
    st.stop()

DB_USER = os.environ.get("MUSIC_DB_USER", "music")
DB_PASSWORD = os.environ.get("MUSIC_DB_PASSWORD", "music123")
DB_DSN = os.environ.get("MUSIC_DB_DSN", "localhost:1521/FREEPDB1")

PLANS = {
    "Basic": (99, "Playlists limited to 50 songs"),
    "Premium": (199, "Unlimited playlist size"),
    "Family": (299, "Unlimited playlist size for the whole household"),
}

st.set_page_config(page_title="Music Streaming Platform", page_icon="🎵", layout="wide")


# =========================================================== database layer
@st.cache_resource
def get_conn():
    conn = oracledb.connect(user=DB_USER, password=DB_PASSWORD, dsn=DB_DSN)
    conn.cursor().callproc("dbms_output.enable", [None])
    return conn


def df(sql, **params):
    """Run a SELECT and return the rows as a DataFrame with lower-case column names."""
    cur = get_conn().cursor()
    cur.execute(sql, params)
    cols = [d[0].lower() for d in cur.description]
    return pd.DataFrame(cur.fetchall(), columns=cols)


def scalar(sql, **params):
    cur = get_conn().cursor()
    cur.execute(sql, params)
    row = cur.fetchone()
    return row[0] if row else None


def execute(sql, **params):
    """Run INSERT / UPDATE / DELETE and commit. Returns rows affected."""
    conn = get_conn()
    cur = conn.cursor()
    try:
        cur.execute(sql, params)
        conn.commit()
        return cur.rowcount
    except oracledb.DatabaseError:
        conn.rollback()
        raise


def insert_returning(sql, **params):
    """INSERT ... RETURNING id INTO :new_id, commit, return the new id."""
    conn = get_conn()
    cur = conn.cursor()
    new_id = cur.var(int)
    try:
        cur.execute(sql, {**params, "new_id": new_id})
        conn.commit()
        return new_id.getvalue()[0]
    except oracledb.DatabaseError:
        conn.rollback()
        raise


def call_proc(name, args):
    """Call a stored procedure and return what it printed with DBMS_OUTPUT."""
    conn = get_conn()
    cur = conn.cursor()
    cur.callproc(name, args)
    lines, line, status = [], cur.var(str), cur.var(int)
    while True:
        cur.callproc("dbms_output.get_line", (line, status))
        if status.getvalue() != 0:
            break
        lines.append(line.getvalue() or "")
    return lines


def friendly_error(e):
    err = e.args[0]
    code = getattr(err, "code", 0)
    msg = str(getattr(err, "message", err)).split("\n")[0]
    if 20001 <= code <= 20099:
        return f"Blocked by the database (ORA-{code}): {msg.split(': ', 1)[-1]}"
    names = {1: "UNIQUE / PRIMARY KEY constraint: that value already exists",
             2291: "FOREIGN KEY constraint: that ID does not exist",
             2292: "FOREIGN KEY constraint: other rows still depend on this one",
             2290: "CHECK constraint: value not allowed",
             1400: "NOT NULL constraint: a required value is missing"}
    if code in names:
        return f"Rejected by the database (ORA-{code:05d}). {names[code]}"
    return f"Database error: {msg}"


# =========================================================== small helpers
def mmss(seconds):
    seconds = int(seconds or 0)
    return f"{seconds // 60}:{seconds % 60:02d}"


def show_table(frame, **kwargs):
    frame = frame.copy()
    for c in frame.columns:
        if pd.api.types.is_datetime64_any_dtype(frame[c]):
            frame[c] = frame[c].dt.strftime("%d-%b-%Y")
    st.dataframe(frame, hide_index=True, **kwargs)


def flash(kind, message, operation, tables, component, effect, sql=None, output=None):
    """Remember the result of an action so it shows after the page refreshes."""
    st.session_state.flash = dict(kind=kind, message=message, operation=operation, tables=tables,
                                  component=component, effect=effect, sql=sql, output=output)


def render_flash():
    f = st.session_state.pop("flash", None)
    if not f:
        return
    (st.success if f["kind"] == "success" else st.error)(f["message"])
    with st.expander("Behind the scenes", expanded=True):
        st.table(pd.DataFrame({
            "Question": ["What operation was performed?", "Which tables were involved?",
                         "Which SQL / PL/SQL component ran?", "How was the database affected?"],
            "Answer": [f["operation"], f["tables"], f["component"], f["effect"]],
        }).set_index("Question"))
        if f.get("output"):
            st.caption("Output from the PL/SQL code (DBMS_OUTPUT)")
            st.code("\n".join(f["output"]), language="text")
        if f.get("sql"):
            st.caption("SQL sent to Oracle")
            st.code(f["sql"].strip(), language="sql")


def user_status(uid):
    row = df("""SELECT s.plan_name, s.end_date
                FROM   Subscriptions s
                WHERE  s.user_id = :u AND s.status = 'Active'
                AND    TRUNC(SYSDATE) BETWEEN s.start_date AND s.end_date""", u=uid)
    if row.empty:
        return None, None
    return row.iloc[0]["plan_name"], row.iloc[0]["end_date"]


# =========================================================== pages
def page_listen(uid, uname):
    st.header("Listen")
    plan, end = user_status(uid)
    if plan:
        st.caption(f"{uname} is on **{plan}** until {pd.Timestamp(end):%d %b %Y}.")
    else:
        st.caption(f"{uname} has **no active subscription**, so the database will block any play.")

    c1, c2 = st.columns([3, 1])
    term = c1.text_input("Search songs or artists", placeholder="e.g. creep, taylor, indie")
    genres = ["All"] + df("SELECT DISTINCT genre FROM Songs ORDER BY genre")["genre"].tolist()
    genre = c2.selectbox("Genre", genres)

    songs = df("""SELECT s.song_id, s.title, a.name AS artist, s.album_title, s.genre,
                         s.duration_sec, s.play_count
                  FROM   Songs s JOIN Artists a ON a.artist_id = s.artist_id
                  WHERE  (:t IS NULL OR LOWER(s.title) LIKE '%' || LOWER(:t) || '%'
                                     OR LOWER(a.name)  LIKE '%' || LOWER(:t) || '%'
                                     OR LOWER(s.genre) LIKE '%' || LOWER(:t) || '%')
                  AND    (:g = 'All' OR s.genre = :g)
                  ORDER  BY s.play_count DESC, s.title""", t=term.strip() or None, g=genre)
    st.caption(f"{len(songs)} songs")

    head = st.columns([4, 3, 1.4, 1, 1, 1.2])
    for col, label in zip(head, ["Song", "Album", "Genre", "Length", "Plays", ""]):
        col.markdown(f"**{label}**")
    for s in songs.itertuples():
        c = st.columns([4, 3, 1.4, 1, 1, 1.2])
        c[0].write(f"{s.title}  \n:gray[{s.artist}]")
        c[1].write(s.album_title or "")
        c[2].write(s.genre or "")
        c[3].write(mmss(s.duration_sec))
        c[4].write(str(s.play_count))
        if c[5].button("Play", key=f"play_{s.song_id}"):
            play(uid, uname, s)

    st.subheader(f"Recently played by {uname}")
    recent = df("""SELECT s.title, a.name AS artist, p.played_at, p.seconds_played
                   FROM   Play_History p JOIN Songs s ON s.song_id = p.song_id
                   JOIN   Artists a ON a.artist_id = s.artist_id
                   WHERE  p.user_id = :u ORDER BY p.played_at DESC FETCH FIRST 5 ROWS ONLY""", u=uid)
    if recent.empty:
        st.caption("Nothing played yet.")
    else:
        recent["played_at"] = pd.to_datetime(recent["played_at"]).dt.strftime("%d-%b-%Y %H:%M")
        show_table(recent)


def play(uid, uname, s):
    sql = """INSERT INTO Play_History (user_id, song_id, seconds_played)
VALUES (:user_id, :song_id, :seconds)"""
    try:
        execute(sql, user_id=uid, song_id=int(s.song_id), seconds=int(s.duration_sec))
        after = scalar("SELECT play_count FROM Songs WHERE song_id = :s", s=int(s.song_id))
        flash("success", f"Now playing {s.title} by {s.artist}. Play count went from {s.play_count} to {after}.",
              f"{uname} plays '{s.title}'", "Play_History, Subscriptions, Songs",
              "TRIGGER trg_check_play (calls FUNCTION is_subscription_active) allowed the insert; "
              "TRIGGER trg_update_play_count then ran",
              f"New row in Play_History; Songs.play_count for '{s.title}' increased by 1", sql=sql)
    except oracledb.DatabaseError as e:
        flash("error", friendly_error(e), f"{uname} tries to play '{s.title}'", "Play_History, Subscriptions",
              "TRIGGER trg_check_play (calls FUNCTION is_subscription_active) rejected the insert",
              "Nothing changed. The trigger raised an error, so the insert was rolled back", sql=sql)
    st.rerun()


def page_subscription(uid, uname):
    st.header("Subscription")
    plan, end = user_status(uid)
    if plan:
        st.success(f"{uname} is on {plan} until {pd.Timestamp(end):%d %b %Y}.")
    else:
        st.warning(f"{uname} has no active subscription.")

    st.subheader("Choose a plan")
    cols = st.columns(3)
    for col, (name, (price, note)) in zip(cols, PLANS.items()):
        with col.container(border=True):
            st.markdown(f"### {name}")
            st.markdown(f"**Rs {price}** / month")
            st.caption(note)
            if st.button(f"Switch to {name}" if plan else f"Subscribe to {name}", key=f"sub_{name}",
                         disabled=(plan == name)):
                try:
                    out = call_proc("subscribe_user", [uid, name])
                    flash("success", f"{uname} is now on {name}.", f"{uname} subscribes to {name}",
                          "Users, Subscriptions", "PROCEDURE subscribe_user",
                          "Old Active subscription set to Cancelled (or Expired); new Active row inserted for one month",
                          sql=f"BEGIN subscribe_user({uid}, '{name}'); END;", output=out)
                except oracledb.DatabaseError as e:
                    flash("error", friendly_error(e), f"{uname} subscribes to {name}", "Users, Subscriptions",
                          "PROCEDURE subscribe_user", "Nothing changed (the procedure rolled back)")
                st.rerun()

    st.subheader("Subscription history")
    show_table(df("""SELECT sub_id, plan_name, price_paid, start_date, end_date, status
                     FROM Subscriptions WHERE user_id = :u ORDER BY start_date DESC, sub_id DESC""", u=uid))


def page_playlists(uid, uname):
    st.header("Playlists")
    mine = df("""SELECT p.playlist_id, p.name,
                        (SELECT COUNT(*) FROM Playlist_Songs ps WHERE ps.playlist_id = p.playlist_id) AS songs,
                        get_playlist_duration(p.playlist_id) AS secs, p.created_on
                 FROM   Playlists p WHERE p.user_id = :u ORDER BY p.created_on, p.playlist_id""", u=uid)

    with st.form("new_playlist", clear_on_submit=True):
        c1, c2 = st.columns([4, 1])
        name = c1.text_input("New playlist name", placeholder="e.g. Late Night Drive")
        if c2.form_submit_button("Create playlist") and name.strip():
            sql = "INSERT INTO Playlists (user_id, name) VALUES (:u, :n) RETURNING playlist_id INTO :new_id"
            try:
                pid = insert_returning(sql, u=uid, n=name.strip())
                flash("success", f"Created playlist '{name.strip()}' (ID {pid}).", f"{uname} creates a playlist",
                      "Playlists", "INSERT with FOREIGN KEY to Users and DEFAULT created_on",
                      "One new row in Playlists", sql=sql)
            except oracledb.DatabaseError as e:
                flash("error", friendly_error(e), f"{uname} creates a playlist", "Playlists", "INSERT",
                      "Nothing changed", sql=sql)
            st.rerun()

    if mine.empty:
        st.info(f"{uname} has no playlists yet.")
        return

    view = mine.copy()
    view["length"] = view["secs"].apply(mmss)
    show_table(view[["playlist_id", "name", "songs", "length", "created_on"]])
    st.caption("Length comes from FUNCTION get_playlist_duration.")

    labels = {f"{r.name} ({r.songs} songs)": int(r.playlist_id) for r in mine.itertuples()}
    pid = labels[st.selectbox("Open a playlist", list(labels))]
    pname = mine.loc[mine.playlist_id == pid, "name"].iloc[0]

    songs = df("""SELECT s.song_id, s.title, a.name AS artist, s.duration_sec
                  FROM Playlist_Songs ps JOIN Songs s ON s.song_id = ps.song_id
                  JOIN Artists a ON a.artist_id = s.artist_id
                  WHERE ps.playlist_id = :p ORDER BY ps.added_on, s.title""", p=pid)
    c1, c2 = st.columns([3, 2])
    with c1:
        st.subheader(pname)
        if songs.empty:
            st.caption("No songs yet.")
        else:
            songs["length"] = songs["duration_sec"].apply(mmss)
            show_table(songs[["title", "artist", "length"]], height=min(400, 38 + 35 * len(songs)))
    with c2:
        st.subheader("Add a song")
        options = df("""SELECT s.song_id, s.title || ' - ' || a.name AS label
                        FROM Songs s JOIN Artists a ON a.artist_id = s.artist_id
                        WHERE s.song_id NOT IN (SELECT song_id FROM Playlist_Songs WHERE playlist_id = :p)
                        ORDER BY s.title""", p=pid)
        if not options.empty:
            choice = st.selectbox("Song", options["label"].tolist())
            if st.button("Add to playlist"):
                sid = int(options.loc[options.label == choice, "song_id"].iloc[0])
                sql = "INSERT INTO Playlist_Songs (playlist_id, song_id) VALUES (:p, :s)"
                try:
                    execute(sql, p=pid, s=sid)
                    flash("success", f"Added {choice} to '{pname}'.", f"{uname} adds a song to '{pname}'",
                          "Playlist_Songs, Playlists, Subscriptions",
                          "TRIGGER trg_playlist_limit (calls FUNCTION is_subscription_active) allowed the insert",
                          "One new row in Playlist_Songs", sql=sql)
                except oracledb.DatabaseError as e:
                    flash("error", friendly_error(e), f"{uname} adds a song to '{pname}'",
                          "Playlist_Songs, Playlists, Subscriptions",
                          "TRIGGER trg_playlist_limit (checks the subscription and the Basic plan limit of 50 songs)",
                          "Nothing changed. The trigger raised an error, so the insert was rolled back", sql=sql)
                st.rerun()
        st.divider()
        if st.button(f"Delete '{pname}'", type="secondary"):
            n = scalar("SELECT COUNT(*) FROM Playlist_Songs WHERE playlist_id = :p", p=pid)
            sql = "DELETE FROM Playlists WHERE playlist_id = :p"
            execute(sql, p=pid)
            flash("success", f"Deleted '{pname}'.", f"{uname} deletes a playlist", "Playlists, Playlist_Songs",
                  "DELETE with ON DELETE CASCADE on Playlist_Songs",
                  f"1 row removed from Playlists and {n} rows removed from Playlist_Songs automatically", sql=sql)
            st.rerun()


def month_options():
    months, d = [], date(2026, 8, 1)
    today = date.today().replace(day=1)
    while d <= max(today, date(2026, 10, 1)):
        months.append(d)
        d = date(d.year + (d.month // 12), d.month % 12 + 1, 1)
    return months[::-1]


def page_royalties():
    st.header("Royalties (admin)")
    st.caption("Artists earn their rate per stream for every play in the month. "
               "The month-end run uses a CURSOR over all artists.")
    months = month_options()
    month = st.selectbox("Month", months, format_func=lambda d: d.strftime("%B %Y"))
    if st.button(f"Run month-end royalties for {month:%B %Y}", type="primary"):
        try:
            out = call_proc("run_monthly_royalties", [datetime(month.year, month.month, 1)])
            flash("success", f"Royalty run for {month:%B %Y} finished.", f"Month-end royalty run for {month:%B %Y}",
                  "Artists, Songs, Play_History, Royalty_Payments",
                  "PROCEDURE run_monthly_royalties (explicit CURSOR over Artists) calling PROCEDURE calc_artist_royalty for each",
                  "One Royalty_Payments row per artist with streams. Artists already paid for the month are skipped "
                  "because of UNIQUE (artist_id, period_month)",
                  sql=f"BEGIN run_monthly_royalties(DATE '{month:%Y-%m-%d}'); END;", output=out)
        except oracledb.DatabaseError as e:
            flash("error", friendly_error(e), "Month-end royalty run", "Royalty_Payments",
                  "PROCEDURE run_monthly_royalties", "Nothing changed")
        st.rerun()

    paid = df("""SELECT a.name AS artist, r.total_streams, a.royalty_per_stream AS rate_now, r.amount, r.paid_on
                 FROM Royalty_Payments r JOIN Artists a ON a.artist_id = r.artist_id
                 WHERE r.period_month = :m ORDER BY r.amount DESC, a.name""",
              m=datetime(month.year, month.month, 1))
    c1, c2, c3 = st.columns(3)
    c1.metric("Artists paid", len(paid))
    c2.metric("Streams paid", int(paid["total_streams"].sum()) if not paid.empty else 0)
    c3.metric("Total paid", f"Rs {paid['amount'].sum():.2f}" if not paid.empty else "Rs 0.00")
    if paid.empty:
        st.info(f"No royalties paid yet for {month:%B %Y}. Press the button to run them.")
    else:
        show_table(paid)
        st.bar_chart(paid.set_index("artist")["amount"], y_label="Rs paid", x_label="Artist")

    st.subheader("All months")
    show_table(df("""SELECT TO_CHAR(period_month, 'Mon YYYY') AS month, COUNT(*) AS artists_paid,
                            SUM(total_streams) AS streams, SUM(amount) AS total_rs
                     FROM Royalty_Payments GROUP BY period_month ORDER BY period_month"""))


REPORTS = {
    "Top 10 most played songs": ("""SELECT s.title, a.name AS artist, s.genre, s.play_count
FROM   Songs s JOIN Artists a ON a.artist_id = s.artist_id
ORDER  BY s.play_count DESC, s.title
FETCH  FIRST 10 ROWS ONLY""", ("title", "play_count")),
    "Revenue per plan": ("""SELECT plan_name, COUNT(*) AS subscriptions, SUM(price_paid) AS revenue_rs
FROM   Subscriptions
GROUP  BY plan_name
ORDER  BY revenue_rs DESC""", ("plan_name", "revenue_rs")),
    "Streams per artist per month": ("""SELECT a.name AS artist,
       SUM(CASE WHEN TRUNC(p.played_at, 'MM') = DATE '2026-08-01' THEN 1 ELSE 0 END) AS aug,
       SUM(CASE WHEN TRUNC(p.played_at, 'MM') = DATE '2026-09-01' THEN 1 ELSE 0 END) AS sep,
       SUM(CASE WHEN TRUNC(p.played_at, 'MM') = DATE '2026-10-01' THEN 1 ELSE 0 END) AS oct,
       COUNT(*) AS total
FROM   Play_History p
JOIN   Songs s   ON s.song_id   = p.song_id
JOIN   Artists a ON a.artist_id = s.artist_id
GROUP  BY a.name
ORDER  BY total DESC""", ("artist", "total")),
    "Listening per genre": ("""SELECT s.genre, COUNT(*) AS plays, ROUND(AVG(p.seconds_played)) AS avg_seconds
FROM   Play_History p JOIN Songs s ON s.song_id = p.song_id
GROUP  BY s.genre
ORDER  BY plays DESC""", ("genre", "plays")),
    "Total royalties per artist": ("""SELECT a.name AS artist, SUM(r.total_streams) AS streams, SUM(r.amount) AS total_paid_rs
FROM   Royalty_Payments r JOIN Artists a ON a.artist_id = r.artist_id
GROUP  BY a.name
ORDER  BY total_paid_rs DESC""", ("artist", "total_paid_rs")),
    "Most played genre in each country": ("""SELECT country, genre, plays
FROM  (SELECT u.country, s.genre, COUNT(*) AS plays,
              RANK() OVER (PARTITION BY u.country ORDER BY COUNT(*) DESC) AS rnk
       FROM   Play_History p
       JOIN   Users u ON u.user_id = p.user_id
       JOIN   Songs s ON s.song_id = p.song_id
       GROUP  BY u.country, s.genre)
WHERE  rnk = 1
ORDER  BY plays DESC, country""", None),
    "Songs in more than 2 playlists": ("""SELECT s.title, a.name AS artist, COUNT(*) AS in_playlists
FROM   Playlist_Songs ps
JOIN   Songs s   ON s.song_id   = ps.song_id
JOIN   Artists a ON a.artist_id = s.artist_id
GROUP  BY s.title, a.name
HAVING COUNT(*) > 2
ORDER  BY in_playlists DESC, s.title""", ("title", "in_playlists")),
    "Artists nobody streamed this month": ("""SELECT a.artist_id, a.name, a.country
FROM   Artists a
WHERE  NOT EXISTS (SELECT 1
                   FROM   Play_History p JOIN Songs s ON s.song_id = p.song_id
                   WHERE  s.artist_id = a.artist_id
                   AND    p.played_at >= TRUNC(SYSDATE, 'MM'))""", None),
    "Users who never played a song": ("""SELECT u.user_id, u.name, u.join_date
FROM   Users u
LEFT   JOIN Play_History p ON p.user_id = u.user_id
WHERE  p.play_id IS NULL""", None),
    "Subscriptions ending in the next 7 days": ("""SELECT u.name, u.email, s.plan_name, s.end_date
FROM   Subscriptions s JOIN Users u ON u.user_id = s.user_id
WHERE  s.status = 'Active'
AND    s.end_date BETWEEN TRUNC(SYSDATE) AND TRUNC(SYSDATE) + 7
ORDER  BY s.end_date""", None),
}


def page_reports():
    st.header("Reports (admin)")
    name = st.selectbox("Report", list(REPORTS))
    sql, chart = REPORTS[name]
    data = df(sql)
    if data.empty:
        st.info("No rows.")
    else:
        if chart:
            st.bar_chart(data.set_index(chart[0])[chart[1]])
        show_table(data)
    with st.expander("SQL for this report"):
        st.code(sql, language="sql")


def page_users():
    st.header("Users (admin)")
    users = df("""SELECT u.user_id, u.name, u.email, u.country, u.join_date,
                         NVL(s.plan_name, '-') AS plan,
                         CASE WHEN is_subscription_active(u.user_id) = 1 THEN 'Yes' ELSE 'No' END AS can_play,
                         s.end_date
                  FROM   Users u
                  LEFT   JOIN Subscriptions s ON s.user_id = u.user_id AND s.status = 'Active'
                         AND TRUNC(SYSDATE) BETWEEN s.start_date AND s.end_date
                  ORDER  BY u.user_id""")
    show_table(users)
    st.caption("can_play comes from FUNCTION is_subscription_active.")

    c1, c2 = st.columns(2)
    with c1, st.form("register", clear_on_submit=True):
        st.subheader("Register a new user")
        name = st.text_input("Name")
        email = st.text_input("Email")
        country = st.text_input("Country", value="India")
        if st.form_submit_button("Register"):
            sql = """INSERT INTO Users (name, email, country) VALUES (:n, :e, :c)
RETURNING user_id INTO :new_id"""
            try:
                new_id = insert_returning(sql, n=name.strip() or None, e=email.strip() or None, c=country.strip() or None)
                flash("success", f"Registered {name} as user {new_id}.", "Register a new user", "Users",
                      "INSERT with UNIQUE (email), NOT NULL (name, email) and DEFAULT (join_date)",
                      "One new row in Users", sql=sql)
            except oracledb.DatabaseError as e:
                flash("error", friendly_error(e), "Register a new user", "Users",
                      "INSERT checked by UNIQUE and NOT NULL constraints", "Nothing changed", sql=sql)
            st.rerun()
    with c2:
        st.subheader("Delete an account")
        labels = {f"{r.name} (#{r.user_id})": int(r.user_id) for r in users.itertuples()}
        if labels:
            who = st.selectbox("User", list(labels))
            uid = labels[who]
            counts = df("""SELECT (SELECT COUNT(*) FROM Subscriptions WHERE user_id = :u) AS subscriptions,
                                  (SELECT COUNT(*) FROM Play_History  WHERE user_id = :u) AS plays,
                                  (SELECT COUNT(*) FROM Playlists     WHERE user_id = :u) AS playlists
                           FROM dual""", u=uid)
            show_table(counts)
            st.caption("These rows will be removed automatically by ON DELETE CASCADE.")
            if st.button(f"Delete {who}", type="primary"):
                sql = "DELETE FROM Users WHERE user_id = :u"
                c = counts.iloc[0]
                execute(sql, u=uid)
                flash("success", f"Deleted {who}.", "Delete a user account",
                      "Users, Subscriptions, Play_History, Playlists, Playlist_Songs",
                      "DELETE with ON DELETE CASCADE",
                      f"1 user, {c.subscriptions} subscriptions, {c.plays} plays and {c.playlists} playlists removed",
                      sql=sql)
                st.rerun()


# =========================================================== layout
def main():
    try:
        conn = get_conn()
        users = df("SELECT user_id, name FROM Users ORDER BY user_id")
    except oracledb.DatabaseError as e:
        st.error(f"Could not reach Oracle at {DB_DSN} as {DB_USER}. Is the oracle-db container running?\n\n{e}")
        if st.button("Try again"):
            get_conn.clear()
            st.rerun()
        st.stop()

    with st.sidebar:
        st.title("Music Streaming Platform")
        st.caption(f"Oracle {conn.version} | {DB_USER} @ {DB_DSN.split('/')[-1]}")
        ids = [int(i) for i in users["user_id"]]
        names = {int(i): n for i, n in zip(users["user_id"], users["name"])}
        if st.session_state.get("uid") not in ids:
            st.session_state.uid = ids[0]
        uid = st.selectbox("Listening as", ids, key="uid", format_func=lambda i: f"{names[i]} (#{i})")
        uname = names[uid]
        plan, end = user_status(uid)
        if plan:
            st.success(f"{plan} until {pd.Timestamp(end):%d %b %Y}")
        else:
            st.error("No active subscription")
        page = st.radio("Page", ["Listen", "Subscription", "Playlists",
                                 "Royalties (admin)", "Reports (admin)", "Users (admin)"])
        st.divider()
        if st.button("Reconnect to Oracle"):
            get_conn.clear()
            st.rerun()

    render_flash()
    if page == "Listen":
        page_listen(uid, uname)
    elif page == "Subscription":
        page_subscription(uid, uname)
    elif page == "Playlists":
        page_playlists(uid, uname)
    elif page == "Royalties (admin)":
        page_royalties()
    elif page == "Reports (admin)":
        page_reports()
    else:
        page_users()


main()
