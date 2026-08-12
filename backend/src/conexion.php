<?php
// backend/src/conexion.php

// Si están usando la librería vlucas/phpdotenv con Composer, 
// asegúrate de requerir el autoload primero.
require_once __DIR__ . '/../vendor/autoload.php'; 

// Cargar las variables del archivo .env
$dotenv = Dotenv\Dotenv::createImmutable(__DIR__ . '/../');
$dotenv->load();

class Conexion {
    private $host;
    private $db;
    private $user;
    private $pass;
    private $charset;

    public function __construct() {
       
        $this->host = $_ENV['DB_HOST'];
        $this->db   = $_ENV['DB_NAME'];
        $this->user = $_ENV['DB_USER'];
        $this->pass = $_ENV['DB_PASS'];
        $this->charset = 'utf8mb4';
    }

    public function conectar() {
        try {
            //cadena de conexion
            $dsn = "mysql:host=" . $this->host . ";dbname=" . $this->db . ";charset=" . $this->charset;
            
            //confuguracion PDO para que nos lance errores claros si algo falla
            $opciones = [
                PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES   => false,
            ];
            
            //creacion  y retorno de la conexión
            $pdo = new PDO($dsn, $this->user, $this->pass, $opciones);
            return $pdo;

        } catch (PDOException $e) {
            //aviso de que si esta apagado o con error la BD
            die(json_encode([
                "estado" => "error", 
                "mensaje" => "Fallo la conexión a la base de datos: " . $e->getMessage()
            ]));
        }
    }
}
?>