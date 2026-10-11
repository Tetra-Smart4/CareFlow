class CfNotification {
  final String id;
  final String? userId;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  const CfNotification({
    required this.id,
    this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory CfNotification.fromJson(Map<String, dynamic> json) {
    return CfNotification(
      id: (json['id'] ?? '').toString(),
      userId: json['user_id']?.toString(),
      title: (json['title'] ?? 'Notification').toString(),
      message: (json['body'] ?? json['message'] ?? '').toString(),
      type: (json['type'] ?? 'general').toString(),
      isRead: json['is_read'] == true,
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (userId != null) 'user_id': userId,
      'title': title,
      'body': message,
      'type': type,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
