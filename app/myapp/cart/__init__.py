from flask import Blueprint

bp = Blueprint('cart', __name__, template_folder='templates', url_prefix='/cart')

from . import routes  # Isto é ESSENCIAL
