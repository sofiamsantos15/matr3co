import os
from flask import (
    render_template, request, redirect, url_for,
    flash, session, current_app, Blueprint, jsonify
)
from werkzeug.utils import secure_filename
from . import bp
from .forms import ProductForm
from myapp.db import get_db

def _load_category_choices(form):
    db = get_db()
    cur = db.cursor(dictionary=True)

    # 1) popula sempre as categorias
    cur.execute('SELECT id, name FROM categories ORDER BY name')
    cats = cur.fetchall()
    form.category.choices = [(c['id'], c['name']) for c in cats]

    # 2) define valor default se não houver data
    if form.category.data is None:
        if form.category.choices:
            form.category.data = form.category.choices[0][0]

    # 3) popula as subcategorias para a category selecionada
    selected_cat = form.category.data
    if selected_cat:
        cur.execute(
            'SELECT id, name FROM subcategories WHERE category_id = %s ORDER BY name',
            (selected_cat,)
        )
        subs = cur.fetchall()
        form.subcategory.choices = [(s['id'], s['name']) for s in subs]
    else:
        form.subcategory.choices = []


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
        GROUP BY p.id
        ORDER BY p.created_at DESC
        LIMIT 20
    """)
    products = cur.fetchall()
    return render_template('index.html', products=products)

@bp.route('/new', methods=['GET', 'POST'])
def create():
    if 'user_id' not in session:
        flash('Faça login para publicar um produto.', 'warning')
        return redirect(url_for('auth.login'))

    form = ProductForm()
    # SEMPRE carregar choices antes de renderizar (GET ou POST)
    _load_category_choices(form)

    if form.validate_on_submit():
        db = get_db()
        cur = db.cursor()
        cur.execute("""
            INSERT INTO products
                (user_id, category_id, subcategory_id, title, description, price, is_negotiable)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
        """, (
            session['user_id'],
            form.category.data,
            form.subcategory.data,
            form.title.data,
            form.description.data,
            float(form.price.data),
            form.is_negotiable.data
        ))
        product_id = cur.lastrowid
        db.commit()

        # grava fotos (igual ao antes)...
        flash('Produto criado com sucesso!', 'success')
        return redirect(url_for('products.detail', product_id=product_id))

    # Se for GET ou se POST falhar na validação,
    # cai aqui e renderiza com os selects já populados.
    return render_template('create_product.html', form=form)

@bp.route('/<int:product_id>/edit', methods=['GET','POST'])
def edit(product_id):
    if 'user_id' not in session:
        flash('Faça login para editar.', 'warning')
        return redirect(url_for('auth.login'))

    db = get_db()
    cur = db.cursor(dictionary=True)
    cur.execute("SELECT * FROM products WHERE id = %s", (product_id,))
    prod = cur.fetchone()
    if prod is None or prod['user_id'] != session['user_id']:
        flash('Produto não encontrado ou sem permissão.', 'danger')
        return redirect(url_for('products.index'))

    form = ProductForm(obj=prod)
    _load_category_choices(form)

    if form.validate_on_submit():
        cur.execute("""
            UPDATE products
               SET category_id=%s, subcategory_id=%s,
                   title=%s, description=%s,
                   price=%s, is_negotiable=%s
             WHERE id=%s
        """, (
            form.category.data,
            form.subcategory.data,
            form.title.data,
            form.description.data,
            float(form.price.data),
            form.is_negotiable.data,
            product_id
        ))
        db.commit()
        flash('Produto atualizado!', 'success')
        return redirect(url_for('products.detail', product_id=product_id))

    return render_template('edit_product.html', form=form, product=prod)

@bp.route('/subcategories/<int:category_id>')
def subcategories(category_id):
    """
    Endpoint que retorna, em JSON, todas as subcategorias
    associadas à categoria cujo id foi passado na URL.
    """
    db = get_db()
    cur = db.cursor(dictionary=True)
    # Busca todas as subcategorias dessa categoria
    cur.execute(
        'SELECT id, name FROM subcategories WHERE category_id = %s ORDER BY name',
        (category_id,)
    )
    subs = cur.fetchall()
    # Retorna no formato { "subcategories": [ { "id": ..., "name": ... }, ... ] }
    return jsonify(subcategories=subs)


@bp.route('/<int:product_id>')
def detail(product_id):
    db = get_db()
    cur = db.cursor(dictionary=True)
    cur.execute("""
        SELECT p.*, u.username,
               c.name AS category, sc.name AS subcategory
          FROM products p
          JOIN users u       ON p.user_id = u.id
          JOIN categories c  ON p.category_id = c.id
          JOIN subcategories sc ON p.subcategory_id = sc.id
         WHERE p.id = %s
    """, (product_id,))
    product = cur.fetchone()
    cur.execute("SELECT filename FROM product_images WHERE product_id = %s", (product_id,))
    images = cur.fetchall()
    return render_template('product_detail.html',
                           product=product, images=images)
