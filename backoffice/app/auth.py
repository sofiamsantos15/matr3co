from flask import Blueprint, render_template, redirect, url_for, session, flash
from werkzeug.security import check_password_hash
from .forms import LoginForm
from .db import get_db, close_db

bp = Blueprint('auth', __name__, url_prefix='')

def admin_required(f):
    from functools import wraps
    @wraps(f)
    def wrapped(*args, **kwargs):
        if 'admin_id' not in session:
            flash('Por favor, entre como admin.', 'warning')
            return redirect(url_for('auth.login'))
        return f(*args, **kwargs)
    return wrapped

@bp.route('/login', methods=['GET','POST'])
def login():
    form = LoginForm()
    if form.validate_on_submit():
        db = get_db()
        cur = db.cursor(dictionary=True)
        cur.execute(
            "SELECT id, password, profile FROM users WHERE username=%s",
            (form.username.data,)
        )
        user = cur.fetchone()
        #if user and user['profile']=='admin' and check_password_hash(user['password'], form.password.data):
        if user and user['profile']=='admin' and user['password']==form.password.data: 
            session.clear()
            session['admin_id'] = user['id']
            return redirect(url_for('routes.dashboard'))
        flash(user['profile'] + ' Credenciais invalidas ou sem permissoes.', 'danger')
    return render_template('login.html', form=form)

@bp.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('auth.login'))
