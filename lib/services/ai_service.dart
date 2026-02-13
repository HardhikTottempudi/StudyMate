import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class AIService {
  // Server-side endpoint. Override with:
  // flutter run --dart-define=AI_BACKEND_BASE_URL=https://your-cloud-run-url
  static const String _backendBaseUrl = String.fromEnvironment(
    'AI_BACKEND_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  static Future<Map<String, dynamic>> generateFlashcards(
      String topic, String? notes) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final idToken = await user.getIdToken();
      
      final response = await http.post(
        Uri.parse('$_backendBaseUrl/generateContent/flashcards'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'topic': topic,
          'notes': notes,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to generate flashcards: ${response.body}');
      }
    } catch (e) {
      // For development, return mock data if cloud function is not set up
      return _mockFlashcards(topic);
    }
  }

  static Future<Map<String, dynamic>> generateMindmap(
      String topic, String? notes) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final idToken = await user.getIdToken();
      
      final response = await http.post(
        Uri.parse('$_backendBaseUrl/generateContent/mindmap'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'topic': topic,
          'notes': notes,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to generate mindmap: ${response.body}');
      }
    } catch (e) {
      // For development, return mock data if cloud function is not set up
      return _mockMindmap(topic);
    }
  }

  // Mock data for development/testing
  static Map<String, dynamic> _mockFlashcards(String topic) {
    return {
      'cards': [
        {
          'id': '1',
          'question': 'What is $topic?',
          'answer': 'This is a sample answer about $topic.',
        },
        {
          'id': '2',
          'question': 'Why is $topic important?',
          'answer': '$topic is important because...',
        },
        {
          'id': '3',
          'question': 'How does $topic work?',
          'answer': '$topic works by...',
        },
      ],
    };
  }

  static Map<String, dynamic> _mockMindmap(String topic) {
    return {
      'root': {
        'id': 'root',
        'text': topic,
        'children': [
          {
            'id': '1',
            'text': 'Concept 1',
            'children': [
              {'id': '1-1', 'text': 'Detail 1.1', 'children': []},
              {'id': '1-2', 'text': 'Detail 1.2', 'children': []},
            ],
          },
          {
            'id': '2',
            'text': 'Concept 2',
            'children': [
              {'id': '2-1', 'text': 'Detail 2.1', 'children': []},
            ],
          },
        ],
      },
    };
  }
}
