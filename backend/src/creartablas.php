<?php
require_once 'conexion.php';

try {
    $conexion = new Conexion();
    $pdo = $conexion->conectar();

    $sql = "
    CREATE TABLE IF NOT EXISTS Categorias (
        id_categoria INT AUTO_INCREMENT PRIMARY KEY,
        nombre VARCHAR(100) NOT NULL
    );

    CREATE TABLE IF NOT EXISTS Productos (
        id_producto INT AUTO_INCREMENT PRIMARY KEY,
        id_categoria INT,
        nombre VARCHAR(100) NOT NULL,
        precio_base FLOAT NOT NULL,
        FOREIGN KEY (id_categoria) REFERENCES Categorias(id_categoria)
    );

    CREATE TABLE IF NOT EXISTS Insumos (
        id_insumo INT AUTO_INCREMENT PRIMARY KEY,
        nombre VARCHAR(100) NOT NULL,
        tipo ENUM('Sabor', 'Jalea', 'Topping', 'Extra', 'Base') NOT NULL,
        stock_actual INT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS Pedidos (
        id_pedido INT AUTO_INCREMENT PRIMARY KEY,
        identificador_cliente VARCHAR(100) NULL,
        fecha_hora DATETIME,
        estado ENUM('En cola', 'En preparación', 'Completado', 'Cancelado') NOT NULL DEFAULT 'En cola',
        total_pagar FLOAT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS detalle_Pedidos (
        id_detalle INT AUTO_INCREMENT PRIMARY KEY,
        id_pedido INT,
        id_producto INT,
        cantidad INT NOT NULL,
        subtotal FLOAT NOT NULL,
        FOREIGN KEY (id_pedido) REFERENCES Pedidos(id_pedido),
        FOREIGN KEY (id_producto) REFERENCES Productos(id_producto)
    );

    CREATE TABLE IF NOT EXISTS personalizacion_detalle (
        id_personalizacion INT AUTO_INCREMENT PRIMARY KEY,
        id_detalle INT,
        id_insumo INT,
        cantidad_usada INT NOT NULL,
        FOREIGN KEY (id_detalle) REFERENCES detalle_Pedidos(id_detalle),
        FOREIGN KEY (id_insumo) REFERENCES Insumos(id_insumo)
    );

    -- Insertar dato de prueba solo si la tabla está vacía
    INSERT INTO Insumos (nombre, tipo, stock_actual) 
    SELECT 'Helado de Vainilla', 'Sabor', 50 
    WHERE NOT EXISTS (SELECT 1 FROM Insumos WHERE nombre = 'Helado de Vainilla');
    ";

    // Ejecutamos todo el bloque SQL de un golpe
    $pdo->exec($sql);
    
    echo "<h1>¡Magia pura! Las tablas y el helado fueron creados con exito directo en el servidor.</h1>";

} catch (Exception $e) {
    echo "<h1>Error: " . $e->getMessage() . "</h1>";
}
?>