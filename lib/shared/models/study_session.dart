class StudySession {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationSeconds;
  final DateTime createdAt;

  StudySession({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.durationSeconds,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'durationSeconds': durationSeconds,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory StudySession.fromMap(String id, Map<String, dynamic> map) {
    return StudySession(
      id: id,
      startTime: DateTime.parse(map['startTime']),
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
      durationSeconds: map['durationSeconds'] ?? 0,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
