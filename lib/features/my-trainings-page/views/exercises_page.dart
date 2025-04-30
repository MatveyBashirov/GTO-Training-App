import 'package:flutter/material.dart';
import 'package:trainings_app/features/my-trainings-page/views/exercise_info.dart';
import 'package:trainings_app/models/exercise.dart';
import 'package:trainings_app/training_database.dart';
import 'package:gif/gif.dart';

class ExercisesPage extends StatefulWidget {
  final int? workoutId;

  const ExercisesPage({super.key, this.workoutId});
  @override
  _ExercisesPageState createState() => _ExercisesPageState();
}

class _ExercisesPageState extends State<ExercisesPage>
    with SingleTickerProviderStateMixin {
  final ExerciseDatabase dbHelper = ExerciseDatabase.instance;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  List<Exercise> allExercises = [];
  List<Exercise> selectedExercises = [];
  Map<int, int> exerciseReps = {};
  bool isLoading = false;
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
      allExercises = await dbHelper.getExercises();

      // Если это редактирование существующей тренировки
      if (widget.workoutId != null) {
        final workout = await dbHelper.getWorkout(widget.workoutId!);
        _titleController.text = workout!['title'];

        final workoutExercises =
            await dbHelper.getWorkoutExercises(widget.workoutId!);

        for (final we in workoutExercises) {
          final exercise = Exercise(
            id: we['id'] as int,
            name: we['name'] as String,
            description: we['description'] as String,
            imageUrl: we['image_url'] as String,
            category: we['category'] as int,
            ccals: we['ccals'] as double,
          );
          selectedExercises.add(exercise);
          exerciseReps[exercise.id] = we['reps'];
        }
      }
    } catch (e) {
      print('Error loading exercises: $e');
      allExercises = [];
    }
    setState(() => isLoading = false);
  }

  void _addExercise(Exercise exercise) {
    setState(() {
      selectedExercises.add(exercise);
    });
  }

  void _removeExercise(Exercise exercise) {
    setState(() {
      selectedExercises.remove(exercise);
      exerciseReps.remove(exercise.id);
    });
  }

  void _updateReps(int exerciseId, int reps) {
    setState(() {
      exerciseReps[exerciseId] = reps;
    });
  }

  Future<void> _saveWorkout() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Добавьте хотя бы одно упражнение')),
      );
      return;
    }

    try {
      if (widget.workoutId == null) {
        final workoutId =
            await dbHelper.createWorkout(title: _titleController.text);

        for (int i = 0; i < selectedExercises.length; i++) {
          final exercise = selectedExercises[i];
          await dbHelper.insertWorkoutExercise(
            workoutId: workoutId,
            exerciseId: exercise.id,
            reps: exerciseReps[exercise.id] ?? 10,
            orderIndex: i,
          );
        }
      } else {
        await dbHelper.updateWorkout(
          id: widget.workoutId!,
          title: _titleController.text,
        );

        // Удаляем все упражнения тренировки
        await dbHelper.deleteWorkoutExercises(widget.workoutId!);

        // Добавляем новые упражнения
        for (int i = 0; i < selectedExercises.length; i++) {
          final exercise = selectedExercises[i];
          await dbHelper.insertWorkoutExercise(
            workoutId: widget.workoutId!,
            exerciseId: exercise.id,
            reps: exerciseReps[exercise.id] ?? 10,
            orderIndex: i,
          );
        }
      }
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка сохранения: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
        appBar: AppBar(
          title: const Text('Создать тренировку'),
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveWorkout,
            )
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                        labelText: 'Название тренировки',
                        border: OutlineInputBorder()),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введите название тренировки';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Выбранные упражнения: ',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: theme.primaryColor),
                  ),
                  _buildSelectedExercisesList(),
                  const Divider(),
                  Text(
                    'Список всех упражнений: ',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: theme.primaryColor),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _buildAllExercisesList(),
                  ),
                ],
              )),
        ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildAllExercisesList() {
    final theme = Theme.of(context);
    if (allExercises.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      itemCount: allExercises.length,
      itemBuilder: (context, index) {
        final exercise = allExercises[index];
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ExerciseInfo(
                  exerciseName: exercise.name,
                  description: exercise.description,
                  imageUrl: exercise.imageUrl,
                ),
              ),
            );
          },
          child: Card(
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
                    icon: Icon(Icons.add, color: theme.colorScheme.primary),
                    onPressed: () => _addExercise(exercise),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectedExercisesList() {
    if (selectedExercises.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text('Нет выбранных упражнений'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: selectedExercises.length,
      itemBuilder: (context, index) {
        final exercise = selectedExercises[index];
        return ListTile(
          title: Text(exercise.name),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () {
                  _updateReps(
                    exercise.id,
                    (exerciseReps[exercise.id] ?? 10) - 1,
                  );
                },
              ),
              Text('${exerciseReps[exercise.id] ?? 10}'),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  _updateReps(
                    exercise.id,
                    (exerciseReps[exercise.id] ?? 10) + 1,
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _removeExercise(exercise),
              ),
            ],
          ),
        );
      },
    );
  }
}
