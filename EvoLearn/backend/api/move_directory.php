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

// FS-only branch
$pathRel = normalizeRelativePath((string)($data['path'] ?? ''));
$newParentRel = normalizeRelativePath((string)($data['new_parent_path'] ?? ''));
if (!$isVip && $pathRel !== '') {
    $srcAbs = absPathForUser((int)$user['id'], $pathRel);
    if (!is_dir($srcAbs)) jsonResponse(404, ['error' => 'Carpeta no encontrada']);
    $destParentAbs = absPathForUser((int)$user['id'], $newParentRel);
    if (!is_dir($destParentAbs)) mkdir($destParentAbs, 0777, true);
    $targetAbs = uniqueChildPath($destParentAbs, basename($srcAbs), false);
    if (!@rename($srcAbs, $targetAbs)) jsonResponse(500, ['error' => 'No se pudo mover la carpeta']);
    $finalRel = normalizeRelativePath(($newParentRel !== '' ? ($newParentRel . '/') : '') . basename($targetAbs));
    jsonResponse(200, ['success' => true, 'mode' => 'fs', 'fs_path' => $finalRel]);
}

// VIP: DB + FS espejo
$id = (int)($data['id'] ?? 0);
$newParent = isset($data['new_parent_id']) ? (int)$data['new_parent_id'] : null;

if ($id <= 0) jsonResponse(400, ['error' => 'id requerido']);
$dir = $pdo->prepare('SELECT id, user_id, parent_id, name FROM directories WHERE id = ?');
$dir->execute([$id]);
$src = $dir->fetch();
if (!$src || (int)$src['user_id'] !== (int)$user['id']) jsonResponse(404, ['error' => 'Directorio no encontrado']);

if ($newParent !== null) {
    if ($newParent === $id) jsonResponse(400, ['error' => 'No puedes mover un directorio dentro de sí mismo']);
    $chk = $pdo->prepare('SELECT id, user_id FROM directories WHERE id = ?');
    $chk->execute([$newParent]);
    $parent = $chk->fetch();
    if (!$parent || (int)$parent['user_id'] !== (int)$user['id']) jsonResponse(400, ['error' => 'new_parent_id inválido']);
}

$upd = $pdo->prepare('UPDATE directories SET parent_id = ? WHERE id = ?');
$upd->execute([$newParent, $id]);

// mover FS espejo
$oldParentRel = dbRelativePathFromId($pdo, (int)$user['id'], (int)$src['parent_id']);
$srcAbs = absPathForUser((int)$user['id'], normalizeRelativePath(($oldParentRel !== '' ? ($oldParentRel . '/') : '') . sanitizeName((string)$src['name'])));
$newParentRel = dbRelativePathFromId($pdo, (int)$user['id'], $newParent);
$destParentAbs = absPathForUser((int)$user['id'], $newParentRel);
if (!is_dir($destParentAbs)) mkdir($destParentAbs, 0777, true);
$targetAbs = $destParentAbs . DIRECTORY_SEPARATOR . sanitizeName((string)$src['name']);
if (is_dir($srcAbs)) @rename($srcAbs, $targetAbs);
$finalRel = normalizeRelativePath(($newParentRel !== '' ? ($newParentRel . '/') : '') . basename($targetAbs));
jsonResponse(200, ['success' => true, 'mode' => 'vip', 'fs_path' => $finalRel]);