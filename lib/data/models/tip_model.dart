enum TipType {
  daily,
  morning,
  afternoon,
  evening,
  night,
  healthWellness,
  workProductivity,
  weatherSpecific,
  contextWeather,
  contextTime,
  moodGuess,
  weekly,
}

class TipModel {
  final int? id;
  final String title;
  final String content;
  final TipType type;
  final Map<String, dynamic>? context;
  final DateTime createdAt;
  final DateTime? displayedAt;
  final bool isRead;
  final int priority;

  const TipModel({
    this.id,
    required this.title,
    required this.content,
    required this.type,
    this.context,
    required this.createdAt,
    this.displayedAt,
    this.isRead = false,
    this.priority = 1,
  });

  factory TipModel.fromJson(Map<String, dynamic> json) {
    return TipModel(
      id: json['id'] as int?,
      title: json['title'] as String,
      content: json['content'] as String,
      type: TipType.values.firstWhere((e) => e.name == json['type']),
      context: json['context'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      displayedAt: json['displayedAt'] != null
          ? DateTime.parse(json['displayedAt'] as String)
          : null,
      isRead: json['isRead'] as bool? ?? false,
      priority: json['priority'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'type': type.name,
      'context': context,
      'createdAt': createdAt.toIso8601String(),
      'displayedAt': displayedAt?.toIso8601String(),
      'isRead': isRead,
      'priority': priority,
    };
  }

  TipModel copyWith({
    int? id,
    String? title,
    String? content,
    TipType? type,
    Map<String, dynamic>? context,
    DateTime? createdAt,
    DateTime? displayedAt,
    bool? isRead,
    int? priority,
  }) {
    return TipModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      context: context ?? this.context,
      createdAt: createdAt ?? this.createdAt,
      displayedAt: displayedAt ?? this.displayedAt,
      isRead: isRead ?? this.isRead,
      priority: priority ?? this.priority,
    );
  }
}
