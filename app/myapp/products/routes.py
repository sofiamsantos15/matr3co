import os
import uuid 
import logging  # Importar o módulo de logging
from flask import (
    render_template, request, redirect, url_for,
    flash, session, current_app, Blueprint, jsonify
)
from werkzeug.utils import secure_filename
from . import bp
from .forms import ProductForm
from myapp.db import get_db

# Configuração básica de logging (se ainda não estiver configurado em __init__.py)
logging.basicConfig(level=logging.DEBUG) 


def _load_category_choices(form):
    db = get_db()
    cur = db.cursor(dictionary=True)

    cur.execute('SELECT id, name FROM categories ORDER BY name')
    cats = cur.fetchall()
    form.category.choices = [(c['id'], c['name']) for c in cats]

    if form.category.data is None:
        if form.category.choices:
            form.category.data = form.category.choices[0][0]

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
    cur.execute("""
        SELECT
            p.id, p.title, p.price, p.is_negotiable,
            p.estado,                      -- exibir estado
            MIN(pi.filename) AS thumb
        FROM products p
        LEFT JOIN product_images pi ON p.id = pi.product_id
        WHERE p.is_available = TRUE     -- somente disponíveis
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
    _load_category_choices(form)

    if form.validate_on_submit():
        db = get_db()
        cur = db.cursor()
        try:
            cur.execute("""
                INSERT INTO products
                    (user_id, category_id, subcategory_id,
                     title, description, price,
                     is_negotiable, estado, is_available)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
            """, (
                session['user_id'],
                form.category.data,
                form.subcategory.data,
                form.title.data,
                form.description.data,
                float(form.price.data),
                form.is_negotiable.data,
                form.estado.data,
                True  # Novo produto sempre disponível
            ))
            product_id = cur.lastrowid

            upload_folder = current_app.config['UPLOAD_FOLDER']
            if not os.path.exists(upload_folder):
                os.makedirs(upload_folder)

            saved_photos_filenames = []
            for photo_file in form.photos.data:
                if photo_file and photo_file.filename:
                    original_filename = secure_filename(photo_file.filename)
                    _, extension = os.path.splitext(original_filename)
                    unique_filename = str(uuid.uuid4()) + extension

                    save_path = os.path.join(upload_folder, unique_filename)
                    photo_file.save(save_path)
                    saved_photos_filenames.append(unique_filename)

            if saved_photos_filenames:
                image_records = [(product_id, filename) for filename in saved_photos_filenames]
                cur.executemany("""
                    INSERT INTO product_images (product_id, filename)
                    VALUES (%s, %s)
                """, image_records)

            db.commit()
            flash('Produto criado com sucesso!', 'success')
            return redirect(url_for('products.detail', product_id=product_id))
        except Exception as e:
            db.rollback()
            flash(f'Ocorreu um erro ao criar o produto: {str(e)}', 'danger')
            current_app.logger.error(f"Erro ao criar produto: {e}")

    return render_template('create_product.html', form=form)


@bp.route('/<int:product_id>/edit', methods=['GET','POST'])
def edit(product_id):
    if 'user_id' not in session:
        flash('Faça login para editar.', 'warning')
        return redirect(url_for('auth.login'))

    db = get_db()
    cur_dict = db.cursor(dictionary=True)

    # Busca os detalhes do produto
    cur_dict.execute("SELECT * FROM products WHERE id = %s", (product_id,))
    prod = cur_dict.fetchone()

    if prod is None or prod['user_id'] != session['user_id']:
        flash('Produto não encontrado ou sem permissão.', 'danger')
        return redirect(url_for('products.index'))

    # Busca as imagens existentes do produto
    cur_dict.execute("SELECT id, filename FROM product_images WHERE product_id = %s", (product_id,))
    product_images = cur_dict.fetchall()
    cur_dict.close()

    # Instancia o form
    form = ProductForm(request.form if request.method == 'POST' else None)

    if request.method == 'GET':
        form.title.data = prod.get('title')
        form.description.data = prod.get('description')
        form.price.data = prod.get('price')
        form.is_negotiable.data = prod.get('is_negotiable')
        form.category.data = prod.get('category_id')
        form.subcategory.data = prod.get('subcategory_id')
        form.estado.data = prod.get('estado')  # valor atual do estado

    _load_category_choices(form)

    if request.method == 'POST':
        # Validação do formulário em POST
        if not form.validate():
            flash('Erro ao validar o formulário. Por favor, verifique os campos.', 'danger')
            for field, errors in form.errors.items():
                for error in errors:
                    flash(f'Erro no campo {field}: {error}', 'danger')
            current_app.logger.error(f"Erros de validação no formulário de edição para produto {product_id}: {form.errors}")
            return render_template('edit_product.html', form=form, product=prod, product_images=product_images)

        cur_update = db.cursor()
        try:
            # Atualiza os dados do produto
            cur_update.execute("""
                UPDATE products
                SET category_id=%s,
                    subcategory_id=%s,
                    title=%s,
                    description=%s,
                    price=%s,
                    is_negotiable=%s,
                    estado=%s
                WHERE id=%s AND user_id=%s
            """, (
                form.category.data,
                form.subcategory.data,
                form.title.data,
                form.description.data,
                float(form.price.data),
                form.is_negotiable.data,
                form.estado.data,
                product_id,
                session['user_id']
            ))

            upload_folder = current_app.config['UPLOAD_FOLDER']
            current_app.logger.debug(f"DEBUG: UPLOAD_FOLDER está configurado para: {upload_folder}")
            if not os.path.exists(upload_folder):
                os.makedirs(upload_folder)
                current_app.logger.info(f"INFO: Pasta de uploads criada: {upload_folder}")

            # --- Lógica de Gestão de Imagens ---

            # 1. Remover imagens assinaladas pelo usuário
            images_to_delete_ids_str = request.form.getlist('images_to_delete')
            current_app.logger.debug(f"DEBUG: IDs de imagens a serem apagadas (string do form): {images_to_delete_ids_str}")

            images_to_delete_ids = []
            for img_id_str in images_to_delete_ids_str:
                try:
                    images_to_delete_ids.append(int(img_id_str))
                except ValueError:
                    current_app.logger.warning(f"AVISO: ID de imagem inválido recebido para exclusão: '{img_id_str}'")

            if images_to_delete_ids:
                temp_cur = db.cursor(dictionary=True)
                placeholders = ', '.join(['%s'] * len(images_to_delete_ids))
                sql_select_filenames = f"SELECT filename FROM product_images WHERE id IN ({placeholders})"
                current_app.logger.debug(f"DEBUG: SQL SELECT para filenames: {sql_select_filenames} com IDs: {images_to_delete_ids}")
                temp_cur.execute(sql_select_filenames, tuple(images_to_delete_ids))
                files_to_delete = temp_cur.fetchall()
                temp_cur.close()

                sql_delete_db = f"DELETE FROM product_images WHERE id IN ({placeholders})"
                current_app.logger.debug(f"DEBUG: SQL DELETE da base de dados: {sql_delete_db} com IDs: {images_to_delete_ids}")
                cur_update.execute(sql_delete_db, tuple(images_to_delete_ids))
                current_app.logger.info(f"INFO: Removidas {cur_update.rowcount} imagens da base de dados.")

                # Apaga fisicamente do filesystem
                for file_record in files_to_delete:
                    file_path = os.path.join(upload_folder, file_record['filename'])
                    if os.path.exists(file_path):
                        try:
                            os.remove(file_path)
                            current_app.logger.info(f"INFO: Arquivo físico removido: {file_path}")
                        except OSError as e:
                            current_app.logger.error(f"ERRO: Erro ao remover arquivo físico {file_path}: {e}")
                            flash(f"Erro ao remover arquivo físico: {file_record['filename']}", 'warning')
                    else:
                        current_app.logger.warning(f"AVISO: Arquivo físico não encontrado para remoção: {file_path}")
            else:
                current_app.logger.info("INFO: Nenhum ID de imagem para apagar recebido do formulário ou IDs inválidos.")

            # 2. Adicionar novas imagens
            new_photos_to_save = []
            for photo_file in request.files.getlist('photos'):
                if photo_file and photo_file.filename:
                    original_filename = secure_filename(photo_file.filename)
                    _, extension = os.path.splitext(original_filename)
                    unique_filename = str(uuid.uuid4()) + extension

                    save_path = os.path.join(upload_folder, unique_filename)
                    try:
                        photo_file.save(save_path)
                        new_photos_to_save.append((product_id, unique_filename))
                        current_app.logger.info(f"INFO: Novo arquivo salvo: {unique_filename}")
                    except Exception as e:
                        current_app.logger.error(f"ERRO: Erro ao salvar novo arquivo {unique_filename}: {e}")
                        flash(f"Erro ao salvar novo arquivo: {unique_filename}", 'warning')

            if new_photos_to_save:
                cur_update.executemany("""
                    INSERT INTO product_images (product_id, filename)
                    VALUES (%s, %s)
                """, new_photos_to_save)
                current_app.logger.info(f"INFO: Inseridas {len(new_photos_to_save)} novas imagens na base de dados.")

            db.commit()
            flash('Produto atualizado com sucesso!', 'success')
            return redirect(url_for('products.detail', product_id=product_id))
        except Exception as e:
            db.rollback()
            flash(f'Erro ao atualizar o produto: {str(e)}', 'danger')
            current_app.logger.error(f"ERRO CRÍTICO: Erro ao editar produto {product_id}: {e}", exc_info=True)
        finally:
            cur_update.close()

    return render_template('edit_product.html', form=form, product=prod, product_images=product_images)


@bp.route('/subcategories/<int:category_id>')
def subcategories(category_id):
    """
    Endpoint que retorna, em JSON, todas as subcategorias
    associadas à categoria cujo id foi passado na URL.
    """
    db = get_db()
    cur = db.cursor(dictionary=True)
    cur.execute(
        'SELECT id, name FROM subcategories WHERE category_id = %s ORDER BY name',
        (category_id,)
    )
    subs = cur.fetchall()
    return jsonify(subcategories=subs)


@bp.route('/<int:product_id>')
def detail(product_id):
    db = get_db()
    cur = db.cursor(dictionary=True)
    cur.execute("""
        SELECT p.*, u.username,
               c.name AS category, sc.name AS subcategory
          FROM products p
          JOIN users u         ON p.user_id = u.id
          JOIN categories c    ON p.category_id = c.id
          JOIN subcategories sc ON p.subcategory_id = sc.id
         WHERE p.id = %s
    """, (product_id,))
    product = cur.fetchone()
    cur.execute("SELECT filename FROM product_images WHERE product_id = %s", (product_id,))
    images = cur.fetchall()
    return render_template('product_detail.html',
                           product=product, images=images)


@bp.route('/<int:product_id>/delete', methods=['POST'])
def delete(product_id):
    if 'user_id' not in session:
        flash('Faça login para excluir o produto.', 'warning')
        return redirect(url_for('auth.login'))

    db = get_db()
    cur = db.cursor(dictionary=True)

    # 1. Verificar se o produto existe e pertence ao usuário
    cur.execute("SELECT * FROM products WHERE id = %s", (product_id,))
    product = cur.fetchone()

    if not product or product['user_id'] != session['user_id']:
        flash('Produto não encontrado ou sem permissão.', 'danger')
        return redirect(url_for('products.index'))

    try:
        # Em vez de apagar fisicamente, apenas marcamos is_available = FALSE
        cur.execute("""
            UPDATE products
               SET is_available = FALSE
             WHERE id = %s AND user_id = %s
        """, (product_id, session['user_id']))
        db.commit()
        flash('Produto marcado como indisponível.', 'success')
        current_app.logger.info(f"Produto {product_id} marcado como indisponível.")
    except Exception as e:
        db.rollback()
        flash(f'Ocorreu um erro ao marcar o produto como indisponível: {str(e)}', 'danger')
        current_app.logger.error(f"Erro ao marcar produto {product_id} como indisponível: {e}", exc_info=True)

    return redirect(url_for('products.index'))
