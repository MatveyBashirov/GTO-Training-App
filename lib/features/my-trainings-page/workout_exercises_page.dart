import 'package:flutter/material.dart';
import 'package:trainings_app/features/appbar/training-appbar.dart';
import 'package:trainings_app/training_database.dart';
import 'package:gif/gif.dart';

class WorkoutExercisesPage extends StatefulWidget {
  final int workoutId;

  const WorkoutExercisesPage({super.key, required this.workoutId});

  @override
  State<WorkoutExercisesPage> createState() => _WorkoutExercisesPageState();
}

class _WorkoutExercisesPageState extends State<WorkoutExercisesPage> with SingleTickerProviderStateMixin {
  final ExerciseDatabase dbHelper = ExerciseDatabase.instance;
  List<Map<String, dynamic>> workoutExercises = [];
  String workoutTitle = '';
  bool isLoading = false;
  late GifController _controller;

  @override
  void initState() {
    super.initState();
    _loadWorkoutData();
    _controller = GifController(vsync: this);
    _controller.value = 0;
  }

  Future<void> _loadWorkoutData() async {
    setState(() => isLoading = true);

    // Загружаем название тренировки
    final workout = await dbHelper.getWorkout(widget.workoutId);
    if (workout != null) {
      workoutTitle = workout['title'];
    }

    // Загружаем упражнения для тренировки
    workoutExercises = await dbHelper.getWorkoutExercises(widget.workoutId);

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: TrainingAppBar(title: workoutTitle),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : workoutExercises.isEmpty
              ? Center(child: Text('Нет упражнений для этой тренировки'))
              : ListView.builder(
                  itemCount: workoutExercises.length,
                  itemBuilder: (context, index) {
                    final exercise = workoutExercises[index];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Row(
                          children: [
                            // Изображение (первый кадр GIF)
                            Container(
                              width: 60,
                              height: 60,
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Gif(
                                image: NetworkImage(exercise['image_url']),
                                controller: _controller,
                                autostart: Autostart.no,
                                placeholder: (context) => Center(
                                  child: Icon(Icons.fitness_center, size: 30),
                                ),
                                fit: BoxFit.cover,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    exercise['name'],
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Повторения: ${exercise['reps']}',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}