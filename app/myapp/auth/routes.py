print(">>> carreguei auth/routes.py")
from flask import (
    render_template, redirect, url_for,
    flash, session, request
)
from werkzeug.security import (
    generate_password_hash, check_password_hash
)
from ..db import get_db
from . import bp
from .forms import LoginForm, RegistrationForm, EditProfileForm

@bp.route('/login', methods=['GET', 'POST'])
def login():
    form = LoginForm()
    if form.validate_on_submit():
        db  = get_db()
        cur = db.cursor(dictionary=True)
        cur.execute(
            "SELECT id, username, password, profile, email "
            "FROM users WHERE email = %s",
            (form.email.data,)
        )
        user = cur.fetchone()
        cur.close()

        if user and check_password_hash(
            user['password'],
            form.password.data
        ):
            session.clear()
            session['user_id']  = user['id']
            session['username'] = user['username']
            session['email']    = user['email']
            session['profile']  = user['profile']
            flash('Login bem-sucedido!', 'success')
            return redirect(url_for('main.index'))

        flash('Credenciais inválidas', 'danger')

    return render_template('login.html', form=form)

@bp.route('/logout')
def logout():
    session.clear()
    flash('Sessão terminada', 'info')
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
                "INSERT INTO users(username, email, password, profile) "
                "VALUES(%s, %s, %s, %s)",
                (form.username.data,
                 form.email.data,
                 pw,
                 'user')
            )
            db.commit()
        except Exception as e:
            db.rollback()
            flash(f'Erro ao criar conta: {e}', 'danger')
            return render_template('register.html', form=form)

        flash('Conta criada! Faça login.', 'success')
        return redirect(url_for('auth.login'))

    return render_template('register.html', form=form)

@bp.route('/edit_profile', methods=['GET', 'POST'])
def edit_profile():
    if 'user_id' not in session:
        return redirect(url_for('auth.login'))

    form = EditProfileForm()
    db   = get_db()
    cur  = db.cursor(dictionary=True)

    # Carregar produtos do utilizador
    cur.execute("""
        SELECT id, title, price, is_available
          FROM products
         WHERE user_id = %s
         ORDER BY created_at DESC
    """, (session['user_id'],))
    user_products = cur.fetchall()

    if request.method == 'GET':
        # pré-carrega campos
        cur.execute(
            "SELECT username, email FROM users WHERE id = %s",
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
                    "UPDATE users SET username=%s, email=%s, password=%s "
                    "WHERE id=%s",
                    (username, email, pw_hash, session['user_id'])
                )
            else:
                cur.execute(
                    "UPDATE users SET username=%s, email=%s "
                    "WHERE id=%s",
                    (username, email, session['user_id'])
                )

            db.commit()
            # atualiza sessão
            session['username'] = username
            session['email']    = email

            flash('Perfil atualizado!', 'success')
            return redirect(url_for('main.index'))

        except Exception as e:
            db.rollback()
            flash(f'Erro ao atualizar perfil: {e}', 'danger')

    cur.close()
    return render_template('edit_profile.html', form=form, user_products=user_products)




@bp.route('/toggle_product_status/<int:product_id>', methods=['POST'])
def toggle_product_status(product_id):
    db = get_db()
    cur = db.cursor(dictionary=True)
    cur.execute("""
        SELECT * FROM products
         WHERE id = %s AND user_id = %s
    """, (product_id, session['user_id']))
    product = cur.fetchone()
    

    if not product:
        flash("Produto não encontrado ou sem permissão.", "danger")
        return redirect(url_for('auth.edit_profile'))

    new_status = 'indisponivel' if product['is_available'] == 'disponivel' else 'disponivel'

    try:
        cur.execute("""
            UPDATE products
               SET is_available = %s
             WHERE id = %s
        """, (new_status, product_id))
        db.commit()
        flash(f"Produto '{product['title']}' atualizado para '{new_status}'.", "success")
    except Exception as e:
        db.rollback()
        flash(f"Ocorreu um erro ao atualizar o estado do produto: {str(e)}", "danger")

    next_url = request.form.get('next') or url_for('auth.edit_profile')
    return redirect(next_url)
