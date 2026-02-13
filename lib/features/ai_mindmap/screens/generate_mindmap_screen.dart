import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/ai_service.dart';
import '../../../shared/models/mindmap.dart';
import 'package:uuid/uuid.dart';
import '../../auth/providers/auth_provider.dart';

class GenerateMindmapScreen extends ConsumerStatefulWidget {
  const GenerateMindmapScreen({super.key});

  @override
  ConsumerState<GenerateMindmapScreen> createState() =>
      _GenerateMindmapScreenState();
}

class _GenerateMindmapScreenState extends ConsumerState<GenerateMindmapScreen> {
  final _formKey = GlobalKey<FormState>();
  final _topicController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isGenerating = false;

  @override
  void dispose() {
    _topicController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _generateMindmap() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isGenerating = true;
    });

    try {
      final topic = _topicController.text.trim();
      final notes = _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim();

      final response = await AIService.generateMindmap(topic, notes);
      final rootData = response['root'] as Map<String, dynamic>;

      final root = MindmapNode.fromMap(rootData);

      final mindmap = Mindmap(
        id: const Uuid().v4(),
        title: topic,
        sourceText: notes,
        root: root,
        createdAt: DateTime.now(),
      );

      final service = ref.read(firestoreServiceProvider);
      await service.saveMindmap(mindmap);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mindmap generated successfully!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating mindmap: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Mindmap'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Enter a topic and optional notes to generate a mindmap',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _topicController,
                decoration: const InputDecoration(
                  labelText: 'Topic *',
                  hintText: 'e.g., Photosynthesis, World War II',
                  prefixIcon: Icon(Icons.topic),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a topic';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Additional context or your notes...',
                  prefixIcon: Icon(Icons.note),
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isGenerating ? null : _generateMindmap,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isGenerating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Generate Mindmap'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
