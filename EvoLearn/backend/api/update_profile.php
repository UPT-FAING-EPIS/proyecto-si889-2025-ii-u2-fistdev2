<?php
declare(strict_types=1);
require_once __DIR__ . '/../includes/bootstrap.php';

// Preflight CORS
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'POST') jsonResponse(405, ['error' => 'Method not allowed']);

$pdo = getPDO();
$user = requireAuth($pdo);

// Get JSON input
$raw = file_get_contents('php://input');
$data = json_decode($raw, true);
if (!is_array($data)) {
    $data = $_POST;
}

$action = $data['action'] ?? '';

if ($action === 'change_password') {
    $currentPassword = (string)($data['current_password'] ?? '');
    $newPassword = (string)($data['new_password'] ?? '');
    $confirmPassword = (string)($data['confirm_password'] ?? '');
    
    // Validations
    if (empty($currentPassword)) {
        jsonResponse(400, ['error' => 'Contraseña actual requerida']);
    }
    if (strlen($newPassword) < 6) {
        jsonResponse(400, ['error' => 'Nueva contraseña debe tener al menos 6 caracteres']);
    }
    if ($newPassword !== $confirmPassword) {
        jsonResponse(400, ['error' => 'Las contraseñas nuevas no coinciden']);
    }
    
    // Verify current password
    $stmt = $pdo->prepare('SELECT password_hash FROM users WHERE id = ?');
    $stmt->execute([(int)$user['id']]);
    $userData = $stmt->fetch();
    
    if (!$userData || !password_verify($currentPassword, $userData['password_hash'])) {
        jsonResponse(400, ['error' => 'Contraseña actual incorrecta']);
    }
    
    // Update password
    $newHash = password_hash($newPassword, PASSWORD_DEFAULT);
    $stmt = $pdo->prepare('UPDATE users SET password_hash = ?, updated_at = NOW() WHERE id = ?');
    $stmt->execute([$newHash, (int)$user['id']]);
    
    jsonResponse(200, ['success' => true, 'message' => 'Contraseña actualizada exitosamente']);
    
} elseif ($action === 'update_profile') {
    $name = trim($data['name'] ?? '');
    
    // Validations
    if (empty($name) || mb_strlen($name) < 2) {
        jsonResponse(400, ['error' => 'Nombre debe tener al menos 2 caracteres']);
    }
    
    // Update name
    $stmt = $pdo->prepare('UPDATE users SET name = ?, updated_at = NOW() WHERE id = ?');
    $stmt->execute([$name, (int)$user['id']]);
    
    jsonResponse(200, ['success' => true, 'message' => 'Perfil actualizado exitosamente']);
    
} else {
    jsonResponse(400, ['error' => 'Acción no válida']);
}
