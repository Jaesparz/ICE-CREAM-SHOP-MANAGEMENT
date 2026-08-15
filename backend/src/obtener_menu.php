<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode([
        "estado" => "error",
        "mensaje" => "Método no permitido. Use GET."
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

require_once 'conexion.php';

try {
    $conexion = new Conexion();
    $pdo = $conexion->conectar();

    $query = "
        SELECT
            p.id_producto,
            p.nombre,
            c.nombre AS categoria,
            p.precio_base
        FROM productos p
        INNER JOIN categorias c
            ON p.id_categoria = c.id_categoria
        ORDER BY c.nombre, p.nombre
    ";

    $stmt = $pdo->prepare($query);
    $stmt->execute();

    $productos = $stmt->fetchAll();

    echo json_encode([
        "estado" => "exito",
        "mensaje" => "Menú recuperado correctamente",
        "datos" => $productos
    ], JSON_UNESCAPED_UNICODE);

} catch (Exception $e) {
    http_response_code(500);

    echo json_encode([
        "estado" => "error",
        "mensaje" => "Error al obtener el menú"
    ], JSON_UNESCAPED_UNICODE);
}
?>