import 'package:flutter/material.dart';
import 'package:trainings_app/models/exercise.dart';
import 'package:trainings_app/features/appbar/training-appbar.dart';
import 'package:trainings_app/training_database.dart';
import 'package:gif/gif.dart';

class ExercisesPage extends StatefulWidget {
  const ExercisesPage({super.key});
  @override
  _ExercisesPageState createState() => _ExercisesPageState();
}

class _ExercisesPageState extends State<ExercisesPage>
    with SingleTickerProviderStateMixin {
  final ExerciseDatabase dbHelper = ExerciseDatabase.instance;
  List<Exercise> exercises = [];
  bool isLoading = false;
  Set<int> selectedExercises = {};
  late final GifController _controller;

  @override
  void initState() {
    _loadExercises();
    _controller = GifController(vsync: this);
    _controller.value = 0;
    super.initState();
  }

  Future<void> _loadExercises() async {
    setState(() => isLoading = true);
    try {
      exercises = await dbHelper.getExercises();
    } catch (e) {
      print('Error loading exercises: $e');
      exercises = [];
    }
    setState(() => isLoading = false);
  }

  void _toggleExerciseSelection(int exerciseId) {
    setState(() {
      if (selectedExercises.contains(exerciseId)) {
        selectedExercises.remove(exerciseId);
      } else {
        selectedExercises.add(exerciseId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: TrainingAppBar(title: 'Доступные упражнения'),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : exercises.isEmpty
              ? Center(child: Text('Нет упражнений'))
              : ListView.builder(
                  itemCount: exercises.length,
                  itemBuilder: (context, index) {
                    final exercise = exercises[index];
                    final isSelected = selectedExercises.contains(exercise.id);
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Row(
                          children: [
                            // Изображение (первый кадр GIF)
                            Container(
                              width: 60, // Фиксированная ширина
                              height: 60, // Фиксированная высота
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Gif(
                                image: AssetImage(exercise.imageUrl),
                                controller: _controller,
                                autostart: Autostart.no,
                                placeholder: (context) => Center(
                                  child: Icon(Icons.fitness_center, size: 30),
                                ),
                                fit: BoxFit.cover, // Заполнение контейнера
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    exercise.name,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Кнопка "+" / галочка
                            IconButton(
                              icon: isSelected
                                  ? Icon(Icons.check, color: Colors.green)
                                  : Icon(Icons.add,
                                      color: theme.colorScheme.primary),
                              onPressed: () =>
                                  _toggleExerciseSelection(exercise.id),
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
