-- Criação do utilizador
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';

-- Concessão de privilégios
GRANT ALL PRIVILEGES ON *.* TO '${MYSQL_USER}'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;

-- Criação do banco de dados e seleção
CREATE DATABASE IF NOT EXISTS matr3co_db;
USE matr3co_db;

-- 1) Tabela de utilizadores (sem alterações)
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

-- 2) Tabela de categorias principais (sem alterações)
CREATE TABLE IF NOT EXISTS categories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 3) Tabela de subcategorias ligadas a uma categoria (sem alterações)
CREATE TABLE IF NOT EXISTS subcategories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    category_id INT NOT NULL,
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE
);

-- 4) Tabela de produtos (ajustes: estado e disponibilidade, sem quantidade)
CREATE TABLE IF NOT EXISTS products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    category_id INT NOT NULL,
    subcategory_id INT NOT NULL,
    title VARCHAR(150) NOT NULL,
    description TEXT NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    is_negotiable BOOLEAN NOT NULL DEFAULT FALSE,

    -- Nova coluna para estado de conservação do produto
    estado ENUM(
        'novo',
        'seminovo',
        'usado',
        'recondicionado'
    ) NOT NULL DEFAULT 'usado',

    -- Nova coluna para indicar se o produto está disponível para venda
    is_available BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id)          REFERENCES users(id)          ON DELETE CASCADE,
    FOREIGN KEY (category_id)      REFERENCES categories(id)     ON DELETE RESTRICT,
    FOREIGN KEY (subcategory_id)   REFERENCES subcategories(id)  ON DELETE RESTRICT
);

-- 5) Tabela de imagens de cada produto (sem alterações)
CREATE TABLE IF NOT EXISTS product_images (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    filename VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
);

-- 6) Novas tabelas para permitir compra de produtos (cada item = 1 produto)

-- 6.1) Tabela de pedidos (orders)
CREATE TABLE IF NOT EXISTS orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    buyer_id INT NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    status ENUM(
        'pendente',       -- pedido criado, esperando pagamento
        'pago',          -- pagamento confirmado
        'enviado',       -- enviado
        'concluído',     -- concluído
        'cancelado'      -- cancelado
    ) NOT NULL DEFAULT 'pendente',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (buyer_id) REFERENCES users(id) ON DELETE RESTRICT
);

-- 6.2) Tabela de itens de cada pedido (order_items)
--     Não há coluna de quantidade: cada linha representa exatamente 1 unidade do produto.
CREATE TABLE IF NOT EXISTS order_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    price DECIMAL(10,2) NOT NULL,  -- preço unitário do produto no momento da compra
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id)   REFERENCES orders(id)    ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id)  ON DELETE RESTRICT
);

-- 7) Inserir dados iniciais
-- Forçar a codificação UTF-8 na ligação
SET NAMES 'utf8mb4';
SET CHARACTER SET utf8mb4;
SET character_set_connection = utf8mb4;

-- 7.1) Usuários
INSERT INTO users (username, email, password, profile, photo, is_active)
VALUES 
    (
        'admin',
        'joao.silva@example.com',
        '1234',
        'admin',
        NULL,
        TRUE
    );

-- 7.2) Dados de categorias 
INSERT IGNORE INTO categories (name) VALUES 
    ('Estrutura e Aglomerantes'),
    ('Tijolos, Blocos e Pré-fabricados'),
    ('Areias, Britas e Inertes'),
    ('Metais e Ferragens'),
    ('Madeira e Derivados'),
    ('Coberturas e Telhas'),
    ('Isolamentos e Impermeabilização'),
    ('Revestimentos e Acabamentos'),
    ('Canalizações e Acessórios'),
    ('Elétrico e Iluminação'),
    ('Ferramentas e Equipamentos'),
    ('Proteção e Segurança'),
    ('Sobrantes Diversos');

-- 7.3) Inserir subcategorias

-- Estrutura e Aglomerantes
SET @category_id = (SELECT id FROM categories WHERE name = 'Estrutura e Aglomerantes');
INSERT IGNORE INTO subcategories (category_id, name) VALUES 
    (@category_id, 'Cimento e argamassas em sacos (fechados)'),
    (@category_id, 'Cal e gesso'),
    (@category_id, 'Adjuvantes e aditivos'),
    (@category_id, 'Sacos de betão seco');

-- Tijolos, Blocos e Pré-fabricados
SET @category_id = (SELECT id FROM categories WHERE name = 'Tijolos, Blocos e Pré-fabricados');
INSERT IGNORE INTO subcategories (category_id, name) VALUES 
    (@category_id, 'Tijolos cerâmicos'),
    (@category_id, 'Blocos de cimento'),
    (@category_id, 'Peças pré-fabricadas (lajes, vigotas, lintéis)'),
    (@category_id, 'Restos de paletes');

-- Areias, Britas e Inertes
SET @category_id = (SELECT id FROM categories WHERE name = 'Areias, Britas e Inertes');
INSERT IGNORE INTO subcategories (category_id, name) VALUES 
    (@category_id, 'Areia (ensacada ou a granel)'),
    (@category_id, 'Brita'),
    (@category_id, 'Restos de inertes embalados');

-- Metais e Ferragens
SET @category_id = (SELECT id FROM categories WHERE name = 'Metais e Ferragens');
INSERT IGNORE INTO subcategories (category_id, name) VALUES 
    (@category_id, 'Vergas e varões de aço'),
    (@category_id, 'Restos de malhas eletrossoldadas'),
    (@category_id, 'Perfis metálicos (sobras de corte)'),
    (@category_id, 'Ferragens diversas');

-- Madeira e Derivados
SET @category_id = (SELECT id FROM categories WHERE name = 'Madeira e Derivados');
INSERT IGNORE INTO subcategories (category_id, name) VALUES 
    (@category_id, 'Tábuas e barrotes'),
    (@category_id, 'Painéis OSB, MDF ou contraplacado'),
    (@category_id, 'Ripas e sarrafos'),
    (@category_id, 'Paletes de madeira reutilizáveis');

-- Coberturas e Telhas
SET @category_id = (SELECT id FROM categories WHERE name = 'Coberturas e Telhas');
INSERT IGNORE INTO subcategories (category_id, name) VALUES 
    (@category_id, 'Telhas cerâmicas ou de betão (sobras)'),
    (@category_id, 'Chapas metálicas ou plásticas'),
    (@category_id, 'Isolamentos térmicos para cobertura');

-- Isolamentos e Impermeabilização
SET @category_id = (SELECT id FROM categories WHERE name = 'Isolamentos e Impermeabilização');
INSERT IGNORE INTO subcategories (category_id, name) VALUES 
    (@category_id, 'Restos de rolos de lã de vidro ou rocha'),
    (@category_id, 'Painéis XPS/EPS'),
    (@category_id, 'Mantas asfálticas ou telas'),
    (@category_id, 'Membranas e geotêxteis');

-- Revestimentos e Acabamentos
SET @category_id = (SELECT id FROM categories WHERE name = 'Revestimentos e Acabamentos');
INSERT IGNORE INTO subcategories (category_id, name) VALUES 
    (@category_id, 'Azulejos, ladrilhos, mosaicos'),
    (@category_id, 'Rodapés'),
    (@category_id, 'Restos de pavimento flutuante ou vinílico'),
    (@category_id, 'Tintas e vernizes (em bom estado e selados)');

-- Canalizações e Acessórios
SET @category_id = (SELECT id FROM categories WHERE name = 'Canalizações e Acessórios');
INSERT IGNORE INTO subcategories (category_id, name) VALUES 
    (@category_id, 'Tubos e conexões (PVC, PEX, multicamada)'),
    (@category_id, 'Torneiras, válvulas, sifões'),
    (@category_id, 'Bombas e acessórios hidráulicos');

-- Elétrico e Iluminação
SET @category_id = (SELECT id FROM categories WHERE name = 'Elétrico e Iluminação');
INSERT IGNORE INTO subcategories (category_id, name) VALUES 
    (@category_id, 'Cabos e rolos'),
    (@category_id, 'Tomadas, interruptores, disjuntores'),
    (@category_id, 'Luminárias e projetores (novos ou em ótimo estado)');

-- Ferramentas e Equipamentos
SET @category_id = (SELECT id FROM categories WHERE name = 'Ferramentas e Equipamentos');
INSERT IGNORE INTO subcategories (category_id, name) VALUES 
    (@category_id, 'Ferramentas manuais usadas em bom estado'),
    (@category_id, 'Ferramentas elétricas em funcionamento'),
    (@category_id, 'Escadas, baldes de obra, andaimes');

-- Proteção e Segurança
SET @category_id = (SELECT id FROM categories WHERE name = 'Proteção e Segurança');
INSERT IGNORE INTO subcategories (category_id, name) VALUES 
    (@category_id, 'Equipamento de proteção individual (não usado)'),
    (@category_id, 'Redes de proteção, sinalização'),
    (@category_id, 'Extintores e suportes');

-- Sobrantes Diversos
SET @category_id = (SELECT id FROM categories WHERE name = 'Sobrantes Diversos');
INSERT IGNORE INTO subcategories (category_id, name) VALUES 
    (@category_id, 'Caixas de pregos, parafusos, buchas'),
    (@category_id, 'Selantes e colas (embalados)'),
    (@category_id, 'Restos de cofragens reutilizáveis');
