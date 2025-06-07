import os
from flask import g, current_app
import mysql.connector

def get_db():
    if 'db' not in g:
        cfg = current_app.config
        try:
            g.db = mysql.connector.connect(
                host=cfg['MYSQL_HOST'],
                user=cfg['MYSQL_USER'],
                password=cfg['MYSQL_PASSWORD'],
                database=cfg['MYSQL_DATABASE']
            )
            
        except mysql.connector.Error as err:
            current_app.logger.error(f"Erro na conexão: {err}")
            raise
    return g.db

def close_db(e=None):
    db = g.pop('db', None)
    if db is not None:
        try:
            db.close()
            current_app.logger.info("BD fechado")
        except mysql.connector.Error as err:
            current_app.logger.error(f"Erro ao fechar BD: {err}")
