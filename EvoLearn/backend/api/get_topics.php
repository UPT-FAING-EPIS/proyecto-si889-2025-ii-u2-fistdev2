<?php
declare(strict_types=1);
require_once 'cors.php';
require_once __DIR__ . '/../includes/db.php';
require_once __DIR__ . '/../includes/auth.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    jsonResponse(405, ['error' => 'Method not allowed']);
}

$pdo = getPDO();
requireAuth($pdo);

$documentId = isset($_GET['document_id']) ? (int)$_GET['document_id'] : 0;
if ($documentId <= 0) {
    jsonResponse(400, ['error' => 'Missing or invalid "document_id"']);
}

// Fetch topics
$stmt = $pdo->prepare('SELECT id, title, summary, position FROM topics WHERE document_id = ? ORDER BY position ASC');
$stmt->execute([$documentId]);
$topics = $stmt->fetchAll();

// Fetch flashcards grouped by topic
$stmt = $pdo->prepare('SELECT id, topic_id, question, answer, position FROM flashcards WHERE topic_id IN (SELECT id FROM topics WHERE document_id = ?) ORDER BY topic_id, position ASC');
$stmt->execute([$documentId]);
$flashcards = $stmt->fetchAll();

// Group flashcards under topics
$flashcardsByTopic = [];
foreach ($flashcards as $fc) {
    $tid = (int)$fc['topic_id'];
    if (!isset($flashcardsByTopic[$tid])) $flashcardsByTopic[$tid] = [];
    $flashcardsByTopic[$tid][] = [
        'id' => (int)$fc['id'],
        'question' => $fc['question'],
        'answer' => $fc['answer'],
        'position' => (int)$fc['position']
    ];
}

$out = [];
foreach ($topics as $t) {
    $tid = (int)$t['id'];
    $out[] = [
        'id' => $tid,
        'title' => $t['title'],
        'summary' => $t['summary'],
        'position' => (int)$t['position'],
        'flashcards' => $flashcardsByTopic[$tid] ?? []
    ];
}

jsonResponse(200, [
    'success' => true,
    'document_id' => $documentId,
    'topics' => $out
]);