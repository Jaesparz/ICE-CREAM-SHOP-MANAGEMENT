USE heladeria_db;

SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS personalizacion_detalle;
DROP TABLE IF EXISTS detalle_pedidos;
DROP TABLE IF EXISTS pedidos;
DROP TABLE IF EXISTS productos;
DROP TABLE IF EXISTS insumos;
DROP TABLE IF EXISTS categorias;

SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE categorias (
    id_categoria INT NOT NULL AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL,
    PRIMARY KEY (id_categoria)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE productos (
    id_producto INT NOT NULL AUTO_INCREMENT,
    id_categoria INT DEFAULT NULL,
    nombre VARCHAR(100) NOT NULL,
    precio_base FLOAT NOT NULL,
    PRIMARY KEY (id_producto),
    KEY id_categoria (id_categoria),
    CONSTRAINT productos_ibfk_1
        FOREIGN KEY (id_categoria)
        REFERENCES categorias (id_categoria)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE pedidos (
    id_pedido INT NOT NULL AUTO_INCREMENT,
    identificador_cliente VARCHAR(100) DEFAULT NULL,
    fecha_hora DATETIME DEFAULT NULL,
    estado ENUM(
        'En cola',
        'En preparación',
        'Completado',
        'Cancelado'
    ) NOT NULL DEFAULT 'En cola',
    total_pagar FLOAT NOT NULL,
    PRIMARY KEY (id_pedido)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE detalle_pedidos (
    id_detalle INT NOT NULL AUTO_INCREMENT,
    id_pedido INT DEFAULT NULL,
    id_producto INT DEFAULT NULL,
    cantidad INT NOT NULL,
    subtotal FLOAT NOT NULL,
    PRIMARY KEY (id_detalle),
    KEY id_pedido (id_pedido),
    KEY id_producto (id_producto),
    CONSTRAINT detalle_pedidos_ibfk_1
        FOREIGN KEY (id_pedido)
        REFERENCES pedidos (id_pedido),
    CONSTRAINT detalle_pedidos_ibfk_2
        FOREIGN KEY (id_producto)
        REFERENCES productos (id_producto)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE insumos (
    id_insumo INT NOT NULL AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL,
    tipo ENUM(
        'Sabor',
        'Jalea',
        'Topping',
        'Extra',
        'Base'
    ) NOT NULL,
    stock_actual INT NOT NULL,
    PRIMARY KEY (id_insumo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE personalizacion_detalle (
    id_personalizacion INT NOT NULL AUTO_INCREMENT,
    id_detalle INT DEFAULT NULL,
    id_insumo INT DEFAULT NULL,
    cantidad_usada INT NOT NULL,
    PRIMARY KEY (id_personalizacion),
    KEY id_detalle (id_detalle),
    KEY id_insumo (id_insumo),
    CONSTRAINT personalizacion_detalle_ibfk_1
        FOREIGN KEY (id_detalle)
        REFERENCES detalle_pedidos (id_detalle),
    CONSTRAINT personalizacion_detalle_ibfk_2
        FOREIGN KEY (id_insumo)
        REFERENCES insumos (id_insumo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Categorías
INSERT INTO categorias (nombre) VALUES
('Helados'),
('Postres'),
('Bebidas');

-- Productos
INSERT INTO productos (id_categoria, nombre, precio_base) VALUES
(1, 'Helado de Vainilla', 2.50),
(1, 'Helado de Chocolate', 2.50),
(1, 'Helado de Fresa', 2.50),
(2, 'Banana Split', 5.00);

-- Insumos
INSERT INTO insumos (nombre, tipo, stock_actual) VALUES
('Helado de Vainilla', 'Sabor', 50),
('Banana Split', 'Topping', 6);