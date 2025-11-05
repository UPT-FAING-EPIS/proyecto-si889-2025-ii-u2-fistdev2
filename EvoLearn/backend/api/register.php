<?php
declare(strict_types=1);
require_once __DIR__ . '/../includes/bootstrap.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonResponse(405, ['error' => 'Method not allowed']);
}

// Admitir JSON o form-data
$raw = file_get_contents('php://input');
$data = json_decode($raw, true);
if (!is_array($data)) {
    $data = $_POST;
}

$name = trim($data['name'] ?? '');
$email = trim($data['email'] ?? '');
$password = (string)($data['password'] ?? '');
$confirm = (string)($data['confirm_password'] ?? $password);

// Validaciones
$len = function_exists('mb_strlen') ? mb_strlen($name) : strlen($name);
if ($name === '' || $len < 2) {
    jsonResponse(400, ['error' => 'Nombre requerido (mínimo 2 caracteres)']);
}
if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    jsonResponse(400, ['error' => 'Email inválido']);
}
if (strlen($password) < 6) {
    jsonResponse(400, ['error' => 'Contraseña mínima 6 caracteres']);
}
if ($password !== $confirm) {
    jsonResponse(400, ['error' => 'Las contraseñas no coinciden']);
}

try {
    $pdo = getPDO();

    // Verificar duplicado por email
    $stmt = $pdo->prepare('SELECT id FROM users WHERE email = ?');
    $stmt->execute([$email]);
    if ($stmt->fetch()) {
        jsonResponse(409, ['error' => 'El email ya está registrado']);
    }

    // Insertar usuario
    $hash = password_hash($password, PASSWORD_DEFAULT);
    $stmt = $pdo->prepare('INSERT INTO users (name, email, password_hash) VALUES (?, ?, ?)');
    $stmt->execute([$name, $email, $hash]);
    $userId = (int)$pdo->lastInsertId();

    // Emitir token post-registro
    $token = issueToken($pdo, $userId);

    jsonResponse(201, [
        'success' => true,
        'token' => $token,
        'user' => [
            'id' => $userId,
            'name' => $name,
            'email' => $email
        ]
    ]);
} catch (Throwable $e) {
    jsonResponse(500, ['error' => 'Server error', 'details' => $e->getMessage()]);
}