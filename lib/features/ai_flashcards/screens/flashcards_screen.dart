import 'package:flutter/material.dart';
import '../../../services/ai_service.dart';

class FlashcardsScreen extends StatefulWidget {
  const FlashcardsScreen({super.key});

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  final TextEditingController _promptController = TextEditingController();
  bool _isLoading = false;
  List<_Flashcard> _flashcards = [];

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _generateFlashcards() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await AIService.generateFlashcards(prompt, null);
      final cards = (response['cards'] as List<dynamic>)
          .map((card) => _Flashcard(
                question: card['question'] ?? '',
                answer: card['answer'] ?? '',
              ))
          .toList();

      setState(() {
        _flashcards = cards;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildPromptSection(context),
            const SizedBox(height: 16),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              )
            else
              Expanded(child: _buildFlashcardGrid()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
          child: Image.asset(
            'assets/images/flashcards/ai_generated_flashcard.png',
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Flashcards',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFE6B9FA),
                    ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPromptSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          SizedBox(
            height: 56,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/ui/search_bar.png',
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
                TextField(
                  controller: _promptController,
                  decoration: const InputDecoration(
                    hintText: 'Enter your prompt here ..',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _isLoading ? null : _generateFlashcards,
            child: const Text('Generate Flashcards'),
          ),
        ],
      ),
    );
  }

  Widget _buildFlashcardGrid() {
    if (_flashcards.isEmpty) {
      return const Center(
        child: Text('No flashcards yet'),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: _flashcards.length,
      itemBuilder: (context, index) {
        final card = _flashcards[index];
        return _FlipCard(card: card);
      },
    );
  }
}

class _Flashcard {
  final String question;
  final String answer;

  const _Flashcard({
    required this.question,
    required this.answer,
  });
}

class _FlipCard extends StatefulWidget {
  final _Flashcard card;

  const _FlipCard({required this.card});

  @override
  State<_FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<_FlipCard> {
  bool _showAnswer = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showAnswer = !_showAnswer;
        });
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return ScaleTransition(scale: animation, child: child);
        },
        child: Container(
          key: ValueKey(_showAnswer),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF606060),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              _showAnswer ? 'A: ${widget.card.answer}' : 'Q: ${widget.card.question}',
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
