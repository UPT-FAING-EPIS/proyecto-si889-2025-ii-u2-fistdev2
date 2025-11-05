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
$summary = trim($data['summary'] ?? '');
$fileName = trim($data['file_name'] ?? '');

if ($summary === '' || $fileName === '') {
    jsonResponse(400, ['error' => 'summary y file_name son requeridos']);
}

// Determinar si estamos en modo VIP o FS
$docId = isset($data['document_id']) ? (int)$data['document_id'] : null;
$pathRel = normalizeRelativePath((string)($data['path'] ?? ''));

if (!$isVip || $pathRel !== '') {
    // Modo FS o ambos modos
    if ($pathRel === '') {
        jsonResponse(400, ['error' => 'path es requerido para modo FS']);
    }
    
    // Obtener la ruta del directorio padre
    $dirRel = normalizeRelativePath(dirname($pathRel));
    $dirAbs = absPathForUser((int)$user['id'], $dirRel);
    
    // Crear el archivo de resumen
    $summaryFileName = 'Resumen_' . sanitizeName($fileName) . '.txt';
    $summaryPath = $dirAbs . DIRECTORY_SEPARATOR . $summaryFileName;
    
    if (!@file_put_contents($summaryPath, $summary)) {
        jsonResponse(500, ['error' => 'No se pudo guardar el resumen']);
    }
    
    $summaryRelPath = normalizeRelativePath(($dirRel !== '' ? ($dirRel . '/') : '') . $summaryFileName);
    
    jsonResponse(200, [
        'success' => true, 
        'mode' => $isVip ? 'vip' : 'fs',
        'summary_path' => $summaryRelPath
    ]);
}

// Si llegamos aquí, es modo VIP sin path
if ($docId === null || $docId <= 0) {
    jsonResponse(400, ['error' => 'document_id es requerido para modo VIP']);
}

// Obtener información del documento
$stmt = $pdo->prepare('SELECT directory_id, display_name FROM documents WHERE id = ? AND user_id = ?');
$stmt->execute([$docId, (int)$user['id']]);
$doc = $stmt->fetch();

if (!$doc) {
    jsonResponse(404, ['error' => 'Documento no encontrado']);
}

// Crear el archivo de resumen en el sistema de archivos espejo
$parentRel = dbRelativePathFromId($pdo, (int)$user['id'], $doc['directory_id'] === null ? null : (int)$doc['directory_id']);
$dirAbs = absPathForUser((int)$user['id'], $parentRel);

$summaryFileName = 'Resumen_' . sanitizeName($doc['display_name']) . '.txt';
$summaryPath = $dirAbs . DIRECTORY_SEPARATOR . $summaryFileName;

if (!@file_put_contents($summaryPath, $summary)) {
    jsonResponse(500, ['error' => 'No se pudo guardar el resumen']);
}

$summaryRelPath = normalizeRelativePath(($parentRel !== '' ? ($parentRel . '/') : '') . $summaryFileName);

jsonResponse(200, [
    'success' => true,
    'mode' => 'vip',
    'summary_path' => $summaryRelPath
]);