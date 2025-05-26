# myapp/auth/__init__.py

from flask import Blueprint

bp = Blueprint(
    'auth',
    __name__,
    url_prefix='/auth',
    template_folder='templates'
)

# importa as routes para que os @bp.route sejam registados
from . import routes
