<?php
declare(strict_types=1);

function storageBaseDir(): string {
    $base = __DIR__ . '/../uploads';
    if (!is_dir($base)) {
        mkdir($base, 0777, true);
    }
    return $base;
}

function userStorageRoot(int $userId): string {
    $root = storageBaseDir() . DIRECTORY_SEPARATOR . (string)$userId;
    if (!is_dir($root)) {
        mkdir($root, 0777, true);
    }
    return $root;
}

function normalizeRelativePath(string $rel): string {
    $rel = trim($rel);
    $rel = str_replace(['\\'], '/', $rel);
    if ($rel === '' || $rel === '/' ) return '';
    // Eliminar múltiples barras y normalizar
    $parts = array_values(array_filter(explode('/', $rel), 'strlen'));
    foreach ($parts as $p) {
        if ($p === '..') {
            throw new RuntimeException('Path traversal no permitido');
        }
        if ($p === '.') continue;
    }
    return implode('/', $parts);
}

function absPathForUser(int $userId, string $rel): string {
    $rel = normalizeRelativePath($rel);
    $root = userStorageRoot($userId);
    $abs = $root . ($rel !== '' ? DIRECTORY_SEPARATOR . str_replace('/', DIRECTORY_SEPARATOR, $rel) : '');
    // Garantizar que el path resultante cae dentro del root
    $realRoot = realpath($root) ?: $root;
    $realAbs = realpath($abs);
    if ($realAbs === false) {
        // Puede ser una ruta nueva; devolvemos el path calculado
        return $abs;
    }
    if (strpos($realAbs, $realRoot) !== 0) {
        throw new RuntimeException('Ruta fuera del root del usuario');
    }
    return $abs;
}

function sanitizeName(string $name): string {
    $name = trim($name);
    // Permitir letras, números, espacio, guion y guion bajo
    $name = preg_replace('/[^A-Za-z0-9 _\-\.]/', '', $name);
    $name = preg_replace('/\s+/', ' ', $name);
    $name = trim($name, " .");
    if ($name === '') throw new RuntimeException('Nombre inválido');
    return $name;
}

function uniqueChildPath(string $parentAbs, string $baseName, bool $isFile, ?string $ext = null): string {
    $attempt = 0;
    do {
        $suffix = $attempt === 0 ? '' : " ($attempt)";
        $name = $baseName . $suffix;
        $candidate = $parentAbs . DIRECTORY_SEPARATOR . $name . ($isFile && $ext ? $ext : '');
        $attempt++;
    } while (file_exists($candidate));
    return $candidate;
}

function dirMetaPath(string $absDir): string {
    return $absDir . DIRECTORY_SEPARATOR . '.dirmeta.json';
}

function readDirMeta(string $absDir): array {
    $metaFile = dirMetaPath($absDir);
    if (is_file($metaFile)) {
        $json = @file_get_contents($metaFile);
        if ($json !== false) {
            $data = json_decode($json, true);
            if (is_array($data)) return $data;
        }
    }
    return [];
}

function writeDirMeta(string $absDir, array $meta): void {
    $metaFile = dirMetaPath($absDir);
    @file_put_contents($metaFile, json_encode($meta, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_PRETTY_PRINT));
}

function listDirectoryNode(int $userId, string $absDir, string $relDir): array {
    $meta = readDirMeta($absDir);
    $node = [
        'name' => basename($absDir),
        'path' => $relDir,              // ruta relativa desde el root del usuario
        'color' => $meta['color'] ?? null,
        'directories' => [],
        'documents' => [],
    ];
    $items = scandir($absDir);
    foreach ($items as $item) {
        if ($item === '.' || $item === '..') continue;
        // ocultar archivos de metadatos
        if ($item === '.dirmeta.json') continue;

        $absItem = $absDir . DIRECTORY_SEPARATOR . $item;
        $relItem = $relDir !== '' ? ($relDir . '/' . $item) : $item;

        if (is_dir($absItem)) {
            $node['directories'][] = listDirectoryNode($userId, $absItem, $relItem);
        } elseif (is_file($absItem)) {
            // Solo listar PDFs por ahora
            $ext = strtolower(pathinfo($item, PATHINFO_EXTENSION));
            if ($ext === 'pdf') {
                $node['documents'][] = [
                    'name' => $item,
                    'path' => $relItem,
                    'size' => filesize($absItem),
                ];
            }
        }
    }
    return $node;
}

// Reflejar jerarquía de directorios de la BD como ruta relativa para FS
function dbRelativePathFromId(PDO $pdo, int $userId, ?int $dirId): string {
    if ($dirId === null) return '';
    $parts = [];
    $current = $dirId;
    $guard = 0;
    while ($current !== null && $guard++ < 1000) {
        $stmt = $pdo->prepare('SELECT id, parent_id, name, user_id FROM directories WHERE id = ?');
        $stmt->execute([$current]);
        $row = $stmt->fetch();
        if (!$row || (int)$row['user_id'] !== $userId) break;
        $parts[] = sanitizeName((string)($row['name'] ?? ''));
        $current = $row['parent_id'] === null ? null : (int)$row['parent_id'];
    }
    $parts = array_reverse(array_filter($parts, fn($p) => $p !== ''));
    return normalizeRelativePath(implode('/', $parts));
}