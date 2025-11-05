<?php
declare(strict_types=1);
require_once 'cors.php';
require_once __DIR__ . '/../includes/bootstrap.php';
require_once __DIR__ . '/../includes/ai.php';
require_once __DIR__ . '/../vendor/autoload.php'; // Para Smalot\PdfParser si se usa archivo FS

use Smalot\PdfParser\Parser as PdfParser;

if ($_SERVER['REQUEST_METHOD'] !== 'POST') jsonResponse(405, ['error' => 'Method not allowed']);

$pdo = getPDO();
$user = requireAuth($pdo);
$isVip = isVip($pdo, $user);

// Acepta JSON o form-data
$data = json_decode(file_get_contents('php://input'), true) ?? $_POST;
$analysisType = (string)($data['analysis_type'] ?? 'summary_fast');
$clientModel = trim((string)($data['model'] ?? ''));
if ($clientModel === '' || preg_match('/^gemini-1\.5/', $clientModel)) {
    $model = ($analysisType === 'summary_detailed') ? 'gemini-2.5-pro' : 'gemini-2.5-flash';
} else {
    $model = $clientModel;
}
$fileName = trim((string)($data['file_name'] ?? ''));
$pathRel = normalizeRelativePath((string)($data['path'] ?? ''));
$docId = isset($data['document_id']) ? (int)$data['document_id'] : null;
log_info('Generate summary request', ['analysis_type' => $analysisType, 'model' => $model, 'docId' => $docId, 'path' => $pathRel, 'file' => $fileName, 'mode_hint' => $isVip ? 'vip' : 'fs']);

// VIP: usar contenido del documento desde BD y guardar resumen en espejo FS
if ($isVip && $docId) {
    $stmt = $pdo->prepare('SELECT directory_id, display_name, text_content FROM documents WHERE id = ? AND user_id = ?');
    $stmt->execute([$docId, (int)$user['id']]);
    $doc = $stmt->fetch();
    if (!$doc) {
        jsonResponse(404, ['error' => 'Documento no encontrado']);
    }

    $text = (string)($doc['text_content'] ?? '');
    if (trim($text) === '') {
        jsonResponse(422, ['error' => 'Documento sin texto extraído para resumen']);
    }

    $summary = gemini_summarize($text, $analysisType, $model);
    if ($summary === '') {
        log_error('Summary generation failed (VIP)', ['docId' => (int)$doc['directory_id']]);
        jsonResponse(502, ['error' => 'No se pudo generar el resumen']);
    }

    // Guardar archivo "Resumen_" junto al documento en espejo FS
    $parentRel = dbRelativePathFromId($pdo, (int)$user['id'], $doc['directory_id'] === null ? null : (int)$doc['directory_id']);
    $dirAbs = absPathForUser((int)$user['id'], $parentRel);

    $summaryFileName = 'Resumen_' . sanitizeName((string)$doc['display_name']) . '.txt';
    $summaryAbsPath = $dirAbs . DIRECTORY_SEPARATOR . $summaryFileName;
    if (!@file_put_contents($summaryAbsPath, $summary)) {
        log_error('Failed to save summary file', ['path' => $summaryAbsPath]);
        jsonResponse(500, ['error' => 'No se pudo guardar el resumen']);
    }

    $summaryRelPath = normalizeRelativePath(($parentRel !== '' ? ($parentRel . '/') : '') . $summaryFileName);

    jsonResponse(200, [
        'success' => true,
        'mode' => 'vip',
        'summary_text' => $summary,
        'summary_path' => $summaryRelPath,
    ]);
}

// FS: si se envía archivo PDF en multipart, parsear y resumir.
// Guardado en servidor es opcional; la app guardará localmente en el cliente.
$pdfTmp = $_FILES['pdf']['tmp_name'] ?? null;
if ($pdfTmp && is_file($pdfTmp)) {
    $parser = new PdfParser();
    try {
        $pdf = $parser->parseFile($pdfTmp);
        $text = (string)$pdf->getText();
    } catch (Throwable $e) {
        jsonResponse(422, ['error' => 'No se pudo extraer texto del PDF']);
    }

    $summary = gemini_summarize($text, $analysisType, $model);
    if ($summary === '') {
        log_error('Summary generation failed (FS)', ['path' => $pathRel, 'file' => $fileName]);
        jsonResponse(502, ['error' => 'No se pudo generar el resumen']);
    }

    // Si se quiere, guardar también en espejo FS usando pathRel (opcional)
    $summaryRelPath = null;
    if ($pathRel !== '' && $fileName !== '') {
        $dirRel = normalizeRelativePath(dirname($pathRel));
        $dirAbs = absPathForUser((int)$user['id'], $dirRel);
        if (!is_dir($dirAbs)) {
            @mkdir($dirAbs, 0777, true);
        }
        $summaryFileName = 'Resumen_' . sanitizeName($fileName) . '.txt';
        $target = $dirAbs . DIRECTORY_SEPARATOR . $summaryFileName;
        if (@file_put_contents($target, $summary)) {
            $summaryRelPath = normalizeRelativePath(($dirRel !== '' ? ($dirRel . '/') : '') . $summaryFileName);
        }
    }

    jsonResponse(200, [
        'success' => true,
        'mode' => $isVip ? 'vip' : 'fs',
        'summary_text' => $summary,
        'summary_path' => $summaryRelPath,
    ]);
}

jsonResponse(400, ['error' => 'Parámetros inválidos: requiere document_id (VIP) o archivo pdf (FS)']);