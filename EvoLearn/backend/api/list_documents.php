<?php
declare(strict_types=1);
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);
require_once __DIR__ . '/../includes/bootstrap.php'; // Includes db.php, auth.php, fs.php, etc.

// Preflight CORS
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'GET') jsonResponse(405, ['error' => 'Method not allowed']);

$pdo = getPDO();
$user = requireAuth($pdo);
$isVip = isVip($pdo, $user);

// --- FS Mode ---
if (!$isVip) {
    $dirRel = normalizeRelativePath((string)($_GET['path'] ?? ''));
    $absDir = absPathForUser((int)$user['id'], $dirRel);

    if (!is_dir($absDir)) jsonResponse(404, ['error' => 'Carpeta no encontrada']);

    $documents = [];
    foreach (scandir($absDir) as $item) {
        if ($item === '.' || $item === '..' || $item === '.dirmeta.json') continue;

        $absItem = $absDir . DIRECTORY_SEPARATOR . $item;
        $relItemPath = normalizeRelativePath(($dirRel !== '' ? ($dirRel . '/') : '') . $item);

        if (is_file($absItem)) {
            $ext = strtolower(pathinfo($item, PATHINFO_EXTENSION));
            $isSummary = str_starts_with($item, 'Resumen_') && $ext === 'txt';
            $isPdf = $ext === 'pdf';

            if ($isPdf || $isSummary) {
                $documents[] = [
                    'path' => $relItemPath,
                    'name' => $item,
                    'size' => filesize($absItem),
                    'type' => $isSummary ? 'summary' : 'pdf'
                ];
            }
        }
        // Directories are handled by list_directories.php
    }

    // Sort documents alphabetically
    usort($documents, fn($a, $b) => strcmp($a['name'], $b['name']));

    jsonResponse(200, [
        'success' => true,
        'mode' => 'fs',
        'fs_documents' => $documents
    ]);
}

// --- VIP Mode ---
$dirId = isset($_GET['directory_id']) ? (int)$_GET['directory_id'] : null;

// Validate parent directory if provided
if ($dirId !== null) {
    $chk = $pdo->prepare('SELECT id FROM directories WHERE id = ? AND user_id = ?');
    $chk->execute([$dirId, (int)$user['id']]);
    if (!$chk->fetch()) jsonResponse(400, ['error' => 'directory_id inválido']);
}

// Fetch documents from DB
$sql = 'SELECT id, display_name, created_at, directory_id
        FROM documents
        WHERE user_id = ? AND directory_id ' . ($dirId === null ? 'IS NULL' : '= ?') . '
        ORDER BY display_name ASC';
$params = $dirId === null ? [(int)$user['id']] : [(int)$user['id'], $dirId];
$stmt = $pdo->prepare($sql);
$stmt->execute($params);
$docs = $stmt->fetchAll();

// --- OPTIMIZACIÓN 1: Obtener la ruta del directorio UNA SOLA VEZ ---
try {
    $parentRel = dbRelativePathFromId($pdo, (int)$user['id'], $dirId);
    $dirAbs = absPathForUser((int)$user['id'], $parentRel);
    $canCheckFs = true;
} catch (Throwable $e) {
    // Si la búsqueda de ruta falla, simplemente omitimos la comprobación de resúmenes
    $canCheckFs = false;
    error_log("No se pudo encontrar la ruta para dirId $dirId: " . $e->getMessage());
}

// --- OPTIMIZACIÓN 2: Leer el contenido del directorio UNA SOLA VEZ ---
$fsFilenames = [];
if ($canCheckFs && is_dir($dirAbs)) {
    // scandir es rápido. Usamos array_flip para búsquedas O(1) (más rápido que in_array)
    $fsFilenames = array_flip(scandir($dirAbs));
}
// -----------------------------------------------------------------

$combinedDocs = [];
foreach ($docs as $doc) {
    // Añadir el documento PDF original
    $combinedDocs[] = [
        'id' => (int)$doc['id'],
        'display_name' => $doc['display_name'],
        'created_at' => $doc['created_at'],
        'directory_id' => $doc['directory_id'] === null ? null : (int)$doc['directory_id'],
        'type' => 'pdf' // Marcar como PDF
    ];

    // Comprobar su archivo de resumen (solo si pudimos leer el directorio)
    if ($canCheckFs) {
        try {
            $summaryFileName = 'Resumen_' . sanitizeName($doc['display_name']) . '.txt';

            // !! OPTIMIZADO: Búsqueda en memoria en lugar de file_exists()
            if (isset($fsFilenames[$summaryFileName])) {
            
                $summaryAbsPath = $dirAbs . DIRECTORY_SEPARATOR . $summaryFileName;
                $summaryRelPath = normalizeRelativePath(($parentRel !== '' ? ($parentRel . '/') : '') . $summaryFileName);
                
                $combinedDocs[] = [
                    'id' => null, // Los resúmenes no tienen ID de BD
                    'display_name' => $summaryFileName,
                    'created_at' => date('Y-m-d H:i:s', filemtime($summaryAbsPath)), // Usar fecha de modificación
                    'directory_id' => $doc['directory_id'] === null ? null : (int)$doc['directory_id'],
                    'type' => 'summary', // Marcar como resumen
                    'summary_path' => $summaryRelPath,
                    'original_doc_id' => (int)$doc['id'] // Enlazar al PDF original
                ];
            }
        } catch (Throwable $e) {
            // Registrar error si es necesario, pero no detener el listado
            error_log("Error procesando resumen para doc ID {$doc['id']}: " . $e->getMessage());
        }
    }
}

// Sort combined list
usort($combinedDocs, fn($a, $b) => strcmp($a['display_name'], $b['display_name']));

jsonResponse(200, [
    'success' => true,
    'mode' => 'vip',
    'documents' => $combinedDocs // Devolver la lista combinada
]);