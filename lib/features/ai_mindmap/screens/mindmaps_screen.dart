import 'package:flutter/material.dart';
import '../../../shared/widgets/soft_surface.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../services/ai_service.dart';
import '../../../shared/models/mindmap.dart';
import '../../auth/providers/auth_provider.dart';
import 'mindmap_viewer_screen.dart';

class MindmapsScreen extends ConsumerStatefulWidget {
  const MindmapsScreen({super.key});

  @override
  ConsumerState<MindmapsScreen> createState() => _MindmapsScreenState();
}

class _MindmapsScreenState extends ConsumerState<MindmapsScreen> {
  final TextEditingController _promptController = TextEditingController();
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isSaved = false;
  Mindmap? _generatedMindmap;

  late final Stream<List<Mindmap>> _savedTopics;

  @override
  void initState() {
    super.initState();
    _savedTopics = ref.read(firestoreServiceProvider).getMindmaps();
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _generateMindmap() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty || _isLoading || _isSaving) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _isSaved = false;
    });

    try {
      final response = await AIService.generateMindmap(prompt, null);
      final rootMap = response['root'] as Map<String, dynamic>;
      final generatedMindmap = Mindmap(
        id: const Uuid().v4(),
        title: prompt,
        sourceText: null,
        createdAt: DateTime.now(),
        root: MindmapNode.fromMap(rootMap),
      );
      if (!mounted) return;
      setState(() {
        _generatedMindmap = generatedMindmap;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Couldn’t generate a mindmap. Check your connection and try again.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveMindmap() async {
    if (_generatedMindmap == null || _isSaving || _isSaved || _isLoading)
      return;
    setState(() {
      _isSaving = true;
    });
    try {
      await ref.read(firestoreServiceProvider).saveMindmap(_generatedMindmap!);
      if (!mounted) return;
      setState(() {
        _isSaved = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mindmap saved to Firebase')),
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
      appBar: AppBar(title: const Text('AI Mindmaps')),
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
                        hintText: 'Enter topic for mindmap',
                        prefixIcon: Icon(Icons.account_tree_rounded),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _generateMindmap,
                            child: const Text('Generate'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _generatedMindmap == null ||
                                    _isSaving ||
                                    _isSaved
                                ? null
                                : _saveMindmap,
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
                Expanded(flex: 2, child: _buildGeneratedArea(context)),
                const SizedBox(height: 10),
                Expanded(flex: 3, child: _buildSavedTopics(context)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGeneratedArea(BuildContext context) {
    if (_generatedMindmap == null) {
      return const _SoftCard(
        child: Center(child: Text('No generated mindmap yet')),
      );
    }

    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _generatedMindmap!.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text('Main branches: ${_generatedMindmap!.root.children.length}'),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        MindmapViewerScreen(mindmap: _generatedMindmap!),
                  ),
                );
              },
              child: const Text('Open Viewer'),
            ),
          ),
        ],
      ),
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
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<List<Mindmap>>(
              stream: _savedTopics,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(
                      child: Text('Failed to load saved topics'));
                }
                final maps = snapshot.data ?? [];
                if (maps.isEmpty) {
                  return const Center(
                      child: Text('No saved mindmap topics yet'));
                }
                return ListView.separated(
                  itemCount: maps.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final map = maps[index];
                    return ListTile(
                      tileColor: const Color(0xFFFFFFFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      title: Text(map.title),
                      subtitle:
                          Text('${map.root.children.length} main branches'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MindmapViewerScreen(mindmap: map),
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
