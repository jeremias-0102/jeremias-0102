-- ============================================================
-- Banco de dados: farmacia
-- Versão: 1.0
-- Descrição: Estrutura completa de tabelas e relacionamentos
-- ============================================================

-- Cria o banco e seleciona
CREATE DATABASE IF NOT EXISTS farmacia
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE farmacia;

-- ============================================================
-- TABELA: usuarios (clientes, administradores, farmacêuticos, entregadores)
-- ============================================================
CREATE TABLE IF NOT EXISTS usuarios (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nome VARCHAR(100) NOT NULL,
  email VARCHAR(150) NOT NULL UNIQUE,
  senha VARCHAR(255) NOT NULL,
  perfil ENUM('admin','farmaceutico','entregador','cliente') NOT NULL DEFAULT 'cliente',
  telefone VARCHAR(20),
  avatar VARCHAR(255),
  criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  atualizado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ============================================================
-- TABELA: categorias (categorias de produtos)
-- ============================================================
CREATE TABLE IF NOT EXISTS categorias (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nome VARCHAR(100) NOT NULL,
  criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  atualizado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ============================================================
-- TABELA: fornecedores
-- ============================================================
CREATE TABLE IF NOT EXISTS fornecedores (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nome VARCHAR(150) NOT NULL,
  nif VARCHAR(50) NOT NULL UNIQUE,
  contato VARCHAR(100),
  email VARCHAR(150),
  telefone VARCHAR(20),
  endereco VARCHAR(255),
  criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  atualizado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ============================================================
-- TABELA: produtos
-- ============================================================
CREATE TABLE IF NOT EXISTS produtos (
  id INT AUTO_INCREMENT PRIMARY KEY,
  codigo VARCHAR(50) NOT NULL UNIQUE,
  nome VARCHAR(150) NOT NULL,
  descricao TEXT,
  preco_custo DECIMAL(10,2) NOT NULL,
  preco_venda DECIMAL(10,2) NOT NULL,
  categoria_id INT,
  fornecedor_id INT,
  receita_obrigatoria BOOLEAN NOT NULL DEFAULT FALSE,
  imagem VARCHAR(255),
  criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  atualizado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (categoria_id) REFERENCES categorias(id) ON DELETE SET NULL,
  FOREIGN KEY (fornecedor_id) REFERENCES fornecedores(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- ============================================================
-- TABELA: lotes
-- ============================================================
CREATE TABLE IF NOT EXISTS lotes (
  id INT AUTO_INCREMENT PRIMARY KEY,
  produto_id INT NOT NULL,
  numero_lote VARCHAR(50) NOT NULL,
  quantidade INT NOT NULL,
  data_fabricacao DATE,
  data_validade DATE,
  criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (produto_id) REFERENCES produtos(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- TABELA: movimentacoes_estoque
-- ============================================================
CREATE TABLE IF NOT EXISTS movimentacoes_estoque (
  id INT AUTO_INCREMENT PRIMARY KEY,
  lote_id INT NOT NULL,
  quantidade INT NOT NULL,
  motivo ENUM('compra','venda','ajuste','devolucao','vencido') NOT NULL,
  referencia_id INT,  -- pode apontar para pedido ou ordem de compra
  realizado_por INT,  -- usuario_id que fez a movimentação
  criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (lote_id) REFERENCES lotes(id) ON DELETE CASCADE,
  FOREIGN KEY (realizado_por) REFERENCES usuarios(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- ============================================================
-- TABELA: pedidos
-- ============================================================
CREATE TABLE IF NOT EXISTS pedidos (
  id INT AUTO_INCREMENT PRIMARY KEY,
  usuario_id INT NOT NULL,
  status ENUM('pendente','pago','processando','pronto','enviado','entregue','cancelado') NOT NULL DEFAULT 'pendente',
  total DECIMAL(10,2) NOT NULL,
  desconto DECIMAL(10,2) NOT NULL DEFAULT 0,
  metodo_pagamento VARCHAR(50),
  referencia_pagamento VARCHAR(100),
  observacoes TEXT,
  criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  atualizado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- TABELA: itens_pedido
-- ============================================================
CREATE TABLE IF NOT EXISTS itens_pedido (
  id INT AUTO_INCREMENT PRIMARY KEY,
  pedido_id INT NOT NULL,
  produto_id INT NOT NULL,
  lote_id INT,
  nome_produto VARCHAR(150) NOT NULL,
  quantidade INT NOT NULL,
  preco_unitario DECIMAL(10,2) NOT NULL,
  subtotal DECIMAL(10,2) NOT NULL,
  criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (pedido_id) REFERENCES pedidos(id) ON DELETE CASCADE,
  FOREIGN KEY (produto_id) REFERENCES produtos(id),
  FOREIGN KEY (lote_id) REFERENCES lotes(id)
) ENGINE=InnoDB;

-- ============================================================
-- TABELA: entregas
-- ============================================================
CREATE TABLE IF NOT EXISTS entregas (
  id INT AUTO_INCREMENT PRIMARY KEY,
  pedido_id INT NOT NULL,
  entregador_id INT,
  status ENUM('pendente','atribuido','em_rota','entregue','falhou') NOT NULL DEFAULT 'pendente',
  endereco VARCHAR(255),
  cidade VARCHAR(100),
  bairro VARCHAR(100),
  codigo_postal VARCHAR(20),
  data_prevista DATETIME,
  data_entrega DATETIME,
  latitude_inicio DECIMAL(10,7),
  longitude_inicio DECIMAL(10,7),
  latitude_fim DECIMAL(10,7),
  longitude_fim DECIMAL(10,7),
  observacoes TEXT,
  criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (pedido_id) REFERENCES pedidos(id) ON DELETE CASCADE,
  FOREIGN KEY (entregador_id) REFERENCES usuarios(id)
) ENGINE=InnoDB;

-- ============================================================
-- TABELA: ordens_compra
-- ============================================================
CREATE TABLE IF NOT EXISTS ordens_compra (
  id INT AUTO_INCREMENT PRIMARY KEY,
  fornecedor_id INT NOT NULL,
  status ENUM('rascunho','enviado','parcial','concluido','cancelado') NOT NULL DEFAULT 'rascunho',
  total DECIMAL(10,2) NOT NULL,
  observacoes TEXT,
  criado_por INT NOT NULL,
  criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  atualizado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (fornecedor_id) REFERENCES fornecedores(id) ON DELETE CASCADE,
  FOREIGN KEY (criado_por) REFERENCES usuarios(id)
) ENGINE=InnoDB;

-- ============================================================
-- TABELA: itens_ordem_compra
-- ============================================================
CREATE TABLE IF NOT EXISTS itens_ordem_compra (
  id INT AUTO_INCREMENT PRIMARY KEY,
  ordem_compra_id INT NOT NULL,
  produto_id INT NOT NULL,
  quantidade_solicitada INT NOT NULL,
  quantidade_recebida INT NOT NULL DEFAULT 0,
  preco_unitario DECIMAL(10,2) NOT NULL,
  numero_lote VARCHAR(50),
  data_validade DATE,
  criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (ordem_compra_id) REFERENCES ordens_compra(id) ON DELETE CASCADE,
  FOREIGN KEY (produto_id) REFERENCES produtos(id)
) ENGINE=InnoDB;

-- ============================================================
-- TABELA: configuracoes
-- ============================================================
CREATE TABLE IF NOT EXISTS configuracoes (
  id INT PRIMARY KEY,                -- use 1 para único registro
  nome_farmacia VARCHAR(150),
  slogan VARCHAR(255),
  descricao TEXT,
  email_contato VARCHAR(150),
  telefone_contato VARCHAR(50),
  endereco VARCHAR(255),
  cidade VARCHAR(100),
  provincia VARCHAR(100),
  codigo_postal VARCHAR(20),
  site VARCHAR(100),
  logo VARCHAR(255),
  nif VARCHAR(50),
  redes_sociais JSON,
  alerta_estoque BOOLEAN NOT NULL DEFAULT TRUE,
  alerta_pedidos BOOLEAN NOT NULL DEFAULT TRUE,
  alerta_validade BOOLEAN NOT NULL DEFAULT TRUE,
  criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  atualizado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;
