class WeatherModel {
  final double temperature;
  final double humidity;
  final String condition;
  final String description;
  final double uvIndex;
  final double windSpeed;
  final String location;
  final DateTime timestamp;

  const WeatherModel({
    required this.temperature,
    required this.humidity,
    required this.condition,
    required this.description,
    required this.uvIndex,
    required this.windSpeed,
    required this.location,
    required this.timestamp,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      temperature: (json['temperature'] as num).toDouble(),
      humidity: (json['humidity'] as num).toDouble(),
      condition: json['condition'] as String,
      description: json['description'] as String,
      uvIndex: (json['uvIndex'] as num).toDouble(),
      windSpeed: (json['windSpeed'] as num).toDouble(),
      location: json['location'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'condition': condition,
      'description': description,
      'uvIndex': uvIndex,
      'windSpeed': windSpeed,
      'location': location,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  WeatherModel copyWith({
    double? temperature,
    double? humidity,
    String? condition,
    String? description,
    double? uvIndex,
    double? windSpeed,
    String? location,
    DateTime? timestamp,
  }) {
    return WeatherModel(
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      condition: condition ?? this.condition,
      description: description ?? this.description,
      uvIndex: uvIndex ?? this.uvIndex,
      windSpeed: windSpeed ?? this.windSpeed,
      location: location ?? this.location,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
