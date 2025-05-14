import 'package:sqflite/sqflite.dart';
import 'package:trainings_app/models/exercise.dart';
import 'package:trainings_app/training_database.dart';

class ExerciseManager{
   final ExerciseDatabase _db;

  ExerciseManager(this._db);

  Future<List<Exercise>> getExercises() async {
    final db = await _db.database;
    final result = await db.query('exercises');
    return result.map((json) => Exercise.fromJson(json)).toList();
  }

  Future<bool> exerciseExists(String id) async {
    final db = await _db.database;
    final result = await db.query(
      'exercises',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty;
  }

  Future<void> insertExercises(List<Exercise> exercises) async {
    final db = await _db.database;
    final batch = db.batch();
    for (var exercise in exercises) {
      batch.insert('exercises', exercise.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit();
  }
}