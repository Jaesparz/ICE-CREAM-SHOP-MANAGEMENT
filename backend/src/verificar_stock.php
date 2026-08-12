<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");


require_once 'conexion.php';

try {
    $conexion = new Conexion();
    $pdo = $conexion->conectar();

    //consulta SQL para traer todos los insumos (nombre, tipo y stock)
    //filtramos para que en el backen se sepa de antemano si el stock es mayor a 0
    $query = "SELECT id_insumo, nombre, tipo, stock_actual, 
              IF(stock_actual > 0, true, false) as disponible 
              FROM Insumos";
              
    $stmt = $pdo->prepare($query);
    $stmt->execute();
    
    //extraemos los datos como un array
    $insumos = $stmt->fetchAll();

    //respuesta en json
    echo json_encode([
        "estado" => "exito",
        "mensaje" => "Inventario recuperado correctamente",
        "datos" => $insumos
    ]);

} catch (Exception $e) {
    //captura de error
    http_response_code(500);
    echo json_encode([
        "estado" => "error",
        "mensaje" => "Error al verificar el stock: " . $e->getMessage()
    ]);
}
?>