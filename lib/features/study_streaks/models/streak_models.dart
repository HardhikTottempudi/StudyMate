class FriendStreak {
  FriendStreak({
    required this.friendId,
    required this.friendName,
    required this.streakCount,
    this.lastSentAtIso,
    required this.pendingCount,
  });

  final String friendId;
  final String friendName;
  final int streakCount;
  final String? lastSentAtIso;
  final int pendingCount;

  DateTime? get lastSentAt =>
      lastSentAtIso == null ? null : DateTime.tryParse(lastSentAtIso!);

  Map<String, dynamic> toMap() {
    return {
      'friendId': friendId,
      'friendName': friendName,
      'streakCount': streakCount,
      'lastSentAt': lastSentAtIso,
      'pendingCount': pendingCount,
    };
  }

  factory FriendStreak.fromMap(Map<String, dynamic> map) {
    return FriendStreak(
      friendId: map['friendId'] ?? '',
      friendName: map['friendName'] ?? 'Friend',
      streakCount: map['streakCount'] ?? 0,
      lastSentAtIso: map['lastSentAt'],
      pendingCount: map['pendingCount'] ?? 0,
    );
  }
}

class StudySnap {
  StudySnap({
    required this.id,
    required this.friendId,
    required this.friendName,
    required this.imagePath,
    required this.createdAtIso,
    required this.dayKey,
    this.caption,
    this.emoji,
    this.viewedAtIso,
  });

  final String id;
  final String friendId;
  final String friendName;
  final String imagePath;
  final String createdAtIso;
  final String dayKey;
  final String? caption;
  final String? emoji;
  final String? viewedAtIso;

  bool get isViewed => viewedAtIso != null;

  DateTime get createdAt => DateTime.parse(createdAtIso);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'friendId': friendId,
      'friendName': friendName,
      'imagePath': imagePath,
      'createdAt': createdAtIso,
      'dayKey': dayKey,
      'caption': caption,
      'emoji': emoji,
      'viewedAt': viewedAtIso,
    };
  }

  factory StudySnap.fromMap(Map<String, dynamic> map) {
    return StudySnap(
      id: map['id'] ?? '',
      friendId: map['friendId'] ?? '',
      friendName: map['friendName'] ?? 'Friend',
      imagePath: map['imagePath'] ?? '',
      createdAtIso: map['createdAt'] ?? DateTime.now().toIso8601String(),
      dayKey: map['dayKey'] ?? '',
      caption: map['caption'],
      emoji: map['emoji'],
      viewedAtIso: map['viewedAt'],
    );
  }
}

class FriendContact {
  const FriendContact({required this.id, required this.name});

  final String id;
  final String name;
}
