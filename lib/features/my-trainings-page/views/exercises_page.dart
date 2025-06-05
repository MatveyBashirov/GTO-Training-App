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
  List<Map<String, dynamic>> categories = [];
  int? selectedCategoryId;
  bool isLoading = false;
  late final GifController _controller;

  @override
  void initState() {
    _loadExercises();
    _loadCategories();
    _controller = GifController(vsync: this);
    _controller.value = 0;
    super.initState();
  }

  Future<void> _loadCategories() async {
    setState(() => isLoading = true);
    try {
      categories = await dbHelper.workoutManager.getCategories();
    } catch (e) {
      print('Error loading categories: $e');
      categories = [];
    }
    setState(() => isLoading = false);
  }

  Future<void> _loadExercises() async {
    setState(() => isLoading = true);
    try {
      allExercises = await dbHelper.exerciseManager.getExercises();

      if (widget.workoutId != null) {
        final workout =
            await dbHelper.workoutManager.getWorkout(widget.workoutId!);
        _titleController.text = workout!['title'];

        final workoutExercises = await dbHelper.workoutManager
            .getWorkoutExercises(widget.workoutId!);

        for (final we in workoutExercises) {
          final exercise = Exercise(
            id: we['id'] as int,
            name: we['name'] as String,
            description: we['description'] as String,
            imageUrl: we['image_url'] as String,
            category: we['category'] as int,
            ccals: we['ccals'] as double,
            points: we['points'] as double,
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
      exerciseReps[exerciseId] = reps.clamp(1, 50);
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
    if (selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите категорию тренировки')),
      );
      return;
    }

    try {
      if (widget.workoutId == null) {
        final workoutId = await dbHelper.workoutManager.createWorkout(
          title: _titleController.text,
          category: selectedCategoryId!,
        );

        for (int i = 0; i < selectedExercises.length; i++) {
          final exercise = selectedExercises[i];
          await dbHelper.workoutManager.insertWorkoutExercise(
            workoutId: workoutId,
            exerciseId: exercise.id,
            reps: exerciseReps[exercise.id] ?? 10,
            orderIndex: i,
          );
        }
      } else {
        await dbHelper.workoutManager.updateWorkout(
          id: widget.workoutId!,
          title: _titleController.text,
          category: selectedCategoryId!,
        );

        await dbHelper.workoutManager.deleteWorkoutExercises(widget.workoutId!);

        for (int i = 0; i < selectedExercises.length; i++) {
          final exercise = selectedExercises[i];
          await dbHelper.workoutManager.insertWorkoutExercise(
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
          title: Center(child: const Text('Создать тренировку')),
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveWorkout,
            )
          ],
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
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
                    DropdownButtonFormField<int>(
                        value: selectedCategoryId,
                        decoration: const InputDecoration(
                          labelText: 'Категория тренировки',
                          border: OutlineInputBorder(),
                        ),
                        items: categories.map((category) {
                          return DropdownMenuItem<int>(
                            value: category['id'],
                            child: Text(
                              category['name'],
                              style: TextStyle(
                                color: Colors.black87
                              ),
                              ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedCategoryId = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Выберите категорию';
                          }
                          return null;
                        },
                      ),
                    const SizedBox(height: 26),
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
          ),
        );
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
                  Container(
                    width: 60,
                    height: 60,
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
                      fit: BoxFit.cover,
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

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: 250,
      ),
      child: ListView.builder(
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
      ),
    );
  }
}
