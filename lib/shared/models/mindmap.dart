class MindmapNode {
  final String id;
  final String text;
  final List<MindmapNode> children;

  MindmapNode({
    required this.id,
    required this.text,
    this.children = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'children': children.map((child) => child.toMap()).toList(),
    };
  }

  factory MindmapNode.fromMap(Map<String, dynamic> map) {
    return MindmapNode(
      id: map['id'] ?? '',
      text: map['text'] ?? '',
      children: (map['children'] as List<dynamic>?)
              ?.map((child) =>
                  MindmapNode.fromMap(child as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class Mindmap {
  final String id;
  final String title;
  final String? sourceText;
  final MindmapNode root;
  final DateTime createdAt;

  Mindmap({
    required this.id,
    required this.title,
    this.sourceText,
    required this.root,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'sourceText': sourceText,
      'root': root.toMap(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Mindmap.fromMap(String id, Map<String, dynamic> map) {
    return Mindmap(
      id: id,
      title: map['title'] ?? '',
      sourceText: map['sourceText'],
      root: MindmapNode.fromMap(map['root'] as Map<String, dynamic>),
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
