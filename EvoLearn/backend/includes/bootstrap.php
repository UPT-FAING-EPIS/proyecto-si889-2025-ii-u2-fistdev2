<?php
declare(strict_types=1);

ini_set('display_errors', '0');
error_reporting(E_ALL);

// Include required files
require_once __DIR__ . '/db.php';
require_once __DIR__ . '/auth.php';
require_once __DIR__ . '/fs.php';
require_once __DIR__ . '/logger.php';

// CORS básico
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');

// Buffer para evitar que salgan warnings como HTML
ob_start();
log_info('Request start');

// Convierte warnings/notices en excepciones
set_error_handler(function (int $severity, string $message, string $file, int $line) {
    throw new ErrorException($message, 0, $severity, $file, $line);
});

// Excepciones → JSON
set_exception_handler(function (Throwable $e) {
    log_error('Unhandled exception', ['error' => $e->getMessage(), 'file' => $e->getFile(), 'line' => $e->getLine()]);
    http_response_code(500);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode([
        'error' => 'Server error',
        'details' => $e->getMessage(),
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
});

// Fatales → JSON
register_shutdown_function(function () {
    $err = error_get_last();
    if ($err && in_array($err['type'], [E_ERROR, E_PARSE, E_CORE_ERROR, E_COMPILE_ERROR])) {
        log_error('Fatal error', ['type' => $err['type'], 'message' => $err['message'], 'file' => $err['file'] ?? null, 'line' => $err['line'] ?? null]);
        http_response_code(500);
        header('Content-Type: application/json; charset=utf-8');
        echo json_encode([
            'error' => 'Server error',
            'details' => $err['message'],
        ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    }
});