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
    if (!is_file($abs)) jsonResponse(404, ['error' => 'Documento no encontrado']);
    @unlink($abs);
    jsonResponse(200, ['success' => true, 'mode' => 'fs']);
}

// VIP Mode: Handle both PDF documents (with DB ID) and summary files (without DB ID)
$docId = isset($data['document_id']) ? (int)$data['document_id'] : null;
$summaryPath = isset($data['summary_path']) ? trim((string)$data['summary_path']) : '';

// If summary_path is provided, delete the summary file directly
if ($summaryPath !== '') {
    $pathRel = normalizeRelativePath($summaryPath);
    $abs = absPathForUser((int)$user['id'], $pathRel);
    
    // Verify it's a summary file and exists
    $fileName = basename($pathRel);
    if (!str_starts_with($fileName, 'Resumen_') || !str_ends_with($fileName, '.txt')) {
        jsonResponse(400, ['error' => 'Solo se pueden eliminar archivos de resumen con este parámetro']);
    }
    
    if (!is_file($abs)) {
        jsonResponse(404, ['error' => 'Archivo de resumen no encontrado']);
    }
    
    @unlink($abs);
    jsonResponse(200, ['success' => true, 'mode' => 'vip', 'type' => 'summary']);
}

$docId = (int)($data['document_id'] ?? 0);
if ($docId <= 0) jsonResponse(400, ['error' => 'document_id requerido']);

$sel = $pdo->prepare('SELECT id, user_id, stored_filename, directory_id, display_name FROM documents WHERE id = ?');
$sel->execute([$docId]);
$d = $sel->fetch();
if (!$d || (int)$d['user_id'] !== (int)$user['id']) jsonResponse(404, ['error' => 'Documento no encontrado']);

// borrar copia física espejo
$parentRel = dbRelativePathFromId($pdo, (int)$user['id'], $d['directory_id'] === null ? null : (int)$d['directory_id']);
$fsAbs = absPathForUser((int)$user['id'], normalizeRelativePath(($parentRel !== '' ? ($parentRel . '/') : '') . sanitizeName((string)$d['display_name']) . '.pdf'));
if (is_file($fsAbs)) @unlink($fsAbs);

// borrar archivo de resumen asociado si existe
$summaryFileName = 'Resumen_' . sanitizeName((string)$d['display_name']) . '.txt';
$summaryAbs = absPathForUser((int)$user['id'], normalizeRelativePath(($parentRel !== '' ? ($parentRel . '/') : '') . $summaryFileName));
if (is_file($summaryAbs)) @unlink($summaryAbs);

// borrar archivo almacenado principal
$path = __DIR__ . '/../uploads/' . $d['stored_filename'];
if (is_file($path)) @unlink($path);

$del = $pdo->prepare('DELETE FROM documents WHERE id = ?');
$del->execute([$docId]);

jsonResponse(200, ['success' => true, 'mode' => 'vip']);