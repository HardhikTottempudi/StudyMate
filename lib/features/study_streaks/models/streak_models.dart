class FriendStreak {
  FriendStreak({
    required this.friendId,
    required this.friendName,
    required this.friendUsername,
    required this.streakCount,
    this.lastSentAtIso,
    required this.pendingCount,
  });

  final String friendId;
  final String friendName;
  final String friendUsername;
  final int streakCount;
  final String? lastSentAtIso;
  final int pendingCount;

  DateTime? get lastSentAt =>
      lastSentAtIso == null ? null : DateTime.tryParse(lastSentAtIso!);

  Map<String, dynamic> toMap() {
    return {
      'friendId': friendId,
      'friendName': friendName,
      'friendUsername': friendUsername,
      'streakCount': streakCount,
      'lastSentAt': lastSentAtIso,
      'pendingCount': pendingCount,
    };
  }

  factory FriendStreak.fromMap(Map<String, dynamic> map) {
    return FriendStreak(
      friendId: map['friendId'] ?? '',
      friendName: map['friendName'] ?? 'Friend',
      friendUsername: map['friendUsername'] ?? '',
      streakCount: map['streakCount'] ?? 0,
      lastSentAtIso: map['lastSentAt'],
      pendingCount: map['pendingCount'] ?? 0,
    );
  }
}

class StudySnap {
  StudySnap({
    required this.id,
    required this.senderUid,
    required this.senderName,
    required this.friendId,
    required this.friendName,
    required this.imageUrl,
    required this.createdAtIso,
    required this.dayKey,
    this.caption,
    this.emoji,
    this.viewedAtIso,
  });

  final String id;
  final String senderUid;
  final String senderName;
  final String friendId;
  final String friendName;
  final String imageUrl;
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
      'senderUid': senderUid,
      'senderName': senderName,
      'friendId': friendId,
      'friendName': friendName,
      'imageUrl': imageUrl,
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
      senderUid: map['senderUid'] ?? '',
      senderName: map['senderName'] ?? 'Someone',
      friendId: map['friendId'] ?? '',
      friendName: map['friendName'] ?? 'Friend',
      imageUrl: map['imageUrl'] ?? '',
      createdAtIso: map['createdAt'] ?? DateTime.now().toIso8601String(),
      dayKey: map['dayKey'] ?? '',
      caption: map['caption'],
      emoji: map['emoji'],
      viewedAtIso: map['viewedAt'],
    );
  }
}

class FriendContact {
  const FriendContact({
    required this.id,
    required this.name,
    required this.username,
  });

  final String id;
  final String name;
  final String username;
}
