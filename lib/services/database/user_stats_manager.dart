import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:FitnessPlus/models/user_data.dart';
import 'package:FitnessPlus/services/auth_service.dart';
import 'package:FitnessPlus/training_database.dart';

class UserStatsManager {
  final ExerciseDatabase _db;
  final AuthService _authService;
  final SupabaseClient _supabase;

  UserStatsManager(this._db, this._authService, this._supabase){initStats();}

  Future<void> initStats() async {
    final user = _authService.getCachedSession();
    if (user != null) {
      await _syncPendingOperations();
    }
    _authService.authStateChanges.listen((authState) async {
      if (authState.event == AuthChangeEvent.signedIn) {
        await _syncWithSupabase();
        await _syncPendingOperations();
      } else if (authState.event == AuthChangeEvent.signedOut) {
        await _clearLocalStats();
      }
    });

    Connectivity().onConnectivityChanged.listen((result) async {
      if (result != ConnectivityResult.none) {
        await _syncPendingOperations();
      }
    });
  }

  Future<bool> _isOnline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<void> _syncPendingOperations() async {
    final userId = _authService.currentUser?.id;
    if (userId == null || !await _isOnline()) return;

    final db = await _db.database;
    final pending = await db.query('pending_sync', where: 'table_name = ?', whereArgs: ['user_fitness_data']);
    
    final batch = db.batch();
    for (var item in pending) {
      final operation = item['operation'] as String;
      final data = jsonDecode(item['data'] as String) as Map<String, dynamic>;
      
      try {
        if (operation == 'insert') {
          await _supabase.from('user_stats').upsert({
            'user_id': userId,
            'date': data['date'],
            'workout_count': data['workout_count'],
            'calories_burned': data['calories_burned'],
            'weight': data['weight'],
            'points': data['points'],
          });
        } else if (operation == 'delete') {
          await _supabase.from('user_stats').delete().eq('user_id', userId).eq('date', data['date']);
        }
        batch.delete('pending_sync', where: 'id = ?', whereArgs: [item['id']]);
      } catch (e) {
        print('Error syncing operation ${item['id']}: $e');
      }
    }
    await batch.commit();
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

    await db.insert(
      'pending_sync',
      {
        'operation': 'insert',
        'table_name': 'user_fitness_data',
        'data': jsonEncode(stats.toMap()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    if (await _isOnline()) {
      await _syncPendingOperations();
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

  Future<double> getTotalPoints() async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return 0;

    final stats = await getStats(DateTime(2000), DateTime.now());
    double total = 0;
    for (var stat in stats) {
      total += stat.points ?? 0;
    }
    return total;
  }
}
