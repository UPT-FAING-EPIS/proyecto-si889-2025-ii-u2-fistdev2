<?php
declare(strict_types=1);
require_once 'cors.php';
require_once __DIR__ . '/../includes/bootstrap.php';

// Secure: require auth to view logs
$pdo = getPDO();
$user = requireAuth($pdo);

$limit = isset($_GET['limit']) ? max(1, min(1000, (int)$_GET['limit'])) : 200;
$path = logger_path();

if (!is_file($path)) {
    jsonResponse(200, ['success' => true, 'logs' => []]);
}

$lines = @file($path, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
if ($lines === false) {
    jsonResponse(500, ['error' => 'No se pudo leer el archivo de logs']);
}

$tail = array_slice($lines, -$limit);
$logs = [];
foreach ($tail as $line) {
    $j = json_decode($line, true);
    if (is_array($j)) {
        $logs[] = $j;
    } else {
        $logs[] = ['raw' => $line];
    }
}

jsonResponse(200, ['success' => true, 'logs' => $logs]);