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
    $abs = absPathForUser((int)$user['id'], $pathRel);
    if (!is_file($abs)) jsonResponse(404, ['error' => 'Documento no encontrado']);
    $destParentAbs = absPathForUser((int)$user['id'], $newParentRel);
    if (!is_dir($destParentAbs)) mkdir($destParentAbs, 0777, true);
    $ext = '.' . strtolower(pathinfo($abs, PATHINFO_EXTENSION));
    $base = basename($abs, $ext);
    $targetAbs = uniqueChildPath($destParentAbs, $base, true, $ext);
    if (!@rename($abs, $targetAbs)) jsonResponse(500, ['error' => 'No se pudo mover']);
    $finalRel = normalizeRelativePath(($newParentRel !== '' ? ($newParentRel . '/') : '') . basename($targetAbs));
    jsonResponse(200, ['success' => true, 'mode' => 'fs', 'fs_path' => $finalRel]);
}

// VIP: DB + FS espejo
$docId = (int)($data['document_id'] ?? 0);
$targetDir = isset($data['target_directory_id']) ? (int)$data['target_directory_id'] : null;
if ($docId <= 0) jsonResponse(400, ['error' => 'document_id requerido']);

$doc = $pdo->prepare('SELECT id, user_id, directory_id, display_name FROM documents WHERE id = ?');
$doc->execute([$docId]);
$d = $doc->fetch();
if (!$d || (int)$d['user_id'] !== (int)$user['id']) jsonResponse(404, ['error' => 'Documento no encontrado']);

if ($targetDir !== null) {
    $chk = $pdo->prepare('SELECT id, user_id FROM directories WHERE id = ?');
    $chk->execute([$targetDir]);
    $dir = $chk->fetch();
    if (!$dir || (int)$dir['user_id'] !== (int)$user['id']) jsonResponse(400, ['error' => 'target_directory_id inválido']);
}

$upd = $pdo->prepare('UPDATE documents SET directory_id = ? WHERE id = ?');
$upd->execute([$targetDir, $docId]);

$oldParentRel = dbRelativePathFromId($pdo, (int)$user['id'], $d['directory_id'] === null ? null : (int)$d['directory_id']);
$newParentRel = dbRelativePathFromId($pdo, (int)$user['id'], $targetDir);
$oldAbs = absPathForUser((int)$user['id'], normalizeRelativePath(($oldParentRel !== '' ? ($oldParentRel . '/') : '') . sanitizeName((string)$d['display_name']) . '.pdf'));
$newParentAbs = absPathForUser((int)$user['id'], $newParentRel);
if (!is_dir($newParentAbs)) mkdir($newParentAbs, 0777, true);
$targetAbs = uniqueChildPath($newParentAbs, sanitizeName((string)$d['display_name']), true, '.pdf');
if (is_file($oldAbs)) @rename($oldAbs, $targetAbs);
$finalRel = normalizeRelativePath(($newParentRel !== '' ? ($newParentRel . '/') : '') . basename($targetAbs));
jsonResponse(200, ['success' => true, 'mode' => 'vip', 'fs_path' => $finalRel]);