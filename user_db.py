"""
==============================================================================
  User Database — SQLite-based Authentication & Profile Management
==============================================================================
  • Manages user registration, email verification, login
  • Stores avatar preferences and session tokens
  • Uses bcrypt for password hashing, JWT for session tokens
==============================================================================
"""

import sqlite3
import os
import random
import string
import hashlib
import time
import json
from datetime import datetime, timedelta

# Email service
try:
    from email_service import send_verification_email
    EMAIL_AVAILABLE = True
except ImportError:
    EMAIL_AVAILABLE = False

# Try importing optional deps
try:
    import bcrypt
    BCRYPT_AVAILABLE = True
except ImportError:
    BCRYPT_AVAILABLE = False

try:
    import jwt
    JWT_AVAILABLE = True
except ImportError:
    JWT_AVAILABLE = False

DB_PATH = os.path.join(os.path.dirname(__file__), "users.db")
JWT_SECRET = "borsa-dashboard-local-secret-key-2026"  # For local use only
JWT_ALGORITHM = "HS256"


def _get_conn():
    """Get a database connection with row_factory for dict-like access."""
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def init_db():
    """Create tables if they don't exist."""
    conn = _get_conn()
    cursor = conn.cursor()
    
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT NOT NULL UNIQUE,
            email TEXT NOT NULL UNIQUE,
            password_hash TEXT NOT NULL,
            avatar_id TEXT DEFAULT 'business_man',
            is_verified INTEGER DEFAULT 0,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
    """)
    
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS verification_codes (
            email TEXT PRIMARY KEY,
            code TEXT NOT NULL,
            expires_at REAL NOT NULL
        )
    """)
    
    conn.commit()
    conn.close()
    print("[AUTH] ✅ Database initialized.")


def _hash_password(password: str) -> str:
    """Hash a password using bcrypt or fallback to SHA256."""
    if BCRYPT_AVAILABLE:
        return bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
    else:
        return hashlib.sha256(password.encode('utf-8')).hexdigest()


def _verify_password(password: str, hashed: str) -> bool:
    """Verify a password against its hash."""
    if BCRYPT_AVAILABLE:
        return bcrypt.checkpw(password.encode('utf-8'), hashed.encode('utf-8'))
    else:
        return hashlib.sha256(password.encode('utf-8')).hexdigest() == hashed


def generate_verification_code(email: str) -> str:
    """Generate a 6-digit verification code and store it."""
    code = ''.join(random.choices(string.digits, k=6))
    expires_at = time.time() + 600  # 10 minutes
    
    conn = _get_conn()
    cursor = conn.cursor()
    cursor.execute(
        "INSERT OR REPLACE INTO verification_codes (email, code, expires_at) VALUES (?, ?, ?)",
        (email.lower(), code, expires_at)
    )
    conn.commit()
    conn.close()
    
    # For local development, print the code to console
    print(f"\n{'='*50}")
    print(f"  📧 VERIFICATION CODE for {email}")
    print(f"  Code: {code}")
    print(f"  Expires in 10 minutes")
    print(f"{'='*50}\n")
    
    return code


def verify_code(email: str, code: str) -> bool:
    """Check if a verification code is valid."""
    conn = _get_conn()
    cursor = conn.cursor()
    cursor.execute(
        "SELECT code, expires_at FROM verification_codes WHERE email = ?",
        (email.lower(),)
    )
    row = cursor.fetchone()
    
    if not row:
        conn.close()
        return False
    
    if row['code'] != code or time.time() > row['expires_at']:
        conn.close()
        return False
    
    # Mark user as verified
    cursor.execute("UPDATE users SET is_verified = 1 WHERE email = ?", (email.lower(),))
    cursor.execute("DELETE FROM verification_codes WHERE email = ?", (email.lower(),))
    conn.commit()
    conn.close()
    return True


def create_user(username: str, email: str, password: str) -> dict:
    """Register a new user. Returns user dict or error."""
    conn = _get_conn()
    cursor = conn.cursor()
    
    # Check for existing user
    cursor.execute("SELECT id FROM users WHERE email = ? OR username = ?", (email.lower(), username))
    if cursor.fetchone():
        conn.close()
        return {"error": "Email or username already exists."}
    
    password_hash = _hash_password(password)
    
    cursor.execute(
        "INSERT INTO users (username, email, password_hash) VALUES (?, ?, ?)",
        (username, email.lower(), password_hash)
    )
    conn.commit()
    user_id = cursor.lastrowid
    conn.close()
    
    # Generate verification code
    code = generate_verification_code(email)
    
    # Send real email
    email_sent = False
    if EMAIL_AVAILABLE:
        email_sent = send_verification_email(email, username, code)
    
    return {
        "id": user_id,
        "username": username,
        "email": email.lower(),
        "verification_code_sent": True,
        "email_delivered": email_sent
    }


def authenticate(email: str, password: str) -> dict:
    """Login a user. Returns JWT token or error."""
    conn = _get_conn()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM users WHERE email = ?", (email.lower(),))
    user = cursor.fetchone()
    conn.close()
    
    if not user:
        return {"error": "Invalid email or password."}
    
    if not _verify_password(password, user['password_hash']):
        return {"error": "Invalid email or password."}
    
    if not user['is_verified']:
        return {"error": "Email not verified. Please check your verification code."}
    
    # Generate JWT token
    payload = {
        "user_id": user['id'],
        "username": user['username'],
        "email": user['email'],
        "avatar_id": user['avatar_id'],
        "exp": datetime.utcnow() + timedelta(days=30)
    }
    
    if JWT_AVAILABLE:
        token = jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)
    else:
        # Fallback: simple base64 token
        import base64
        token = base64.b64encode(json.dumps(payload, default=str).encode()).decode()
    
    return {
        "token": token,
        "user": {
            "id": user['id'],
            "username": user['username'],
            "email": user['email'],
            "avatar_id": user['avatar_id'],
        }
    }


def get_user_from_token(token: str) -> dict | None:
    """Decode a JWT token and return user data."""
    try:
        if JWT_AVAILABLE:
            payload = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
        else:
            import base64
            payload = json.loads(base64.b64decode(token).decode())
        
        return {
            "id": payload.get("user_id"),
            "username": payload.get("username"),
            "email": payload.get("email"),
            "avatar_id": payload.get("avatar_id"),
        }
    except Exception:
        return None


def update_avatar(user_id: int, avatar_id: str) -> bool:
    """Update a user's avatar selection."""
    valid_avatars = [
        "business_man", "business_woman", "classic_trader", 
        "bull", "bear", "rocket", "diamond", "moon"
    ]
    if avatar_id not in valid_avatars:
        return False
    
    conn = _get_conn()
    cursor = conn.cursor()
    cursor.execute("UPDATE users SET avatar_id = ? WHERE id = ?", (avatar_id, user_id))
    conn.commit()
    conn.close()
    return True


# Initialize database on import
init_db()
