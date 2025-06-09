from flask import Blueprint, render_template, request, redirect, url_for, flash
from .auth import admin_required
from .db import get_db
from .forms import CategoryForm, SubcategoryForm, UserForm

bp = Blueprint('routes', __name__, url_prefix='')

@bp.route('/')
@admin_required
def dashboard():
    return render_template('dashboard.html')

# Categories
@bp.route('/categories')
@admin_required
def categories():
    db = get_db(); cur = db.cursor(dictionary=True)
    cur.execute("SELECT * FROM categories ORDER BY name")
    cats = cur.fetchall()
    return render_template('categories.html', categories=cats)

@bp.route('/categories/new', methods=['GET','POST'])
@admin_required
def new_category():
    form = CategoryForm()
    if form.validate_on_submit():
        db = get_db(); cur = db.cursor()
        cur.execute("INSERT INTO categories (name) VALUES (%s)", (form.name.data,))
        db.commit()
        flash('Categoria criada!', 'success')
        return redirect(url_for('routes.categories'))
    return render_template('category_form.html', form=form)

@bp.route('/categories/<int:id>/edit', methods=['GET','POST'])
@admin_required
def edit_category(id):
    db = get_db(); cur = db.cursor(dictionary=True)
    cur.execute("SELECT * FROM categories WHERE id=%s", (id,))
    cat = cur.fetchone()
    form = CategoryForm(data=cat)
    if form.validate_on_submit():
        cur.execute("UPDATE categories SET name=%s WHERE id=%s", (form.name.data, id))
        db.commit()
        flash('Categoria atualizada!', 'success')
        return redirect(url_for('routes.categories'))
    return render_template('category_form.html', form=form)

@bp.route('/categories/<int:id>/delete', methods=['POST'])
@admin_required
def delete_category(id):
    db = get_db(); cur = db.cursor()
    cur.execute("DELETE FROM categories WHERE id=%s", (id,))
    db.commit()
    flash('Categoria apagada.', 'success')
    return redirect(url_for('routes.categories'))

# Subcategories
@bp.route('/subcategories')
@admin_required
def subcategories():
    db = get_db(); cur = db.cursor(dictionary=True)
    cur.execute("""
      SELECT sc.id, sc.name, c.name AS category_name, sc.category_id
        FROM subcategories sc
        JOIN categories c ON sc.category_id=c.id
      ORDER BY c.name, sc.name
    """)

    subs = cur.fetchall()
    return render_template('subcategories.html', subcategories=subs)

@bp.route('/subcategories/new', methods=['GET','POST'])
@admin_required
def new_subcategory():
    form = SubcategoryForm()
    db = get_db(); cur = db.cursor(dictionary=True)
    cur.execute("SELECT id, name FROM categories ORDER BY name")
    form.category.choices = [(c['id'], c['name']) for c in cur.fetchall()]

    if form.validate_on_submit():
        cur = db.cursor()
        cur.execute("INSERT INTO subcategories (category_id,name) VALUES (%s,%s)",
                    (form.category.data, form.name.data))
        db.commit()
        flash('Subcategoria criada!', 'success')
        return redirect(url_for('routes.subcategories'))
    return render_template('subcategory_form.html', form=form)

@bp.route('/subcategories/<int:id>/edit', methods=['GET','POST'])
@admin_required
def edit_subcategory(id):
    db = get_db(); cur = db.cursor(dictionary=True)
    cur.execute("SELECT * FROM subcategories WHERE id=%s", (id,))
    sub = cur.fetchone()
    form = SubcategoryForm(data=sub)
    cur.execute("SELECT id, name FROM categories ORDER BY name")
    form.category.choices = [(c['id'], c['name']) for c in cur.fetchall()]

    if form.validate_on_submit():
        cur.execute("UPDATE subcategories SET category_id=%s,name=%s WHERE id=%s",
                    (form.category.data, form.name.data, id))
        db.commit()
        flash('Subcategoria atualizada!', 'success')
        return redirect(url_for('routes.subcategories'))
    return render_template('subcategory_form.html', form=form)

@bp.route('/subcategories/<int:id>/delete', methods=['POST'])
@admin_required
def delete_subcategory(id):
    db = get_db(); cur = db.cursor()
    cur.execute("DELETE FROM subcategories WHERE id=%s", (id,))
    db.commit()
    flash('Subcategoria apagada.', 'success')
    return redirect(url_for('routes.subcategories'))

# Users
@bp.route('/users')
@admin_required
def users():
    db = get_db(); cur = db.cursor(dictionary=True)
    cur.execute("SELECT id, username, email, profile, is_active FROM users ORDER BY username")
    users = cur.fetchall()
    return render_template('users.html', users=users)

@bp.route('/users/<int:id>/edit', methods=['GET','POST'])
@admin_required
def edit_user(id):
    db = get_db(); cur = db.cursor(dictionary=True)
    cur.execute("SELECT id, username, email, profile, is_active FROM users WHERE id=%s", (id,))
    u = cur.fetchone()
    form = UserForm(data=u)
    if form.validate_on_submit():
        cur.execute("""
          UPDATE users
             SET username=%s, email=%s, profile=%s, is_active=%s
           WHERE id=%s
        """, (form.username.data, form.email.data, form.profile.data, form.is_active.data, id))
        db.commit()
        flash('Utilizador atualizado!', 'success')
        return redirect(url_for('routes.users'))
    return render_template('user_form.html', form=form)
