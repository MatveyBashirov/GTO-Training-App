import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:FitnessPlus/models/exercise.dart';

class ExerciseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Exercise>> getExercises() async {
    final response = await _supabase
        .from('exercises')
        .select('*')
        .order('name');  // Сортировка по имени

    return (response as List).map((e) => Exercise.fromJson(e)).toList();
  }

  // Фильтр по категории
  Future<List<Exercise>> getExercisesByCategory(int categoryId) async {
    final response = await _supabase
        .from('exercises')
        .select('*')
        .eq('category', categoryId);  // WHERE category = categoryId

    return (response as List).map((e) => Exercise.fromJson(e)).toList();
  }
}