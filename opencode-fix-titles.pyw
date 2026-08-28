"""
OpenCode Session 標題修復工具
雙擊執行：修正標題中錯誤的日期，並補命名仍為 New session 的對話。
時間一律取自 DB 的 session.time_created（毫秒 epoch），不依賴當下時間。
"""
import sqlite3
import os
import re
import json
import tkinter
import tkinter.messagebox
from datetime import datetime, timezone, timedelta

# 設定
DB_PATH = os.path.join(os.environ['USERPROFILE'], '.local', 'share', 'opencode', 'opencode.db')
TITLE_MAX_LEN = 20  # 關鍵字最大長度
TIMEZONE_OFFSET = timedelta(hours=8)  # 台灣時區 UTC+8

DATE_RE = re.compile(r'^(.*) (\d{4}-\d{2}-\d{2} \d{2}:\d{2})$')


def extract_keywords(text, max_len=TITLE_MAX_LEN):
    """從文字中擷取關鍵字（取前 N 個中文字或前 N 個字元）"""
    if not text:
        return None

    text = re.sub(r'^(你好|hi|hello|hey|幫我|請|我想|我要|幫忙| help)[\s,，!！。.]*', '', text, flags=re.IGNORECASE)

    chinese = re.findall(r'[\u4e00-\u9fff]+', text)
    if chinese:
        result = ''
        for seg in chinese:
            if len(result) + len(seg) > max_len:
                remaining = max_len - len(result)
                if remaining > 0:
                    result += seg[:remaining]
                break
            result += seg
        if result:
            return result

    clean = re.sub(r'\s+', ' ', text).strip()
    if clean:
        return clean[:max_len]

    return None


def format_title(keywords, dt):
    """格式化標題：關鍵字 2026-08-27 14:30"""
    return f'{keywords} {dt:%Y-%m-%d %H:%M}'


def session_dt(time_created):
    """將 DB 的毫秒 epoch 轉為台灣時間"""
    return datetime.fromtimestamp(time_created / 1000, tz=timezone.utc) + TIMEZONE_OFFSET


def first_user_text(db, session_id):
    """取得該 session 第一則 user text message 的文字"""
    row = db.execute(
        """SELECT p.data
           FROM message m
           JOIN part p ON p.message_id = m.id
           WHERE m.session_id = ?
             AND json_extract(m.data, '$.role') = 'user'
             AND json_extract(p.data, '$.type') = 'text'
           ORDER BY m.time_created ASC, p.time_created ASC
           LIMIT 1""",
        (session_id,)
    ).fetchone()
    if not row or not row[0]:
        return None
    part_data = json.loads(row[0])
    return part_data.get('text', '')


def repair():
    root = tkinter.Tk()
    root.withdraw()

    if not os.path.exists(DB_PATH):
        tkinter.messagebox.showinfo('OpenCode 標題修復', '找不到 opencode.db，無需修復。')
        root.destroy()
        return

    db = sqlite3.connect(DB_PATH, timeout=5)
    db.execute('PRAGMA journal_mode=WAL')
    db.execute('PRAGMA busy_timeout=5000')

    fixed = 0
    try:
        rows = db.execute(
            'SELECT id, title, time_created FROM session'
        ).fetchall()

        for session_id, old_title, time_created in rows:
            if not old_title:
                continue

            dt = session_dt(time_created)
            correct_date = dt.strftime('%Y-%m-%d %H:%M')

            m = DATE_RE.match(old_title)
            if m:
                # 標題已有日期：比對是否與 DB 時間相符
                if m.group(2) != correct_date:
                    new_title = f'{m.group(1)} {correct_date}'
                    db.execute('UPDATE session SET title = ? WHERE id = ?', (new_title, session_id))
                    fixed += 1
                    print(f'{session_id}: 修正日期 {m.group(2)} -> {correct_date}')

            elif old_title.startswith('New session'):
                # 仍為 New session：補命名
                text = first_user_text(db, session_id)
                if not text:
                    continue
                keywords = extract_keywords(text)
                if not keywords:
                    continue
                new_title = format_title(keywords, dt)
                db.execute('UPDATE session SET title = ? WHERE id = ?', (new_title, session_id))
                fixed += 1
                print(f'{session_id}: 補命名 -> {new_title}')

        db.commit()
    except Exception as e:
        db.rollback()
        tkinter.messagebox.showerror('OpenCode 標題修復', f'發生錯誤：{e}')
        root.destroy()
        return
    finally:
        db.close()

    tkinter.messagebox.showinfo('OpenCode 標題修復', f'修復完成，共修正 {fixed} 筆。')
    root.destroy()


if __name__ == '__main__':
    repair()
