<?php
declare(strict_types=1);

// Simple JSONL logger for AI workflow
// Writes to backend/logs/ai.log and also mirrors to PHP error_log

function logger_path(): string {
    $dir = __DIR__ . '/../logs';
    if (!is_dir($dir)) {
        @mkdir($dir, 0777, true);
    }
    return $dir . '/ai.log';
}

function logger_init(): void {
    if (!isset($GLOBALS['LOGGER_CTX'])) {
        $GLOBALS['LOGGER_CTX'] = [
            'request_id' => uniqid('req_', true),
            'user_id' => null,
            'script' => basename($_SERVER['SCRIPT_NAME'] ?? 'unknown'),
        ];
    }
}

function logger_set_user(int $userId): void {
    logger_init();
    $GLOBALS['LOGGER_CTX']['user_id'] = $userId;
}

function logger_write(string $level, string $message, array $context = []): void {
    logger_init();
    $ctx = $GLOBALS['LOGGER_CTX'];
    $ts = (new DateTime())->format('Y-m-d H:i:s.u');

    $base = [
        'ts' => $ts,
        'lvl' => $level,
        'req' => $ctx['request_id'],
        'user' => $ctx['user_id'],
        'script' => $ctx['script'],
        'method' => $_SERVER['REQUEST_METHOD'] ?? null,
        'uri' => $_SERVER['REQUEST_URI'] ?? null,
        'message' => $message,
    ];

    $line = json_encode(array_merge($base, $context), JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    @file_put_contents(logger_path(), $line . PHP_EOL, FILE_APPEND);
    // Mirror to PHP error log for quick visibility
    error_log('[AI] ' . $line);
}

function log_info(string $message, array $context = []): void { logger_write('INFO', $message, $context); }
function log_error(string $message, array $context = []): void { logger_write('ERROR', $message, $context); }
function log_debug(string $message, array $context = []): void { logger_write('DEBUG', $message, $context); }