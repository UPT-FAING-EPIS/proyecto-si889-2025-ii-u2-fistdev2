<?php
declare(strict_types=1);

require_once __DIR__ . '/db.php';
require_once __DIR__ . '/logger.php';

function getAuthorizationHeader(): ?string {
    // Prefer server vars exposed by Apache/FastCGI
    foreach ([
        'HTTP_AUTHORIZATION',
        'REDIRECT_HTTP_AUTHORIZATION',
        'Authorization'
    ] as $key) {
        if (isset($_SERVER[$key]) && is_string($_SERVER[$key]) && $_SERVER[$key] !== '') {
            return trim((string)$_SERVER[$key]);
        }
    }
    // Fallback: apache_request_headers with case-insensitive lookup
    if (function_exists('apache_request_headers')) {
        $requestHeaders = apache_request_headers();
        if (is_array($requestHeaders)) {
            foreach ($requestHeaders as $k => $v) {
                if (strcasecmp($k, 'Authorization') === 0) {
                    return trim((string)$v);
                }
            }
        }
    }
    return null;
}

function getBearerToken(): ?string {
    $headers = getAuthorizationHeader();
    if (!$headers) return null;
    if (preg_match('/Bearer\s(\S+)/', $headers, $matches)) {
        return $matches[1];
    }
    return null;
}

function issueToken(PDO $pdo, int $userId): string {
    $token = bin2hex(random_bytes(32)); // 64 hex chars
    $expires = (new DateTime('+7 days'))->format('Y-m-d H:i:s');
    $stmt = $pdo->prepare('UPDATE users SET auth_token = ?, token_expires_at = ? WHERE id = ?');
    $stmt->execute([$token, $expires, $userId]);
    return $token;
}

function requireAuth(PDO $pdo): array {
    $token = getBearerToken();
    if (!$token) {
        jsonResponse(401, ['error' => 'Missing Bearer token']);
    }
    $stmt = $pdo->prepare('SELECT id, name, email, token_expires_at FROM users WHERE auth_token = ?');
    $stmt->execute([$token]);
    $user = $stmt->fetch();
    if (!$user) {
        jsonResponse(401, ['error' => 'Invalid token']);
    }
    if (!empty($user['token_expires_at']) && (new DateTime() > new DateTime($user['token_expires_at']))) {
        jsonResponse(401, ['error' => 'Token expired']);
    }
    logger_set_user((int)$user['id']);
    log_info('Auth OK', ['user_id' => (int)$user['id']]);
    return $user;
}

function isVip(PDO $pdo, array $user): bool {
    // Check if VIP columns exist in the database first
    try {
        // Try is_vip column
        $stmt = $pdo->query('SHOW COLUMNS FROM users LIKE "is_vip"');
        if ($stmt->fetch()) {
            $stmt = $pdo->prepare('SELECT is_vip FROM users WHERE id = ?');
            $stmt->execute([(int)$user['id']]);
            $row = $stmt->fetch();
            if ($row !== false && isset($row['is_vip'])) {
                return (int)$row['is_vip'] === 1;
            }
        }
        
        // Try vip column
        $stmt = $pdo->query('SHOW COLUMNS FROM users LIKE "vip"');
        if ($stmt->fetch()) {
            $stmt = $pdo->prepare('SELECT vip FROM users WHERE id = ?');
            $stmt->execute([(int)$user['id']]);
            $row = $stmt->fetch();
            if ($row !== false && isset($row['vip'])) {
                $v = $row['vip'];
                return (int)$v === 1 || in_array(strtolower((string)$v), ['1', 'true'], true);
            }
        }
        
        // Try plan column
        $stmt = $pdo->query('SHOW COLUMNS FROM users LIKE "plan"');
        if ($stmt->fetch()) {
            $stmt = $pdo->prepare('SELECT plan FROM users WHERE id = ?');
            $stmt->execute([(int)$user['id']]);
            $row = $stmt->fetch();
            if ($row !== false && isset($row['plan'])) {
                $p = strtolower((string)$row['plan']);
                return in_array($p, ['vip', 'premium'], true);
            }
        }
    } catch (Throwable $e) {
        // If any error occurs, log it and return false (FS mode)
        error_log("isVip function error: " . $e->getMessage());
    }
    
    // Default to FS mode (non-VIP) if no VIP columns exist
    return false;
}