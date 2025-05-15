import 'package:flutter/material.dart';
import 'package:gif/gif.dart';
import 'package:trainings_app/features/appbar/training-appbar.dart';
import 'package:trainings_app/features/my-trainings-page/views/completion_screen.dart';

class TrainingScreen extends StatefulWidget {
  final List<Map<String, dynamic>> exercises;
  final String workoutTitle;

  const TrainingScreen(
      {super.key, required this.exercises, required this.workoutTitle});
  @override
  State<StatefulWidget> createState() => TrainingScreenState();
}

class TrainingScreenState extends State<TrainingScreen> {
  final DateTime? _startTime = DateTime.now();
  int _currentExerciseIndex = 0;
  bool get _isLastExercise =>
      _currentExerciseIndex == widget.exercises.length - 1;

  void _nextExercise() {
    if (_isLastExercise) {
      _completeTraining();
    } else {
      setState(() => _currentExerciseIndex++);
    }
  }

  void _completeTraining() {
    final duration = DateTime.now().difference(_startTime!);
    double totalCalories = 0.0;
    for (var exercise in widget.exercises) {
      final reps = exercise['reps'] as int;
      final caloriesPerRep = exercise['ccals'] as double;
      totalCalories += reps * caloriesPerRep;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => CompletionScreen(
          caloriesBurned: totalCalories,
          duration: duration,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exercise = widget.exercises[_currentExerciseIndex];
    final isLastExercise = _currentExerciseIndex == widget.exercises.length - 1;
    double _caloriesBurned = 0.0;

    return Scaffold(
      appBar: TrainingAppBar(title: widget.workoutTitle),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Container(
                    height: 250,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Gif(
                      image: AssetImage(exercise['image_url']),
                      autostart:
                          Autostart.loop,
                      fit: BoxFit.contain,
                      placeholder: (context) => const Center(
                        child: Icon(Icons.fitness_center, size: 30),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    exercise['name'],
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    exercise['description'],
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Повторений: ${exercise['reps']}',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: Theme.of(context).primaryColor),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _nextExercise,
              child: Text(isLastExercise
                  ? 'Завершить тренировку'
                  : 'Следующее упражнение'),
            ),
          ),
        ],
      ),
    );
  }
}
