class DeviceUsageModel {
  final int? id;
  final DateTime date;
  final int unlockCount;
  final int screenTimeMinutes;
  final Map<String, int> appUsageMinutes;
  final String peakUsageTime; // morning, afternoon, evening, night
  final bool isWeekend;
  final DateTime createdAt;

  const DeviceUsageModel({
    this.id,
    required this.date,
    required this.unlockCount,
    required this.screenTimeMinutes,
    required this.appUsageMinutes,
    required this.peakUsageTime,
    required this.isWeekend,
    required this.createdAt,
  });

  factory DeviceUsageModel.fromJson(Map<String, dynamic> json) {
    return DeviceUsageModel(
      id: json['id'] as int?,
      date: DateTime.parse(json['date'] as String),
      unlockCount: json['unlockCount'] as int,
      screenTimeMinutes: json['screenTimeMinutes'] as int,
      appUsageMinutes: Map<String, int>.from(json['appUsageMinutes'] as Map),
      peakUsageTime: json['peakUsageTime'] as String,
      isWeekend: json['isWeekend'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'unlockCount': unlockCount,
      'screenTimeMinutes': screenTimeMinutes,
      'appUsageMinutes': appUsageMinutes,
      'peakUsageTime': peakUsageTime,
      'isWeekend': isWeekend,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  DeviceUsageModel copyWith({
    int? id,
    DateTime? date,
    int? unlockCount,
    int? screenTimeMinutes,
    Map<String, int>? appUsageMinutes,
    String? peakUsageTime,
    bool? isWeekend,
    DateTime? createdAt,
  }) {
    return DeviceUsageModel(
      id: id ?? this.id,
      date: date ?? this.date,
      unlockCount: unlockCount ?? this.unlockCount,
      screenTimeMinutes: screenTimeMinutes ?? this.screenTimeMinutes,
      appUsageMinutes: appUsageMinutes ?? this.appUsageMinutes,
      peakUsageTime: peakUsageTime ?? this.peakUsageTime,
      isWeekend: isWeekend ?? this.isWeekend,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
