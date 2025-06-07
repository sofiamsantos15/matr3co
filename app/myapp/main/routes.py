from flask import render_template, redirect, url_for, flash, session, request
from . import bp
from myapp.db import get_db   # <— adiciona esta linha


@bp.route('/', methods=['GET'])
def index():
    """Listagem pública de produtos (homepage)."""
    db = get_db()
    cur = db.cursor(dictionary=True)
    # traz cada produto com sua primeira imagem
    cur.execute("""
        SELECT
            p.id, p.title, p.price, p.is_negotiable,
            MIN(pi.filename) AS thumb
        FROM products p
        LEFT JOIN product_images pi ON p.id = pi.product_id
        WHERE p.is_available='disponivel'
        GROUP BY p.id
        ORDER BY p.created_at DESC
        LIMIT 20
    """)
    products = cur.fetchall()
    return render_template('index.html', products=products)


@bp.route('/products')
def products():
    if 'user_id' not in session:
        flash('Por favor faça login primeiro', 'warning')
        return redirect(url_for('c.login'))
    return render_template('products/index.html')


@bp.route('/busca')
def busca():
    query = request.args.get('q', '').strip()

    db = get_db()
    cur = db.cursor(dictionary=True)

    products = []
    if query:
        like_pattern = f"%{query}%"
        cur.execute("""
            SELECT
                p.id, p.title, p.price, p.is_negotiable, 
                MIN(pi.filename) AS thumb
            FROM products p
            LEFT JOIN product_images pi ON p.id = pi.product_id
            WHERE p.title LIKE %s OR p.description LIKE %s
            AND p.is_available='disponivel'
            GROUP BY p.id
            ORDER BY p.created_at DESC
            LIMIT 30
        """, (like_pattern, like_pattern))
        products = cur.fetchall()

    return render_template('index.html', products=products, search_query=query)


