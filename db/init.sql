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
    is_available ENUM(
    'indisponivel',
    'disponivel', 
    'reservado', 
    'vendido'
    ) NOT NULL DEFAULT 'disponivel',

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
        'Administrador',
        'admin',
        'pbkdf2:sha256:260000$2TCoKx9ZsUgnklPv$932506fb5cb0d12b1edcee6f7c3ee4728133b33c311548d03a95c0a6a594453d',
        'admin',
        NULL,
        TRUE
    ),
    (
        'Sofia Santos',
        'sofia.marcelino.santos@gmail.com',
        'pbkdf2:sha256:260000$2TCoKx9ZsUgnklPv$932506fb5cb0d12b1edcee6f7c3ee4728133b33c311548d03a95c0a6a594453d',
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

-- Inserção do produto: Cimento CP II 44kg
INSERT INTO products
    (user_id, category_id, subcategory_id, title, description, price, is_negotiable, estado, is_available)
VALUES
    (1,
     (SELECT id FROM categories WHERE name = 'Estrutura e Aglomerantes'),
     (SELECT id FROM subcategories WHERE name = 'Cimento e argamassas em sacos (fechados)' 
       AND category_id = (SELECT id FROM categories WHERE name = 'Estrutura e Aglomerantes')),
     'Cimento CP II 44kg',
     'Descrição detalhada de Cimento CP II 44kg. Produto de alta qualidade e pronto a usar.',
     467.23,
     1,
     'seminovo',
     'disponivel'
    );SET @pid = LAST_INSERT_ID();
INSERT INTO product_images (product_id, filename) VALUES (@pid, 'cimento_cp_ii_44kg.jpg');

-- Inserção do produto: Tábua de Pinheiro 2x10x300 cm 2
INSERT INTO products
    (user_id, category_id, subcategory_id, title, description, price, is_negotiable, estado, is_available)
VALUES
    (1,
     (SELECT id FROM categories WHERE name = 'Madeira e Derivados'),
     (SELECT id FROM subcategories WHERE name = 'Tábuas e barrotes' 
       AND category_id = (SELECT id FROM categories WHERE name = 'Madeira e Derivados')),
     'Tábua de Pinheiro 2x10x300 cm 2',
     'Descrição detalhada de Tábua de Pinheiro 2x10x300 cm 2. Produto de alta qualidade e pronto a usar.',
     323.45,
     0,
     'usado',
     'disponivel'
    );SET @pid = LAST_INSERT_ID();
INSERT INTO product_images (product_id, filename) VALUES (@pid, 't_bua_de_pinheiro_2x10x300_cm_2.jpg');

-- Inserção do produto: Tubo PVC 3/4" x 4m 3
INSERT INTO products
    (user_id, category_id, subcategory_id, title, description, price, is_negotiable, estado, is_available)
VALUES
    (1,
     (SELECT id FROM categories WHERE name = 'Canalizações e Acessórios'),
     (SELECT id FROM subcategories WHERE name = 'Tubos e conexões (PVC, PEX, multicamada)' 
       AND category_id = (SELECT id FROM categories WHERE name = 'Canalizações e Acessórios')),
     'Tubo PVC 3/4" x 4m 3',
     'Descrição detalhada de Tubo PVC 3/4" x 4m 3. Produto de alta qualidade e pronto a usar.',
     75.10,
     1,
     'novo',
     'disponivel'
    );SET @pid = LAST_INSERT_ID();
INSERT INTO product_images (product_id, filename) VALUES (@pid, 'tubo_pvc_3_4_x_4m_3.jpg');

-- Inserção do produto: Rodapé MDF 7cm (por metro) 4
INSERT INTO products
    (user_id, category_id, subcategory_id, title, description, price, is_negotiable, estado, is_available)
VALUES
    (1,
     (SELECT id FROM categories WHERE name = 'Revestimentos e Acabamentos'),
     (SELECT id FROM subcategories WHERE name = 'Rodapés' 
       AND category_id = (SELECT id FROM categories WHERE name = 'Revestimentos e Acabamentos')),
     'Rodapé MDF 7cm (por metro) 4',
     'Descrição detalhada de Rodapé MDF 7cm (por metro) 4. Produto de alta qualidade e pronto a usar.',
     15.75,
     0,
     'recondicionado',
     'disponivel'
    );SET @pid = LAST_INSERT_ID();
INSERT INTO product_images (product_id, filename) VALUES (@pid, 'rodap_mdf_7cm_por_metro_4.jpg');

-- Inserção do produto: Bloco de Cimento 15x20x40 cm 5
INSERT INTO products
    (user_id, category_id, subcategory_id, title, description, price, is_negotiable, estado, is_available)
VALUES
    (1,
     (SELECT id FROM categories WHERE name = 'Tijolos, Blocos e Pré-fabricados'),
     (SELECT id FROM subcategories WHERE name = 'Blocos de cimento' 
       AND category_id = (SELECT id FROM categories WHERE name = 'Tijolos, Blocos e Pré-fabricados')),
     'Bloco de Cimento 15x20x40 cm 5',
     'Descrição detalhada de Bloco de Cimento 15x20x40 cm 5. Produto de alta qualidade e pronto a usar.',
     3.50,
     1,
     'seminovo',
     'disponivel'
    );SET @pid = LAST_INSERT_ID();
INSERT INTO product_images (product_id, filename) VALUES (@pid, 'bloco_de_cimento_15x20x40_cm_5.jpg');

-- Inserção do produto: Torneira Monocomando Lavatório 6
INSERT INTO products
    (user_id, category_id, subcategory_id, title, description, price, is_negotiable, estado, is_available)
VALUES
    (1,
     (SELECT id FROM categories WHERE name = 'Canalizações e Acessórios'),
     (SELECT id FROM subcategories WHERE name = 'Torneiras, válvulas, sifões' 
       AND category_id = (SELECT id FROM categories WHERE name = 'Canalizações e Acessórios')),
     'Torneira Monocomando Lavatório 6',
     'Descrição detalhada de Torneira Monocomando Lavatório 6. Produto de alta qualidade e pronto a usar.',
     45.90,
     0,
     'usado',
     'disponivel'
    );SET @pid = LAST_INSERT_ID();
INSERT INTO product_images (product_id, filename) VALUES (@pid, 'torneira_monocomando_lavat_rio_6.png');

-- Inserção do produto: Furadeira Bosch 500W 7
INSERT INTO products
    (user_id, category_id, subcategory_id, title, description, price, is_negotiable, estado, is_available)
VALUES
    (1,
     (SELECT id FROM categories WHERE name = 'Ferramentas e Equipamentos'),
     (SELECT id FROM subcategories WHERE name = 'Ferramentas elétricas em funcionamento' 
       AND category_id = (SELECT id FROM categories WHERE name = 'Ferramentas e Equipamentos')),
     'Furadeira Bosch 500W 7',
     'Descrição detalhada de Furadeira Bosch 500W 7. Produto de alta qualidade e pronto a usar.',
     120.00,
     1,
     'novo',
     'disponivel'
    );SET @pid = LAST_INSERT_ID();
INSERT INTO product_images (product_id, filename) VALUES (@pid, 'furadeira_bosch_500w_7.jpg');

-- Inserção do produto: Telha Cerâmica Marselha 8
INSERT INTO products
    (user_id, category_id, subcategory_id, title, description, price, is_negotiable, estado, is_available)
VALUES
    (1,
     (SELECT id FROM categories WHERE name = 'Coberturas e Telhas'),
     (SELECT id FROM subcategories WHERE name = 'Telhas cerâmicas ou de betão (sobras)' 
       AND category_id = (SELECT id FROM categories WHERE name = 'Coberturas e Telhas')),
     'Telha Cerâmica Marselha 8',
     'Descrição detalhada de Telha Cerâmica Marselha 8. Produto de alta qualidade e pronto a usar.',
     2.25,
     0,
     'seminovo',
     'disponivel'
    );SET @pid = LAST_INSERT_ID();
INSERT INTO product_images (product_id, filename) VALUES (@pid, 'telha_cer_mica_marselha_8.png');

-- Inserção do produto: Conjunto de Chaves de Fenda 9
INSERT INTO products
    (user_id, category_id, subcategory_id, title, description, price, is_negotiable, estado, is_available)
VALUES
    (1,
     (SELECT id FROM categories WHERE name = 'Ferramentas e Equipamentos'),
     (SELECT id FROM subcategories WHERE name = 'Ferramentas manuais usadas em bom estado' 
       AND category_id = (SELECT id FROM categories WHERE name = 'Ferramentas e Equipamentos')),
     'Conjunto de Chaves de Fenda 9',
     'Descrição detalhada de Conjunto de Chaves de Fenda 9. Produto de alta qualidade e pronto a usar.',
     35.80,
     1,
     'usado',
     'disponivel'
    );SET @pid = LAST_INSERT_ID();
INSERT INTO product_images (product_id, filename) VALUES (@pid, 'conjunto_de_chaves_de_fenda_9.jpg');

-- Inserção do produto: Saco de Areia 50kg 10
INSERT INTO products
    (user_id, category_id, subcategory_id, title, description, price, is_negotiable, estado, is_available)
VALUES
    (1,
     (SELECT id FROM categories WHERE name = 'Areias, Britas e Inertes'),
     (SELECT id FROM subcategories WHERE name = 'Areia (ensacada ou a granel)' 
       AND category_id = (SELECT id FROM categories WHERE name = 'Areias, Britas e Inertes')),
     'Saco de Areia 50kg 10',
     'Descrição detalhada de Saco de Areia 50kg 10. Produto de alta qualidade e pronto a usar.',
     7.50,
     0,
     'usado',
     'disponivel'
    );SET @pid = LAST_INSERT_ID();
INSERT INTO product_images (product_id, filename) VALUES (@pid, 'saco_de_areia_50kg_10.jpg');

-- Inserção do produto: Capacete de Proteção EN397 11
INSERT INTO products
    (user_id, category_id, subcategory_id, title, description, price, is_negotiable, estado, is_available)
VALUES
    (2,
     (SELECT id FROM categories WHERE name = 'Proteção e Segurança'),
     (SELECT id FROM subcategories WHERE name = 'Equipamento de proteção individual (não usado)' 
       AND category_id = (SELECT id FROM categories WHERE name = 'Proteção e Segurança')),
     'Capacete de Proteção EN397 11',
     'Descrição detalhada de Capacete de Proteção EN397 11. Produto de alta qualidade e pronto a usar.',
     22.00,
     1,
     'novo',
     'disponivel'
    );SET @pid = LAST_INSERT_ID();
INSERT INTO product_images (product_id, filename) VALUES (@pid, 'capacete_de_prote_o_en397_11.jpg');

-- Inserção do produto: Perfil Metálico U 50x20x2 mm - 2m 12
INSERT INTO products
    (user_id, category_id, subcategory_id, title, description, price, is_negotiable, estado, is_available)
VALUES
    (2,
     (SELECT id FROM categories WHERE name = 'Metais e Ferragens'),
     (SELECT id FROM subcategories WHERE name = 'Perfis metálicos (sobras de corte)' 
       AND category_id = (SELECT id FROM categories WHERE name = 'Metais e Ferragens')),
     'Perfil Metálico U 50x20x2 mm - 2m 12',
     'Descrição detalhada de Perfil Metálico U 50x20x2 mm - 2m 12. Produto de alta qualidade e pronto a usar.',
     45.00,
     0,
     'seminovo',
     'disponivel'
    );SET @pid = LAST_INSERT_ID();
INSERT INTO product_images (product_id, filename) VALUES (@pid, 'perfil_met_lico_u_50x20x2_mm_2m_12.jpg');

-- Inserção do produto: Rolo de Cabo Elétrico 2,5mm² - 100m 13
INSERT INTO products
    (user_id, category_id, subcategory_id, title, description, price, is_negotiable, estado, is_available)
VALUES
    (2,
     (SELECT id FROM categories WHERE name = 'Elétrico e Iluminação'),
     (SELECT id FROM subcategories WHERE name = 'Cabos e rolos' 
       AND category_id = (SELECT id FROM categories WHERE name = 'Elétrico e Iluminação')),
     'Rolo de Cabo Elétrico 2,5mm² - 100m 13',
     'Descrição detalhada de Rolo de Cabo Elétrico 2,5mm² - 100m 13. Produto de alta qualidade e pronto a usar.',
     150.00,
     1,
     'recondicionado',
     'disponivel'
    );SET @pid = LAST_INSERT_ID();
INSERT INTO product_images (product_id, filename) VALUES (@pid, 'rolo_de_cabo_el_trico_2_5mm_2_-_100m_13.png');

-- Inserção do produto: Bombas e acessórios hidráulicos em bom estado 14
INSERT INTO products
    (user_id, category_id, subcategory_id, title, description, price, is_negotiable, estado, is_available)
VALUES
    (2,
     (SELECT id FROM categories WHERE name = 'Canalizações e Acessórios'),
     (SELECT id FROM subcategories WHERE name = 'Bombas e acessórios hidráulicos' 
       AND category_id = (SELECT id FROM categories WHERE name = 'Canalizações e Acessórios')),
     'Bombas e acessórios hidráulicos em bom estado 14',
     'Descrição detalhada de Bombas e acessórios hidráulicos em bom estado 14. Produto de alta qualidade e pronto a usar.',
     89.99,
     0,
     'usado',
     'disponivel'
    );SET @pid = LAST_INSERT_ID();
INSERT INTO product_images (product_id, filename) VALUES (@pid, 'bombas_e_acess_rios_hidr_u_licos_em_bom_estado_14.jpg');

-- Inserção do produto: Extintores e suportes em bom estado 15
INSERT INTO products
    (user_id, category_id, subcategory_id, title, description, price, is_negotiable, estado, is_available)
VALUES
    (2,
     (SELECT id FROM categories WHERE name = 'Proteção e Segurança'),
     (SELECT id FROM subcategories WHERE name = 'Extintores e suportes' 
       AND category_id = (SELECT id FROM categories WHERE name = 'Proteção e Segurança')),
     'Extintores e suportes em bom estado 15',
     'Descrição detalhada de Extintores e suportes em bom estado 15. Produto de alta qualidade e pronto a usar.',
     150.50,
     1,
     'usado',
     'disponivel'
    );SET @pid = LAST_INSERT_ID();
INSERT INTO product_images (product_id, filename) VALUES (@pid, 'extintores_e_suportes_em_bom_estado_15.png');

-- Inserção do produto: Painel OSB 15mm 244x122 cm 16
INSERT INTO products
    (user_id, category_id, subcategory_id, title, description, price, is_negotiable, estado, is_available)
VALUES
    (2,
     (SELECT id FROM categories WHERE name = 'Madeira e Derivados'),
     (SELECT id FROM subcategories WHERE name = 'Painéis OSB, MDF ou contraplacado' 
       AND category_id = (SELECT id FROM categories WHERE name = 'Madeira e Derivados')),
     'Painel OSB 15mm 244x122 cm 16',
     'Descrição detalhada de Painel OSB 15mm 244x122 cm 16. Produto de alta qualidade e pronto a usar.',
     32.75,
     0,
     'novo',
     'disponivel'
    );SET @pid = LAST_INSERT_ID();
INSERT INTO product_images (product_id, filename) VALUES (@pid, 'painel_osb_15mm_244x122_cm_16.jpg');

-- Inserção do produto: Laje Pré-fabricada 1x1 m 17
INSERT INTO products
    (user_id, category_id, subcategory_id, title, description, price, is_negotiable, estado, is_available)
VALUES
    (1,
     (SELECT id FROM categories WHERE name = 'Tijolos, Blocos e Pré-fabricados'),
     (SELECT id FROM subcategories WHERE name = 'Peças pré-fabricadas (lajes, vigotas, lintéis)' 
       AND category_id = (SELECT id FROM categories WHERE name = 'Tijolos, Blocos e Pré-fabricados')),
     'Laje Pré-fabricada 1x1 m 17',
     'Descrição detalhada de Laje Pré-fabricada 1x1 m 17. Produto de alta qualidade e pronto a usar.',
     120.00,
     1,
     'seminovo',
     'disponivel'
    );SET @pid = LAST_INSERT_ID();
INSERT INTO product_images (product_id, filename) VALUES (@pid, 'laje_pr_-fabricada_1x1_m_17.jpg');

-- Inserção do produto: Sobrantes de paletes em bom estado 18
INSERT INTO products
    (user_id, category_id, subcategory_id, title, description, price, is_negotiable, estado, is_available)
VALUES
    (1,
     (SELECT id FROM categories WHERE name = 'Tijolos, Blocos e Pré-fabricados'),
     (SELECT id FROM subcategories WHERE name = 'Restos de paletes' 
       AND category_id = (SELECT id FROM categories WHERE name = 'Tijolos, Blocos e Pré-fabricados')),
     'Restos de paletes em bom estado 18',
     'Descrição detalhada de Restos de paletes em bom estado 18. Produto de alta qualidade e pronto a usar.',
     5.00,
     0,
     'usado',
     'disponivel'
    );SET @pid = LAST_INSERT_ID();
INSERT INTO product_images (product_id, filename) VALUES (@pid, 'restos_de_paletes_em_bom_estado_18.jpg');

-- Inserção do produto: Brita N.º 2 - 1m³ 19
INSERT INTO products
    (user_id, category_id, subcategory_id, title, description, price, is_negotiable, estado, is_available)
VALUES
    (1,
     (SELECT id FROM categories WHERE name = 'Areias, Britas e Inertes'),
     (SELECT id FROM subcategories WHERE name = 'Brita' 
       AND category_id = (SELECT id FROM categories WHERE name = 'Areias, Britas e Inertes')),
     'Brita N.º 2 - 1m³ 19',
     'Descrição detalhada de Brita N.º 2 - 1m³ 19. Produto de alta qualidade e pronto a usar.',
     40.00,
     1,
     'seminovo',
     'disponivel'
    );SET @pid = LAST_INSERT_ID();
INSERT INTO product_images (product_id, filename) VALUES (@pid, 'brita_n_2_-_1m_19.jpg');

-- Inserção do produto: Perfis metálicos (sobras de corte) em bom estado 20
INSERT INTO products
    (user_id, category_id, subcategory_id, title, description, price, is_negotiable, estado, is_available)
VALUES
    (1,
     (SELECT id FROM categories WHERE name = 'Metais e Ferragens'),
     (SELECT id FROM subcategories WHERE name = 'Perfis metálicos (sobras de corte)' 
       AND category_id = (SELECT id FROM categories WHERE name = 'Metais e Ferragens')),
     'Perfis metálicos (sobras de corte) em bom estado 20',
     'Descrição detalhada de Perfis metálicos (sobras de corte) em bom estado 20. Produto de alta qualidade e pronto a usar.',
     25.00,
     0,
     'usado',
     'disponivel'
    );SET @pid = LAST_INSERT_ID();
INSERT INTO product_images (product_id, filename) VALUES (@pid, 'perfis_met_licos_sobras_de_corte_em_bom_estado_20.jpg');

-- Inserção do produto: Luminária LED 10W 21
INSERT INTO products
    (user_id, category_id, subcategory_id, title, description, price, is_negotiable, estado, is_available)
VALUES
    (1,
     (SELECT id FROM categories WHERE name = 'Elétrico e Iluminação'),
     (SELECT id FROM subcategories WHERE name = 'Luminárias e projetores (novos ou em ótimo estado)' 
       AND category_id = (SELECT id FROM categories WHERE name = 'Elétrico e Iluminação')),
     'Luminária LED 10W 21',
     'Descrição detalhada de Luminária LED 10W 21. Produto de alta qualidade e pronto a usar.',
     18.90,
     1,
     'seminovo',
     'disponivel'
    );SET @pid = LAST_INSERT_ID();
INSERT INTO product_images (product_id, filename) VALUES (@pid, 'lumin_ria_led_10w_21.jpg');

-- Inserção do produto: Conjunto de Chaves de Fenda 22
INSERT INTO products
    (user_id, category_id, subcategory_id, title, description, price, is_negotiable, estado, is_available)
VALUES
    (1,
     (SELECT id FROM categories WHERE name = 'Ferramentas e Equipamentos'),
     (SELECT id FROM subcategories WHERE name = 'Ferramentas manuais usadas em bom estado' 
       AND category_id = (SELECT id FROM categories WHERE name = 'Ferramentas e Equipamentos')),
     'Conjunto de Chaves de Fenda 22',
     'Descrição detalhada de Conjunto de Chaves de Fenda 22. Produto de alta qualidade e pronto a usar.',
     32.00,
     0,
     'usado',
     'disponivel'
    );SET @pid = LAST_INSERT_ID();
INSERT INTO product_images (product_id, filename) VALUES (@pid, 'conjunto_de_chaves_de_fenda_22.jpg');

-- Inserção do produto: Saco de Areia 50kg 23
INSERT INTO products
    (user_id, category_id, subcategory_id, title, description, price, is_negotiable, estado, is_available)
VALUES
    (1,
     (SELECT id FROM categories WHERE name = 'Areias, Britas e Inertes'),
     (SELECT id FROM subcategories WHERE name = 'Areia (ensacada ou a granel)' 
       AND category_id = (SELECT id FROM categories WHERE name = 'Areias, Britas e Inertes')),
     'Saco de Areia 50kg 23',
     'Descrição detalhada de Saco de Areia 50kg 23. Produto de alta qualidade e pronto a usar.',
     7.80,
     1,
     'novo',
     'disponivel'
    );SET @pid = LAST_INSERT_ID();
INSERT INTO product_images (product_id, filename) VALUES (@pid, 'saco_de_areia_50kg_23.jpg');

-- Inserção do produto: Extintores e suportes em bom estado 24
INSERT INTO products
    (user_id, category_id, subcategory_id, title, description, price, is_negotiable, estado, is_available)
VALUES
    (1,
     (SELECT id FROM categories WHERE name = 'Proteção e Segurança'),
     (SELECT id FROM subcategories WHERE name = 'Extintores e suportes' 
       AND category_id = (SELECT id FROM categories WHERE name = 'Proteção e Segurança')),
     'Extintores e suportes em bom estado 24',
     'Descrição detalhada de Extintores e suportes em bom estado 24. Produto de alta qualidade e pronto a usar.',
     160.00,
     0,
     'seminovo',
     'disponivel'
    );SET @pid = LAST_INSERT_ID();
INSERT INTO product_images (product_id, filename) VALUES (@pid, 'extintores_e_suportes_em_bom_estado_24.jpg');

-- Inserção do produto: Painel OSB 15mm 244x122 cm 25
INSERT INTO products
    (user_id, category_id, subcategory_id, title, description, price, is_negotiable, estado, is_available)
VALUES
    (1,
     (SELECT id FROM categories WHERE name = 'Madeira e Derivados'),
     (SELECT id FROM subcategories WHERE name = 'Painéis OSB, MDF ou contraplacado' 
       AND category_id = (SELECT id FROM categories WHERE name = 'Madeira e Derivados')),
     'Painel OSB 15mm 244x122 cm 25',
     'Descrição detalhada de Painel OSB 15mm 244x122 cm 25. Produto de alta qualidade e pronto a usar.',
     30.00,
     1,
     'usado',
     'disponivel'
    );SET @pid = LAST_INSERT_ID();
INSERT INTO product_images (product_id, filename) VALUES (@pid, 'painel_osb_15mm_244x122_cm_25.jpg');

-- Inserção do produto: Laje Pré-fabricada 1x1 m 26
INSERT INTO products
    (user_id, category_id, subcategory_id, title, description, price, is_negotiable, estado, is_available)
VALUES
    (1,
     (SELECT id FROM categories WHERE name = 'Tijolos, Blocos e Pré-fabricados'),
     (SELECT id FROM subcategories WHERE name = 'Peças pré-fabricadas (lajes, vigotas, lintéis)' 
       AND category_id = (SELECT id FROM categories WHERE name = 'Tijolos, Blocos e Pré-fabricados')),
     'Laje Pré-fabricada 1x1 m 26',
     'Descrição detalhada de Laje Pré-fabricada 1x1 m 26. Produto de alta qualidade e pronto a usar.',
     118.50,
     0,
     'recondicionado',
     'disponivel'
    );SET @pid = LAST_INSERT_ID();
INSERT INTO product_images (product_id, filename) VALUES (@pid, 'laje_pr_-fabricada_1x1_m_26.jpg');

-- Inserção do produto: Restos de paletes em bom estado 27
INSERT INTO products
    (user_id, category_id, subcategory_id, title, description, price, is_negotiable, estado, is_available)
VALUES
    (1,
     (SELECT id FROM categories WHERE name = 'Tijolos, Blocos e Pré-fabricados'),
     (SELECT id FROM subcategories WHERE name = 'Restos de paletes' 
       AND category_id = (SELECT id FROM categories WHERE name = 'Tijolos, Blocos e Pré-fabricados')),
     'Restos de paletes em bom estado 27',
     'Descrição detalhada de Restos de paletes em bom estado 27. Produto de alta qualidade e pronto a usar.',
     6.00,
     1,
     'seminovo',
     'disponivel'
    );SET @pid = LAST_INSERT_ID();
INSERT INTO product_images (product_id, filename) VALUES (@pid, 'restos_de_paletes_em_bom_estado_27.jpg');

-- Inserção do produto: Brita N.º 2 - 1m³ 28
INSERT INTO products
    (user_id, category_id, subcategory_id, title, description, price, is_negotiable, estado, is_available)
VALUES
    (1,
     (SELECT id FROM categories WHERE name = 'Areias, Britas e Inertes'),
     (SELECT id FROM subcategories WHERE name = 'Brita' 
       AND category_id = (SELECT id FROM categories WHERE name = 'Areias, Britas e Inertes')),
     'Brita N.º 2 - 1m³ 28',
     'Descrição detalhada de Brita N.º 2 - 1m³ 28. Produto de alta qualidade e pronto a usar.',
     42.00,
     0,
     'usado',
     'disponivel'
    );SET @pid = LAST_INSERT_ID();
INSERT INTO product_images (product_id, filename) VALUES (@pid, 'brita_n_2_-_1m_28.jpg');

-- Inserção do produto: Conjunto de Chaves de Fenda 29
INSERT INTO products
    (user_id, category_id, subcategory_id, title, description, price, is_negotiable, estado, is_available)
VALUES
    (1,
     (SELECT id FROM categories WHERE name = 'Ferramentas e Equipamentos'),
     (SELECT id FROM subcategories WHERE name = 'Ferramentas manuais usadas em bom estado' 
       AND category_id = (SELECT id FROM categories WHERE name = 'Ferramentas e Equipamentos')),
     'Conjunto de Chaves de Fenda 29',
     'Descrição detalhada de Conjunto de Chaves de Fenda 29. Produto de alta qualidade e pronto a usar.',
     34.50,
     1,
     'semi­novo',
     'disponivel'
    );SET @pid = LAST_INSERT_ID();
INSERT INTO product_images (product_id, filename) VALUES (@pid, 'conjunto_de_chaves_de_fenda_29.jpg');

-- Inserção do produto: Bombas e acessórios hidráulicos em bom estado 30
INSERT INTO products
    (user_id, category_id, subcategory_id, title, description, price, is_negotiable, estado, is_available)
VALUES
    (1,
     (SELECT id FROM categories WHERE name = 'Canalizações e Acessórios'),
     (SELECT id FROM subcategories WHERE name = 'Bombas e acessórios hidráulicos' 
       AND category_id = (SELECT id FROM categories WHERE name = 'Canalizações e Acessórios')),
     'Bombas e acessórios hidráulicos em bom estado 30',
     'Descrição detalhada de Bombas e acessórios hidráulicos em bom estado 30. Produto de alta qualidade e pronto a usar.',
     92.30,
     0,
     'usado',
     'disponivel'
    );SET @pid = LAST_INSERT_ID();
INSERT INTO product_images (product_id, filename) VALUES (@pid, 'bombas_e_acess_rios_hidr_u_licos_em_bom_estado_30.jpg');
