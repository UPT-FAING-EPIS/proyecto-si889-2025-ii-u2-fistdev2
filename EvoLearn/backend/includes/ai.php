<?php
declare(strict_types=1);

// Helper para resumen con Gemini
// Usa env GEMINI_API_KEY si está disponible; de lo contrario, usa DEFAULT_GEMINI_KEY.

const DEFAULT_GEMINI_KEY = 'AIzaSyBQJQ3q68LqFGoUDA9QxxYTQZA1KpwUzTQ';
const GEMINI_ENDPOINT = 'https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent?key=%s';
const GEMINI_ENDPOINT_V1 = 'https://generativelanguage.googleapis.com/v1/models/%s:generateContent?key=%s';

/**
 * Resume texto largo con Gemini. Maneja chunking si el texto excede límites.
 * @param string $text Texto a resumir
 * @param string $analysisType 'summary_fast' | 'summary_detailed'
 * @param string $model Modelo, ej. 'gemini-1.5-flash'
 * @return string Resumen generado
 */
function gemini_summarize(string $text, string $analysisType = 'summary_fast', string $model = 'gemini-2.5-flash'): string {
    $apiKey = getenv('GEMINI_API_KEY');
    if (!$apiKey || trim($apiKey) === '') {
        $apiKey = DEFAULT_GEMINI_KEY;
    }

    $text = trim($text);
    if ($text === '') {
        return '';
    }

    // Chunking simple por caracteres para evitar límites.
    $chunks = split_text_chunks($text, 12000); // 12k chars por chunk como base segura
    log_info('AI: chunking complete', ['chunks' => count($chunks), 'analysis_type' => $analysisType, 'model' => $model]);

    $partialSummaries = [];
    foreach ($chunks as $idx => $chunk) {
        $prompt = build_prompt($chunk, $analysisType, $idx + 1, count($chunks));
        log_debug('AI: calling Gemini for chunk', ['index' => $idx + 1, 'prompt_len' => strlen($prompt)]);
        $summary = call_gemini($prompt, $apiKey, $model);
        if ($summary !== '') {
            log_info('AI: chunk summarized', ['index' => $idx + 1, 'summary_len' => strlen($summary)]);
            $partialSummaries[] = $summary;
        } else {
            log_error('AI: chunk summary empty', ['index' => $idx + 1]);
        }
    }

    if (count($partialSummaries) === 0) {
        log_error('AI: no partial summaries');
        return '';
    }

    if (count($partialSummaries) === 1) {
        return $partialSummaries[0];
    }

    // Resumen final para combinar parciales.
    $finalPrompt = "Combina y sintetiza los siguientes resúmenes parciales en un único resumen claro y coherente.\n\n" .
                   "Respetar el idioma original del texto (español).\n" .
                   "Usa viñetas concisas y una sección final de recomendaciones accionables.\n\n" .
                   implode("\n\n---\n\n", $partialSummaries);

    log_info('AI: combining partial summaries', ['count' => count($partialSummaries)]);
    $final = call_gemini($finalPrompt, $apiKey, $model);
    return $final !== '' ? $final : implode("\n\n", $partialSummaries);
}

function build_prompt(string $text, string $analysisType, int $chunkIndex, int $chunksTotal): string {
    $mode = $analysisType === 'summary_detailed' ? 'detallado' : 'rápido';
    $guidelines = $analysisType === 'summary_detailed'
        ? "- Extensión: 250-400 palabras.\n- Estructura: título, puntos clave, hallazgos, recomendaciones.\n- Mantén nombres propios y términos técnicos.\n"
        : "- Extensión: 100-180 palabras.\n- Céntrate en 5-8 viñetas clave y 2-3 acciones.\n";

    return sprintf(
        "Genera un resumen %s del siguiente contenido (parte %d de %d).\n\n" .
        "%s\n" .
        "- Mantén el idioma original (español).\n- No inventes contenido.\n- No incluyas metadatos del sistema.\n\nContenido:\n\n%s",
        $mode,
        $chunkIndex,
        $chunksTotal,
        $guidelines,
        $text
    );
}

/**
 * Divide texto en trozos por límite de caracteres.
 * @param string $text
 * @param int $limit
 * @return array<int,string>
 */
function split_text_chunks(string $text, int $limit): array {
    $text = str_replace(["\r\n", "\r"], "\n", $text);
    $chunks = [];
    $len = strlen($text);
    for ($i = 0; $i < $len; $i += $limit) {
        $chunks[] = substr($text, $i, min($limit, $len - $i));
    }
    return $chunks;
}

/**
 * Llama a Gemini API con un prompt y devuelve el texto.
 * @param string $prompt
 * @param string $apiKey
 * @param string $model
 * @return string
 */
function list_models_log(string $apiKey): void {
    static $done = false;
    if ($done) return;
    $done = true;
    $endpoints = [
        'v1' => 'https://generativelanguage.googleapis.com/v1/models?key=%s',
        'v1beta' => 'https://generativelanguage.googleapis.com/v1beta/models?key=%s',
    ];
    foreach ($endpoints as $label => $tpl) {
        $url = sprintf($tpl, urlencode($apiKey));
        $ch = curl_init($url);
        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT => 20,
        ]);
        $resp = curl_exec($ch);
        $err = curl_error($ch);
        $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        if ($resp === false) {
            log_error('ListModels curl failed', ['api' => $label, 'error' => $err ?: 'unknown']);
            continue;
        }
        $data = json_decode($resp, true);
        $names = [];
        if (isset($data['models']) && is_array($data['models'])) {
            foreach ($data['models'] as $m) {
                if (isset($m['name'])) $names[] = $m['name'];
            }
        }
        log_info('ListModels', ['api' => $label, 'code' => $code, 'count' => count($names), 'sample' => array_slice($names, 0, 6)]);
    }
}

function call_gemini(string $prompt, string $apiKey, string $model): string {
    list_models_log($apiKey);
    $models = array_values(array_unique([
        $model,
        'gemini-2.5-flash',
        'gemini-2.5-pro',
        'gemini-2.0-flash',
        'gemini-2.0-flash-001'
    ]));
    $endpointVersions = [
        ['label' => 'v1', 'tpl' => GEMINI_ENDPOINT_V1],
        ['label' => 'v1beta', 'tpl' => GEMINI_ENDPOINT],
    ];
    foreach ($endpointVersions as $ver) {
        foreach ($models as $m) {
            $url = sprintf($ver['tpl'], $m, urlencode($apiKey));
            $payload = [
                'contents' => [[
                    'role' => 'user',
                    'parts' => [[ 'text' => $prompt ]]
                ]]
            ];
            $ch = curl_init($url);
            curl_setopt_array($ch, [
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_POST => true,
                CURLOPT_HTTPHEADER => [
                    'Content-Type: application/json'
                ],
                CURLOPT_POSTFIELDS => json_encode($payload),
                CURLOPT_TIMEOUT => 30,
            ]);
            $resp = curl_exec($ch);
            $err = curl_error($ch);
            $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            curl_close($ch);

            log_debug('Gemini response meta', ['code' => $code, 'api' => $ver['label'], 'model' => $m, 'err' => $err ? (string)$err : null]);
            if ($resp === false) {
                log_error('Gemini curl failed', ['api' => $ver['label'], 'model' => $m, 'error' => $err ?: 'unknown']);
                continue;
            }

            $respExcerpt = substr((string)$resp, 0, 240);
            $data = json_decode($resp, true);
            if ($code >= 200 && $code < 300 && isset($data['candidates'][0]['content']['parts'][0]['text'])) {
                $out = trim((string)$data['candidates'][0]['content']['parts'][0]['text']);
                log_info('Gemini success', ['api' => $ver['label'], 'model' => $m, 'text_len' => strlen($out)]);
                return $out;
            }

            log_error('Gemini unexpected response', ['code' => $code, 'api' => $ver['label'], 'model' => $m, 'body_excerpt' => $respExcerpt]);
        }
    }
    return '';
}