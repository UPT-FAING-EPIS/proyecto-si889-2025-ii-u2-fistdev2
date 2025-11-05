<?php
declare(strict_types=1);
require_once 'cors.php';
require_once '../includes/db.php';
require_once '../includes/auth.php';
require_once __DIR__ . '/../includes/fs.php';
// Preflight CORS
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }
// Allow GET or POST
if ($_SERVER['REQUEST_METHOD'] !== 'GET' && $_SERVER['REQUEST_METHOD'] !== 'POST') jsonResponse(405, ['error' => 'Method not allowed']);

$pdo = getPDO();
$user = requireAuth($pdo);
$isVip = isVip($pdo, $user);

if (!$isVip) {
    $root = userStorageRoot((int)$user['id']);
    if (!is_dir($root)) mkdir($root, 0777, true);
    $fsTree = listDirectoryNode((int)$user['id'], $root, '');
    jsonResponse(200, ['success' => true, 'mode' => 'fs', 'fs_tree' => $fsTree]);
}

$stmt = $pdo->prepare('SELECT id, parent_id, name, color_hex, position FROM directories WHERE user_id = ? ORDER BY parent_id ASC, position ASC, name ASC');
$stmt->execute([(int)$user['id']]);
$rows = $stmt->fetchAll();

$byId = [];
foreach ($rows as $r) {
    $byId[(int)$r['id']] = [
        'id' => (int)$r['id'],
        'parent_id' => $r['parent_id'] === null ? null : (int)$r['parent_id'],
        'name' => $r['name'],
        'color_hex' => $r['color_hex'],
        'position' => (int)$r['position'],
        'children' => []
    ];
}
$roots = [];
foreach ($byId as $id => &$node) {
    $pid = $node['parent_id'];
    if ($pid === null || !isset($byId[$pid])) {
        $roots[] = &$node;
    } else {
        $byId[$pid]['children'][] = &$node;
    }
}
jsonResponse(200, ['success' => true, 'mode' => 'vip', 'directories' => $roots]);



