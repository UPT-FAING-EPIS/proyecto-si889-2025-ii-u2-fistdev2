<?php
declare(strict_types=1);
require_once 'cors.php';
require_once __DIR__ . '/../includes/db.php';
require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../vendor/autoload.php'; // smalot/pdfparser
require_once __DIR__ . '/../includes/fs.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonResponse(405, ['error' => 'Method not allowed']);
}

$pdo = getPDO();
$user = requireAuth($pdo);
$isVip = isVip($pdo, $user);

// Leer directory_id (DB) y ruta relativa (FS)
$dirId = isset($_POST['directory_id']) ? (int)$_POST['directory_id'] : null;
$relativePath = normalizeRelativePath((string)($_POST['relative_path'] ?? ''));

if ($dirId !== null) {
    $checkDir = $pdo->prepare('SELECT id FROM directories WHERE id = ? AND user_id = ?');
    $checkDir->execute([$dirId, (int)$user['id']]);
    if (!$checkDir->fetch()) {
        jsonResponse(400, ['error' => 'Invalid directory_id']);
    }
}

// Validate upload
if (!isset($_FILES['pdf'])) {
    jsonResponse(400, ['error' => 'Missing file field "pdf"']);
}

$file = $_FILES['pdf'];
if ($file['error'] !== UPLOAD_ERR_OK) {
    jsonResponse(400, ['error' => 'Upload error', 'code' => $file['error']]);
}

$finfo = finfo_open(FILEINFO_MIME_TYPE);
$mime = finfo_file($finfo, $file['tmp_name']);
finfo_close($finfo);
if ($mime !== 'application/pdf') {
    jsonResponse(400, ['error' => 'Only PDF files are allowed', 'mime' => $mime]);
}

// Guardado principal (uploads)
$uploadDir = __DIR__ . '/../uploads';
if (!is_dir($uploadDir)) {
    mkdir($uploadDir, 0777, true);
}
$originalName = basename($file['name']);
$storedName = sprintf('%s_%s.pdf', date('YmdHis'), bin2hex(random_bytes(6)));
$targetPath = $uploadDir . DIRECTORY_SEPARATOR . $storedName;
if (!move_uploaded_file($file['tmp_name'], $targetPath)) {
    jsonResponse(500, ['error' => 'Failed to store file']);
}

// Parse PDF text
try {
    $parser = new \Smalot\PdfParser\Parser();
    $pdf = $parser->parseFile($targetPath);
    $text = $pdf->getText();
    $text = mb_substr($text, 0, 40000, 'UTF-8');
} catch (Throwable $e) {
    jsonResponse(500, ['error' => 'PDF parsing failed', 'details' => $e->getMessage()]);
}

// Siempre: guardar copia física bajo el root del usuario
$displayName = $originalName;
$baseRel = $relativePath !== '' ? $relativePath : dbRelativePathFromId($pdo, (int)$user['id'], $dirId);
$baseAbs = absPathForUser((int)$user['id'], $baseRel);
if (!is_dir($baseAbs)) mkdir($baseAbs, 0777, true);
$fsCopyAbs = uniqueChildPath($baseAbs, sanitizeName(pathinfo($displayName, PATHINFO_FILENAME)), true, '.pdf');
@copy($targetPath, $fsCopyAbs);
$fsCopyRel = normalizeRelativePath(($baseRel !== '' ? ($baseRel . '/') : '') . basename($fsCopyAbs));

// después de copiar al FS, si no es VIP, respondemos y no persistimos en BD:
if (!$isVip) {
    jsonResponse(200, [
        'success' => true,
        'mode' => 'fs',
        'fs_path' => $fsCopyRel,
        'ai_preview' => ['text_length' => strlen($text)]
    ]);
}

// Persistencia en DB (solo VIP)
try {
    $stmt = $pdo->prepare('INSERT INTO documents (user_id, directory_id, original_filename, display_name, stored_filename, mime_type, size_bytes, text_content, model_used) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)');
    $stmt->execute([(int)$user['id'], $dirId, $originalName, $displayName, $storedName, $mime, (int)$file['size'], $text, 'llama3']);
    $documentId = (int)$pdo->lastInsertId();
} catch (Throwable $e) {
    jsonResponse(500, ['error' => 'DB insert error (document)', 'details' => $e->getMessage()]);
}

// Build prompt
function buildEducationalPrompt(string $content): string {
    return <<<EOT
Eres un asistente educativo. Analiza el siguiente contenido (extracto de un sílabo/apuntes) y devuelve EXCLUSIVAMENTE un JSON válido con el siguiente esquema. NO agregues comentarios ni texto fuera del JSON.

Esquema:
{
  "summary": {
    "title": "string",
    "overview": "string (breve resumen en 3-5 frases)",
    "topics": [
      { "title": "string", "key_points": ["string", "string", "..."] }
    ]
  },
  "flashcards": [
    { "topic": "string", "question": "string", "answer": "string" }
  ]
}

Requisitos:
- Escribe las respuestas en español claro.
- Usa entre 4 y 8 temas máximo.
- Genera entre 10 y 20 flashcards variadas.
- Mantén las preguntas y respuestas concisas y útiles para estudio.
- No incluyas enlaces.
- Devuelve SOLO JSON, sin backticks.

Contenido:
---
$content
---
EOT;
}

$payload = [
    'model' => 'llama3',
    'prompt' => buildEducationalPrompt($text),
    'stream' => false,
    'format' => 'json',
    'options' => [
        'temperature' => 0.3,
        'num_predict' => 2048
    ]
];

// Desactivar IA por ahora (modo demo sin Ollama)
$USE_AI = false;

function stubAIFromText(string $text): array {
    $clean = trim(preg_replace('/\s+/', ' ', $text));
    $sentences = preg_split('/(?<=[\.\?\!])\s+/', $clean);
    $sentences = array_values(array_filter(array_map('trim', $sentences)));
    $overview = implode(' ', array_slice($sentences, 0, 3));
    $topics = [];
    $chunkSize = 3;
    $maxTopics = 4;
    for ($i = 0; $i < min($maxTopics, (int)ceil(count($sentences)/$chunkSize)); $i++) {
        $chunk = array_slice($sentences, $i*$chunkSize, $chunkSize);
        if (empty($chunk)) break;
        $topics[] = [
            'title' => 'Tema ' . ($i+1),
            'key_points' => array_map(fn($s) => mb_strimwidth($s, 0, 120, '...'), $chunk)
        ];
    }
    $flashcards = [];
    $maxCards = 12;
    $topicCount = max(1, count($topics));
    foreach (array_slice($sentences, 0, $maxCards) as $idx => $s) {
        $flashcards[] = [
            'topic' => 'Tema ' . (min($idx, $topicCount-1)+1),
            'question' => '¿Idea clave?: ' . mb_strimwidth($s, 0, 80, '...'),
            'answer' => mb_strimwidth($s, 0, 160, '...')
        ];
    }
    return [
        'summary' => [
            'title' => 'Documento subido',
            'overview' => $overview ?: 'Resumen generado sin IA (modo demo).',
            'topics' => $topics
        ],
        'flashcards' => $flashcards
    ];
}

// Call Ollama
function callOllama(array $payload): array {
    $ch = curl_init('http://localhost:11434/api/generate');
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_POST => true,
        CURLOPT_HTTPHEADER => ['Content-Type: application/json'],
        CURLOPT_POSTFIELDS => json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES),
        CURLOPT_TIMEOUT => 30
    ]);
    $result = curl_exec($ch);
    if ($result === false) {
        $err = curl_error($ch);
        curl_close($ch);
        throw new RuntimeException("Ollama call failed: $err");
    }
    $status = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    if ($status < 200 || $status >= 300) {
        throw new RuntimeException("Ollama returned HTTP $status: $result");
    }
    $json = json_decode($result, true);
    if (!is_array($json) || !isset($json['response'])) {
        throw new RuntimeException("Unexpected Ollama response");
    }
    $responseText = $json['response'];
    $parsed = json_decode($responseText, true);
    if (!is_array($parsed)) {
        throw new RuntimeException("Model did not return valid JSON");
    }
    return $parsed;
}

try {
    $ai = $USE_AI ? callOllama($payload) : stubAIFromText($text);

    // Store raw AI result
    $stmt = $pdo->prepare('INSERT INTO ai_results (document_id, prompt, response_json) VALUES (?, ?, ?)');
    $stmt->execute([$documentId, $payload['prompt'], json_encode($ai, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES)]);

    // Persist topics
    $topics = $ai['summary']['topics'] ?? [];
    $topicIds = [];
    $position = 0;
    foreach ($topics as $t) {
        $title = trim($t['title'] ?? 'Tema');
        $keyPoints = $t['key_points'] ?? [];
        $summary = implode("; ", array_map('strval', $keyPoints));
        $stmt = $pdo->prepare('INSERT INTO topics (document_id, title, summary, position) VALUES (?, ?, ?, ?)');
        $stmt->execute([$documentId, $title, $summary, $position++]);
        $topicIds[$title] = (int)$pdo->lastInsertId();
    }

    // Persist flashcards
    $flashcards = $ai['flashcards'] ?? [];
    $position = 0;
    foreach ($flashcards as $fc) {
        $topicTitle = trim($fc['topic'] ?? '');
        $topicId = $topicIds[$topicTitle] ?? null;
        if ($topicId === null && !empty($topicIds)) {
            $topicId = reset($topicIds);
        }
        if ($topicId === null) {
            continue;
        }
        $question = trim($fc['question'] ?? '');
        $answer = trim($fc['answer'] ?? '');
        if ($question === '' || $answer === '') continue;

        $stmt = $pdo->prepare('INSERT INTO flashcards (topic_id, question, answer, position) VALUES (?, ?, ?, ?)');
        $stmt->execute([$topicId, $question, $answer, $position++]);
    }

    jsonResponse(200, [
        'success' => true,
        'mode' => 'vip',
        'document_id' => $documentId,
        'topics_count' => count($topicIds),
        'flashcards_count' => count($flashcards),
        'fs_path' => $fsCopyRel
    ]);
} catch (Throwable $e) {
    // Fallback de seguridad: si algo falla, intenta stub y continúa
    $ai = stubAIFromText($text);
    $stmt = $pdo->prepare('INSERT INTO ai_results (document_id, prompt, response_json) VALUES (?, ?, ?)');
    $stmt->execute([$documentId, 'STUB_MODE', json_encode($ai, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES)]);
    jsonResponse(200, [
        'success' => true,
        'mode' => 'vip',
        'document_id' => $documentId,
        'topics_count' => count($ai['summary']['topics'] ?? []),
        'flashcards_count' => count($ai['flashcards'] ?? []),
        'fs_path' => $fsCopyRel
    ]);
}
jsonResponse(500, ['error' => 'AI processing failed', 'details' => $e->getMessage()]);