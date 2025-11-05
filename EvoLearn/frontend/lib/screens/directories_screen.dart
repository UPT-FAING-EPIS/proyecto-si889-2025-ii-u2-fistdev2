import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'dart:math';

// Service Imports
import '../services/api_service.dart';
import '../services/analysis_service.dart';
import '../providers/theme_provider.dart';

// Screen Imports
import 'profile_screen.dart';
import 'login_screen.dart';
import 'summary_screen.dart';
import 'quiz_screen.dart';
// REMOVED: import 'flashcards_screen.dart'; // No longer used directly

class DirectoriesScreen extends StatefulWidget {
  final ApiService api;
  const DirectoriesScreen({super.key, required this.api});

  @override
  State<DirectoriesScreen> createState() => _DirectoriesScreenState();
}

class _DirectoriesScreenState extends State<DirectoriesScreen> {
  // State Variables
  int? _currentDirId; // null = root in VIP mode
  List<dynamic> _dirTree = []; // VIP directory structure
  List<Map<String, dynamic>> _flatDirs = []; // Flattened VIP directories
  List<dynamic> _docs = []; // Raw documents list from API
  bool _loading = true;
  String? _error;
  String _mode = 'vip'; // Current mode ('vip' or 'fs')
  Map<String, dynamic>? _fsRoot; // FS directory structure root
  String? _currentPath; // null or '' = root in FS mode

  late AnalysisService _analysisService; // Instance of the analysis service

  @override
  void initState() {
    super.initState();
    _analysisService = AnalysisService(widget.api); // Initialize AnalysisService
    // Restore last location before fetching data
    _restoreLocation().then((_) => _refresh());
  }

  /// Restores the last viewed directory location from SharedPreferences.
  Future<void> _restoreLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString('mode');
    final savedDirId = prefs.getInt('current_dir_id');
    final savedPath = prefs.getString('current_path');
    if (mounted) {
      // Check if the widget is still mounted
      setState(() {
        if (savedMode != null) _mode = savedMode;
        // Use -1 as the saved value for root (null)
        _currentDirId = (savedDirId != null && savedDirId >= 0) ? savedDirId : null;
        _currentPath = savedPath ?? _currentPath; // Keep current if nothing saved
      });
    }
  }

  /// Saves the current directory location to SharedPreferences.
  Future<void> _saveLocation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_screen', 'directories'); // Mark last screen
    await prefs.setString('mode', _mode);
    await prefs.setInt('current_dir_id', _currentDirId ?? -1); // Save -1 for root (null)
    await prefs.setString('current_path', _currentPath ?? '');
  }

  /// Refreshes the directory and document lists from the API.
  Future<void> _refresh() async {
    if (!mounted) return; // Don't refresh if widget is disposed
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dirsResp = await widget.api.listDirectories();
      if (!mounted) return;
      final currentMode = dirsResp['mode']?.toString() ?? 'vip';

      // Reset location if mode changed unexpectedly (e.g., user downgraded)
      if (_mode != currentMode) {
        _currentDirId = null;
        _currentPath = '';
        _mode = currentMode;
      }

      Map<String, dynamic> docsResp;
      if (_mode == 'vip') {
        _dirTree = (dirsResp['directories'] as List<dynamic>? ?? []);
        _flatDirs = _flatten(_dirTree);
        docsResp = await widget.api.listDocuments(directoryId: _currentDirId);
        // Unificar documentos PDF y resúmenes (si el backend devuelve 'summaries')
        final documents = (docsResp['documents'] as List<dynamic>? ?? []);
        final summaries = (docsResp['summaries'] as List<dynamic>? ?? []);
        _docs = [
          ...documents,
          ...summaries.map((s) => {
                'id': s['id'] ?? s['summary_id'],
                'display_name': s['display_name'] ?? s['name'] ?? 'Resumen',
                'created_at': s['created_at'] ?? '',
                'type': 'summary',
                'original_doc_id': s['original_doc_id'],
                'path': s['path'], // si el backend lo proporciona
              }),
        ];
      } else {
        // FS Mode
        _fsRoot = dirsResp['fs_tree'] as Map<String, dynamic>?;
        _currentPath ??= ''; // raíz
        final effectivePath = (_currentPath?.isEmpty ?? true) ? null : _currentPath;
        docsResp = await widget.api.listDocuments(path: effectivePath);
        _docs = (docsResp['fs_documents'] as List<dynamic>? ?? []);
      }
    } catch (e) {
      if (mounted) {
        // If missing/invalid token, clear it and redirect to Login
        final msg = e.toString();
        if (msg.contains('Missing auth token') || msg.contains('Missing Bearer token') || msg.contains('Invalid token') || msg.contains('Token expired')) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('token');
          widget.api.clearToken();

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => LoginScreen(api: widget.api)),
            (route) => false,
          );
          return;
        }
        setState(() {
          _error = "Error: ${e.toString()}";
        }); // Provide clearer error
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
        _saveLocation(); // Save location after successful or failed refresh
      }
    }
  }

  /// Flattens the hierarchical directory tree (VIP mode).
  List<Map<String, dynamic>> _flatten(List<dynamic> dirs) {
    final out = <Map<String, dynamic>>[];
    for (final d in dirs) {
      if (d is Map<String, dynamic>) {
        // Type check
        out.add({
          'id': d['id'],
          'parent_id': d['parent_id'],
          'name': d['name'],
          'color_hex': d['color_hex']
        });
        if (d['children'] is List) {
          out.addAll(_flatten(d['children'] as List<dynamic>));
        }
      }
    }
    return out;
  }

  /// Finds a directory by ID in the flattened list (VIP mode).
  Map<String, dynamic>? _dirById(int? id) {
    if (id == null) return null;
    // Use try-firstWhere for safety
    try {
      return _flatDirs.firstWhere((d) => d['id'] == id);
    } catch (e) {
      return null; // Return null if not found
    }
  }

  /// Finds a node in the FS tree by its path (FS mode).
  Map<String, dynamic>? _fsFindNodeByPath(Map<String, dynamic>? node, String path) {
    if (node == null) return null;
    if ((node['path'] as String? ?? '') == path) return node;
    final children = node['directories'] as List<dynamic>? ?? [];
    for (final child in children) {
      if (child is Map<String, dynamic>) {
        final found = _fsFindNodeByPath(child, path);
        if (found != null) return found;
      }
    }
    return null;
  }

  /// Collects direct children of a parent ID from the VIP tree.
  void _collectChildren(dynamic node, int? parentId, List<dynamic> out) {
    if (node is Map<String, dynamic>) {
      // Check if the node itself is a direct child
      if (node['parent_id'] == parentId) {
        out.add(node);
      }
      // Recursively check children only if the current node is NOT the target parent
      // OR if we are at the root (parentId is null)
      if (node['id'] != parentId || parentId == null) {
        if (node['children'] is List) {
          for (final c in (node['children'] as List<dynamic>)) {
            _collectChildren(c, parentId, out);
          }
        }
      }
    } else if (node is List) {
      // Handle case where the root might be a list
      for (final item in node) {
        _collectChildren(item, parentId, out);
      }
    }
  }

  /// Gets all descendant IDs for a given directory ID (VIP mode).
  Set<int> _descendantIds(int id) {
    final ids = <int>{};
    // Find the starting node within the original tree structure
    dynamic findNodeInTree(List<dynamic> nodes, int targetId) {
      for (final node in nodes) {
        if (node is Map<String, dynamic>) {
          if (node['id'] == targetId) return node;
          if (node['children'] is List) {
            final found = findNodeInTree(node['children'] as List<dynamic>, targetId);
            if (found != null) return found;
          }
        }
      }
      return null;
    }

    final startNodeInTree = findNodeInTree(_dirTree, id);

    if (startNodeInTree != null && startNodeInTree['children'] is List) {
      for (final c in (startNodeInTree['children'] as List<dynamic>)) {
        _collectAllIds(c, ids); // Start collecting from children
      }
    }
    return ids;
  }

  /// Recursively collects all IDs from a node and its children (VIP mode).
  void _collectAllIds(dynamic node, Set<int> ids) {
    if (node is Map<String, dynamic> && node['id'] is int) {
      ids.add(node['id'] as int);
      if (node['children'] is List) {
        for (final c in (node['children'] as List<dynamic>)) {
          _collectAllIds(c, ids);
        }
      }
    }
  }

  /// Builds the breadcrumb path for VIP mode.
  List<Map<String, dynamic>> _breadcrumbVip() {
    final path = <Map<String, dynamic>>[];
    int? cur = _currentDirId;
    while (cur != null) {
      final d = _dirById(cur);
      // Use ?.isEmpty check for safety
      if (d == null || d.isEmpty) break;
      path.insert(0, d);
      cur = d['parent_id'] as int?;
    }
    return path;
  }

  /// Builds the breadcrumb path for FS mode.
  List<Map<String, dynamic>> _breadcrumbFs() {
    final crumbs = <Map<String, dynamic>>[];
    final curPath = _currentPath ?? '';
    if (curPath.isEmpty) return crumbs;

    final parts = curPath.split('/').where((p) => p.isNotEmpty).toList();
    String accumulatedPath = '';
    for (final part in parts) {
      accumulatedPath = accumulatedPath.isEmpty ? part : '$accumulatedPath/$part';
      final node = _fsFindNodeByPath(_fsRoot, accumulatedPath);
      crumbs.add({
        'name': node?['name'] ?? part,
        'path': accumulatedPath,
        'color_hex': (node?['color'] as String?) ?? '#1565C0',
      });
    }
    return crumbs;
  }

  /// Returns a normalized list of child directories for the current view.
  List<Map<String, dynamic>> _childrenNormalized() {
    if (_mode == 'vip') {
      final children = <dynamic>[];
      // Directly collect children based on parent_id from the flat list
      for (final dir in _flatDirs) {
        if (dir['parent_id'] == _currentDirId) {
          children.add(dir);
        }
      }
      // Sort children alphabetically by name
      children.sort((a, b) => (a['name'] as String? ?? '').compareTo(b['name'] as String? ?? ''));

      return children
          .map((d) => {
                'kind': 'vip',
                'id': d['id'],
                'name': d['name'] ?? 'Unnamed',
                'color_hex': d['color_hex'] ?? '#1565C0',
              })
          .toList();
    } else {
      // FS Mode
      final node = _fsFindNodeByPath(_fsRoot, _currentPath ?? '');
      final fsChildren = (node?['directories'] as List<dynamic>? ?? []);
      // Sort children alphabetically by name
      fsChildren.sort((a, b) => (a['name'] as String? ?? '').compareTo(b['name'] as String? ?? ''));

      return fsChildren
          .whereType<Map<String, dynamic>>()
          .map((d) => {
                'kind': 'fs',
                'path': d['path'] ?? '',
                'name': d['name'] ?? 'Unnamed',
                'color_hex': (d['color'] as String?) ?? '#1565C0',
              })
          .toList();
    }
  }

  /// Returns a normalized list of documents for the current view.
  List<Map<String, dynamic>> _docsNormalized() {
    // Assuming _docs is already populated correctly by _refresh for the current mode
    return _docs.whereType<Map<String, dynamic>>().map((d) {
      if (_mode == 'vip') {
        return {
          'kind': 'vip',
          'id': d['id'], // Assume 'id' exists for VIP docs
          'display_name': d['display_name'] ?? 'Documento',
          'created_at': d['created_at'] ?? '',
          'type': d['type'] ?? 'pdf', // Include type
          'original_doc_id': d['original_doc_id'], // Include for summaries
          'path': d['path'], // algunos backends pueden adjuntar path para resumen
        };
      } else {
        // FS mode
        final name = d['name'] as String? ?? '';
        final inferredType = name.toLowerCase().endsWith('.txt') ? 'summary' : 'pdf';
        return {
          'kind': 'fs',
          'path': d['path'] ?? '',
          'display_name': d['name'] ?? 'Archivo',
          'size': d['size'] ?? 0, // Assume 'size' exists
          'type': d['type'] ?? inferredType, // Include type
        };
      }
    }).toList();
  } // <--- ESTA ES LA LLAVE '}' QUE FALTABA
  // --- UI Building Methods ---

  /// Builds the breadcrumb bar widget.
  Widget _breadcrumbBar() {
    final crumbs = _mode == 'vip' ? _breadcrumbVip() : _breadcrumbFs();
    final total = crumbs.length;

    List<Widget> buildCrumbWidgets(List<Map<String, dynamic>> items) {
      final widgets = <Widget>[];
      for (int i = 0; i < items.length; i++) {
        widgets.add(const Text('/'));
        widgets.add(
          InkWell(
            onTap: () {
              setState(() {
                if (_mode == 'vip') {
                  _currentDirId = items[i]['id'] as int?;
                } else {
                  _currentPath = items[i]['path'] as String?;
                }
              });
              _saveLocation();
              _refresh();
            },
            child: Chip(label: Text(items[i]['name'] as String? ?? '...')),
          ),
        );
      }
      return widgets;
    }

    Future<void> openCrumbsPicker() async {
      await showModalBottomSheet(
        context: context,
        builder: (ctx) {
          return SafeArea(
            child: ListView.builder(
              itemCount: crumbs.length,
              itemBuilder: (ctx, i) {
                final name = crumbs[i]['name'] as String? ?? '...';
                return ListTile(
                  leading: const Icon(Icons.folder_open),
                  title: Text(name),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      if (_mode == 'vip') {
                        _currentDirId = crumbs[i]['id'] as int?;
                      } else {
                        _currentPath = crumbs[i]['path'] as String?;
                      }
                    });
                    _saveLocation();
                    _refresh();
                  },
                );
              },
            ),
          );
        },
      );
    }

    // Build condensed list: show Root, then if many, an ellipsis chip, then last two
    final rowChildren = <Widget>[
      InkWell(
        onTap: () {
          setState(() {
            _currentDirId = null;
            _currentPath = '';
          });
          _saveLocation();
          _refresh();
        },
        child: const Chip(label: Text('Raíz')),
      ),
    ];

    if (total <= 3) {
      rowChildren.addAll(buildCrumbWidgets(crumbs));
    } else {
      // Show interactive ellipsis that opens a picker for middle levels
      final visible = [crumbs[total - 2], crumbs[total - 1]];
      rowChildren.add(const Text('/'));
      rowChildren.add(
        InkWell(
          onTap: openCrumbsPicker,
          child: const Chip(label: Text('…')),
        ),
      );
      rowChildren.addAll(buildCrumbWidgets(visible));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: rowChildren,
      ),
    );
  }

  // --- Dialogs and Actions ---

  /// Shows a dialog to pick a color from a predefined grid.
  Future<String?> _pickColorHex(BuildContext context, {String initialHex = '#1565C0'}) async {
    final colors = [
      '#1565C0', '#2E7D32', '#C62828', '#6A1B9A', '#FF8F00',
      '#0097A7', '#8E24AA', '#5D4037', '#00796B', '#F4511E',
      '#3949AB', '#D81B60', '#00ACC1', '#1B5E20', '#BF360C',
    ];
    String selected = initialHex;
    final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Elegir color'),
            content: StatefulBuilder(
              // Use StatefulBuilder for dialog UI updates
              builder: (BuildContext context, StateSetter setStateDialog) {
                return SizedBox(
                  width: 320, // Adjust width as needed
                  height: 150, // Adjust height as needed
                  child: GridView.builder(
                    // Use GridView.builder
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: colors.length,
                    itemBuilder: (context, index) {
                      final hex = colors[index];
                      final bool isSelected = hex == selected;
                      return GestureDetector(
                        onTap: () {
                          setStateDialog(() {
                            // Update the dialog state
                            selected = hex;
                          });
                          // Optionally close dialog immediately on selection:
                          // Navigator.pop(ctx, true);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: _hexToColor(hex), // Use helper
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).primaryColorDark
                                  : Colors.grey.shade300,
                              width: isSelected ? 3 : 1,
                            ),
                          ),
                          child: isSelected // Add checkmark
                              ? Icon(Icons.check, color: Theme.of(context).canvasColor, size: 20)
                              : null,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
              // Added a separate Save button
              ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Guardar')),
            ],
          );
        }) ??
        false;
    return ok ? selected : null;
  }

  /// Shows the dialog to create a new directory.
  Future<void> _createDir() async {
    final nameCtrl = TextEditingController();
    String selectedColor = '#1565C0'; // Default color
    final List<String> colorOptions = [
      '#1565C0', '#2E7D32', '#C62828', '#6A1B9A', '#FF8F00',
      '#0097A7', '#8E24AA', '#5D4037', '#00796B', '#F4511E',
      '#3949AB', '#D81B60', '#00ACC1', '#1B5E20', '#BF360C',
    ];

    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          // Use StatefulBuilder for color picker UI update
          builder: (BuildContext context, StateSetter setStateDialog) {
            return AlertDialog(
              title: const Text('Nueva carpeta'),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  autofocus: true,
                ),
                const SizedBox(height: 15),
                const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Color:', style: TextStyle(fontSize: 16))),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.maxFinite,
                  height: 150,
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: colorOptions.length,
                    itemBuilder: (context, index) {
                      final hex = colorOptions[index];
                      final bool isSelected = hex == selectedColor;
                      return GestureDetector(
                        onTap: () {
                          setStateDialog(() {
                            selectedColor = hex;
                          }); // Update dialog state
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: _hexToColor(hex),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).primaryColorDark
                                  : Colors.grey.shade300,
                              width: isSelected ? 3 : 1,
                            ),
                          ),
                          child: isSelected
                              ? Icon(Icons.check, color: Theme.of(context).canvasColor, size: 20)
                              : null,
                        ),
                      );
                    },
                  ),
                ),
              ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true), child: const Text('Crear')),
              ],
            );
          },
        );
      },
    );

    if (ok == true && nameCtrl.text.trim().isNotEmpty) {
      _showLoadingDialog("Creando carpeta...");
      try {
        if (_mode == 'vip') {
          await widget.api.createDirectory(nameCtrl.text.trim(),
              parentId: _currentDirId, colorHex: selectedColor);
        } else {
          await widget.api.createDirectory(nameCtrl.text.trim(),
              parentPath: _currentPath ?? '', colorHex: selectedColor);
        }
        if (mounted) Navigator.pop(context);
        await _refresh();
      } catch (e) {
        if (mounted) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al crear: $e'), backgroundColor: Colors.red));
      }
    }
  }

  /// Shows a dialog to pick a target directory (VIP mode).
  Future<int?> _chooseTargetDir({Set<int> exclude = const {}}) async {
    if (_mode == 'fs') return null;

    int? targetId = _currentDirId;
    final options = _flatDirs.where((d) => !exclude.contains(d['id'] as int)).toList();
    // Sort options for better display (optional)
    options.sort((a, b) => (a['name'] as String? ?? '').compareTo(b['name'] as String? ?? ''));

    return await showDialog<int?>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Mover a Carpeta'),
            content: DropdownButtonFormField<int?>(
              value: targetId,
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('► Raíz')),
                ...options.map((d) => DropdownMenuItem<int>(
                      value: d['id'] as int,
                      child: Text('    ${d['name'] as String? ?? 'Unnamed'}'), // Indentation
                    ))
              ],
              onChanged: (v) {
                setStateDialog(() {
                  targetId = v;
                });
              },
              decoration: const InputDecoration(labelText: 'Carpeta Destino'),
              isExpanded: true,
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, null), child: const Text('Cancelar')),
              ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, targetId),
                  child: const Text('Mover Aquí')),
            ],
          );
        });
      },
    );
  }

  /// Shows a dialog to pick a target directory path (FS mode).
  Future<String?> _chooseTargetFsDirPath({Set<String> exclude = const {}}) async {
    if (_mode == 'vip') return null;

    final List<Map<String, String>> flatStructure = [];
    void walk(Map<String, dynamic>? node, int level) {
      if (node == null) return;
      final path = node['path'] as String? ?? '';
      final name = node['name'] as String? ?? 'Unnamed';
      if (!exclude.contains(path)) {
        String indent = '  ' * level;
        flatStructure.add({
          'path': path,
          'displayName': path.isEmpty ? '► Raíz' : '$indent└─ $name',
        });
      }
      final children = node['directories'] as List<dynamic>? ?? [];
      children.sort((a, b) => (a['name'] as String? ?? '').compareTo(
          b['name'] as String? ?? '')); // Sort children
      for (final child in children) {
        if (child is Map<String, dynamic>) {
          walk(child, level + 1);
        }
      }
    }

    walk(_fsRoot, 0); // Start from root

    String? targetPath = _currentPath ?? '';

    return await showDialog<String?>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Mover a Carpeta'),
            content: DropdownButtonFormField<String?>(
              value: targetPath,
              items: flatStructure
                  .map((d) => DropdownMenuItem<String?>(
                        value: d['path'],
                        child: Text(d['displayName']!),
                      ))
                  .toList(),
              onChanged: (v) {
                setStateDialog(() {
                  targetPath = v;
                });
              },
              decoration: const InputDecoration(labelText: 'Carpeta Destino'),
              isExpanded: true,
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, null), child: const Text('Cancelar')),
              ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, targetPath),
                  child: const Text('Mover Aquí')),
            ],
          );
        });
      },
    );
  }

  /// Renames a directory (VIP mode).
  Future<void> _renameDir(int id, String currentName) async {
    final ctrl = TextEditingController(text: currentName);
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Renombrar carpeta'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Nuevo nombre'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Guardar')),
        ],
      ),
    );

    if (ok == true && ctrl.text.trim().isNotEmpty && ctrl.text.trim() != currentName) {
      _showLoadingDialog('Renombrando...');
      try {
        await widget.api.updateDirectory(id: id, name: ctrl.text.trim());
        if (mounted) Navigator.pop(context);
        await _refresh();
      } catch (e) {
        if (mounted) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al renombrar: $e'), backgroundColor: Colors.red));
      }
    }
  }

  /// Renames a directory (FS mode).
  Future<void> _renameDirFs(String path, String currentName) async {
    final ctrl = TextEditingController(text: currentName);
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Renombrar carpeta'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Nuevo nombre'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Guardar')),
        ],
      ),
    );

    if (ok == true && ctrl.text.trim().isNotEmpty && ctrl.text.trim() != currentName) {
      _showLoadingDialog('Renombrando...');
      try {
        await widget.api.updateDirectory(path: path, name: ctrl.text.trim());
        if (mounted) Navigator.pop(context);
        await _refresh();
      } catch (e) {
        if (mounted) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al renombrar: $e'), backgroundColor: Colors.red));
      }
    }
  }

  /// Changes the color of a directory (VIP mode).
  Future<void> _changeColor(int id) async {
    final Map<String, dynamic>? currentDir = _dirById(id);
    final String initialColor = currentDir?['color_hex'] ?? '#1565C0';

    final picked = await _pickColorHex(context, initialHex: initialColor);
    if (picked != null && picked != initialColor) {
      _showLoadingDialog('Cambiando color...');
      try {
        await widget.api.updateDirectory(id: id, colorHex: picked);
        if (mounted) Navigator.pop(context);
        await _refresh();
      } catch (e) {
        if (mounted) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al cambiar color: $e'), backgroundColor: Colors.red));
      }
    }
  }

  /// Changes the color of a directory (FS mode).
  Future<void> _changeColorFs(String path) async {
    final Map<String, dynamic>? currentDir = _fsFindNodeByPath(_fsRoot, path);
    final String initialColor = (currentDir?['color'] as String?) ?? '#1565C0';

    final picked = await _pickColorHex(context, initialHex: initialColor);
    if (picked != null && picked != initialColor) {
      _showLoadingDialog('Cambiando color...');
      try {
        await widget.api.updateDirectory(path: path, colorHex: picked);
        if (mounted) Navigator.pop(context);
        await _refresh();
      } catch (e) {
        if (mounted) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al cambiar color: $e'), backgroundColor: Colors.red));
      }
    }
  }

  /// Moves a directory (VIP mode).
  Future<void> _moveDir(int id) async {
    final exclude = _descendantIds(id)..add(id);
    final target = await _chooseTargetDir(exclude: exclude);

    final currentDir = _dirById(id);
    final currentParentId = currentDir?['parent_id'] as int?;

    // Check if target is different from current parent
    // Note: target can be null (root), currentParentId can be null (root)
    if (target != currentParentId) {
      _showLoadingDialog('Moviendo carpeta...');
      try {
        await widget.api.moveDirectory(id: id, newParentId: target);
        if (mounted) Navigator.pop(context);
        await _refresh();
      } catch (e) {
        if (mounted) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al mover: $e'), backgroundColor: Colors.red));
      }
    }
  }

  /// Moves a directory (FS mode).
  Future<void> _moveDirFs(String path) async {
    final node = _fsFindNodeByPath(_fsRoot, path);
    if (node == null) return;

    final excludePaths = <String>{path};
    // Implementation for collectDescendantPaths
    void collectDescendantPaths(Map<String, dynamic>? n) {
      if (n == null) return;
      final children = n['directories'] as List<dynamic>? ?? [];
      for (final child in children) {
        if (child is Map<String, dynamic>) {
          final childPath = child['path'] as String?;
          if (childPath != null) {
            excludePaths.add(childPath);
            collectDescendantPaths(child); // Recurse
          }
        }
      }
    }
    collectDescendantPaths(node);

    final targetPath = await _chooseTargetFsDirPath(exclude: excludePaths);

    List<String> parts = path.split('/');
    parts.removeLast();
    String currentParentPath = parts.join('/');

    if (targetPath != null && targetPath != currentParentPath) {
      _showLoadingDialog('Moviendo carpeta...');
      try {
        await widget.api.moveDirectory(path: path, newParentPath: targetPath);
        if (mounted) Navigator.pop(context);
        if (path == _currentPath) {
          final nodeName = path.split('/').last;
          setState(() {
            _currentPath = targetPath.isEmpty ? nodeName : '$targetPath/$nodeName';
          });
        }
        await _refresh();
      } catch (e) {
        if (mounted) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al mover: $e'), backgroundColor: Colors.red));
      }
    }
  }

  /// Deletes a directory (VIP mode).
  Future<void> _deleteDir(int id) async {
    final bool? ok = await _showDeleteConfirmationDialog('esta carpeta y todo su contenido');
    if (ok == true) {
      _showLoadingDialog('Eliminando...');
      try {
        await widget.api.deleteDirectory(id: id);
        if (mounted) Navigator.pop(context);
        if (_currentDirId == id) {
          final cur = _dirById(id);
          setState(() {
            _currentDirId = cur?['parent_id'];
          });
          _saveLocation();
        }
        await _refresh();
      } catch (e) {
        if (mounted) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar: $e'), backgroundColor: Colors.red));
      }
    }
  }

  /// Deletes a directory (FS mode).
  Future<void> _deleteDirFs(String path) async {
    final bool? ok = await _showDeleteConfirmationDialog('esta carpeta y todo su contenido');
    if (ok == true) {
      _showLoadingDialog('Eliminando...');
      try {
        await widget.api.deleteDirectory(path: path);
        if (mounted) Navigator.pop(context);
        if (_currentPath == path) {
          final parts = path.split('/').where((p) => p.isNotEmpty).toList();
          parts.removeLast();
          setState(() {
            _currentPath = parts.join('/');
          });
          _saveLocation();
        }
        await _refresh();
      } catch (e) {
        if (mounted) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar: $e'), backgroundColor: Colors.red));
      }
    }
  }

  // --- Document Actions ---

  /// Renames a document (VIP mode).
  Future<void> _renameDoc(int id, String currentName) async {
    final ctrl = TextEditingController(text: currentName);
    final bool? ok = await _showRenameDialog(ctrl, 'Documento');

    if (ok == true && ctrl.text.trim().isNotEmpty && ctrl.text.trim() != currentName) {
      _showLoadingDialog('Renombrando...');
      try {
        await widget.api.updateDocumentName(documentId: id, newName: ctrl.text.trim());
        if (mounted) Navigator.pop(context);
        await _refresh();
      } catch (e) {
        if (mounted) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al renombrar: $e'), backgroundColor: Colors.red));
      }
    }
  }

  /// Renames a document (FS mode).
  Future<void> _renameDocFs(String path, String currentName) async {
    final ctrl = TextEditingController(text: currentName);
    final bool? ok = await _showRenameDialog(ctrl, 'Documento');

    String newName = ctrl.text.trim();
    if (currentName.toLowerCase().endsWith('.pdf') && !newName.toLowerCase().endsWith('.pdf')) {
      newName += '.pdf';
    }
    // Also handle summary renaming if needed
    if (currentName.toLowerCase().endsWith('.txt') && !newName.toLowerCase().endsWith('.txt')) {
      newName += '.txt'; // Keep txt extension for summaries
    }

    if (ok == true && newName.isNotEmpty && newName != currentName) {
      _showLoadingDialog('Renombrando...');
      try {
        await widget.api.updateDocumentName(path: path, newName: newName);
        if (mounted) Navigator.pop(context);
        await _refresh();
      } catch (e) {
        if (mounted) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al renombrar: $e'), backgroundColor: Colors.red));
      }
    }
  }

  /// Moves a document (VIP mode).
  Future<void> _moveDoc(int id) async {
    final targetDirId = await _chooseTargetDir(); // No exclusion needed

    // Find the current parent ID
    Map<String, dynamic>? currentDocData;
    final originalDoc =
        _docs.firstWhere((d) => d is Map && d['id'] == id, orElse: () => null);
    if (originalDoc != null) {
      currentDocData = originalDoc as Map<String, dynamic>;
    }
    final currentParentId = currentDocData?['directory_id'] as int?;

    if (targetDirId != currentParentId) {
      _showLoadingDialog('Moviendo documento...');
      try {
        await widget.api.moveDocument(documentId: id, targetDirectoryId: targetDirId);
        if (mounted) Navigator.pop(context);
        await _refresh();
      } catch (e) {
        if (mounted) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al mover: $e'), backgroundColor: Colors.red));
      }
    }
  }

  /// Moves a document (FS mode).
  Future<void> _moveDocFs(String path) async {
    final targetPath = await _chooseTargetFsDirPath(); // No exclusion needed

    List<String> parts = path.split('/');
    parts.removeLast();
    String currentParentPath = parts.join('/');

    if (targetPath != null && targetPath != currentParentPath) {
      _showLoadingDialog('Moviendo documento...');
      try {
        await widget.api.moveDocument(path: path, newParentPath: targetPath);
        if (mounted) Navigator.pop(context);
        await _refresh();
      } catch (e) {
        if (mounted) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al mover: $e'), backgroundColor: Colors.red));
      }
    }
  }

  /// Deletes a document (VIP mode).
  Future<void> _deleteDoc(int id) async {
    final bool? ok = await _showDeleteConfirmationDialog(
        'este documento y sus datos asociados (resúmenes, etc.)');
    if (ok == true) {
      _showLoadingDialog('Eliminando documento...');
      try {
        await widget.api.deleteDocument(documentId: id);
        if (mounted) Navigator.pop(context);
        await _refresh();
      } catch (e) {
        if (mounted) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar: $e'), backgroundColor: Colors.red));
      }
    }
  }

  /// Deletes a summary file (VIP mode).
  Future<void> _deleteSummaryVip(String summaryPath) async {
    final bool? ok = await _showDeleteConfirmationDialog('este resumen');
    if (ok == true) {
      _showLoadingDialog('Eliminando resumen...');
      try {
        await widget.api.deleteSummary(summaryPath: summaryPath);
        if (mounted) Navigator.pop(context);
        await _refresh();
      } catch (e) {
        if (mounted) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar resumen: $e'), backgroundColor: Colors.red));
      }
    }
  }

  /// Deletes a document or summary (FS mode).
  Future<void> _deleteDocFs(String path) async {
    final bool isSummary =
        path.toLowerCase().startsWith('resumen_') && path.toLowerCase().endsWith('.txt');
    final String itemType = isSummary ? 'este resumen' : 'este documento';
    final bool? ok = await _showDeleteConfirmationDialog(itemType);

    if (ok == true) {
      _showLoadingDialog('Eliminando ${isSummary ? "resumen" : "documento"}...');
      try {
        await widget.api.deleteDocument(path: path);
        if (mounted) Navigator.pop(context);
        await _refresh();
      } catch (e) {
        if (mounted) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar: $e'), backgroundColor: Colors.red));
      }
    }
  }

  /// Picks and uploads PDF files.
  Future<void> _pickAndProcessPdfs() async {
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
          allowMultiple: true,
          withData: true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar archivos: $e'), backgroundColor: Colors.orange));
      return;
    }

    if (result == null || result.files.isEmpty) return;

    final filesToUpload = result.files.where((f) => f.bytes != null).toList();
    if (filesToUpload.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No se pudieron leer los archivos seleccionados.'),
          backgroundColor: Colors.orange));
      return;
    }

    _showLoadingDialog('Subiendo ${filesToUpload.length} PDF(s)...');
    int successCount = 0;
    List<String> errors = [];

    try {
      for (final file in filesToUpload) {
        try {
          await widget.api.uploadPdf(
            file.bytes!,
            file.name,
            directoryId: _mode == 'vip' ? _currentDirId : null,
            relativePath: _mode == 'fs' ? (_currentPath ?? '') : null,
          );
          successCount++;
        } catch (e) {
          errors.add('${file.name}: $e');
        }
      }
    } finally {
      if (mounted) Navigator.pop(context); // Close dialog

      String message;
      Color bgColor;
      if (errors.isEmpty) {
        message = '$successCount PDF(s) subido(s) exitosamente.';
        bgColor = Colors.green;
      } else if (successCount > 0) {
        message = '$successCount subido(s), ${errors.length} con error(es).';
        bgColor = Colors.orange;
        print("Errores de subida:\n${errors.join('\n')}");
      } else {
        message = 'Error al subir ${errors.length} PDF(s).';
        bgColor = Colors.red;
        print("Errores de subida:\n${errors.join('\n')}");
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message), backgroundColor: bgColor));
      await _refresh();
    }
  }

  /// Converts HEX color string to Color object.
  Color _hexToColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    try {
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return Colors.grey;
    } // Default on error
  }

  // --- Analysis Methods ---

  /// Shows dialog to choose analysis type.
  Future<String?> _showAnalyzeOptions() async {
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tipo de Análisis'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.flash_on),
              title: const Text('Resumen Rápido'),
              subtitle: const Text('Breve y conciso.'),
              onTap: () => Navigator.pop(ctx, 'summary_fast'),
            ),
            ListTile(
              leading: const Icon(Icons.article),
              title: const Text('Resumen Detallado'),
              subtitle: const Text('Más profundo y completo.'),
              onTap: () => Navigator.pop(ctx, 'summary_detailed'),
            ),
          ],
        ),
      ),
    );
  }

  /// Initiates analysis for a VIP document.
  Future<void> _analyzeDocVip(int docId, String displayName) async {
    final type = await _showAnalyzeOptions();
    if (type == null || !mounted) return;

    _showLoadingDialog('Generando resumen ($type)...');
    try {
      // Genera y guarda (si el backend lo soporta) el resumen
      final summary = await _analysisService.summarizePdf(
        mode: 'vip',
        documentId: docId.toString(),
        fileName: displayName,
        analysisType: type,
      );
      if (mounted) Navigator.pop(context); // cerrar loading
      // Navega a la pantalla de resumen mostrando el texto generado
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SummaryScreen(
            title: displayName,
            summaryText: summary,
            api: widget.api,
          ),
        ),
      );
      await _refresh(); // refresca para ver el archivo de resumen en la lista si aplica
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al analizar: $e'), backgroundColor: Colors.red),
      );
    }
  }

  /// Initiates analysis for an FS document.
  Future<void> _analyzeDocFs(String path, String displayName) async {
    final type = await _showAnalyzeOptions();
    if (type == null || !mounted) return;

    _showLoadingDialog('Generando resumen ($type)...');
    try {
      final summary = await _analysisService.summarizePdf(
        mode: 'fs',
        path: path,
        fileName: displayName,
        analysisType: type,
      );
      if (mounted) Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SummaryScreen(
            title: displayName,
            summaryText: summary,
            api: widget.api,
          ),
        ),
      );
      await _refresh();
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al analizar: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // --- Navigation Methods ---

  /// Navigates to the Summary screen.
// --- Navigation Methods ---

  /// Navigates to the Summary screen.
  void _viewSummary(Map<String, dynamic> docData) async {
    if (!mounted) return;
    _showLoadingDialog('Cargando resumen...');
    try {
      Map<String, dynamic> details;
      if (_mode == 'vip') {
        final int? id = docData['id'] as int?;
        final int? originalId = docData['original_doc_id'] as int?;
        final String? path = docData['path'] as String?;
        if (id != null) {
          details = await widget.api.fetchSummaryDetails(vipSummaryId: id);
        } else if (originalId != null) {
          details = await widget.api.fetchSummaryDetails(vipSummaryId: originalId);
        } else if (path != null && path.isNotEmpty) {
          // Fallback: si viene de listado local
          details = await widget.api.fetchSummaryDetails(fsPath: path);
        } else {
          throw Exception('Referencia de resumen VIP faltante.');
        }
      } else {
        final path = docData['path'] as String?;
        if (path == null || path.isEmpty) throw Exception('Path del resumen FS faltante.');
        details = await widget.api.fetchSummaryDetails(fsPath: path);
      }
      if (mounted) Navigator.pop(context);
      final summaryText = details['summary_text'] as String? ?? '(Sin contenido)';
      final displayName = docData['display_name'] ?? 'Resumen';
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => SummaryScreen(
          title: displayName,
          summaryText: summaryText,
          api: widget.api,
        ),
      ));
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir el resumen: $e'), backgroundColor: Colors.red),
      );
    }
  }

  /// Navigates to the Quiz screen.
  void _generateQuiz(Map<String, dynamic> docData) {
    if (!mounted) return;
    final displayName = docData['display_name'] ?? 'Quiz';

    int? vipId;
    String? fsPath;
    if (_mode == 'vip') {
      vipId = docData['id'] as int? ?? docData['original_doc_id'] as int?;
      if (vipId == null) {
        fsPath = docData['path'] as String?;
      }
    } else {
      fsPath = docData['path'] as String?;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizScreen(
          sourceName: displayName,
          api: widget.api,
          vipSummaryId: vipId,
          fsPath: fsPath,
        ),
      ),
    );
  } // <--- ESTA ES LA LLAVE QUE FALTABA

  /// Shows preferences dialog with theme toggle.
  void _showPreferences() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Preferencias'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Tema oscuro'),
              subtitle: const Text('Activar modo oscuro'),
              value: Provider.of<ThemeProvider>(context, listen: true).isDarkMode,
              onChanged: (value) {
                Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
              },
              secondary: const Icon(Icons.dark_mode),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  /// Shows VIP upgrade dialog.
  void _showUpgradeVipDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.star, color: Color(0xFFFFD700)),
            SizedBox(width: 8),
            Text('Volverse VIP'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¡Mejora tu experiencia con EstudiaFácil VIP!',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text('Beneficios VIP:'),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Expanded(child: Text('Almacenamiento en la nube')),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Expanded(child: Text('Acceso desde cualquier dispositivo')),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Expanded(child: Text('Sincronización automática')),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Expanded(child: Text('Respaldo seguro de tus documentos')),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'Actualmente estás usando el modo gratuito que guarda archivos localmente en tu dispositivo.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Más tarde'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('¡Función VIP próximamente disponible!'),
                  backgroundColor: Color(0xFFFFD700),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
            ),
            child: const Text('¡Quiero ser VIP!'),
          ),
        ],
      ),
    );
  }

  /// Navigates to the Profile screen.
  void _goToProfile() {
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ProfileScreen(api: widget.api)),
      );
    }
  }

  /// Logs the user out and returns to LoginScreen.
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    // Limpia token del ApiService y preferencias locales
    widget.api.clearToken();
    await prefs.clear();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => LoginScreen(api: widget.api)),
        (route) => false,
      );
    }
  }

  // --- Helper Dialogs ---

  /// Shows a standard loading dialog. Must be closed manually.
  void _showLoadingDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Text(message),
          ],
        ),
      ),
    );
  }

  /// Shows a generic rename dialog.
  Future<bool?> _showRenameDialog(TextEditingController controller, String itemType) async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Renombrar $itemType'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nuevo nombre'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Guardar')),
        ],
      ),
    );
  }

  /// Shows a generic confirmation dialog for deletion.
  Future<bool?> _showDeleteConfirmationDialog(String itemDescription) async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content:
            Text('¿Seguro que quieres eliminar $itemDescription? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar Definitivamente'),
          ),
        ],
      ),
    );
  }

  // --- Main Build Method ---
  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> childrenDirs = _childrenNormalized();
    final List<Map<String, dynamic>> currentDocs = _docsNormalized();

    return Scaffold(
      appBar: AppBar(
        title: _breadcrumbBar(),
        titleSpacing: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Usuario',
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  _goToProfile();
                  break;
                case 'preferences':
                  _showPreferences();
                  break;
                case 'upgrade_vip':
                  _showUpgradeVipDialog();
                  break;
                case 'logout':
                  _logout();
                  break;
              }
            },
            itemBuilder: (context) {
              List<PopupMenuEntry<String>> items = [
                const PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person, color: Color(0xFF1976D2)),
                      SizedBox(width: 8),
                      Text('Mi Perfil'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'preferences',
                  child: Row(
                    children: [
                      Icon(Icons.settings, color: Color(0xFF1976D2)),
                      SizedBox(width: 8),
                      Text('Preferencias'),
                    ],
                  ),
                ),
              ];
              
              // Agregar opción VIP solo para usuarios no VIP
              if (_mode == 'fs') {
                items.addAll([
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'upgrade_vip',
                    child: Row(
                      children: [
                        Icon(Icons.star, color: Color(0xFFFFD700)),
                        SizedBox(width: 8),
                        Text('Volverse VIP', style: TextStyle(color: Color(0xFFFFD700))),
                      ],
                    ),
                  ),
                ]);
              }
              
              items.addAll([
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ]);
              
              return items;
            },
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            onPressed: _pickAndProcessPdfs,
            tooltip: 'Subir PDF',
            heroTag: 'upload',
            child: const Icon(Icons.upload_file),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: _createDir,
            tooltip: 'Nueva Carpeta',
            heroTag: 'create_dir',
            child: const Icon(Icons.create_new_folder_outlined),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 10),
                      Text(_error ?? 'Ocurrió un error desconocido',
                          textAlign: TextAlign.center),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                        onPressed: _refresh,
                      )
                    ],
                  ),
                ))
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      // --- Subfolders Section ---
                      if (_mode == 'vip' || (_mode == 'fs' && childrenDirs.isNotEmpty)) ...[
                        const Text('Subcarpetas',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        if (childrenDirs.isEmpty && _mode == 'vip')
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            child: Center(
                                child: Text('No hay subcarpetas.',
                                    style: TextStyle(color: Colors.grey))),
                          )
                        else
                          ...childrenDirs.map((d) {
                            final color = _hexToColor(d['color_hex'] ?? '#1565C0');
                            return ListTile(
                              leading: Icon(Icons.folder_open, color: color),
                              title: Text(d['name'] ?? 'Unnamed'),
                              onTap: () {
                                setState(() {
                                  if (d['kind'] == 'vip') {
                                    _currentDirId = d['id'] as int?;
                                  } else {
                                    _currentPath = d['path'] as String?;
                                  }
                                });
                                _saveLocation();
                                _refresh();
                              },
                              trailing: PopupMenuButton<String>(
                                tooltip: 'Opciones de carpeta',
                                icon: const Icon(Icons.more_vert),
                                onSelected: (value) {
                                  if (d['kind'] == 'vip') {
                                    final int id = d['id'] as int;
                                    switch (value) {
                                      case 'rename':
                                        _renameDir(id, d['name']);
                                        break;
                                      case 'color':
                                        _changeColor(id);
                                        break;
                                      case 'move':
                                        _moveDir(id);
                                        break;
                                      case 'delete':
                                        _deleteDir(id);
                                        break;
                                    }
                                  } else {
                                    final String path = d['path'] as String;
                                    switch (value) {
                                      case 'rename':
                                        _renameDirFs(path, d['name']);
                                        break;
                                      case 'color':
                                        _changeColorFs(path);
                                        break;
                                      case 'move':
                                        _moveDirFs(path);
                                        break;
                                      case 'delete':
                                        _deleteDirFs(path);
                                        break;
                                    }
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(
                                      value: 'rename', 
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit, color: Color(0xFF1976D2)),
                                          SizedBox(width: 8),
                                          Text('Renombrar'),
                                        ],
                                      )),
                                  const PopupMenuItem(
                                      value: 'color', 
                                      child: Row(
                                        children: [
                                          Icon(Icons.palette, color: Color(0xFF1976D2)),
                                          SizedBox(width: 8),
                                          Text('Cambiar color'),
                                        ],
                                      )),
                                  const PopupMenuItem(
                                      value: 'move', 
                                      child: Row(
                                        children: [
                                          Icon(Icons.drive_file_move, color: Color(0xFF1976D2)),
                                          SizedBox(width: 8),
                                          Text('Mover'),
                                        ],
                                      )),
                                  const PopupMenuDivider(),
                                  const PopupMenuItem(
                                      value: 'delete', 
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Eliminar', style: TextStyle(color: Colors.red)),
                                        ],
                                      )),
                                ],
                              ),
                              dense: true,
                            );
                          }),
                        const Divider(height: 24),
                      ],

                      // --- Documents Section ---
                      const Text('Documentos',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (currentDocs.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Center(
                              child: Text('No hay documentos aquí. \nSube un PDF para empezar.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey))),
                        )
                      else
                        ...currentDocs.map((d) {
                          final String docType = d['type'] ?? 'pdf';
                          final String displayName = d['display_name'] ?? 'Archivo';
                          final IconData leadingIcon = docType == 'summary'
                              ? Icons.description_outlined
                              : Icons.picture_as_pdf_outlined;
                          final int? docSize = d['size'] as int?; // Handle potential null size

                          return ListTile(
                            leading: Icon(leadingIcon),
                            title: Text(displayName),
                            subtitle: Text(
                              _mode == 'vip'
                                  ? (docType == 'pdf'
                                      ? 'ID: ${d['id']} · ${d['created_at']}'
                                      : 'Resumen · ${d['created_at']}')
                                  : (docType == 'pdf'
                                      ? 'Tamaño: ${_formatBytes(docSize ?? 0)}'
                                      : 'Resumen · ${_formatBytes(docSize ?? 0)}'),
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            onTap: () {
                              if (docType == 'summary') {
                                _viewSummary(d); // View the summary
                              } else {
                                // For a PDF, show analysis options
                                if (_mode == 'vip') {
                                  _analyzeDocVip(d['id'] as int, d['display_name'] ?? 'Doc');
                                } else {
                                  _analyzeDocFs(d['path'] as String, d['display_name'] ?? 'Doc');
                                }
                              }
                            },
                            trailing: PopupMenuButton<String>(
                                tooltip: 'Opciones',
                                icon: const Icon(Icons.more_vert),
                                onSelected: (value) async {
                                  if (_mode == 'vip') {
                                    final int? id = d['id'] as int?;
                                    final String? summaryPath = d['summary_path'] as String?;
                                    switch (value) {
                                      case 'rename':
                                        if (id != null) _renameDoc(id, displayName);
                                        break;
                                      case 'move':
                                        if (id != null) _moveDoc(id);
                                        break;
                                      case 'delete':
                                        if (id != null) {
                                          _deleteDoc(id);
                                        } else if (summaryPath != null) {
                                          _deleteSummaryVip(summaryPath);
                                        }
                                        break;
                                      case 'analyze':
                                        if (id != null) _analyzeDocVip(id, displayName);
                                        break; // For PDFs
                                      case 'quiz':
                                        _generateQuiz(d);
                                        break; // For summaries
                                    }
                                  } else {
                                    final String path = d['path'] as String;
                                    switch (value) {
                                      case 'rename':
                                        _renameDocFs(path, displayName);
                                        break;
                                      case 'move':
                                        _moveDocFs(path);
                                        break;
                                      case 'delete':
                                        _deleteDocFs(path);
                                        break;
                                      case 'analyze':
                                        _analyzeDocFs(path, displayName);
                                        break; // For PDFs
                                      case 'quiz':
                                        _generateQuiz(d);
                                        break; // For summaries
                                    }
                                  }
                                },
                                itemBuilder: (ctx) {
                                  if (docType == 'summary') {
                                    return [
                                      const PopupMenuItem(
                                          value: 'quiz', 
                                          child: Row(
                                            children: [
                                              Icon(Icons.quiz, color: Color(0xFF1976D2)),
                                              SizedBox(width: 8),
                                              Text('Generar Quiz'),
                                            ],
                                          )),
                                      const PopupMenuItem(
                                          value: 'rename', 
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit, color: Color(0xFF1976D2)),
                                              SizedBox(width: 8),
                                              Text('Renombrar'),
                                            ],
                                          )),
                                      const PopupMenuItem(
                                          value: 'move', 
                                          child: Row(
                                            children: [
                                              Icon(Icons.drive_file_move, color: Color(0xFF1976D2)),
                                              SizedBox(width: 8),
                                              Text('Mover'),
                                            ],
                                          )),
                                      const PopupMenuDivider(),
                                      const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete, color: Colors.red),
                                              SizedBox(width: 8),
                                              Text('Eliminar', style: TextStyle(color: Colors.red)),
                                            ],
                                          )),
                                    ];
                                  } else {
                                    // It's a PDF
                                    return [
                                      const PopupMenuItem(
                                          value: 'analyze', 
                                          child: Row(
                                            children: [
                                              Icon(Icons.analytics, color: Color(0xFF1976D2)),
                                              SizedBox(width: 8),
                                              Text('Analizar'),
                                            ],
                                          )),
                                      const PopupMenuItem(
                                          value: 'rename', 
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit, color: Color(0xFF1976D2)),
                                              SizedBox(width: 8),
                                              Text('Renombrar'),
                                            ],
                                          )),
                                      const PopupMenuItem(
                                          value: 'move', 
                                          child: Row(
                                            children: [
                                              Icon(Icons.drive_file_move, color: Color(0xFF1976D2)),
                                              SizedBox(width: 8),
                                              Text('Mover'),
                                            ],
                                          )),
                                      const PopupMenuDivider(),
                                      const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete, color: Colors.red),
                                              SizedBox(width: 8),
                                              Text('Eliminar', style: TextStyle(color: Colors.red)),
                                            ],
                                          )),
                                    ];
                                  }
                                }),
                            dense: true,
                          );
                        }), // End map for docs
                    ],
                  ),
                ),
    );
  }

  // Helper function to format bytes
  String _formatBytes(int bytes, [int decimals = 1]) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (log(bytes) / log(1024)).floor(); // log requires dart:math
    return ((bytes / pow(1024, i)).toStringAsFixed(decimals)) + ' ' + suffixes[i]; // pow requires dart:math
  }
} // <--- BRACE MOVED TO HERE. This closes _DirectoriesScreenState

// _ProcessedDoc class (minimal version)
class _ProcessedDoc {
  final int? docId;
  final String? fsPath;
  final String fileName;
  _ProcessedDoc({this.docId, this.fsPath, required this.fileName});
}