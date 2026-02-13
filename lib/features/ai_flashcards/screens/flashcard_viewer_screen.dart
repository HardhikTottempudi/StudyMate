import 'package:flutter/material.dart';
import '../../../shared/models/flashcard_set.dart';

class FlashcardViewerScreen extends StatefulWidget {
  final FlashcardSet flashcardSet;

  const FlashcardViewerScreen({
    super.key,
    required this.flashcardSet,
  });

  @override
  State<FlashcardViewerScreen> createState() => _FlashcardViewerScreenState();
}

class _FlashcardViewerScreenState extends State<FlashcardViewerScreen> {
  int _currentIndex = 0;
  bool _showAnswer = false;

  @override
  Widget build(BuildContext context) {
    final cards = widget.flashcardSet.cards;
    if (cards.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.flashcardSet.title),
        ),
        body: const Center(
          child: Text('No cards in this set'),
        ),
      );
    }

    final currentCard = cards[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.flashcardSet.title),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: LinearProgressIndicator(
              value: (_currentIndex + 1) / cards.length,
            ),
          ),
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showAnswer = !_showAnswer;
                  });
                },
                child: Card(
                  margin: const EdgeInsets.all(24),
                  elevation: 4,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _showAnswer ? Icons.lightbulb : Icons.help_outline,
                          size: 48,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _showAnswer ? 'Answer' : 'Question',
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _showAnswer
                              ? currentCard.answer
                              : currentCard.question,
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Tap to ${_showAnswer ? 'hide' : 'show'} answer',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _currentIndex > 0
                      ? () {
                          setState(() {
                            _currentIndex--;
                            _showAnswer = false;
                          });
                        }
                      : null,
                  icon: const Icon(Icons.arrow_back),
                ),
                Text(
                  '${_currentIndex + 1} / ${cards.length}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  onPressed: _currentIndex < cards.length - 1
                      ? () {
                          setState(() {
                            _currentIndex++;
                            _showAnswer = false;
                          });
                        }
                      : null,
                  icon: const Icon(Icons.arrow_forward),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
