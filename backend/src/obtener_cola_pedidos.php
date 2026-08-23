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
            id_pedido,
            identificador_cliente,
            fecha_hora,
            estado,
            total_pagar
        FROM pedidos
        WHERE estado = 'En cola'
        ORDER BY fecha_hora ASC
    ";

    $stmt = $pdo->prepare($query);
    $stmt->execute();

    $pedidos = $stmt->fetchAll();

    $consultaDetalle = $pdo->prepare("
        SELECT
            p.nombre,
            dp.cantidad,
            dp.subtotal
        FROM detalle_pedidos dp
        INNER JOIN productos p ON p.id_producto = dp.id_producto
        WHERE dp.id_pedido = :id_pedido
    ");

    foreach ($pedidos as &$pedido) {
        $consultaDetalle->execute([
            'id_pedido' => $pedido['id_pedido']
        ]);
        $pedido['productos'] = $consultaDetalle->fetchAll();
    }
    unset($pedido);

    echo json_encode([
        "estado" => "exito",
        "mensaje" => "Cola de pedidos recuperada correctamente",
        "cantidad" => count($pedidos),
        "datos" => $pedidos
    ], JSON_UNESCAPED_UNICODE);

} catch (Exception $e) {

    http_response_code(500);

    echo json_encode([
        "estado" => "error",
        "mensaje" => "Error al obtener la cola de pedidos: " . $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}
?>
