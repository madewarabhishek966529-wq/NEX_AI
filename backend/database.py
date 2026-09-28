import sqlite3
import uuid
from datetime import datetime, timezone
from typing import List, Dict, Any, Optional
try:
    from backend.config import settings
except ImportError:
    from config import settings

class Database:
    def __init__(self, db_path: str = settings.DATABASE_PATH):
        self.db_path = db_path
        self._init_db()

    def _get_connection(self):
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row
        return conn

    def _init_db(self):
        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS conversations (
                    conversation_id TEXT PRIMARY KEY,
                    user_id TEXT NOT NULL,
                    title TEXT,
                    summary TEXT DEFAULT '',
                    created_at TEXT NOT NULL,
                    updated_at TEXT NOT NULL
                )
            """)
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS messages (
                    message_id TEXT PRIMARY KEY,
                    conversation_id TEXT NOT NULL,
                    role TEXT NOT NULL,
                    text TEXT NOT NULL,
                    timestamp TEXT NOT NULL,
                    FOREIGN KEY (conversation_id) REFERENCES conversations(conversation_id)
                )
            """)
            cursor.execute("""
                CREATE INDEX IF NOT EXISTS idx_messages_conv 
                ON messages(conversation_id, timestamp)
            """)
            conn.commit()

    def create_conversation(self, user_id: str, title: Optional[str] = None) -> str:
        conv_id = f"conv_{uuid.uuid4().hex[:12]}"
        now = datetime.now(timezone.utc).isoformat()
        default_title = title or "New Conversation"
        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(
                "INSERT INTO conversations (conversation_id, user_id, title, created_at, updated_at) VALUES (?, ?, ?, ?, ?)",
                (conv_id, user_id, default_title, now, now)
            )
            conn.commit()
        return conv_id

    def ensure_conversation(self, conversation_id: str, user_id: str) -> None:
        now = datetime.now(timezone.utc).isoformat()
        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT conversation_id FROM conversations WHERE conversation_id = ?", (conversation_id,))
            if not cursor.fetchone():
                cursor.execute(
                    "INSERT INTO conversations (conversation_id, user_id, title, created_at, updated_at) VALUES (?, ?, ?, ?, ?)",
                    (conversation_id, user_id, "Voice Chat", now, now)
                )
                conn.commit()

    def add_message(self, conversation_id: str, role: str, text: str) -> str:
        msg_id = f"msg_{uuid.uuid4().hex[:12]}"
        now = datetime.now(timezone.utc).isoformat()
        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(
                "INSERT INTO messages (message_id, conversation_id, role, text, timestamp) VALUES (?, ?, ?, ?, ?)",
                (msg_id, conversation_id, role, text, now)
            )
            cursor.execute(
                "UPDATE conversations SET updated_at = ? WHERE conversation_id = ?",
                (now, conversation_id)
            )
            conn.commit()
        return msg_id

    def get_messages(self, conversation_id: str, limit: Optional[int] = None) -> List[Dict[str, Any]]:
        with self._get_connection() as conn:
            cursor = conn.cursor()
            if limit:
                # Get the most recent N messages in chronological order
                cursor.execute(
                    """
                    SELECT message_id, role, text, timestamp 
                    FROM (
                        SELECT message_id, role, text, timestamp 
                        FROM messages 
                        WHERE conversation_id = ? 
                        ORDER BY timestamp DESC 
                        LIMIT ?
                    ) ORDER BY timestamp ASC
                    """,
                    (conversation_id, limit)
                )
            else:
                cursor.execute(
                    "SELECT message_id, role, text, timestamp FROM messages WHERE conversation_id = ? ORDER BY timestamp ASC",
                    (conversation_id,)
                )
            rows = cursor.fetchall()
            return [dict(row) for row in rows]

    def get_conversation_summary(self, conversation_id: str) -> str:
        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT summary FROM conversations WHERE conversation_id = ?", (conversation_id,))
            row = cursor.fetchone()
            return row["summary"] if row and row["summary"] else ""

    def update_conversation_summary(self, conversation_id: str, summary: str) -> None:
        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("UPDATE conversations SET summary = ? WHERE conversation_id = ?", (summary, conversation_id))
            conn.commit()

    def delete_conversation(self, conversation_id: str) -> bool:
        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("DELETE FROM messages WHERE conversation_id = ?", (conversation_id,))
            cursor.execute("DELETE FROM conversations WHERE conversation_id = ?", (conversation_id,))
            conn.commit()
            return cursor.rowcount > 0

    def get_user_conversations(self, user_id: str) -> List[Dict[str, Any]]:
        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(
                "SELECT conversation_id, title, summary, created_at, updated_at FROM conversations WHERE user_id = ? ORDER BY updated_at DESC",
                (user_id,)
            )
            rows = cursor.fetchall()
            return [dict(row) for row in rows]

db = Database()
