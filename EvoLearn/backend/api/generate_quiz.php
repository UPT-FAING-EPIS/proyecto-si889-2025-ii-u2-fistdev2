<?php
declare(strict_types=1);

require_once __DIR__ . '/../includes/bootstrap.php';
require_once __DIR__ . '/../includes/ai.php';

// CORS preflight
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

$pdo = null;
try {
    $pdo = getPDO();
} catch (Throwable $e) {
    // In FS mode or when DB isn't available, we still allow GET preview and POST without VIP checks
    log_error('DB init failed for generate_quiz', ['error' => $e->getMessage()]);
}

function build_prompt_for_quiz(string $summaryText, int $numQuestions): string {
    $summaryText = trim($summaryText);
    if (strlen($summaryText) > 9000) {
        $summaryText = substr($summaryText, 0, 9000);
    }
    $guidelines = <<<PROMPT
Genera exactamente {$numQuestions} preguntas de opción múltiple en español basadas en el siguiente resumen.

Requisitos:
- Devuelve SOLO JSON válido, sin texto adicional.
- Esquema:
{
  "questions": [
    { "text": "...", "options": ["...","...","...","..."], "correct_index": 0 }
  ]
}
- Cada pregunta debe tener 4 opciones.
- "correct_index" es el índice (0-3) de la opción correcta.
- No incluyas explicaciones ni justificaciones.

Resumen:
PROMPT;

    return $guidelines . "\n" . $summaryText;
}

function try_parse_json(string $text): ?array {
    $text = trim($text);
    if ($text === '') return null;
    // Try to extract the first JSON object from the text
    $start = strpos($text, '{');
    $end = strrpos($text, '}');
    if ($start !== false && $end !== false && $end > $start) {
        $jsonStr = substr($text, $start, $end - $start + 1);
        $data = json_decode($jsonStr, true);
        if (is_array($data)) return $data;
    }
    // Fallback: direct decode
    $data = json_decode($text, true);
    return is_array($data) ? $data : null;
}

function fallback_quiz_from_text(string $summaryText, int $numQuestions): array {
    $summaryText = trim($summaryText);
    if ($summaryText === '') {
        $summaryText = 'Contenido educativo general sobre el tema.';
    }
    // Basic sentence split
    $sentences = preg_split('/(?<=[.!?])\s+/', $summaryText) ?: [];
    if (count($sentences) === 0) {
        $sentences = [$summaryText];
    }
    $questions = [];
    for ($i = 0; $i < $numQuestions; $i++) {
        $base = $sentences[$i % count($sentences)];
        $base = trim($base);
        if (strlen($base) > 120) $base = substr($base, 0, 117) . '...';
        $qText = '¿Cuál es la afirmación correcta respecto a: ' . $base . '?';
        $opts = [
            'Afirmación correcta basada en el resumen',
            'Dato irrelevante o incorrecto',
            'Generalización ambigua',
            'Ejemplo que no aplica',
        ];
        $correctIndex = $i % 4;
        $questions[] = [
            'text' => $qText,
            'options' => $opts,
            'correct_index' => $correctIndex,
        ];
    }
    return $questions;
}

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    // Preview helper for testing in browser
    $text = isset($_GET['text']) ? (string)$_GET['text'] : '';
    $n = isset($_GET['n']) ? max(3, min(20, (int)$_GET['n'])) : 6;
    $questions = fallback_quiz_from_text($text !== '' ? $text : 'Texto de ejemplo para generar un cuestionario.', $n);
    jsonResponse(200, ['success' => true, 'questions' => $questions]);
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonResponse(405, ['error' => 'Method not allowed']);
}

// Auth required for POST
if ($pdo) {
    requireAuth($pdo);
}

$inputStr = file_get_contents('php://input');
$input = json_decode($inputStr, true);
if (!is_array($input)) {
    jsonResponse(400, ['error' => 'Invalid JSON body']);
}

$summaryText = isset($input['summary_text']) ? trim((string)$input['summary_text']) : '';
$numQuestions = isset($input['num_questions']) ? max(3, min(20, (int)$input['num_questions'])) : 6;
$model = isset($input['model']) ? (string)$input['model'] : 'gemini-2.5-flash';

if ($summaryText === '') {
    jsonResponse(400, ['error' => 'summary_text requerido']);
}

$apiKey = getenv('GEMINI_API_KEY');
if (!$apiKey || trim($apiKey) === '') {
    $apiKey = DEFAULT_GEMINI_KEY; // Fallback key
}

log_info('Quiz generation start', ['model' => $model, 'num_questions' => $numQuestions, 'summary_len' => strlen($summaryText)]);

$prompt = build_prompt_for_quiz($summaryText, $numQuestions);
$responseText = call_gemini($prompt, $apiKey, $model);
$data = try_parse_json($responseText);

if (!$data || !isset($data['questions']) || !is_array($data['questions'])) {
    log_error('AI quiz parse failed, using fallback', ['response_excerpt' => substr((string)$responseText, 0, 240)]);
    $questions = fallback_quiz_from_text($summaryText, $numQuestions);
    jsonResponse(200, ['success' => true, 'source' => 'fallback', 'questions' => $questions]);
}

// Normalize and validate structure
$questionsOut = [];
foreach ($data['questions'] as $q) {
    $text = isset($q['text']) ? (string)$q['text'] : '';
    $options = isset($q['options']) && is_array($q['options']) ? array_values(array_map('strval', $q['options'])) : [];
    $correct = isset($q['correct_index']) ? (int)$q['correct_index'] : 0;
    if ($text !== '' && count($options) === 4) {
        $correct = max(0, min(3, $correct));
        $questionsOut[] = [
            'text' => $text,
            'options' => $options,
            'correct_index' => $correct,
        ];
    }
}

if (count($questionsOut) === 0) {
    $questionsOut = fallback_quiz_from_text($summaryText, $numQuestions);
}

jsonResponse(200, ['success' => true, 'source' => 'ai', 'questions' => $questionsOut]);