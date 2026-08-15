<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

require_once 'conexion.php';

try {
    $conexion = new Conexion();
    $pdo = $conexion->conectar();

    // Consulta SQL para traer todos los pedidos pendientes (estado = 'Pendiente')
    // Ordena por fecha de creación (más antiguos primero)
    $query = "SELECT id_pedido, numero_pedido, fecha_pedido, estado, detalles
              FROM Pedidos 
              WHERE estado = 'Pendiente' 
              ORDER BY fecha_pedido ASC";
              
    $stmt = $pdo->prepare($query);
    $stmt->execute();
    
    // Extraemos los datos como un array
    $pedidos = $stmt->fetchAll();

    // Respuesta en JSON
    echo json_encode([
        "estado" => "exito",
        "mensaje" => "Cola de pedidos recuperada correctamente",
        "cantidad" => count($pedidos),
        "datos" => $pedidos
    ]);

} catch (Exception $e) {
    // Captura de error
    http_response_code(500);
    echo json_encode([
        "estado" => "error",
        "mensaje" => "Error al obtener la cola de pedidos: " . $e->getMessage()
    ]);
}
?>
