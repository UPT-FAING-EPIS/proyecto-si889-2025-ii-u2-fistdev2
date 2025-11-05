import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final String baseUrl;

  ApiService({required this.baseUrl});

  String? _token;
  void setToken(String token) => _token = token;
  void clearToken() => _token = null; // NUEVO

  // --- NUEVO: asegura que el token esté cargado desde preferencias ---
  Future<void> _ensureAuth() async {
    if (_token == null || _token!.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('token');
      if (stored != null && stored.isNotEmpty) {
        _token = stored;
      }
    }
  }

  Map<String, String> get authHeaders => {
    'Content-Type': 'application/json',
    if (_token != null && _token!.isNotEmpty) 'Authorization': 'Bearer $_token',
    if (_token != null && _token!.isNotEmpty) 'X-Auth-Token': _token!,
  };

  Future<String> register(
      String name, String email, String password, String confirm) async {
    final url = Uri.parse('$baseUrl/api/register.php');
    final resp = await http.post(
      url,
      // Enviar como form-url-encoded para compatibilidad con servidor desplegado
      body: {
        'name': name,
        'email': email,
        'password': password,
        'confirm_password': confirm,
      },
    );
    final data = jsonDecode(resp.body);
    if (resp.statusCode == 201 && data['success'] == true) {
      _token = data['token'];

      // Persist token and user info for session restore
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      if (data['user'] != null && data['user']['id'] != null) {
        await prefs.setString('user_id', data['user']['id'].toString());
      }

      return _token!;
    }
    final err = data['error'];
    final msg = err is String ? err : (resp.statusCode == 409 ? 'El email ya está registrado' : 'Registro fallido');
    throw Exception(msg);
  }

  Future<String> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/api/login.php');
    final resp = await http.post(url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}));

    Map<String, dynamic> data;
    try {
      data = jsonDecode(resp.body);
    } catch (_) {
      throw Exception('Respuesta no JSON del backend: ${resp.body}');
    }

    if (resp.statusCode == 200 && data['success'] == true) {
      final token = data['token'] as String;
      _token = token;
      // Persist token
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      return token;
    }
    throw Exception(data['error'] ?? 'Login failed');
  }

  Future<List<dynamic>> getTopics(int documentId) async {
    if (_token == null) throw Exception('Missing auth token');
    final url = Uri.parse('$baseUrl/api/get_topics.php?document_id=$documentId');
    final resp = await http.get(url, headers: authHeaders);
    final data = jsonDecode(resp.body);
    if (resp.statusCode == 200 && data['success'] == true) {
      return data['topics'] as List<dynamic>;
    }
    throw Exception(data['error'] ?? 'Failed to fetch topics');
  }

  // ===================================
  // MÉTODOS OBSOLETOS ELIMINADOS
  // (uploadPdf, createDirectory, updateDirectory, moveDirectory, deleteDirectory)
  // ===================================

  // Directories
  Future<Map<String, dynamic>> listDirectories() async {
    // Asegura que el token esté presente antes de llamar
    await _ensureAuth();
    if (_token == null || _token!.isEmpty) {
      throw Exception('Missing auth token');
    }

    final url = Uri.parse('$baseUrl/api/list_directories.php');
    // Debug: Log URL and headers
    try {
      print('[Api] POST: ' + url.toString());
      final h = authHeaders;
      print('[Api] Headers: ' + h.entries.map((e) => '${e.key}=${e.value}').join(', '));
    } catch (_) {}

    http.Response resp;
    try {
      resp = await http
          .post(url, headers: authHeaders, body: jsonEncode({}))
          .timeout(const Duration(seconds: 8));
    } on TimeoutException {
      throw Exception('Tiempo de espera agotado al listar directorios');
    }

    // Debug: Log status and short body
    try {
      print('[Api] Status: ' + resp.statusCode.toString());
      final body = resp.body;
      final preview = body.length > 300 ? body.substring(0, 300) : body;
      print('[Api] Body: ' + preview);
    } catch (_) {}

    final data = jsonDecode(resp.body);
    if (resp.statusCode == 200 && data['success'] == true)
      return data; // incluye mode
    throw Exception(data['error'] ?? 'No se pudo listar directorios');
  }

  // Documents
  Future<Map<String, dynamic>> listDocuments({int? directoryId, String? path}) async {
    // Check if user is VIP by checking directories mode
    try {
      final dirsResp = await listDirectories().timeout(const Duration(seconds: 8));
      final isVip = dirsResp['mode'] == 'vip';
      
      if (!isVip) {
        // For non-VIP users, list local files
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('user_id') ?? 'default_user';

        final files = await LocalStorageService.listFiles(userId, path);
        final documents = <Map<String, dynamic>>[];

        for (final file in files) {
          if (file is File) {
            final fileName = file.path.split('/').last;
            final isPdf = fileName.toLowerCase().endsWith('.pdf');
            final isSummary = fileName.toLowerCase().startsWith('resumen_') &&
                fileName.toLowerCase().endsWith('.txt');

            if (isPdf || isSummary) {
              documents.add({
                'path': fileName,
                'name': fileName,
                'size': await file.length(),
                'type': isSummary ? 'summary' : 'pdf',
                'display_name': fileName,
              });
            }
          }
        }

        return {
          'success': true,
          'mode': 'fs',
          'fs_documents': documents,
        };
      }
    } catch (e) {
      // If we can't determine VIP status, assume non-VIP and list local files
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? 'default_user';

      final files = await LocalStorageService.listFiles(userId, path);
      final documents = <Map<String, dynamic>>[];

      for (final file in files) {
        if (file is File) {
          final fileName = file.path.split('/').last;
          final isPdf = fileName.toLowerCase().endsWith('.pdf');
          final isSummary = fileName.toLowerCase().startsWith('resumen_') &&
              fileName.toLowerCase().endsWith('.txt');

          if (isPdf || isSummary) {
            documents.add({
              'path': fileName,
              'name': fileName,
              'size': await file.length(),
              'type': isSummary ? 'summary' : 'pdf',
              'display_name': fileName,
            });
          }
        }
      }

      return {
        'success': true,
        'mode': 'fs',
        'fs_documents': documents,
      };
    }

    // VIP users: use backend (commented out for now)
    /*
    final qp = directoryId != null
        ? '?directory_id=$directoryId'
        : (path != null && path.isNotEmpty ? '?path=${Uri.encodeQueryComponent(path)}' : '');
    final url = Uri.parse('$baseUrl/api/list_documents.php$qp');
    final resp = await http.get(url, headers: authHeaders);
    final data = jsonDecode(resp.body);
    if (resp.statusCode == 200 && data['success'] == true) return data; // incluye mode
    throw Exception(data['error'] ?? 'No se pudo listar documentos');
    */

    // Si es VIP, por ahora devolvemos lista vacía hasta implementar
    return {
      'success': true,
      'mode': 'vip',
      'documents': <dynamic>[],
      'summaries': <dynamic>[],
    };
  }

  Future<Map<String, dynamic>> deleteDirectory({int? id, String? path}) async {
    final url = Uri.parse('$baseUrl/api/delete_directory.php');
    final body = <String, dynamic>{
      if (id != null) 'id': id,
      if (path != null) 'path': path,
    };
    final resp =
        await http.post(url, headers: authHeaders, body: jsonEncode(body));
    final data = jsonDecode(resp.body);
    if (resp.statusCode == 200 && data['success'] == true) return data;
    throw Exception(data['error'] ?? 'No se pudo eliminar directorio');
  }

  // --- NUEVO: crear directorio ---
  Future<Map<String, dynamic>> createDirectory(
    String name, {
    int? parentId,
    String? parentPath,
    String? colorHex,
  }) async {
    await _ensureAuth();
    if (_token == null || _token!.isEmpty) {
      throw Exception('Missing auth token');
    }

    final url = Uri.parse('$baseUrl/api/create_directory.php');
    final body = <String, dynamic>{
      'name': name,
      if (parentId != null) 'parent_id': parentId,
      if (parentPath != null) 'parent_path': parentPath,
      if (colorHex != null) 'color_hex': colorHex,
    };
    final resp = await http.post(url, headers: authHeaders, body: jsonEncode(body));
    final data = jsonDecode(resp.body);
    if (resp.statusCode == 200 && data['success'] == true) return data;
    throw Exception(data['error'] ?? 'No se pudo crear directorio');
  }

  // --- REPUESTO: método requerido por DirectoriesScreen ---
  Future<Map<String, dynamic>> moveDirectory({
    int? id,
    int? newParentId,
    String? path,
    String? newParentPath,
  }) async {
    // Asegura token antes de llamar endpoint protegido
    await _ensureAuth();
    if (_token == null || _token!.isEmpty) {
      throw Exception('Missing auth token');
    }

    final url = Uri.parse('$baseUrl/api/move_directory.php');
    final body = <String, dynamic>{
      if (id != null) 'id': id,
      if (newParentId != null) 'new_parent_id': newParentId,
      if (path != null) 'path': path,
      if (newParentPath != null) 'new_parent_path': newParentPath,
    };
    final resp =
        await http.post(url, headers: authHeaders, body: jsonEncode(body));
    final data = jsonDecode(resp.body);
    if (resp.statusCode == 200 && data['success'] == true) return data;
    throw Exception(data['error'] ?? 'No se pudo mover directorio');
  }

  // --- NUEVO: método requerido por DirectoriesScreen ---
  Future<Map<String, dynamic>> updateDirectory({
    int? id,
    String? path,
    String? name,
    String? colorHex,
  }) async {
    await _ensureAuth();
    if (_token == null || _token!.isEmpty) {
      throw Exception('Missing auth token');
    }

    final url = Uri.parse('$baseUrl/api/update_directory.php');
    final body = <String, dynamic>{
      if (id != null) 'id': id,
      if (path != null) 'path': path,
      if (name != null) 'new_name': name,
      if (colorHex != null) 'color_hex': colorHex,
    };
    final resp =
        await http.post(url, headers: authHeaders, body: jsonEncode(body));
    final data = jsonDecode(resp.body);
    if (resp.statusCode == 200 && data['success'] == true) return data;
    throw Exception(data['error'] ?? 'No se pudo actualizar directorio');
  }

  Future<Map<String, dynamic>> uploadPdf(Uint8List fileBytes, String filename,
      {int? directoryId, String? relativePath}) async {
    if (_token == null) throw Exception('Missing auth token');

    // Check if user is VIP by checking directories mode
    try {
      final dirsResp = await listDirectories();
      final isVip = dirsResp['mode'] == 'vip';
      
      if (!isVip) {
        // For non-VIP users, save locally
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('user_id') ?? 'default_user';

        final localPath =
            await LocalStorageService.savePdfFile(userId, filename, fileBytes);

        return {
          'success': true,
          'mode': 'fs',
          'fs_path': filename, // Return just filename for local storage
          'local_path': localPath,
          'message': 'Archivo guardado localmente'
        };
      }
    } catch (e) {
      // If we can't determine VIP status, assume non-VIP and save locally
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? 'default_user';

      final localPath =
          await LocalStorageService.savePdfFile(userId, filename, fileBytes);

      return {
        'success': true,
        'mode': 'fs',
        'fs_path': filename,
        'local_path': localPath,
        'message': 'Archivo guardado localmente'
      };
    }

    // VIP users: use backend storage (commented out for now)
    /*
    final url = Uri.parse('$baseUrl/api/upload_pdf.php');
    final req = http.MultipartRequest('POST', url);
    req.headers['Authorization'] = 'Bearer $_token';
    if (directoryId != null) req.fields['directory_id'] = directoryId.toString();
    if (relativePath != null) req.fields['relative_path'] = relativePath;

    final file = http.MultipartFile.fromBytes('pdf', fileBytes, filename: filename);
    req.files.add(file);

    final streamed = await req.send();
    final respStr = await streamed.stream.bytesToString();
    final data = jsonDecode(respStr);

    if (streamed.statusCode == 200 && data['success'] == true) {
      return data; // mode: vip/fs, document_id (vip), fs_path
    }
    throw Exception(data['error'] ?? 'Upload failed');
    */

    // For now, VIP users also save locally
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? 'default_user';

    final localPath =
        await LocalStorageService.savePdfFile(userId, filename, fileBytes);

    return {
      'success': true,
      'mode': 'vip',
      'fs_path': filename,
      'local_path': localPath,
      'message': 'Archivo guardado localmente (modo VIP temporal)'
    };
  }

  Future<Map<String, dynamic>> moveDocument(
      {int? documentId,
      int? targetDirectoryId,
      String? path,
      String? newParentPath}) async {
    final url = Uri.parse('$baseUrl/api/move_document.php');
    final body = <String, dynamic>{
      if (documentId != null) 'document_id': documentId,
      if (targetDirectoryId != null) 'target_directory_id': targetDirectoryId,
      if (path != null) 'path': path,
      if (newParentPath != null) 'new_parent_path': newParentPath,
    };
    final resp =
        await http.post(url, headers: authHeaders, body: jsonEncode(body));
    final data = jsonDecode(resp.body);
    if (resp.statusCode == 200 && data['success'] == true) return data;
    throw Exception(data['error'] ?? 'No se pudo mover documento');
  }

  Future<Map<String, dynamic>> updateDocumentName(
      {int? documentId, required String newName, String? path}) async {
    final url = Uri.parse('$baseUrl/api/update_document.php');
    final body = <String, dynamic>{
      if (documentId != null) 'document_id': documentId,
      if (path != null) 'path': path,
      'new_name': newName,
    };
    final resp =
        await http.post(url, headers: authHeaders, body: jsonEncode(body));
    final data = jsonDecode(resp.body);
    if (resp.statusCode == 200 && data['success'] == true) return data;
    throw Exception(data['error'] ?? 'No se pudo renombrar documento');
  }

  Future<Map<String, dynamic>> deleteDocument(
      {int? documentId, String? path}) async {
    final url = Uri.parse('$baseUrl/api/delete_document.php');
    final body = <String, dynamic>{
      if (documentId != null) 'document_id': documentId,
      if (path != null) 'path': path,
    };
    final resp =
        await http.post(url, headers: authHeaders, body: jsonEncode(body));
    final data = jsonDecode(resp.body);
    if (resp.statusCode == 200 && data['success'] == true) return data;
    throw Exception(data['error'] ?? 'No se pudo eliminar documento');
  }

  Future<Map<String, dynamic>> deleteSummary({required String summaryPath}) async {
    final url = Uri.parse('$baseUrl/api/delete_document.php');
    final body = <String, dynamic>{
      'summary_path': summaryPath,
    };
    final resp =
        await http.post(url, headers: authHeaders, body: jsonEncode(body));
    final data = jsonDecode(resp.body);
    if (resp.statusCode == 200 && data['success'] == true) return data;
    throw Exception(data['error'] ?? 'No se pudo eliminar resumen');
  }

  // --- NUEVO MÉTODO AÑADIDO ---
  /// Obtiene los detalles (incluyendo el texto) de un resumen.
  Future<Map<String, dynamic>> fetchSummaryDetails(
      {int? vipSummaryId, String? fsPath}) async {
    if (_token == null) throw Exception('Missing auth token');

    // FS local: leer archivo directamente
    if (fsPath != null) {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? 'default_user';

      final content =
          await LocalStorageService.readFileContent(userId, fsPath, null);
      if (content != null) {
        return {
          'success': true,
          'summary_text': content,
          'file_name': fsPath,
          'mode': 'fs',
        };
      } else {
        throw Exception('No se pudo leer el archivo de resumen');
      }
    }

    // VIP: backend real
    if (vipSummaryId != null) {
      final qp = '?summary_id=$vipSummaryId';
      final url = Uri.parse('$baseUrl/api/get_summary_details.php$qp');
      final resp = await http.get(url, headers: authHeaders);
      final data = jsonDecode(resp.body);
      if (resp.statusCode == 200 && data['success'] == true) {
        return data;
      }
      throw Exception(data['error'] ?? 'No se pudo obtener el resumen');
    }

    throw Exception('Debe proveer un ID o un path para buscar el resumen.');
  }
  // --- FIN DEL NUEVO MÉTODO ---

  Future<Map<String, dynamic>> loginWithUser(
      String email, String password) async {
    // NUEVO
    final url = Uri.parse('$baseUrl/api/login.php');
    final resp = await http.post(url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}));

    Map<String, dynamic> data;
    try {
      data = jsonDecode(resp.body);
    } catch (_) {
      throw Exception('Respuesta no JSON del backend: ${resp.body}');
    }

    if (resp.statusCode == 200 && data['success'] == true) {
      _token = data['token'] as String;

      // Save user_id and token for local storage & sesión
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      if (data['user'] != null && data['user']['id'] != null) {
        await prefs.setString('user_id', data['user']['id'].toString());
      }

      return data; // incluye 'user'
    }
    throw Exception(data['error'] ?? 'Login failed');
  }

  // Profile management methods
  Future<Map<String, dynamic>> changePassword(String currentPassword,
      String newPassword, String confirmPassword) async {
    if (_token == null) throw Exception('Missing auth token');

    final url = Uri.parse('$baseUrl/api/update_profile.php');
    final resp = await http.post(url,
        headers: authHeaders,
        body: jsonEncode({
          'action': 'change_password',
          'current_password': currentPassword,
          'new_password': newPassword,
          'confirm_password': confirmPassword,
        }));

    final data = jsonDecode(resp.body);
    if (resp.statusCode == 200 && data['success'] == true) {
      return data;
    }
    throw Exception(data['error'] ?? 'Failed to change password');
  }

  Future<Map<String, dynamic>> updateProfile(String name) async {
    if (_token == null) throw Exception('Missing auth token');

    final url = Uri.parse('$baseUrl/api/update_profile.php');
    final resp = await http.post(url,
        headers: authHeaders,
        body: jsonEncode({
          'action': 'update_profile',
          'name': name,
        }));

    final data = jsonDecode(resp.body);
    if (resp.statusCode == 200 && data['success'] == true) {
      return data;
    }
    throw Exception(data['error'] ?? 'Failed to update profile');
  }


  Future<List<Map<String, dynamic>>> generateQuizFromSummary(String summaryText, {int numQuestions = 6}) async {
    await _ensureAuth();
    if (_token == null || _token!.isEmpty) {
      throw Exception('Missing auth token');
    }

    final url = Uri.parse('$baseUrl/api/generate_quiz.php');
    http.Response resp;
    try {
      resp = await http.post(
        url,
        headers: authHeaders,
        body: jsonEncode({
          'summary_text': summaryText,
          'num_questions': numQuestions,
          'model': 'gemini-2.5-flash',
        }),
      ).timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw Exception('Tiempo de espera agotado al generar quiz');
    }

    Map<String, dynamic> data;
    try {
      data = jsonDecode(resp.body);
    } catch (_) {
      throw Exception('Respuesta no JSON al generar quiz');
    }

    if (resp.statusCode == 200 && data['success'] == true && data['questions'] is List) {
      final raw = (data['questions'] as List);
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }

    throw Exception(data['error'] ?? 'No se pudo generar el cuestionario');
  }
}
