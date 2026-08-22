<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

require_once 'conexion.php';

try {

    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        throw new Exception("Método no permitido. Use POST.");
    }

    $input = json_decode(file_get_contents("php://input"), true);

    if (!is_array($input)) {
        throw new Exception("El cuerpo de la solicitud debe ser un JSON válido.");
    }

    if (
        !isset($input['id_pedido']) ||
        !isset($input['nuevo_estado'])
    ) {
        throw new Exception(
            "Parámetros incompletos: id_pedido y nuevo_estado son requeridos."
        );
    }

    $id_pedido = filter_var(
        $input['id_pedido'],
        FILTER_VALIDATE_INT
    );

    $nuevo_estado = trim($input['nuevo_estado']);

    if ($id_pedido === false || $id_pedido <= 0) {
        throw new Exception("El id_pedido debe ser un número válido.");
    }

    // Estados permitidos por la base de datos
    $estados_permitidos = [
        'En cola',
        'En preparación',
        'Completado',
        'Cancelado'
    ];

    if (!in_array($nuevo_estado, $estados_permitidos, true)) {
        throw new Exception(
            "Estado no válido. Estados permitidos: " .
            implode(", ", $estados_permitidos)
        );
    }

    $conexion = new Conexion();
    $pdo = $conexion->conectar();

    // Verificar que el pedido existe
    $verificar = "
        SELECT id_pedido, estado
        FROM pedidos
        WHERE id_pedido = ?
    ";

    $stmt = $pdo->prepare($verificar);
    $stmt->execute([$id_pedido]);

    $pedido = $stmt->fetch();

    if (!$pedido) {
        throw new Exception(
            "El pedido con ID {$id_pedido} no existe."
        );
    }

    // Actualizar estado
    $query = "
        UPDATE pedidos
        SET estado = ?
        WHERE id_pedido = ?
    ";

    $stmt = $pdo->prepare($query);
    $stmt->execute([
        $nuevo_estado,
        $id_pedido
    ]);

    echo json_encode([
        "estado" => "exito",
        "mensaje" => "Pedido actualizado correctamente",
        "datos" => [
            "id_pedido" => $id_pedido,
            "estado_anterior" => $pedido['estado'],
            "nuevo_estado" => $nuevo_estado
        ]
    ], JSON_UNESCAPED_UNICODE);

} catch (Exception $e) {

    http_response_code(400);

    echo json_encode([
        "estado" => "error",
        "mensaje" => $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}
?>
