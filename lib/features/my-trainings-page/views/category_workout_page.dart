import 'package:flutter/material.dart';
import 'package:trainings_app/features/appbar/training-appbar.dart';
import 'package:trainings_app/features/homepage/widgets/training-card.dart';
import 'package:trainings_app/training_database.dart';

class CategoryWorkoutsPage extends StatefulWidget {
  final int categoryId;
  final String categoryName;

  const CategoryWorkoutsPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<CategoryWorkoutsPage> createState() => _CategoryWorkoutsPageState();
}

class _CategoryWorkoutsPageState extends State<CategoryWorkoutsPage> {

  final ExerciseDatabase dbHelper = ExerciseDatabase.instance;
  List<Map<String, dynamic>> workouts = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  Future<void> _loadWorkouts() async {
    setState(() => isLoading = true);
    try {
      workouts = await dbHelper.workoutManager.getWorkoutsByCategory(widget.categoryId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки тренировок: $e')),
      );
      workouts = [];
    } finally {
      setState(() => isLoading = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: TrainingAppBar(title: widget.categoryName),
      body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : workouts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Нет тренировок в этой категории',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onBackground.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadWorkouts,
                          child: const Text('Попробовать снова'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: workouts.length,
                    itemBuilder: (context, index) {
                      final workout = workouts[index];
                      return AnimatedOpacity(
                        opacity: 1.0,
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOut,
                        child: TrainingCard(
                          title: workout['title'],
                          workoutId: workout['id'],
                          categoryId: workout['category'],
                          onDeleted: () async {
                            await dbHelper.workoutManager.deleteWorkout(workout['id']);
                            await _loadWorkouts();
                          },
                        ),
                      );
                    },
                  ),
    );
  }

}