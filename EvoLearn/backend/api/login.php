<?php
declare(strict_types=1);
require_once __DIR__ . '/../includes/bootstrap.php';
require_once __DIR__ . '/../includes/db.php';
require_once __DIR__ . '/../includes/auth.php';

// Preflight CORS para web
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonResponse(405, ['error' => 'Method not allowed']);
}

$raw = file_get_contents('php://input');
$data = json_decode($raw, true);
if (!is_array($data)) {
    // fallback para form-data
    $data = $_POST;
}

$email = trim($data['email'] ?? '');
$password = trim($data['password'] ?? ''); 

if ($email === '' || $password === '') {
    jsonResponse(400, ['error' => 'Email and password are required']);
}

try {
    $pdo = getPDO();
    $stmt = $pdo->prepare('SELECT id, password_hash, name, email FROM users WHERE email = ?');
    $stmt->execute([$email]);
    $user = $stmt->fetch();

    if (!$user || !password_verify($password, $user['password_hash'])) {
        jsonResponse(401, ['error' => 'Invalid credentials']);
    }

    $token = issueToken($pdo, (int)$user['id']);

    jsonResponse(200, [
        'success' => true,
        'token' => $token,
        'user' => [
            'id' => (int)$user['id'],
            'name' => $user['name'],
            'email' => $user['email']
        ]
    ]);
} catch (Throwable $e) {
    jsonResponse(500, ['error' => 'Server error', 'details' => $e->getMessage()]);
}