import 'package:flutter/material.dart';
import 'package:trainings_app/features/appbar/training-appbar.dart';
import 'package:trainings_app/features/homepage/widgets/training-card.dart';
import 'package:trainings_app/features/my-trainings-page/views/exercises_page.dart';
import 'package:trainings_app/training_database.dart';

class SelectWorkoutScreen extends StatefulWidget {
  const SelectWorkoutScreen({super.key});

  @override
  _SelectWorkoutScreenState createState() => _SelectWorkoutScreenState();
}

class _SelectWorkoutScreenState extends State<SelectWorkoutScreen> {
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
    workouts = await dbHelper.workoutManager.getAllWorkouts();
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: TrainingAppBar(title: 'Мои тренировки'),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ExercisesPage()),
          );
          if (result == true) {
            _loadWorkouts();
          }
        },
        backgroundColor: theme.colorScheme.primary,
        tooltip: 'Создать тренировку',
        child: Icon(Icons.add, color: Colors.white),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : workouts.isEmpty
              ? Center(child: Text('Нет тренировок'))
              : ListView.builder(
                padding: const EdgeInsets.only(
                    top: 0,
                    bottom: 80,
                  ),
                  itemCount: workouts.length,
                  itemBuilder: (context, index) {
                    final workout = workouts[index];
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(0,20,0,0),
                      child: TrainingCard(
                        title: workout['title'],
                        workoutId: workout['id'],
                        categoryId: workout['category'],
                        onDeleted: () => setState(() {
                          workouts = workouts.where((w) => w['id'] != workout['id']).toList();
                        }),
                      ),
                    );
                  },
                ),
    );
  }
}
