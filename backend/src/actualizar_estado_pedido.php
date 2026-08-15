<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

// Manejo de preflight request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once 'conexion.php';

try {
    // Validamos que sea una petición POST
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        throw new Exception("Método no permitido. Use POST");
    }

    // Obtenemos los datos del cliente
    $input = json_decode(file_get_contents("php://input"), true);

    // Validación de parámetros
    if (empty($input['id_pedido']) || empty($input['nuevo_estado'])) {
        throw new Exception("Parámetros incompletos: id_pedido y nuevo_estado son requeridos");
    }

    $id_pedido = intval($input['id_pedido']);
    $nuevo_estado = $input['nuevo_estado']; // "Completado"

    // Estados permitidos
    $estados_permitidos = ['Pendiente', 'En Preparación', 'Completado', 'Cancelado'];
    if (!in_array($nuevo_estado, $estados_permitidos)) {
        throw new Exception("Estado no válido. Estados permitidos: " . implode(", ", $estados_permitidos));
    }

    $conexion = new Conexion();
    $pdo = $conexion->conectar();

    // Primero verificamos que el pedido existe
    $verificar = "SELECT id_pedido, estado FROM Pedidos WHERE id_pedido = ?";
    $stmt = $pdo->prepare($verificar);
    $stmt->execute([$id_pedido]);
    $pedido = $stmt->fetch();

    if (!$pedido) {
        throw new Exception("El pedido con ID {$id_pedido} no existe");
    }

    // Actualizamos el estado del pedido
    $query = "UPDATE Pedidos 
              SET estado = ?, fecha_actualizacion = NOW() 
              WHERE id_pedido = ?";
    
    $stmt = $pdo->prepare($query);
    $resultado = $stmt->execute([$nuevo_estado, $id_pedido]);

    if (!$resultado) {
        throw new Exception("No se pudo actualizar el pedido");
    }

    // Respuesta exitosa
    echo json_encode([
        "estado" => "exito",
        "mensaje" => "Pedido {$id_pedido} actualizado a '{$nuevo_estado}' exitosamente",
        "id_pedido" => $id_pedido,
        "nuevo_estado" => $nuevo_estado
    ]);

} catch (Exception $e) {
    // Captura de error
    http_response_code(400);
    echo json_encode([
        "estado" => "error",
        "mensaje" => $e->getMessage()
    ]);
}
?>
