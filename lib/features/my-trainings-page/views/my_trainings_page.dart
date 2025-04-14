import 'package:flutter/material.dart';
import 'package:trainings_app/features/appbar/training-appbar.dart';
import 'package:trainings_app/models/workout.dart';

class SelectWorkoutScreen extends StatefulWidget {
  @override
  _SelectWorkoutScreenState createState() => _SelectWorkoutScreenState();
}

class _SelectWorkoutScreenState extends State<SelectWorkoutScreen> {
  List<Workout> workouts = []; // Здесь будут храниться тренировки пользователя

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  Future<void> _loadWorkouts() async {
    
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.secondary,
      appBar: TrainingAppBar(title: 'Мои тренировки'),
    );
  }
}