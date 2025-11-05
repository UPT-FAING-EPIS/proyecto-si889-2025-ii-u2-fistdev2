import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'profile_screen.dart';
import 'login_screen.dart';
import '../services/api_service.dart'; // <-- Ensure import

class QuizScreen extends StatefulWidget {
  final String sourceName;
  final ApiService api; // <-- Add api field
  final int? vipSummaryId;
  final String? fsPath;

  const QuizScreen({
    super.key,
    required this.sourceName,
    required this.api, // <-- Require api in constructor
    this.vipSummaryId,
    this.fsPath,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late List<_Question> _questions;
  final Map<int, int> _answers = {}; // question index -> answer index
  bool _submitted = false;
  int _score = 0;
  bool _reviewMode = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadQuiz(); // Load real questions from backend
  }

  // Load questions from backend based on summary
  Future<void> _loadQuiz() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Fetch summary text first
      final details = await widget.api.fetchSummaryDetails(
        vipSummaryId: widget.vipSummaryId,
        fsPath: widget.fsPath,
      );
      final summaryText = details['summary_text'] as String?;
      if (summaryText == null || summaryText.isEmpty) {
        throw Exception('Resumen vacío o no disponible');
      }
      // Generate quiz via backend
      final q = await widget.api.generateQuizFromSummary(summaryText, numQuestions: 6);
      _questions = q.map((m) {
        final Map<String, dynamic> mm = Map<String, dynamic>.from(m);
        final String text = (mm['text'] as String?) ?? (mm['question'] as String?) ?? 'Pregunta';
        List<String> options = (mm['options'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];
        if (options.length < 4) {
          for (int i = options.length; i < 4; i++) {
            options.add('Opción ${i + 1}');
          }
        } else if (options.length > 4) {
          options = options.take(4).toList();
        }
        final int correct = (mm['correct_index'] is int)
            ? mm['correct_index'] as int
            : (mm['correctIndex'] as int?) ?? 0;
        return _Question(text, options, correct.clamp(0, 3));
      }).toList();
      setState(() {
        _answers.clear();
        _submitted = false;
        _reviewMode = false;
        _score = 0;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // Generate placeholder questions (now triggers reload)
  void _generateQuestions() {
    _loadQuiz();
  }


  void _submit() {
    int correctCount = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (_answers.containsKey(i) && _answers[i] == _questions[i].correctIndex) {
        correctCount++;
      }
    }
    setState(() {
      _score = correctCount;
      _submitted = true;
      _reviewMode = false; // Ensure review mode is off when submitting
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Show back arrow unless on results screen before review
        leading: _submitted && !_reviewMode
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
        title: Text('Cuestionario: ${widget.sourceName}'),
        actions: [ // <-- Added actions block
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle),
            onSelected: (value) async {
              if (value == 'profile') {
                // Pass api
                Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen(api: widget.api)));
              } else if (value == 'logout') {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                // Clear token in ApiService instance as well
                widget.api.clearToken();
                if (context.mounted) {
                  // Pass api
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen(api: widget.api)),
                    (route) => false,
                  );
                }
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Ver perfil'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Cerrar sesión'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _submitted && !_reviewMode
            ? _buildResultsView() // Show results
            : _buildQuestionsView(), // Show questions or review
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // Helper widget for results view
  Widget _buildResultsView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Resultado: $_score/${_questions.length}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Wrap( // Use Wrap for better spacing on small screens
          spacing: 8.0,
          runSpacing: 8.0,
          children: [
            ElevatedButton(onPressed: _generateQuestions, child: const Text('Intentar nuevamente')),
            ElevatedButton(onPressed: () => setState(() => _reviewMode = true), child: const Text('Revisión')),
            OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Regresar')),
          ],
        )
      ],
    );
  }

 // Helper widget for questions/review view
  Widget _buildQuestionsView() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Error: '+_error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: _loadQuiz, child: const Text('Reintentar')), 
        ],
      );
    }
    return ListView.builder(
      itemCount: _questions.length,
      itemBuilder: (ctx, i) {
        final q = _questions[i];
        final currentAnswer = _answers[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(q.text, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...List.generate(q.options.length, (optIndex) {
                  final isSelected = currentAnswer == optIndex;
                  final isCorrect = q.correctIndex == optIndex;
                  Color? tileColor;
                  Widget? trailingIcon;

                  if (_reviewMode) {
                    if (isCorrect) {
                      tileColor = Colors.green.shade100;
                      trailingIcon = const Icon(Icons.check_circle, color: Colors.green);
                    } else if (isSelected) { // Incorrectly selected
                      tileColor = Colors.red.shade100;
                      trailingIcon = const Icon(Icons.cancel, color: Colors.red);
                    }
                  }

                  return ListTile(
                    title: Text(q.options[optIndex]),
                    leading: Radio<int>(
                      value: optIndex,
                      groupValue: currentAnswer,
                      // Disable radio buttons in review mode
                      onChanged: _reviewMode ? null : (v) => setState(() => _answers[i] = v!),
                    ),
                    tileColor: tileColor,
                    trailing: trailingIcon,
                    contentPadding: EdgeInsets.zero,
                     // Allow tapping the whole row to select the radio button
                    onTap: _reviewMode ? null : () {
                      if (currentAnswer != optIndex) {
                        setState(() => _answers[i] = optIndex);
                      }
                    }
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper widget for the bottom navigation bar
  Widget? _buildBottomBar() {
    if (_submitted) {
      // Show "Exit Review" button only in review mode
      return _reviewMode
          ? Padding(
              padding: const EdgeInsets.all(12.0),
              child: ElevatedButton(
                onPressed: () => setState(() => _reviewMode = false),
                child: const Text('Salir de Revisión'),
              ),
            )
          : null; // Nothing needed after results shown, before review
    } else {
      // Show "Submit" button before submission
      return Padding(
        padding: const EdgeInsets.all(12),
        child: ElevatedButton(
          // Enable only when all questions are answered
          onPressed: (!_loading && _error == null && _answers.length == _questions.length) ? _submit : null,
          child: const Text('Enviar'),
        ),
      );
    }
  }
} // End of _QuizScreenState

// Simple class for Question data
class _Question {
  final String text;
  final List<String> options;
  final int correctIndex;
  _Question(this.text, this.options, this.correctIndex);
}