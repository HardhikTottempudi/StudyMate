class Flashcard {
  final String id;
  final String question;
  final String answer;

  Flashcard({
    required this.id,
    required this.question,
    required this.answer,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
    };
  }

  factory Flashcard.fromMap(Map<String, dynamic> map) {
    return Flashcard(
      id: map['id'] ?? '',
      question: map['question'] ?? '',
      answer: map['answer'] ?? '',
    );
  }
}

class FlashcardSet {
  final String id;
  final String title;
  final String? sourceText;
  final List<Flashcard> cards;
  final DateTime createdAt;

  FlashcardSet({
    required this.id,
    required this.title,
    this.sourceText,
    required this.cards,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'sourceText': sourceText,
      'cards': cards.map((card) => card.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory FlashcardSet.fromMap(String id, Map<String, dynamic> map) {
    return FlashcardSet(
      id: id,
      title: map['title'] ?? '',
      sourceText: map['sourceText'],
      cards: (map['cards'] as List<dynamic>?)
              ?.map((card) => Flashcard.fromMap(card as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
