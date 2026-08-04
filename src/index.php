<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

echo json_encode([
    "mensaje" => "¡El backend de la heladería está funcionando!",
    "estado" => "ok"
]);