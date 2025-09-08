import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/tip_model.dart';
import '../../models/device_usage_model.dart';
import '../../models/weather_model.dart';
import '../../../core/constants/app_constants.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(AppConstants.databaseName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Tips table
    await db.execute('''
      CREATE TABLE tips (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        type TEXT NOT NULL,
        context TEXT,
        created_at TEXT NOT NULL,
        displayed_at TEXT,
        is_read INTEGER NOT NULL DEFAULT 0,
        priority INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Device usage table
    await db.execute('''
      CREATE TABLE device_usage (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        unlock_count INTEGER NOT NULL,
        screen_time_minutes INTEGER NOT NULL,
        app_usage_minutes TEXT NOT NULL,
        peak_usage_time TEXT NOT NULL,
        is_weekend INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Weather data table
    await db.execute('''
      CREATE TABLE weather_data (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        temperature REAL NOT NULL,
        humidity REAL NOT NULL,
        condition TEXT NOT NULL,
        description TEXT NOT NULL,
        uv_index REAL NOT NULL,
        wind_speed REAL NOT NULL,
        location TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');

    // User preferences table
    await db.execute('''
      CREATE TABLE user_preferences (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
    if (oldVersion < 2) {
      // Add new columns or tables for version 2
    }
  }

  // Tips CRUD operations
  Future<int> insertTip(TipModel tip) async {
    final db = await instance.database;
    return await db.insert('tips', {
      'title': tip.title,
      'content': tip.content,
      'type': tip.type.name,
      'context': tip.context != null ? json.encode(tip.context) : null,
      'created_at': tip.createdAt.toIso8601String(),
      'displayed_at': tip.displayedAt?.toIso8601String(),
      'is_read': tip.isRead ? 1 : 0,
      'priority': tip.priority,
    });
  }

  Future<List<TipModel>> getAllTips() async {
    final db = await instance.database;
    final result = await db.query('tips', orderBy: 'created_at DESC');
    return result.map((json) => _tipFromMap(json)).toList();
  }

  Future<List<TipModel>> getTipsByType(TipType type) async {
    final db = await instance.database;
    final result = await db.query(
      'tips',
      where: 'type = ?',
      whereArgs: [type.name],
      orderBy: 'created_at DESC',
    );
    return result.map((json) => _tipFromMap(json)).toList();
  }

  Future<int> updateTip(TipModel tip) async {
    final db = await instance.database;
    return await db.update(
      'tips',
      {
        'title': tip.title,
        'content': tip.content,
        'type': tip.type.name,
        'context': tip.context != null ? json.encode(tip.context) : null,
        'displayed_at': tip.displayedAt?.toIso8601String(),
        'is_read': tip.isRead ? 1 : 0,
        'priority': tip.priority,
      },
      where: 'id = ?',
      whereArgs: [tip.id],
    );
  }

  Future<int> deleteTip(int id) async {
    final db = await instance.database;
    return await db.delete('tips', where: 'id = ?', whereArgs: [id]);
  }

  // Device usage CRUD operations
  Future<int> insertDeviceUsage(DeviceUsageModel usage) async {
    final db = await instance.database;
    return await db.insert('device_usage', {
      'date': usage.date.toIso8601String().split('T')[0],
      'unlock_count': usage.unlockCount,
      'screen_time_minutes': usage.screenTimeMinutes,
      'app_usage_minutes': json.encode(usage.appUsageMinutes),
      'peak_usage_time': usage.peakUsageTime,
      'is_weekend': usage.isWeekend ? 1 : 0,
      'created_at': usage.createdAt.toIso8601String(),
    });
  }

  Future<List<DeviceUsageModel>> getDeviceUsageByDateRange(
      DateTime start, DateTime end) async {
    final db = await instance.database;
    final result = await db.query(
      'device_usage',
      where: 'date >= ? AND date <= ?',
      whereArgs: [
        start.toIso8601String().split('T')[0],
        end.toIso8601String().split('T')[0],
      ],
      orderBy: 'date DESC',
    );
    return result.map((json) => _deviceUsageFromMap(json)).toList();
  }

  // Weather data operations
  Future<int> insertWeatherData(WeatherModel weather) async {
    final db = await instance.database;
    return await db.insert('weather_data', {
      'temperature': weather.temperature,
      'humidity': weather.humidity,
      'condition': weather.condition,
      'description': weather.description,
      'uv_index': weather.uvIndex,
      'wind_speed': weather.windSpeed,
      'location': weather.location,
      'timestamp': weather.timestamp.toIso8601String(),
    });
  }

  Future<WeatherModel?> getLatestWeatherData() async {
    final db = await instance.database;
    final result = await db.query(
      'weather_data',
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    if (result.isNotEmpty) {
      return _weatherFromMap(result.first);
    }
    return null;
  }

  // Helper methods to convert from Map to Model
  TipModel _tipFromMap(Map<String, dynamic> map) {
    // Parse context từ string JSON hoặc Map
    Map<String, dynamic>? context;
    if (map['context'] != null) {
      try {
        if (map['context'] is String) {
          // Parse từ JSON string
          final decoded = json.decode(map['context'] as String);
          if (decoded is Map) {
            context = Map<String, dynamic>.from(decoded);
          }
        } else if (map['context'] is Map) {
          // Nếu đã là Map
          context = Map<String, dynamic>.from(map['context'] as Map);
        }
      } catch (e) {
        print('Error parsing tip context: $e');
        context = null;
      }
    }

    return TipModel(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      type: TipType.values.firstWhere((e) => e.name == map['type']),
      context: context,
      createdAt: DateTime.parse(map['created_at']),
      displayedAt: map['displayed_at'] != null
          ? DateTime.parse(map['displayed_at'])
          : null,
      isRead: map['is_read'] == 1,
      priority: map['priority'],
    );
  }

  DeviceUsageModel _deviceUsageFromMap(Map<String, dynamic> map) {
    // Parse app_usage_minutes từ string JSON
    Map<String, int> appUsageMinutes = {};
    if (map['app_usage_minutes'] != null) {
      try {
        if (map['app_usage_minutes'] is String) {
          // Parse từ JSON string
          final decoded = json.decode(map['app_usage_minutes'] as String);
          if (decoded is Map) {
            appUsageMinutes = Map<String, int>.from(decoded);
          }
        } else if (map['app_usage_minutes'] is Map) {
          // Nếu đã là Map
          appUsageMinutes = Map<String, int>.from(map['app_usage_minutes'] as Map);
        }
      } catch (e) {
        print('Error parsing app_usage_minutes: $e');
        appUsageMinutes = {};
      }
    }

    return DeviceUsageModel(
      id: map['id'],
      date: DateTime.parse(map['date']),
      unlockCount: map['unlock_count'],
      screenTimeMinutes: map['screen_time_minutes'],
      appUsageMinutes: appUsageMinutes,
      peakUsageTime: map['peak_usage_time'],
      isWeekend: map['is_weekend'] == 1,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  WeatherModel _weatherFromMap(Map<String, dynamic> map) {
    return WeatherModel(
      temperature: map['temperature'],
      humidity: map['humidity'],
      condition: map['condition'],
      description: map['description'],
      uvIndex: map['uv_index'],
      windSpeed: map['wind_speed'],
      location: map['location'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
