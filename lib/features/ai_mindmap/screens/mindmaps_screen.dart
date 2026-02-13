import 'package:flutter/material.dart';
import '../../../services/ai_service.dart';
import '../../../shared/models/mindmap.dart';
import 'mindmap_viewer_screen.dart';

class MindmapsScreen extends StatefulWidget {
  const MindmapsScreen({super.key});

  @override
  State<MindmapsScreen> createState() => _MindmapsScreenState();
}

class _MindmapsScreenState extends State<MindmapsScreen> {
  final TextEditingController _promptController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _generateMindmap() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await AIService.generateMindmap(prompt, null);
      if (mounted) {
        final mindmap = _buildSampleMindmap(prompt);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MindmapViewerScreen(mindmap: mindmap),
          ),
        );
      }
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
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            const SizedBox(height: 8),
            Expanded(child: _buildFolderGrid()),
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
            'assets/images/mindmaps/logo_ai_generated_mindmaps.png',
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
                'Mind Maps',
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
            onPressed: _isLoading ? null : _generateMindmap,
            child: const Text('Generate Mind Map'),
          ),
        ],
      ),
    );
  }

  Widget _buildFolderGrid() {
    final folders = ['Physics', 'Chemistry', 'Maths'];

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 24,
        crossAxisSpacing: 24,
        childAspectRatio: 0.9,
      ),
      itemCount: folders.length,
      itemBuilder: (context, index) {
        final title = folders[index];
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                final mindmap = _buildSampleMindmap(title);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MindmapViewerScreen(mindmap: mindmap),
                  ),
                );
              },
              child: Image.asset(
                'assets/images/mindmaps/folder_icon.png',
                width: 80,
                height: 80,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
                fontSize: 16,
              ),
            ),
          ],
        );
      },
    );
  }

  Mindmap _buildSampleMindmap(String title) {
    return Mindmap(
      id: 'sample-$title',
      title: title,
      sourceText: null,
      createdAt: DateTime.now(),
      root: MindmapNode(
        id: 'root',
        text: title,
        children: [
          MindmapNode(
            id: 'c1',
            text: 'Concept 1',
            children: [
              MindmapNode(id: 'c1a', text: 'Detail 1'),
              MindmapNode(id: 'c1b', text: 'Detail 2'),
            ],
          ),
          MindmapNode(
            id: 'c2',
            text: 'Concept 2',
            children: [
              MindmapNode(id: 'c2a', text: 'Detail 3'),
            ],
          ),
        ],
      ),
    );
  }
}
