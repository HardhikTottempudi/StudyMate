import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/streak_models.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({
    super.key,
    required this.friends,
  });

  final List<FriendContact> friends;

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  final TextEditingController _captionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<String> _emojis = const ['📚', '🔥', '✅', '🧠', '☕'];

  XFile? _capturedImage;
  FriendContact? _selectedFriend;
  String? _selectedEmoji;

  @override
  void initState() {
    super.initState();
    _selectedFriend = widget.friends.isEmpty ? null : widget.friends.first;
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _captureImage() async {
    final image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 75,
      maxWidth: 1200,
    );
    if (image == null) return;
    setState(() {
      _capturedImage = image;
    });
  }

  void _submit() {
    if (_capturedImage == null || _selectedFriend == null) return;
    Navigator.pop(context, {
      'imagePath': _capturedImage!.path,
      'friend': _selectedFriend,
      'caption': _captionController.text.trim().isEmpty
          ? null
          : _captionController.text.trim(),
      'emoji': _selectedEmoji,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF101318), Color(0xFF202631)],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: _capturedImage == null
                ? Container(
                    color: Colors.black.withOpacity(0.32),
                    child: const Center(
                      child: Icon(Icons.camera_alt_rounded,
                          color: Colors.white70, size: 44),
                    ),
                  )
                : ShaderMask(
                    shaderCallback: (rect) => const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.white, Colors.transparent, Colors.white],
                      stops: [0, 0.45, 1],
                    ).createShader(rect),
                    blendMode: BlendMode.dstIn,
                    child: Image.file(
                      File(_capturedImage!.path),
                      fit: BoxFit.cover,
                    ),
                  ),
          ),
          Positioned(
            top: 48,
            left: 16,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded, color: Colors.white),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 26,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ColorFilter.mode(
                  Colors.white.withOpacity(0.16),
                  BlendMode.srcATop,
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _captionController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Add a short study caption',
                          hintStyle: const TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: Colors.white12,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (_, index) {
                            final emoji = _emojis[index];
                            final selected = _selectedEmoji == emoji;
                            return ChoiceChip(
                              label: Text(emoji),
                              selected: selected,
                              onSelected: (_) {
                                setState(() {
                                  _selectedEmoji = selected ? null : emoji;
                                });
                              },
                            );
                          },
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemCount: _emojis.length,
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<FriendContact>(
                        value: _selectedFriend,
                        dropdownColor: const Color(0xFF2A3341),
                        style: const TextStyle(color: Colors.white),
                        iconEnabledColor: Colors.white,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white12,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: widget.friends
                            .map(
                              (friend) => DropdownMenuItem(
                                value: friend,
                                child: Text(friend.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedFriend = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _captureImage,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white24,
                                foregroundColor: Colors.white,
                              ),
                              child: Text(
                                _capturedImage == null ? 'Capture' : 'Retake',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _capturedImage == null ? null : _submit,
                              child: const Text('Send'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
