import 'package:flutter/material.dart';

class FlashcardsScreen extends StatefulWidget {
  final List<dynamic> topics;
  const FlashcardsScreen({super.key, required this.topics});

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  int _topicIndex = 0;
  int _cardIndex = 0;
  bool _showAnswer = false;

  void _nextCard() {
    final cards = (widget.topics[_topicIndex]['flashcards'] as List<dynamic>);
    if (_cardIndex < cards.length - 1) {
      setState(() { _cardIndex++; _showAnswer = false; });
    } else if (_topicIndex < widget.topics.length - 1) {
      setState(() { _topicIndex++; _cardIndex = 0; _showAnswer = false; });
    }
  }

  void _prevCard() {
    if (_cardIndex > 0) {
      setState(() { _cardIndex--; _showAnswer = false; });
    } else if (_topicIndex > 0) {
      final prevTopic = widget.topics[_topicIndex - 1];
      final cards = (prevTopic['flashcards'] as List<dynamic>);
      setState(() { _topicIndex--; _cardIndex = cards.isNotEmpty ? cards.length - 1 : 0; _showAnswer = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.topics.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Flashcards')),
        body: const Center(child: Text('No hay temas disponibles')),
      );
    }

    final topic = widget.topics[_topicIndex];
    final cards = (topic['flashcards'] as List<dynamic>);
    final question = cards.isNotEmpty ? cards[_cardIndex]['question'] as String : 'Sin tarjetas';
    final answer = cards.isNotEmpty ? cards[_cardIndex]['answer'] as String : '';

    return Scaffold(
      appBar: AppBar(title: const Text('Flashcards')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('${_topicIndex + 1}/${widget.topics.length} - ${topic['title']}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text(topic['summary'], style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            Expanded(
              child: Card(
                elevation: 3,
                child: InkWell(
                  onTap: () => setState(() { _showAnswer = !_showAnswer; }),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        _showAnswer ? answer : question,
                        style: const TextStyle(fontSize: 20),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: _prevCard,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Anterior'),
                ),
                ElevatedButton.icon(
                  onPressed: () => setState(() { _showAnswer = !_showAnswer; }),
                  icon: const Icon(Icons.visibility),
                  label: Text(_showAnswer ? 'Ocultar' : 'Mostrar'),
                ),
                ElevatedButton.icon(
                  onPressed: _nextCard,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Siguiente'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}