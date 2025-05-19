import 'package:sqflite/sqflite.dart';
import 'package:trainings_app/training_database.dart';

class WorkoutManager {
  final ExerciseDatabase _db;

  WorkoutManager(this._db);

  Future<int> createWorkout(
      {required String title, required int category}) async {
    final db = await _db.database;
    return await db.insert('workouts', {'title': title, 'category': category});
  }

  Future<int> insertWorkoutExercise({
    required int workoutId,
    required int exerciseId,
    required int reps,
    required int orderIndex,
  }) async {
    final db = await _db.database;
    return await db.insert(
      'workout_exercises',
      {
        'workout_id': workoutId,
        'exercise_id': exerciseId,
        'reps': reps,
        'order_index': orderIndex,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getWorkoutExercises(int workoutId) async {
    final db = await _db.database;
    return await db.rawQuery('''
      SELECT 
        e.id,
        e.name,
        e.description,
        e.image_url,
        e.category,
        e.ccals,
        we.reps,
        we.order_index
      FROM workout_exercises we
      JOIN exercises e ON we.exercise_id = e.id
      WHERE we.workout_id = ?
      ORDER BY we.order_index ASC
    ''', [workoutId]);
  }

  Future<List<Map<String, dynamic>>> getAllWorkouts() async {
    final db = await _db.database;
    return await db.query('workouts');
  }

  Future<Map<String, dynamic>?> getWorkout(int id) async {
    final db = await _db.database;
    final result = await db.query(
      'workouts',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<List<Map<String, dynamic>>> getWorkoutsByCategory(
      int categoryId) async {
    final db = await _db.database;
    return await db.query(
      'workouts',
      where: 'category = ?',
      whereArgs: [categoryId],
    );
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final db = await _db.database;
    return await db.query('categories');
  }

  Future<int> updateWorkout(
      {required int id, required String title, required int category}) async {
    final db = await _db.database;
    return await db.update(
      'workouts',
      {'title': title, 'category': category},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteWorkout(int id) async {
    final db = await _db.database;
    return await db.delete(
      'workouts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteWorkoutExercises(int workoutId) async {
    final db = await _db.database;
    return await db.delete(
      'workout_exercises',
      where: 'workout_id = ?',
      whereArgs: [workoutId],
    );
  }

  Future<int> removeExerciseFromWorkout({
    required int workoutId,
    required int exerciseId,
    required int orderIndex,
  }) async {
    final db = await _db.database;
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
    final db = await _db.database;
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
}
