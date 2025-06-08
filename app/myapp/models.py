from werkzeug.security import generate_password_hash, check_password_hash
from flask_login import UserMixin
from myapp.db import get_db

class User(UserMixin):
    def __init__(self, id, email, password_hash, username=None):
        self.id = id
        self.email = email
        self.password_hash = password_hash
        self.username = username

    @staticmethod
    def get_by_email(email):
        db = get_db()
        cur = db.cursor(dictionary=True)
        cur.execute('SELECT id, email, password_hash, username FROM users WHERE email = %s', (email,))
        row = cur.fetchone()
        cur.close()
        if row:
            return User(**row)
        return None

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)
