import os
from flask import Flask
from myapp.db import close_db


def create_app():
    app = Flask(__name__)
   
    app = Flask(__name__,
                static_folder='static',
                template_folder='templates')  # só para o caso de teres templates comuns

    # secrets & BD
    app.config.update(
        SECRET_KEY=os.getenv('SECRET_KEY', 'dev'),
        MYSQL_HOST=os.getenv('DB_HOST', 'db'),
        MYSQL_USER=os.getenv('DB_USER', 'matr3co_user'),
        MYSQL_PASSWORD=os.getenv('DB_PASSWORD', 'matr3co_password'),
        MYSQL_DATABASE=os.getenv('DB_NAME', 'matr3co_db'),
        UPLOAD_FOLDER='static/images/uploads',
        MAX_CONTENT_LENGTH=16*1024*1024
    )

    # regista teardown para fechar a BD
    app.teardown_appcontext(close_db)

    # regista blueprints
    from myapp.main     import bp as main_bp
    from myapp.auth     import bp as auth_bp
    from myapp.products import bp as products_bp
    from myapp.cart     import bp as cart_bp

    app.register_blueprint(main_bp)
    app.register_blueprint(auth_bp)
    app.register_blueprint(products_bp)
    app.register_blueprint(cart_bp)

    #app.logger.info(f"💡 Cart Blueprint: {cart_bp}")
    
    
    #app.logger.info("💡 Blueprints registados: %s", app.blueprints.keys())
    #for rule in app.url_map.iter_rules():
    #    app.logger.info("🔗 %s -> %s", rule.endpoint, rule)

    #app.logger.info("💡 ENDPOINTS REGISTADOS:")
    #for rule in app.url_map.iter_rules():
    #    app.logger.info("%s -> %s", rule.endpoint, rule)

    return app

if __name__ == '__main__':
    # cria pasta de uploads
    os.makedirs('static/images/uploads', exist_ok=True)
    create_app().run(debug=True)
