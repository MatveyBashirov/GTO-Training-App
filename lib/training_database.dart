import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trainings_app/models/user_data.dart';
import 'package:trainings_app/services/auth_service.dart';
import 'package:trainings_app/services/database/exercise_manager.dart';
import 'package:trainings_app/services/database/user_stats_manager.dart';
import 'package:trainings_app/services/database/workout_manager.dart';

class ExerciseDatabase {
  static final ExerciseDatabase instance = ExerciseDatabase._init();
  static Database? _database;
  final AuthService _authService = AuthService(Supabase.instance.client);
  final SupabaseClient _supabase = Supabase.instance.client;

  late final ExerciseManager exerciseManager;
  late final WorkoutManager workoutManager;
  late final UserStatsManager userStatsManager;

  ExerciseDatabase._init(){
    exerciseManager = ExerciseManager(this);
    workoutManager = WorkoutManager(this);
    userStatsManager = UserStatsManager(this, _authService, _supabase);
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('exercises.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = join(await getDatabasesPath(), filePath);
    return await openDatabase(
      dbPath,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE exercises (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        image_url TEXT,
        category INTEGER,
        ccals FLOAT,
        FOREIGN KEY (category) REFERENCES categories (id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE workouts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE workout_exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workout_id INTEGER NOT NULL,
        exercise_id INTEGER NOT NULL,
        reps INTEGER NOT NULL DEFAULT 10,
        order_index INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (workout_id) REFERENCES workouts (id) ON DELETE CASCADE,
        FOREIGN KEY (exercise_id) REFERENCES exercises (id) ON DELETE CASCADE,
        UNIQUE (workout_id, exercise_id, order_index) ON CONFLICT REPLACE
      )
    ''');

    await db.execute('''
    CREATE TABLE user_fitness_data (
      date TEXT PRIMARY KEY NOT NULL DEFAULT (strftime('%Y-%m-%d', 'now', 'localtime')),
        workout_count INTEGER,
        calories_burned REAL,
        weight REAL
    )
  ''');

  await db.execute('''
          CREATE TABLE sync_status (
            date TEXT PRIMARY KEY,
            synced INTEGER NOT NULL DEFAULT 0
          )
        ''');

    await _insertInitialData(db);
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS workout_exercises');
      await db.execute('DROP TABLE IF EXISTS workouts');
      await db.execute('DROP TABLE IF EXISTS exercises');
      await db.execute('DROP TABLE IF EXISTS categories');
      await _createDB(db, newVersion);
    }
    if (oldVersion < 3) {
      await db.execute('''
      CREATE TABLE user_fitness_data (
        date TEXT PRIMARY KEY NOT NULL DEFAULT (strftime('%Y-%m-%d', 'now', 'localtime')),
        workout_count INTEGER,
        calories_burned REAL,
        weight REAL
      )
    ''');
    }
    try {
      await db.execute('ALTER TABLE exercises ADD COLUMN ccals FLOAT');
    } catch (e) {
      print('Столбец ccals уже существует или не может быть добавлен: $e');
    }
  }

  Future<void> _insertInitialData(Database db) async {
    final count = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM workouts')) ??
        0;

    if (count > 0) return; // Данные уже есть

    // Загружаем данные из JSON
    final exercises = await _loadJsonData('assets/initial_data/exercises.json');
    final categories =
        await _loadJsonData('assets/initial_data/categories.json');
    final workouts = await _loadJsonData('assets/initial_data/workout.json');
    final workout_exercises =
        await _loadJsonData('assets/initial_data/workout_exercise.json');

    // Вставляем категории
    final categoryBatch = db.batch();
    for (final category in categories) {
      categoryBatch.insert('categories', {
        'id': category['id'],
        'name': category['name'],
      });
    }
    await categoryBatch.commit();

    final exerciseBatch = db.batch();
    for (final exercise in exercises) {
      exerciseBatch.insert('exercises', {
        'id': exercise['id'],
        'name': exercise['name'],
        'description': exercise['description'],
        'image_url': exercise['image_url'],
        'category': exercise['category'],
        'ccals': exercise['ccals']
      });
    }
    await exerciseBatch.commit();

    final workoutBatch = db.batch();
    for (final workout in workouts) {
      workoutBatch.insert('workouts', {
        'id': workout['id'],
        'title': workout['title'],
      });
    }
    await workoutBatch.commit();

    final workoutExercisesBatch = db.batch();
    for (final workoutExercise in workout_exercises) {
      workoutExercisesBatch.insert('workout_exercises', {
        'workout_id': workoutExercise['workout_id'],
        'exercise_id': workoutExercise['exercise_id'],
        'reps': workoutExercise['reps'],
        'order_index': workoutExercise['order_index'],
      });
    }
    await workoutExercisesBatch.commit();
  }

  Future<List<Map<String, dynamic>>> _loadJsonData(String path) async {
    try {
      final str = await rootBundle.loadString(path);
      final decodedData = jsonDecode(str);
      if (decodedData is List) {
        return decodedData.map((item) => item as Map<String, dynamic>).toList();
      } else {
        print('Error: $path is not a list');
        return [];
      }
    } catch (e) {
      print('Error loading JSON from $path: $e');
      return [];
    }
  }

  // Проверка - пустая ли база данных (для первоначальной загрузки).
  Future<bool> isDatabaseEmpty() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM exercises');
    final count = Sqflite.firstIntValue(result);
    return count == 0;
  }
}
