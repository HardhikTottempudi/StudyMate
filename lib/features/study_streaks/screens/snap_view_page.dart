import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/streak_models.dart';

class SnapViewPage extends StatefulWidget {
  const SnapViewPage({
    super.key,
    required this.snap,
    required this.onViewed,
  });

  final StudySnap snap;
  final Future<void> Function() onViewed;

  @override
  State<SnapViewPage> createState() => _SnapViewPageState();
}

class _SnapViewPageState extends State<SnapViewPage> {
  static const int totalSeconds = 7;
  int _remaining = totalSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    widget.onViewed();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remaining <= 1) {
        timer.cancel();
        Navigator.pop(context);
        return;
      }
      setState(() {
        _remaining -= 1;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _remaining / totalSeconds;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.file(
              File(widget.snap.imagePath),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Center(
                child: Icon(Icons.broken_image_rounded, color: Colors.white70),
              ),
            ),
          ),
          Positioned(
            top: 44,
            left: 12,
            right: 12,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 3,
              color: Colors.white,
              backgroundColor: Colors.white24,
            ),
          ),
          Positioned(
            top: 58,
            right: 10,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Colors.white),
            ),
          ),
          Positioned(
            left: 16,
            bottom: 24,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((widget.snap.emoji ?? '').isNotEmpty)
                  Text(widget.snap.emoji!, style: const TextStyle(fontSize: 26)),
                if ((widget.snap.caption ?? '').isNotEmpty)
                  Text(
                    widget.snap.caption!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
