<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require 'conexion.php';


$conexionObj = new Conexion();
$pdo = $conexionObj->conectar();

$data = json_decode(file_get_contents("php://input"));

if (isset($data->usuario) && isset($data->password)) {
    $usuario = $data->usuario;
    $password = $data->password;

    try {
        $query = "SELECT * FROM usuarios WHERE usuario = :usuario AND password = :password";
        // Usamos la variable $pdo que nos acaba de devolver tu clase
        $stmt = $pdo->prepare($query);
        $stmt->execute([':usuario' => $usuario, ':password' => $password]);
        
        $user = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($user) {
            echo json_encode(["estado" => "exito", "mensaje" => "Bienvenido " . $user['rol']]);
        } else {
            http_response_code(401);
            echo json_encode(["estado" => "error", "mensaje" => "Credenciales incorrectas"]);
        }
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(["estado" => "error", "mensaje" => "Error de servidor: " . $e->getMessage()]);
    }
} else {
    http_response_code(400);
    echo json_encode(["estado" => "error", "mensaje" => "Faltan datos"]);
}
?>