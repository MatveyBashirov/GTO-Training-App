import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trainings_app/models/user_data.dart';
import 'package:trainings_app/services/auth_service.dart';
import 'package:trainings_app/training_database.dart';

class UserStatsManager {
  final ExerciseDatabase _db;
  final AuthService _authService;
  final SupabaseClient _supabase;

  UserStatsManager(this._db, this._authService, this._supabase);

  Future<void> initStats() async {
    final user = _authService.currentUser;
    if (user != null) {
      await _syncWithSupabase();
    }

    // Подписываемся на изменения состояния аутентификации
    _authService.authStateChanges.listen((authState) {
      if (authState.event == AuthChangeEvent.signedIn) {
        _syncWithSupabase();
      } else if (authState.event == AuthChangeEvent.signedOut) {
        _clearLocalStats();
      }
    });
  }

  Future<void> _syncWithSupabase() async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return;

    try {
      final data =
          await _supabase.from('user_stats').select().eq('user_id', userId);

      final db = await _db.database;
      final batch = db.batch();
      for (var item in data) {
        final stat = UserStats.fromJson(item);
        batch.insert(
          'user_fitness_data',
          stat.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit();
    } catch (e) {
      print('Error syncing with Supabase: $e');
    }
  }

  Future<void> _clearLocalStats() async {
    final db = await _db.database;
    await db.delete('user_fitness_data');
  }

  Future<void> saveStats(UserStats stats) async {
    final userId = _authService.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final db = await _db.database;
    await db.insert(
      'user_fitness_data',
      stats.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    try {
      await _supabase.from('user_stats').upsert({
        'user_id': userId,
        'date': stats.date.toIso8601String(),
        'workout_count': stats.workoutCount,
        'calories_burned': stats.caloriesBurned,
        'weight': stats.weight,
        'points': stats.points,
      });
    } catch (e) {
      print('Error saving to Supabase: $e');
    }
  }

  Future<List<UserStats>> getStats(DateTime start, DateTime end) async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return [];

    List<UserStats> stats = [];
    final db = await _db.database;
    final localResult = await db.query(
      'user_fitness_data',
      where: 'date >= ? AND date <= ?',
      whereArgs: [
        start.toIso8601String().substring(0, 10),
        end.toIso8601String().substring(0, 10),
      ],
    );
    stats = localResult.map((map) => UserStats.fromMap(map)).toList();

    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      try {
        final data = await _supabase
            .from('user_stats')
            .select()
            .eq('user_id', userId)
            .gte('date', start.toIso8601String().substring(0, 10))
            .lte('date', end.toIso8601String().substring(0, 10));

        final supabaseStats =
            data.map((item) => UserStats.fromJson(item)).toList();

        final batch = db.batch();
        for (var stat in supabaseStats) {
          batch.insert(
            'user_fitness_data',
            stat.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit();

        stats = supabaseStats;
      } catch (e) {
        print('Error fetching from Supabase: $e');
      }
    }

    final filledStats = <UserStats>[];
    for (var day = start;
        day.isBefore(end) || day.isAtSameMomentAs(end);
        day = day.add(Duration(days: 1))) {
      final existingStat = stats.firstWhere(
        (stat) =>
            stat.date.day == day.day &&
            stat.date.month == day.month &&
            stat.date.year == day.year,
        orElse: () => UserStats(date: day),
      );
      filledStats.add(existingStat);
    }

    return filledStats;
  }

  Future<bool> isFirstWorkoutToday() async {
    final today = DateTime.now();
    final todayString = today.toIso8601String().substring(0, 10);
    final db = await _db.database;
    final result = await db.query(
      'user_fitness_data',
      where: 'date = ?',
      whereArgs: [todayString],
    );
    if (result.isEmpty) {
      return true;
    }
    final stat = UserStats.fromMap(result.first);
    return stat.workoutCount == 0;
  }

  Future<void> awardPointsForWorkout() async {
    final today = DateTime.now();
    final yesterday = today.subtract(Duration(days: 1));

    final todayStats = await getStats(today, today);
    final yesterdayStats = await getStats(yesterday, yesterday);

    final existingTodayStat =
        todayStats.isNotEmpty ? todayStats.first : UserStats(date: today);
    int currentPoints = existingTodayStat.points ?? 0;

    currentPoints += 1;

    if (yesterdayStats.isNotEmpty &&
        (yesterdayStats.first.workoutCount ?? 0) > 0) {
      currentPoints += 3;
    }

    final updatedStat = UserStats(
      date: today,
      workoutCount: (existingTodayStat.workoutCount ?? 0) + 1,
      caloriesBurned: existingTodayStat.caloriesBurned,
      weight: existingTodayStat.weight,
      points: currentPoints,
    );

    await saveStats(updatedStat);
  }

  Future<int> getTotalPoints() async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return 0;

    final stats = await getStats(DateTime(2000), DateTime.now());
    int total = 0;
    for (var stat in stats) {
      total += stat.points ?? 0;
    }
    return total;
  }
}
