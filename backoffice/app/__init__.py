# app/__init__.py
import os
from flask import Flask
from .db import close_db

def create_app():
    app = Flask(__name__)
    app.config.update(
    SECRET_KEY=os.getenv('SECRET_KEY', 'dev'),
    MYSQL_HOST=os.getenv('DB_HOST', 'db'),
    MYSQL_USER=os.getenv('DB_USER', 'matr3co_user'),
    MYSQL_PASSWORD=os.getenv('DB_PASSWORD', 'matr3co_password'),
    MYSQL_DATABASE=os.getenv('DB_NAME', 'matr3co_db'),
    UPLOAD_FOLDER='static/images/uploads',
    MAX_CONTENT_LENGTH=16*1024*1024
    )

    # regista o teardown para fechar a BD
    app.teardown_appcontext(close_db)

    from .auth import bp as auth_bp
    app.register_blueprint(auth_bp)

    from .routes import bp as admin_bp
    app.register_blueprint(admin_bp)

    return app
