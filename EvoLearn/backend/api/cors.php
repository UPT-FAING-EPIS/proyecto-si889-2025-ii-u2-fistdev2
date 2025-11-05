<?php
// Permitir solicitudes desde cualquier origen (para desarrollo)
// En producción, deberías cambiar '*' por el dominio de tu app.
header("Access-Control-Allow-Origin: *");

// Permitir los métodos HTTP que usará tu app
header("Access-Control-Allow-Methods: POST, GET, OPTIONS, PUT, DELETE");

// Permitir las cabeceras que envía tu app (¡importante!)
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");

// Manejar la solicitud OPTIONS (preflight)
// Si el método es OPTIONS, simplemente enviamos una respuesta OK (200) y terminamos.
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}