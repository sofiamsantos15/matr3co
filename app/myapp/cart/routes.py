from flask import Blueprint, session, redirect, url_for, render_template, flash
from flask_login import login_required, current_user
from myapp.db import get_db
from myapp.cart.forms import CheckoutForm
import smtplib

from . import bp

def init_cart():
    if 'cart' not in session:
        session['cart'] = []

@bp.route('/add/<int:product_id>')
def add_to_cart(product_id):
    if 'user_id' not in session:
        flash('Faça login para adicionar ao carrinho.', 'warning')
        return redirect(url_for('auth.login'))

    db = get_db()
    cur = db.cursor(dictionary=True)
    cur.execute('SELECT * FROM products WHERE id = %s', (product_id,))
    product = cur.fetchone()
    cur.close()

    if product and product['user_id'] != session['user_id'] and product['is_available'] == 'disponivel':
        init_cart()
        if product_id not in session['cart']:
            session['cart'].append(product_id)
            cur = db.cursor()
            cur.execute('UPDATE products SET is_available = %s WHERE id = %s',
                        ('reservado', product_id))
            db.commit()
            cur.close()
            flash('Produto adicionado ao carrinho.', 'success')
        else:
            flash('Produto já está no carrinho.', 'info')
    else:
        flash('Não é possível adicionar este produto.', 'danger')

    return redirect(url_for('products.detail', product_id=product_id))

@bp.route('/remove/<int:product_id>')
def remove_from_cart(product_id):
    if 'user_id' not in session:
        flash('Faça login para remover do carrinho.', 'warning')
        return redirect(url_for('auth.login'))

    init_cart()
    if product_id in session['cart']:
        session['cart'].remove(product_id)
        db = get_db()
        cur = db.cursor()
        cur.execute('UPDATE products SET is_available = %s WHERE id = %s',
                    ('disponivel', product_id))
        db.commit()
        cur.close()
        flash('Produto removido do carrinho.', 'info')

    return redirect(url_for('cart.view_cart'))

@bp.route('/')
def view_cart():
    if 'user_id' not in session:
        flash('Faça login para remover do carrinho.', 'warning')
        return redirect(url_for('auth.login'))
    db = get_db()
    init_cart()
    products = []
    total = 0
    for pid in session['cart']:
        cur = db.cursor(dictionary=True)
        cur.execute('SELECT * FROM products WHERE id = %s', (pid,))
        product = cur.fetchone()
        cur.close()
        if product:
            products.append(product)
            total += product['price']
    return render_template('view_cart.html', products=products, total=total)

@bp.route('/checkout', methods=['GET', 'POST'])
def checkout():
    if 'user_id' not in session:
        flash('Faça login para remover do carrinho.', 'warning')
        return redirect(url_for('auth.login'))
    db = get_db()
    init_cart()
    form = CheckoutForm()

    if form.validate_on_submit():
        total = 0
        for pid in session['cart']:
            cur = db.cursor()
            cur.execute('SELECT price FROM products WHERE id = %s', (pid,))
            row = cur.fetchone()
            cur.close()
            if row:
                total += row[0]
        cur = db.cursor()
        cur.execute(
            'INSERT INTO orders (buyer_id, total_amount, status) VALUES (%s, %s, %s)',
            (session['user_id'], total, 'pendente')
        )
        order_id = cur.lastrowid
        cur.close()
        for pid in session['cart']:
            cur = db.cursor()
            cur.execute('SELECT price FROM products WHERE id = %s', (pid,))
            row = cur.fetchone()
            cur.close()
            price = row[0] if row else None
            if price is not None:
                cur = db.cursor()
                cur.execute(
                    'INSERT INTO order_items (order_id, product_id, price) VALUES (%s, %s, %s)',
                    (order_id, pid, price)
                )
                cur.close()
                cur = db.cursor()
                cur.execute(
                    'UPDATE products SET is_available = %s WHERE id = %s',
                    ('vendido', pid)
                )
                cur.close()
                cur = db.cursor(dictionary=True)
                cur.execute(
                    'SELECT u.email, p.title '
                    'FROM products p JOIN users u ON p.user_id = u.id '
                    'WHERE p.id = %s',
                    (pid,)
                )
                seller = cur.fetchone()
                cur.close()
                if seller:
                    send_email_to_seller(seller['email'], seller['title'])
        db.commit()
        session.pop('cart')
        flash('Compra concluída com sucesso!', 'success')
        return redirect(url_for('main.index'))
    return render_template('checkout.html', form=form)

def send_email_to_seller(email, product_title):
    sender = 'noreply@matr3co.pt'
    subject = 'O seu produto foi comprado!'
    body = f'O seu produto "{product_title}" foi comprado. Prepare-o para envio.'
    message = f"Subject: {subject}\n\n{body}"
    try:
        with smtplib.SMTP('smtp.example.com', 587) as server:
            server.starttls()
            server.login('username', 'password')
            server.sendmail(sender, email, message)
    except Exception as e:
        print(f"Erro ao enviar email: {e}")
