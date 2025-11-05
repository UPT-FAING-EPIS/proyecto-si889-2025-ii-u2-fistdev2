<?php
declare(strict_types=1);
require_once 'cors.php';
require_once '../includes/db.php';
require_once '../includes/auth.php';
require_once __DIR__ . '/../includes/fs.php';
if ($_SERVER['REQUEST_METHOD'] !== 'POST') jsonResponse(405, ['error' => 'Method not allowed']);

$pdo = getPDO();
$user = requireAuth($pdo);
$isVip = isVip($pdo, $user);

$data = json_decode(file_get_contents('php://input'), true) ?? $_POST;
$name = trim($data['name'] ?? '');
$parentId = isset($data['parent_id']) ? (int)$data['parent_id'] : null;
$color = strtoupper(trim($data['color_hex'] ?? '#1565C0'));
$parentPath = normalizeRelativePath((string)($data['parent_path'] ?? $data['parent'] ?? ''));

if ($name === '') jsonResponse(400, ['error' => 'Nombre requerido']);
if (!preg_match('/^#[0-9A-F]{6}$/', $color)) $color = '#1565C0';

if (!$isVip) {
    // Crear solo en FS
    $baseAbs = absPathForUser((int)$user['id'], $parentPath);
    if (!is_dir($baseAbs)) mkdir($baseAbs, 0777, true);
    $targetAbs = uniqueChildPath($baseAbs, sanitizeName($name), false);
    if (!mkdir($targetAbs, 0777, true)) {
        jsonResponse(500, ['error' => 'No se pudo crear la carpeta física']);
    }
    writeDirMeta($targetAbs, ['color' => $color]);
    $rel = normalizeRelativePath(($parentPath !== '' ? ($parentPath . '/') : '') . basename($targetAbs));
    jsonResponse(201, ['success' => true, 'mode' => 'fs', 'fs_path' => $rel]);
}

// VIP: DB + FS espejo bajo jerarquía DB
if ($parentId !== null) {
    $chk = $pdo->prepare('SELECT id FROM directories WHERE id = ? AND user_id = ?');
    $chk->execute([$parentId, (int)$user['id']]);
    if (!$chk->fetch()) jsonResponse(400, ['error' => 'parent_id inválido']);
}
try {
    $stmt = $pdo->prepare('INSERT INTO directories (user_id, parent_id, name, color_hex, position) VALUES (?, ?, ?, ?, ?)');
    $pos = 0;
    $stmt->execute([(int)$user['id'], $parentId, $name, $color, $pos]);
    $newId = (int)$pdo->lastInsertId();

    $parentRel = dbRelativePathFromId($pdo, (int)$user['id'], $parentId);
    $baseAbs = absPathForUser((int)$user['id'], $parentRel);
    if (!is_dir($baseAbs)) mkdir($baseAbs, 0777, true);
    $targetAbs = $baseAbs . DIRECTORY_SEPARATOR . sanitizeName($name);
    if (!is_dir($targetAbs)) mkdir($targetAbs, 0777, true);
    writeDirMeta($targetAbs, ['color' => $color]);
    $rel = normalizeRelativePath(($parentRel !== '' ? ($parentRel . '/') : '') . basename($targetAbs));

    jsonResponse(201, ['success' => true, 'mode' => 'vip', 'id' => $newId, 'fs_path' => $rel]);
} catch (Throwable $e) {
    if (str_contains($e->getMessage(), 'uniq_dir_name_per_parent')) {
        jsonResponse(409, ['error' => 'Ya existe una carpeta con ese nombre en el mismo nivel']);
    }
    jsonResponse(500, ['error' => 'Server error', 'details' => $e->getMessage()]);
}