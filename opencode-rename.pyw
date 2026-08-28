"""
OpenCode Session 自動命名腳本
從用戶的第一則訊息中擷取關鍵字，加上日期時間，自動改寫 session 標題。
"""
import sqlite3
import os
import re
import json
import sys
from datetime import datetime, timezone, timedelta

# 設定
DB_PATH = os.path.join(os.environ['USERPROFILE'], '.local', 'share', 'opencode', 'opencode.db')
TITLE_MAX_LEN = 20  # 關鍵字最大長度
TIMEZONE_OFFSET = timedelta(hours=8)  # 台灣時區 UTC+8


def extract_keywords(text, max_len=TITLE_MAX_LEN):
    """從文字中擷取關鍵字（取前 N 個中文字或前 N 個字元）"""
    if not text:
        return None

    # 移除常見的開頭問候語
    text = re.sub(r'^(你好|hi|hello|hey|幫我|請|我想|我要|幫忙| help)[\s,，!！。.]*', '', text, flags=re.IGNORECASE)

    # 嘗試擷取連續中文字符
    chinese = re.findall(r'[\u4e00-\u9fff]+', text)
    if chinese:
        # 取前幾個中文詞組，直到達到長度上限
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

    # 若無中文，取前 N 個非空白字元
    clean = re.sub(r'\s+', ' ', text).strip()
    if clean:
        return clean[:max_len]

    return None


def format_title(keywords, dt):
    """格式化標題：關鍵字 2026-08-27 14:30"""
    date_str = dt.strftime('%Y-%m-%d %H:%M')
    return f'{keywords} {date_str}'


def process_sessions():
    """主處理邏輯：找到 New session 並改名"""
    # 檢查 DB 是否存在
    if not os.path.exists(DB_PATH):
        return 0

    db = sqlite3.connect(DB_PATH, timeout=5)
    db.execute('PRAGMA journal_mode=WAL')
    db.execute('PRAGMA busy_timeout=5000')

    try:
        # 找所有 New session 且有 user message 的 session
        rows = db.execute(
            """SELECT DISTINCT s.id, s.title, s.time_created
               FROM session s
               JOIN message m ON m.session_id = s.id
               WHERE s.title LIKE 'New session%'
                 AND json_extract(m.data, '$.role') = 'user'"""
        ).fetchall()

        renamed_count = 0

        for session_id, old_title, time_created in rows:
            # 取得該 session 的第一則 user message 的文字
            part_row = db.execute(
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

            if not part_row or not part_row[0]:
                continue

            part_data = json.loads(part_row[0])
            text = part_data.get('text', '')
            if not text:
                continue

            keywords = extract_keywords(text)
            if not keywords:
                continue

            # 使用 session 在 DB 中記錄的建立時間（毫秒 epoch）
            dt = datetime.fromtimestamp(time_created / 1000, tz=timezone.utc) + TIMEZONE_OFFSET
            new_title = format_title(keywords, dt)

            # 避免重複改名（若標題已含有日期格式）
            if re.match(r'.+\d{4}-\d{2}-\d{2} \d{2}:\d{2}$', old_title):
                continue

            db.execute(
                'UPDATE session SET title = ? WHERE id = ?',
                (new_title, session_id)
            )
            renamed_count += 1
            print(f'{session_id} -> {new_title}')

        db.commit()
        return renamed_count

    except Exception as e:
        print(f'Error: {e}', file=sys.stderr)
        db.rollback()
        return 0
    finally:
        db.close()


if __name__ == '__main__':
    import time
    # 每 30 秒輪詢一次，静默運行
    while True:
        process_sessions()
        time.sleep(30)
