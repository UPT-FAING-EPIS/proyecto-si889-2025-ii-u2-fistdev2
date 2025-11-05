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

if (!$isVip) {
    $pathRel = normalizeRelativePath((string)($data['path'] ?? ''));
    if ($pathRel === '') jsonResponse(400, ['error' => 'Path requerido']);
    $abs = absPathForUser((int)$user['id'], $pathRel);
    if (!is_dir($abs)) jsonResponse(404, ['error' => 'Carpeta no encontrada']);
    // Borrado recursivo
    $it = new RecursiveDirectoryIterator($abs, FilesystemIterator::SKIP_DOTS);
    $files = new RecursiveIteratorIterator($it, RecursiveIteratorIterator::CHILD_FIRST);
    foreach ($files as $fi) {
        if ($fi->isDir()) @rmdir($fi->getRealPath());
        else @unlink($fi->getRealPath());
    }
    @rmdir($abs);
    jsonResponse(200, ['success' => true, 'mode' => 'fs']);
}

$id = (int)($data['id'] ?? 0);
if ($id <= 0) jsonResponse(400, ['error' => 'id requerido']);

$stmt = $pdo->prepare('SELECT id, user_id, parent_id, name FROM directories WHERE id = ?');
$stmt->execute([$id]);
$row = $stmt->fetch();
if (!$row || (int)$row['user_id'] !== (int)$user['id']) jsonResponse(404, ['error' => 'Directorio no encontrado']);

$del = $pdo->prepare('DELETE FROM directories WHERE id = ?');
$del->execute([$id]);

// espejo FS
$parentRel = dbRelativePathFromId($pdo, (int)$user['id'], (int)$row['parent_id']);
$abs = absPathForUser((int)$user['id'], normalizeRelativePath(($parentRel !== '' ? ($parentRel . '/') : '') . sanitizeName((string)$row['name'])));
if (is_dir($abs)) {
    $it = new RecursiveDirectoryIterator($abs, FilesystemIterator::SKIP_DOTS);
    $files = new RecursiveIteratorIterator($it, RecursiveIteratorIterator::CHILD_FIRST);
    foreach ($files as $fi) {
        if ($fi->isDir()) @rmdir($fi->getRealPath());
        else @unlink($fi->getRealPath());
    }
    @rmdir($abs);
}

jsonResponse(200, ['success' => true, 'mode' => 'vip']);