import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnalysisService {
  final ApiService _api;
  final String _baseUrl;

  // Constructor correctly takes ApiService and gets baseUrl
  AnalysisService(this._api) : _baseUrl = _api.baseUrl;

  /// Generates a summary for a given PDF document.
  Future<String> summarizePdf({
    required String mode,      // 'vip' or 'fs'
    String? documentId,     // VIP mode identifier (ensure consistency if it's int or string)
    String? path,           // FS mode identifier
    required String fileName, // Used for saving
    String analysisType = 'summary_fast', // 'summary_fast' | 'summary_detailed'
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? 'default_user';

    if (mode == 'vip' && documentId != null) {
      // Llamada JSON al backend (VIP)
      final url = Uri.parse('$_baseUrl/api/generate_summary.php');
      final resp = await http.post(
        url,
        headers: _api.authHeaders,
        body: jsonEncode({
          'document_id': documentId,
          'file_name': fileName,
          'analysis_type': analysisType,
          'model': 'gemini-1.5-flash',
        }),
      );
      if (resp.statusCode != 200) {
        final data = jsonDecode(resp.body);
        throw Exception(data['error'] ?? 'No se pudo generar el resumen (VIP)');
      }
      final data = jsonDecode(resp.body);
      final summary = (data['summary_text'] as String?) ?? '';
      if (summary.isEmpty) {
        throw Exception('Resumen vacío');
      }
      // Guardar localmente para que aparezca en la lista
      final summaryFileName = 'Resumen_$fileName.txt';
      await LocalStorageService.saveSummaryFile(userId, summaryFileName, summary);
      return summary;
    }

    if (mode == 'fs' && path != null) {
      // Multipart con el PDF local (FS)
      final docsDir = await LocalStorageService.getDocumentsDir(userId);
      final file = File('${docsDir.path}/$path');
      if (!await file.exists()) {
        throw Exception('Archivo no encontrado: $path');
      }

      final url = Uri.parse('$_baseUrl/api/generate_summary.php');
      final request = http.MultipartRequest('POST', url);
      request.headers.addAll(_api.authHeaders);
      request.fields['file_name'] = fileName;
      request.fields['path'] = path; // nombre relativo para que el backend pueda guardar opcionalmente
      request.fields['analysis_type'] = analysisType;
      request.fields['model'] = 'gemini-1.5-flash';
      request.files.add(await http.MultipartFile.fromPath('pdf', file.path));

      final streamed = await request.send();
      final resp = await http.Response.fromStream(streamed);
      if (resp.statusCode != 200) {
        final data = jsonDecode(resp.body);
        throw Exception(data['error'] ?? 'No se pudo generar el resumen (FS)');
      }
      final data = jsonDecode(resp.body);
      final summary = (data['summary_text'] as String?) ?? '';
      if (summary.isEmpty) {
        throw Exception('Resumen vacío');
      }
      final summaryFileName = 'Resumen_$fileName.txt';
      await LocalStorageService.saveSummaryFile(userId, summaryFileName, summary);
      return summary;
    }

    throw Exception('Parámetros inválidos para resumen');
  }
}

/// Generates quiz questions for a given PDF document.
Future<List<Map<String, dynamic>>> generateQuizFromPdf({
  required String mode,      // 'vip' or 'fs'
  String? documentId,     // VIP mode identifier
  String? path,           // FS mode identifier
  required String fileName, // Used for placeholder text
}) async {
  // --- Placeholder for Actual Gemini AI Call ---
  // Similar to summarizePdf, this will involve:
  // 1. Fetching PDF content if needed.
  // 2. Calling Gemini with prompts designed to generate multiple-choice questions.
  // 3. Parsing the response (likely JSON) into the desired question format.
  print('Simulating Gemini quiz generation for: $fileName');
  await Future.delayed(const Duration(seconds: 5)); // Reduced simulation time

  // Simple pseudo-randomness for placeholder correct answers
  final baseSeed = DateTime.now().second + fileName.length;

  // Placeholder quiz data structure
  return List.generate(6, (i) => {
    'question': 'Pregunta ${i + 1} simulada sobre "$fileName"',
    'options': List.generate(4, (j) => 'Opción ${j + 1} para P.${i + 1} (simulada)'),
    // Generate a somewhat predictable but varying correct index
    'correctIndex': (baseSeed + i * 2) % 4,
  });
  // --- End Placeholder ---

  // Note: Unlike the summary, there's currently no backend call here
  // to save the generated quiz questions. This could be added if needed.
}