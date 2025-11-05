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
$docId = (int)($data['document_id'] ?? 0);
$newName = trim($data['new_name'] ?? '');
$pathRel = normalizeRelativePath((string)($data['path'] ?? ''));

if (!$isVip) {
    if ($pathRel === '' || $newName === '') jsonResponse(400, ['error' => 'path y new_name requeridos']);
    $abs = absPathForUser((int)$user['id'], $pathRel);
    if (!is_file($abs)) jsonResponse(404, ['error' => 'Documento no encontrado']);
    $dirAbs = dirname($abs);
    $ext = '.' . strtolower(pathinfo($abs, PATHINFO_EXTENSION));
    $targetAbs = uniqueChildPath($dirAbs, sanitizeName($newName), true, $ext);
    if (!@rename($abs, $targetAbs)) jsonResponse(500, ['error' => 'No se pudo renombrar']);
    $dirRel = normalizeRelativePath(dirname($pathRel));
    $finalRel = normalizeRelativePath(($dirRel !== '' ? ($dirRel . '/') : '') . basename($targetAbs));
    jsonResponse(200, ['success' => true, 'mode' => 'fs', 'fs_path' => $finalRel]);
}

// VIP: DB + FS espejo
if ($docId <= 0 || $newName === '') jsonResponse(400, ['error' => 'document_id y new_name requeridos']);
$doc = $pdo->prepare('SELECT id, user_id, directory_id, display_name FROM documents WHERE id = ?');
$doc->execute([$docId]);
$d = $doc->fetch();
if (!$d || (int)$d['user_id'] !== (int)$user['id']) jsonResponse(404, ['error' => 'Documento no encontrado']);

$upd = $pdo->prepare('UPDATE documents SET display_name = ? WHERE id = ?');
$upd->execute([$newName, $docId]);

$parentRel = dbRelativePathFromId($pdo, (int)$user['id'], $d['directory_id'] === null ? null : (int)$d['directory_id']);
$oldAbs = absPathForUser((int)$user['id'], normalizeRelativePath(($parentRel !== '' ? ($parentRel . '/') : '') . sanitizeName((string)$d['display_name']) . '.pdf'));
$dirAbs = absPathForUser((int)$user['id'], $parentRel);
$targetAbs = uniqueChildPath($dirAbs, sanitizeName($newName), true, '.pdf');
if (is_file($oldAbs)) @rename($oldAbs, $targetAbs);
$finalRel = normalizeRelativePath(($parentRel !== '' ? ($parentRel . '/') : '') . basename($targetAbs));
jsonResponse(200, ['success' => true, 'mode' => 'vip', 'fs_path' => $finalRel]);