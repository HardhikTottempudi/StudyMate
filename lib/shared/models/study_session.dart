class StudySession {
  final String id;
  final String sessionName;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationSeconds; // Active study time only
  final int goalDurationSeconds;
  final int breakDurationSeconds;
  final int breakCount;
  final bool appBlockEnabled;
  final List<String> blockedApps;
  final DateTime createdAt;

  StudySession({
    required this.id,
    this.sessionName = '',
    required this.startTime,
    this.endTime,
    required this.durationSeconds,
    this.goalDurationSeconds = 0,
    this.breakDurationSeconds = 0,
    this.breakCount = 0,
    this.appBlockEnabled = false,
    this.blockedApps = const [],
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'sessionName': sessionName,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'durationSeconds': durationSeconds,
      'goalDurationSeconds': goalDurationSeconds,
      'breakDurationSeconds': breakDurationSeconds,
      'breakCount': breakCount,
      'appBlockEnabled': appBlockEnabled,
      'blockedApps': blockedApps,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory StudySession.fromMap(String id, Map<String, dynamic> map) {
    return StudySession(
      id: id,
      sessionName: map['sessionName'] ?? '',
      startTime: DateTime.parse(map['startTime']),
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
      durationSeconds: map['durationSeconds'] ?? 0,
      goalDurationSeconds: map['goalDurationSeconds'] ?? 0,
      breakDurationSeconds: map['breakDurationSeconds'] ?? 0,
      breakCount: map['breakCount'] ?? 0,
      appBlockEnabled: map['appBlockEnabled'] ?? false,
      blockedApps: (map['blockedApps'] as List<dynamic>? ?? [])
          .map((app) => app.toString())
          .toList(),
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
