from flask import Blueprint
bp = Blueprint('products', __name__, template_folder='templates', url_prefix='/products')

from . import routes

