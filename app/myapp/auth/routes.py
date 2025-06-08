print(">>> carreguei auth/routes.py")
import os
from itsdangerous import URLSafeTimedSerializer
from flask import (
    render_template, redirect, url_for,
    flash, session, request, current_app
)
from werkzeug.security import generate_password_hash, check_password_hash
from myapp.db import get_db
from .forms import (
    LoginForm, RegistrationForm, EditProfileForm
)
from . import bp

@bp.route('/login', methods=['GET', 'POST'])
def login():
    form = LoginForm()
    if form.validate_on_submit():
        db  = get_db()
        cur = db.cursor(dictionary=True)
        cur.execute(
            'SELECT id, username, password, profile, email '
            'FROM users WHERE email = %s',
            (form.email.data,)
        )
        user = cur.fetchone()
        cur.close()
        if user and check_password_hash(user['password'], form.password.data):
            session.clear()
            session['user_id']  = user['id']
            session['username'] = user['username']
            session['email']    = user['email']
            session['profile']  = user['profile']
            flash('Login bem-sucedido!', 'success')
            return redirect(url_for('main.index'))
        flash('Credenciais inválidas.', 'danger')
    return render_template('login.html', form=form)

@bp.route('/logout')
def logout():
    session.clear()
    flash('Sessão terminada.', 'info')
    return redirect(url_for('main.index'))

@bp.route('/register', methods=['GET', 'POST'])
def register():
    form = RegistrationForm()
    if form.validate_on_submit():
        db  = get_db()
        cur = db.cursor()
        pw  = generate_password_hash(form.password.data)
        try:
            cur.execute(
                'INSERT INTO users(username, email, password, profile) '
                'VALUES(%s, %s, %s, %s)',
                (form.username.data, form.email.data, pw, 'user')
            )
            db.commit()
        except Exception as e:
            db.rollback()
            flash(f'Erro ao criar conta: {e}', 'danger')
            return render_template('register.html', form=form)
        cur.close()
        flash('Conta criada! Faça login.', 'success')
        return redirect(url_for('auth.login'))
    return render_template('register.html', form=form)

# Agora 'is_available' é tratado como string
@bp.route('/edit_profile/<string:is_available>', methods=['GET', 'POST'])
def edit_profile(is_available):
    if 'user_id' not in session:
        return redirect(url_for('auth.login'))

    # Se quiser, valide aqui se is_available está num conjunto de valores válidos
    valid_states = {'indisponivel', 'disponivel', 'vendido'}
    if is_available not in valid_states:
        flash('Filtro inválido.', 'warning')
        return redirect(url_for('user.edit_profile', is_available='disponivel'))

    form = EditProfileForm()
    db   = get_db()
    cur  = db.cursor(dictionary=True)

    # Consulta usando o valor de enum (string)
    cur.execute(
        """
        SELECT id, title, price, is_available
          FROM products
         WHERE user_id = %s
           AND is_available = %s
         ORDER BY created_at DESC
        """,
        (session['user_id'], is_available)
    )
    user_products = cur.fetchall()

    if request.method == 'GET':
        cur.execute(
            'SELECT username, email FROM users WHERE id = %s',
            (session['user_id'],)
        )
        user = cur.fetchone()
        form.username.data = user['username']
        form.email.data    = user['email']

    if form.validate_on_submit():
        username = form.username.data
        email    = form.email.data
        pw       = form.password.data
        try:
            if pw:
                pw_hash = generate_password_hash(pw)
                cur.execute(
                    """
                    UPDATE users
                       SET username = %s,
                           email    = %s,
                           password = %s
                     WHERE id = %s
                    """,
                    (username, email, pw_hash, session['user_id'])
                )
            else:
                cur.execute(
                    """
                    UPDATE users
                       SET username = %s,
                           email    = %s
                     WHERE id = %s
                    """,
                    (username, email, session['user_id'])
                )
            db.commit()
            session['username'] = username
            session['email']    = email
            flash('Perfil atualizado!', 'success')
            return redirect(url_for('main.index'))
        except Exception as e:
            db.rollback()
            flash(f'Erro ao atualizar perfil: {e}', 'danger')

    cur.close()
    return render_template(
        'edit_profile.html',
        form=form,
        user_products=user_products,
        is_available=is_available
    )