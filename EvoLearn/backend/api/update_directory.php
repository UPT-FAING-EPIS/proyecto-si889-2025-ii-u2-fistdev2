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
$id = (int)($data['id'] ?? 0);
$name = isset($data['name']) ? trim($data['name']) : null;
$color = isset($data['color_hex']) ? strtoupper(trim($data['color_hex'])) : null;
$pathRel = normalizeRelativePath((string)($data['path'] ?? ''));

if (!$isVip) {
    if ($pathRel === '') jsonResponse(400, ['error' => 'Path requerido']);
    $abs = absPathForUser((int)$user['id'], $pathRel);
    if (!is_dir($abs)) jsonResponse(404, ['error' => 'Carpeta no encontrada']);
    $finalAbs = $abs;
    if ($name !== null && $name !== '') {
        $parentAbs = dirname($abs);
        $targetAbs = uniqueChildPath($parentAbs, sanitizeName($name), false);
        if (!@rename($abs, $targetAbs)) jsonResponse(500, ['error' => 'No se pudo renombrar la carpeta']);
        $finalAbs = $targetAbs;
    }
    if ($color !== null && preg_match('/^#[0-9A-F]{6}$/', $color)) {
        $meta = readDirMeta($finalAbs);
        $meta['color'] = $color;
        writeDirMeta($finalAbs, $meta);
    }
    $finalRel = normalizeRelativePath(($pathRel !== '' ? dirname($pathRel) . '/' : '') . basename($finalAbs));
    jsonResponse(200, ['success' => true, 'mode' => 'fs', 'fs_path' => $finalRel]);
}

// VIP: DB + FS espejo
if ($id <= 0) jsonResponse(400, ['error' => 'id requerido']);
$dir = $pdo->prepare('SELECT id, user_id, parent_id, name FROM directories WHERE id = ?');
$dir->execute([$id]);
$row = $dir->fetch();
if (!$row || (int)$row['user_id'] !== (int)$user['id']) jsonResponse(404, ['error' => 'Directorio no encontrado']);

if ($color !== null && !preg_match('/^#[0-9A-F]{6}$/', $color)) $color = null;

$fields = []; $params = [];
if ($name !== null && $name !== '') { $fields[] = 'name = ?'; $params[] = $name; }
if ($color !== null) { $fields[] = 'color_hex = ?'; $params[] = $color; }
if (empty($fields)) jsonResponse(400, ['error' => 'Nada por actualizar']);

$set = implode(', ', $fields);
$params[] = $id;

try {
    $upd = $pdo->prepare("UPDATE directories SET $set WHERE id = ?");
    $upd->execute($params);

    // FS renombrado/metadata
    $parentRel = dbRelativePathFromId($pdo, (int)$user['id'], (int)$row['parent_id']);
    $oldAbs = absPathForUser((int)$user['id'], normalizeRelativePath(($parentRel !== '' ? ($parentRel . '/') : '') . sanitizeName((string)$row['name'])));
    $finalAbs = $oldAbs;
    if ($name !== null && $name !== '' && is_dir($oldAbs)) {
        $parentAbs = absPathForUser((int)$user['id'], $parentRel);
        $targetAbs = $parentAbs . DIRECTORY_SEPARATOR . sanitizeName($name);
        if (!is_dir($targetAbs)) {
            @rename($oldAbs, $targetAbs);
        }
        $finalAbs = is_dir($targetAbs) ? $targetAbs : $oldAbs;
    }
    if ($color !== null) {
        $meta = readDirMeta($finalAbs);
        $meta['color'] = $color;
        writeDirMeta($finalAbs, $meta);
    }
    $finalRel = normalizeRelativePath(($parentRel !== '' ? ($parentRel . '/') : '') . basename($finalAbs));
    jsonResponse(200, ['success' => true, 'mode' => 'vip', 'fs_path' => $finalRel]);
} catch (Throwable $e) {
    if (str_contains($e->getMessage(), 'uniq_dir_name_per_parent')) {
        jsonResponse(409, ['error' => 'Ya existe una carpeta con ese nombre en el mismo nivel']);
    }
    jsonResponse(500, ['error' => 'Server error', 'details' => $e->getMessage()]);
}