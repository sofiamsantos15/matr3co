-- Criação do utilizador
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';

-- Concessão de privilégios
GRANT ALL PRIVILEGES ON *.* TO '${MYSQL_USER}'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;

-- As linhas abaixo estão comentadas porque parece que são exemplos de como pode criar outro utilizador
-- GRANT ALL PRIVILEGES ON *.* TO 'flask_user'@'%' IDENTIFIED BY 'flask_password' WITH GRANT OPTION;
-- FLUSH PRIVILEGES;


-- Criação do banco de dados e tabela para o CRUD
CREATE DATABASE IF NOT EXISTS matr3co_db;
USE matr3co_db;

-- 1) Tabela de utilizadores
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    photo VARCHAR(255) DEFAULT NULL,
    profile ENUM('user','admin') NOT NULL DEFAULT 'user',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);


-- 1) Tabela de categorias principais
CREATE TABLE IF NOT EXISTS categories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 2) Tabela de subcategorias ligadas a uma categoria
CREATE TABLE IF NOT EXISTS subcategories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    category_id INT NOT NULL,
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE
);

-- 3) Tabela de produtos que são comercializados no site
CREATE TABLE IF NOT EXISTS products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    category_id INT NOT NULL,
    subcategory_id INT NOT NULL,
    title VARCHAR(150) NOT NULL,
    description TEXT NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    is_negotiable BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id)          REFERENCES users(id)          ON DELETE CASCADE,
    FOREIGN KEY (category_id)      REFERENCES categories(id)     ON DELETE RESTRICT,
    FOREIGN KEY (subcategory_id)   REFERENCES subcategories(id)  ON DELETE RESTRICT
);

-- 4) Tabela de imagens de cada produto 
CREATE TABLE IF NOT EXISTS product_images (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    filename VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
);

-- Inserir dados iniciais
-- 1) Utilizadores
-- O primeiro utilizador é o admin que tem acesso ao backoffice
INSERT INTO users (username, email, password, profile, photo, is_active)
VALUES (
    'admin',
    'joao.silva@example.com',
    '1234',
    'admin',
    NULL, -- Corrigido: 'NULL' em vez de 'NULL,'
    TRUE
);
-- 2) Dados de categorias 
Insert into categories (name)
            Values('Ferramentas');

Insert into categories (name)
            Values('Areias e Britas');

Insert into categories (name)
            Values('Madeiras');

Insert into categories (name)
            Values('Tintas');

-- 2) Dados de subcategorias 
Insert into subcategories (category_id, name)
Values(1,'Martelos');

Insert into subcategories (category_id, name)
Values(1,'Chaves de Fendas');

Insert into subcategories (category_id, name)
Values(1,'Alicates');

Insert into subcategories (category_id, name)
Values(2,'Areia');

Insert into subcategories (category_id, name)
Values(2,'Brita');

Insert into subcategories (category_id, name)
Values(2,'Restos de inertes embalados');

Insert into subcategories (category_id, name)
Values(3,'Tábuas e Barrotes');

Insert into subcategories (category_id, name)
Values(3,'Paineis OSB, MDF ou contraplacado');

Insert into subcategories (category_id, name)
Values(4,'Tintas de Exterior');