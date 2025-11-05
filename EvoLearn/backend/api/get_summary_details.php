<?php
declare(strict_types=1);
require_once __DIR__ . '/../includes/bootstrap.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    jsonResponse(405, ['error' => 'Method not allowed']);
}

$pdo = getPDO();
$user = requireAuth($pdo);
$isVip = isVip($pdo, $user);

// Get parameters
$summaryId = isset($_GET['summary_id']) ? (int)$_GET['summary_id'] : null;
$path = isset($_GET['path']) ? trim($_GET['path']) : '';

if ($isVip && $summaryId !== null) {
    // VIP Mode: Get summary by ID
    // First, check if this is a summary document
    $stmt = $pdo->prepare('SELECT display_name FROM documents WHERE id = ? AND user_id = ?');
    $stmt->execute([$summaryId, (int)$user['id']]);
    $doc = $stmt->fetch();
    
    if (!$doc) {
        jsonResponse(404, ['error' => 'Resumen no encontrado']);
    }
    
    // Get the directory path for this document
    $stmt = $pdo->prepare('SELECT directory_id FROM documents WHERE id = ? AND user_id = ?');
    $stmt->execute([$summaryId, (int)$user['id']]);
    $docData = $stmt->fetch();
    
    if (!$docData) {
        jsonResponse(404, ['error' => 'Documento no encontrado']);
    }
    
    // Get the relative path for the directory
    $parentRel = dbRelativePathFromId($pdo, (int)$user['id'], $docData['directory_id'] === null ? null : (int)$docData['directory_id']);
    $dirAbs = absPathForUser((int)$user['id'], $parentRel);
    
    // Construct the summary file path
    $summaryFileName = 'Resumen_' . sanitizeName($doc['display_name']) . '.txt';
    $summaryPath = $dirAbs . DIRECTORY_SEPARATOR . $summaryFileName;
    
    if (!file_exists($summaryPath)) {
        jsonResponse(404, ['error' => 'Archivo de resumen no encontrado']);
    }
    
    $summaryContent = @file_get_contents($summaryPath);
    if ($summaryContent === false) {
        jsonResponse(500, ['error' => 'No se pudo leer el archivo de resumen']);
    }
    
    jsonResponse(200, [
        'success' => true,
        'mode' => 'vip',
        'summary_text' => $summaryContent,
        'file_name' => $doc['display_name']
    ]);
    
} elseif (!$isVip && $path !== '') {
    // FS Mode: Get summary by path
    $pathRel = normalizeRelativePath($path);
    $absPath = absPathForUser((int)$user['id'], $pathRel);
    
    if (!file_exists($absPath)) {
        jsonResponse(404, ['error' => 'Archivo de resumen no encontrado']);
    }
    
    $summaryContent = @file_get_contents($absPath);
    if ($summaryContent === false) {
        jsonResponse(500, ['error' => 'No se pudo leer el archivo de resumen']);
    }
    
    $fileName = basename($pathRel);
    jsonResponse(200, [
        'success' => true,
        'mode' => 'fs',
        'summary_text' => $summaryContent,
        'file_name' => $fileName
    ]);
    
} else {
    jsonResponse(400, ['error' => 'Parámetros inválidos. Para modo VIP use summary_id, para modo FS use path']);
}
