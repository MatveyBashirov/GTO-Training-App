import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:FitnessPlus/features/appbar/training-appbar.dart';
import 'package:FitnessPlus/features/my-trainings-page/views/exercise_info.dart';
import 'package:FitnessPlus/features/my-trainings-page/views/training_screen.dart';
import 'package:FitnessPlus/training_database.dart';
import 'package:gif/gif.dart';

class WorkoutExercisesPage extends StatefulWidget {
  final int workoutId;

  const WorkoutExercisesPage({super.key, required this.workoutId});

  @override
  State<WorkoutExercisesPage> createState() => _WorkoutExercisesPageState();
}

class _WorkoutExercisesPageState extends State<WorkoutExercisesPage>
    with SingleTickerProviderStateMixin {
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

    final workout = await dbHelper.workoutManager.getWorkout(widget.workoutId);
    if (workout != null) {
      workoutTitle = workout['title'];
    }

    workoutExercises = await dbHelper.workoutManager.getWorkoutExercises(widget.workoutId);

    setState(() => isLoading = false);
  }

  Future<bool> _checkInternetConnection() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  void _startWorkout() async {
    bool isConnected = await _checkInternetConnection();
    if (!isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Для прохождения тренировки необходимо подключение к интернету'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrainingScreen(
          exercises: workoutExercises,
          workoutTitle: workoutTitle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TrainingAppBar(title: workoutTitle),
      body: isLoading
        ? const Center(child: CircularProgressIndicator())
        : workoutExercises.isEmpty
            ? const Center(child: Text('Нет упражнений для этой тренировки'))
            : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: workoutExercises.length,
                      itemBuilder: (context, index) {
                        final exercise = workoutExercises[index];
                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ExerciseInfo(
                                  exerciseName: exercise['name'],
                                  description: exercise['description'],
                                  imageUrl: exercise['image_url'],
                                ),
                              ),
                            );
                          },
                          child: Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    clipBehavior: Clip.antiAlias,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Gif(
                                      image: AssetImage(exercise['image_url']),
                                      controller: _controller,
                                      autostart: Autostart.no,
                                      placeholder: (context) => Center(
                                        child: Icon(Icons.fitness_center, size: 30),
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          exercise['name'],
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Повторения: ${exercise['reps']}',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: workoutExercises.isNotEmpty
                          ? _startWorkout
                          : null,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('Начать тренировку'),
                    ),
                  ),
                ],
              ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
