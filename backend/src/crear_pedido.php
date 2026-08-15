<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);

    echo json_encode([
        "estado" => "error",
        "mensaje" => "Método no permitido. Use POST."
    ], JSON_UNESCAPED_UNICODE);

    exit;
}

require_once 'conexion.php';

try {

    $entrada = json_decode(file_get_contents("php://input"), true);

    if (!is_array($entrada)) {
        throw new Exception("El cuerpo de la solicitud debe ser un JSON válido.");
    }

    /*
     * Identificador del cliente.
     * La DB solamente tiene una columna:
     * identificador_cliente
     */
    $identificadorCliente = trim(
        (string)($entrada['identificador_cliente'] ?? '')
    );

    $items = $entrada['productos'] ?? [];

    if ($identificadorCliente === '') {
        throw new Exception("El identificador del cliente es obligatorio.");
    }

    if (!is_array($items) || count($items) === 0) {
        throw new Exception("El pedido debe contener al menos un producto.");
    }

    $conexion = new Conexion();
    $pdo = $conexion->conectar();

    // Iniciamos una transacción para que pedido y detalles
    // se guarden juntos.
    $pdo->beginTransaction();

    /*
     * Consultamos el precio real de cada producto
     * directamente desde la base de datos.
     */
    $consultaProducto = $pdo->prepare("
        SELECT
            id_producto,
            nombre,
            precio_base
        FROM productos
        WHERE id_producto = :id_producto
    ");

    $detalles = [];
    $total = 0;

    foreach ($items as $item) {

        $idProducto = filter_var(
            $item['id_producto'] ?? null,
            FILTER_VALIDATE_INT
        );

        $cantidad = filter_var(
            $item['cantidad'] ?? null,
            FILTER_VALIDATE_INT
        );

        if ($idProducto === false || $idProducto <= 0) {
            throw new Exception(
                "Cada producto debe tener un id_producto válido."
            );
        }

        if ($cantidad === false || $cantidad <= 0) {
            throw new Exception(
                "La cantidad debe ser mayor que cero."
            );
        }

        $consultaProducto->execute([
            'id_producto' => $idProducto
        ]);

        $producto = $consultaProducto->fetch();

        if (!$producto) {
            throw new Exception(
                "El producto con ID {$idProducto} no existe."
            );
        }

        $precio = (float)$producto['precio_base'];

        $subtotal = $precio * $cantidad;

        $total += $subtotal;

        $detalles[] = [
            'id_producto' => $idProducto,
            'nombre' => $producto['nombre'],
            'cantidad' => $cantidad,
            'subtotal' => $subtotal
        ];
    }

    /*
     * Guardamos el encabezado del pedido.
     *
     * La DB genera:
     * - id_pedido
     * - fecha_hora
     *
     * Nosotros enviamos:
     * - identificador_cliente
     * - estado
     * - total_pagar
     */
    $insertarPedido = $pdo->prepare("
        INSERT INTO pedidos
            (
                identificador_cliente,
                fecha_hora,
                estado,
                total_pagar
            )
        VALUES
            (
                :identificador_cliente,
                NOW(),
                :estado,
                :total_pagar
            )
    ");

    $insertarPedido->execute([
        'identificador_cliente' => $identificadorCliente,
        'estado' => 'Pendiente',
        'total_pagar' => $total
    ]);

    $idPedido = (int)$pdo->lastInsertId();

    /*
     * Guardamos cada producto en detalle_pedidos.
     */
    $insertarDetalle = $pdo->prepare("
        INSERT INTO detalle_pedidos
            (
                id_pedido,
                id_producto,
                cantidad,
                subtotal
            )
        VALUES
            (
                :id_pedido,
                :id_producto,
                :cantidad,
                :subtotal
            )
    ");

    foreach ($detalles as $detalle) {

        $insertarDetalle->execute([
            'id_pedido' => $idPedido,
            'id_producto' => $detalle['id_producto'],
            'cantidad' => $detalle['cantidad'],
            'subtotal' => $detalle['subtotal']
        ]);
    }

    // Si todo salió bien, confirmamos los cambios.
    $pdo->commit();

    echo json_encode([
        "estado" => "exito",
        "mensaje" => "Pedido creado correctamente",
        "datos" => [
            "id_pedido" => $idPedido,
            "identificador_cliente" => $identificadorCliente,
            "total_pagar" => round($total, 2),
            "estado" => "Pendiente",
            "productos" => $detalles
        ]
    ], JSON_UNESCAPED_UNICODE);

} catch (Exception $e) {

    if (isset($pdo) && $pdo->inTransaction()) {
        $pdo->rollBack();
    }

    http_response_code(400);

    echo json_encode([
        "estado" => "error",
        "mensaje" => $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}
?>