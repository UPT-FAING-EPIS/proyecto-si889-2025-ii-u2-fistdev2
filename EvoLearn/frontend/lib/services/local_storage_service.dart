import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class LocalStorageService {
  static Directory? _appDir;
  
  /// Gets the application documents directory
  static Future<Directory> get appDir async {
    if (_appDir != null) return _appDir!;
    
    final directory = await getApplicationDocumentsDirectory();
    _appDir = Directory(path.join(directory.path, 'EstudiaFacil'));
    
    // Create directory if it doesn't exist
    if (!await _appDir!.exists()) {
      await _appDir!.create(recursive: true);
    }
    
    return _appDir!;
  }
  
  /// Gets the user's storage directory
  static Future<Directory> getUserDir(String userId) async {
    final appDir = await LocalStorageService.appDir;
    final userDir = Directory(path.join(appDir.path, 'user_$userId'));
    
    if (!await userDir.exists()) {
      await userDir.create(recursive: true);
    }
    
    return userDir;
  }
  
  /// Gets the documents directory for a user
  static Future<Directory> getDocumentsDir(String userId) async {
    final userDir = await getUserDir(userId);
    final docsDir = Directory(path.join(userDir.path, 'documents'));
    
    if (!await docsDir.exists()) {
      await docsDir.create(recursive: true);
    }
    
    return docsDir;
  }
  
  /// Gets the directories directory for a user
  static Future<Directory> getDirectoriesDir(String userId) async {
    final userDir = await getUserDir(userId);
    final dirsDir = Directory(path.join(userDir.path, 'directories'));
    
    if (!await dirsDir.exists()) {
      await dirsDir.create(recursive: true);
    }
    
    return dirsDir;
  }
  
  /// Saves a PDF file locally
  static Future<String> savePdfFile(String userId, String fileName, Uint8List fileData) async {
    final docsDir = await getDocumentsDir(userId);
    final file = File(path.join(docsDir.path, fileName));
    
    await file.writeAsBytes(fileData);
    return file.path;
  }
  
  /// Saves a summary file locally
  static Future<String> saveSummaryFile(String userId, String fileName, String content) async {
    final docsDir = await getDocumentsDir(userId);
    final file = File(path.join(docsDir.path, fileName));
    
    await file.writeAsString(content);
    return file.path;
  }
  
  /// Creates a directory locally
  static Future<String> createDirectory(String userId, String dirName, String? parentPath) async {
    final dirsDir = await getDirectoriesDir(userId);
    final fullPath = parentPath != null && parentPath.isNotEmpty 
        ? path.join(dirsDir.path, parentPath, dirName)
        : path.join(dirsDir.path, dirName);
    
    final directory = Directory(fullPath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    
    return fullPath;
  }
  
  /// Lists files in a directory
  static Future<List<FileSystemEntity>> listFiles(String userId, String? relativePath) async {
    final docsDir = await getDocumentsDir(userId);
    final targetDir = relativePath != null && relativePath.isNotEmpty
        ? Directory(path.join(docsDir.path, relativePath))
        : docsDir;
    
    if (!await targetDir.exists()) {
      return [];
    }
    
    return targetDir.listSync();
  }
  
  /// Lists directories
  static Future<List<Directory>> listDirectories(String userId, String? relativePath) async {
    final dirsDir = await getDirectoriesDir(userId);
    final targetDir = relativePath != null && relativePath.isNotEmpty
        ? Directory(path.join(dirsDir.path, relativePath))
        : dirsDir;
    
    if (!await targetDir.exists()) {
      return [];
    }
    
    return targetDir.listSync()
        .whereType<Directory>()
        .toList();
  }
  
  /// Deletes a file
  static Future<bool> deleteFile(String userId, String fileName, String? relativePath) async {
    try {
      final docsDir = await getDocumentsDir(userId);
      final filePath = relativePath != null && relativePath.isNotEmpty
          ? path.join(docsDir.path, relativePath, fileName)
          : path.join(docsDir.path, fileName);
      
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  /// Deletes a directory
  static Future<bool> deleteDirectory(String userId, String dirName, String? relativePath) async {
    try {
      final dirsDir = await getDirectoriesDir(userId);
      final dirPath = relativePath != null && relativePath.isNotEmpty
          ? path.join(dirsDir.path, relativePath, dirName)
          : path.join(dirsDir.path, dirName);
      
      final directory = Directory(dirPath);
      if (await directory.exists()) {
        await directory.delete(recursive: true);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  /// Reads a file content
  static Future<String?> readFileContent(String userId, String fileName, String? relativePath) async {
    try {
      final docsDir = await getDocumentsDir(userId);
      final filePath = relativePath != null && relativePath.isNotEmpty
          ? path.join(docsDir.path, relativePath, fileName)
          : path.join(docsDir.path, fileName);
      
      final file = File(filePath);
      if (await file.exists()) {
        return await file.readAsString();
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
