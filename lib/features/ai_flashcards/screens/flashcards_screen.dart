import 'package:flutter/material.dart';
import '../../../shared/widgets/soft_surface.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../services/ai_service.dart';
import '../../../shared/models/flashcard_set.dart';
import '../../auth/providers/auth_provider.dart';
import 'flashcard_viewer_screen.dart';

class FlashcardsScreen extends ConsumerStatefulWidget {
  const FlashcardsScreen({super.key});

  @override
  ConsumerState<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends ConsumerState<FlashcardsScreen> {
  final TextEditingController _promptController = TextEditingController();
  String _generatedTitle = '';
  String? _generatedId;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isSaved = false;
  List<Flashcard> _flashcards = [];

  late final Stream<List<FlashcardSet>> _savedTopics;

  @override
  void initState() {
    super.initState();
    _savedTopics = ref.read(firestoreServiceProvider).getFlashcardSets();
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _generateFlashcards() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty || _isLoading || _isSaving) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _isSaved = false;
    });

    try {
      final response = await AIService.generateFlashcards(prompt, null);
      final cards = (response['cards'] as List<dynamic>)
          .map((card) => Flashcard(
                id: const Uuid().v4(),
                question: card['question'] ?? '',
                answer: card['answer'] ?? '',
              ))
          .where((card) => card.question.isNotEmpty && card.answer.isNotEmpty)
          .toList();

      if (!mounted) return;
      setState(() {
        _flashcards = cards;
        _generatedTitle = prompt;
        _generatedId = const Uuid().v4();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Couldn’t generate flashcards. Check your connection and try again.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveFlashcards() async {
    if (_flashcards.isEmpty || _isSaving || _isLoading || _isSaved) return;
    setState(() {
      _isSaving = true;
    });
    try {
      final set = FlashcardSet(
        id: _generatedId!,
        title: _generatedTitle,
        sourceText: null,
        cards: _flashcards,
        createdAt: DateTime.now(),
      );
      await ref.read(firestoreServiceProvider).saveFlashcardSet(set);
      if (!mounted) return;
      setState(() {
        _isSaved = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Flashcards saved to Firebase')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Flashcards')),
      body: SoftBackdrop(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              _SoftCard(
                child: Column(
                  children: [
                    TextField(
                      controller: _promptController,
                      decoration: const InputDecoration(
                        hintText: 'Enter topic for flashcards',
                        prefixIcon: Icon(Icons.auto_awesome_rounded),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _generateFlashcards,
                            child: const Text('Generate'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed:
                                _flashcards.isEmpty || _isSaved || _isSaving
                                    ? null
                                    : _saveFlashcards,
                            child: _isSaving
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : Text(_isSaved ? 'Saved' : 'Save'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (_isLoading) const CircularProgressIndicator(),
              if (!_isLoading) ...[
                Expanded(flex: 3, child: _buildFlashcardGrid()),
                const SizedBox(height: 10),
                Expanded(flex: 2, child: _buildSavedTopics(context)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFlashcardGrid() {
    if (_flashcards.isEmpty) {
      return const _SoftCard(
        child: Center(child: Text('No generated flashcards yet')),
      );
    }

    return GridView.builder(
      itemCount: _flashcards.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.08,
      ),
      itemBuilder: (context, index) => _FlipCard(card: _flashcards[index]),
    );
  }

  Widget _buildSavedTopics(BuildContext context) {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Saved Topics',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: StreamBuilder<List<FlashcardSet>>(
              stream: _savedTopics,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(
                      child: Text('Failed to load saved topics'));
                }
                final sets = snapshot.data ?? [];
                if (sets.isEmpty) {
                  return const Center(
                      child: Text('No saved flashcard topics yet'));
                }
                return ListView.separated(
                  itemCount: sets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final set = sets[index];
                    return ListTile(
                      tileColor: const Color(0xFFFFFFFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      title: Text(set.title),
                      subtitle: Text('${set.cards.length} cards'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                FlashcardViewerScreen(flashcardSet: set),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftCard extends StatelessWidget {
  const _SoftCard({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => SizedBox(
      width: double.infinity,
      child: SoftSurface(padding: const EdgeInsets.all(16), child: child));
}

class _FlipCard extends StatefulWidget {
  const _FlipCard({required this.card});
  final Flashcard card;

  @override
  State<_FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<_FlipCard> {
  bool _showAnswer = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => setState(() => _showAnswer = !_showAnswer),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _showAnswer
                ? [const Color(0xFFE8F8FF), const Color(0xFFF5EEFF)]
                : [const Color(0xFFFFF1F3), const Color(0xFFF5F1FF)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            _showAnswer ? widget.card.answer : widget.card.question,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
