import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:trainings_app/models/exercise.dart';

class ExerciseDatabase {
  static final ExerciseDatabase instance = ExerciseDatabase._init();
  static Database? _database;

  ExerciseDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('exercises.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = join(await getDatabasesPath(), filePath);
    return await openDatabase(dbPath, version: 2, onCreate: _createDB, onUpgrade: _onUpgrade,);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE exercises (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        image_url TEXT,
        category INTEGER
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

  ///           <--------------------ОПЕРАЦИИ С УПРАЖНЕНИЯМИ---------------------->

  Future<List<Exercise>> getExercises() async {
    final db = await database;
    final result = await db.query('exercises');
    return result.map((json) => Exercise.fromJson(json)).toList();
  }

  Future<bool> exerciseExists(String id) async {
    final db = await instance.database;
    final result = await db.query(
      'exercises',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty;
  }

  Future<void> insertExercises(List<Exercise> exercises) async {
    final db = await database;
    final batch = db.batch();
    for (var exercise in exercises) {
      batch.insert('exercises', exercise.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit();
  }

  ///           <--------------------ОПЕРАЦИИ С ТРЕНИРОВКАМИ---------------------->

  Future<int> createWorkout({
    required String title,
  }) async {
    final db = await database;
    return await db.insert('workouts', {
      'title': title,
    });
  }

  Future<void> addExerciseToWorkout({
    required int workoutId,
    required int exerciseId,
    int reps = 10,
    int orderIndex = 0,
  }) async {
    final db = await database;

    await db.insert(
        'workout_exercises',
        {
          'workout_id': workoutId,
          'exercise_id': exerciseId,
          'reps': reps,
          'order_index': orderIndex,
        },
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getWorkoutExercises(int workoutId) async {
    final db = await database;

    return await db.rawQuery('''
    SELECT 
      e.id,
      e.name,
      e.description,
      e.image_url,
      e.category,
      we.reps,
      we.order_index
    FROM workout_exercises we
    JOIN exercises e ON we.exercise_id = e.id
    WHERE we.workout_id = ?
    ORDER BY we.order_index ASC
  ''', [workoutId]);
  }

  Future<List<Map<String, dynamic>>> getAllWorkouts() async {
    final db = await database;
    return await db.query('workouts');
  }

  Future<Map<String, dynamic>?> getWorkout(int id) async {
    final db = await database;
    final result = await db.query(
      'workouts',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> updateWorkout({
    required int id,
    required String title,
  }) async {
    final db = await database;
    return await db.update(
      'workouts',
      {'title': title},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteWorkout(int id) async {
    final db = await database;
    return await db.delete(
      'workouts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> removeExerciseFromWorkout({
    required int workoutId,
    required int exerciseId,
    required int orderIndex,
  }) async {
    final db = await database;
    return await db.delete(
      'workout_exercises',
      where: 'workout_id = ? AND exercise_id = ? AND order_index = ?',
      whereArgs: [workoutId, exerciseId, orderIndex],
    );
  }

  Future<void> reorderWorkoutExercises({
    required int workoutId,
    required List<int> exerciseIdsInOrder,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      for (int i = 0; i < exerciseIdsInOrder.length; i++) {
        await txn.update(
          'workout_exercises',
          {'order_index': i},
          where: 'workout_id = ? AND exercise_id = ?',
          whereArgs: [workoutId, exerciseIdsInOrder[i]],
        );
      }
    });
  }

  // Проверка - пустая ли база данных (для первоначальной загрузки).
  Future<bool> isDatabaseEmpty() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM exercises');
    final count = Sqflite.firstIntValue(result);
    return count == 0;
  }
}
