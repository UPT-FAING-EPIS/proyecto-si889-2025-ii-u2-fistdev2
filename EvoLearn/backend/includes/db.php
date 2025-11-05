<?php
declare(strict_types=1);

function getPDO(): PDO {
    // Ajustar estos valores a tu entorno local
    $host = '161.132.49.24';
    $db   = 'estudiafacil';
    $user = 'php_user';
    $pass = 'psswdphp8877'; // Cambia si tu MySQL tiene contraseña
    $port = 3306;
    $charset = 'utf8mb4';

    $dsn = "mysql:host=$host;dbname=$db;charset=$charset";
    $options = [
        PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES   => false,
    ];

    return new PDO($dsn, $user, $pass, $options);
}

function jsonResponse(int $status, array $payload): void {
    http_response_code($status);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}