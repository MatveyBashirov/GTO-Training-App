import 'package:flutter/material.dart';
import 'package:trainings_app/features/appbar/training-appbar.dart';
import 'package:trainings_app/features/drawer/drawer.dart';
import 'package:trainings_app/features/homepage/widgets/training-card.dart';
import 'package:trainings_app/training_database.dart';

class TrainingHomePage extends StatefulWidget {
  const TrainingHomePage({super.key});

  @override
  State<TrainingHomePage> createState() => _TrainingHomePageState();
}

class _TrainingHomePageState extends State<TrainingHomePage> {
  ///Список бокового меню
  final List<String> drawerItems = [
    "Мои тренировки",
    "Статистика",
    "Нормативы ГТО",
  ];

  ///Список бокового меню
  final List<String> drawerRoutes = [
    "/myworkouts",
    "/stats",
    "/",
  ];

  final ExerciseDatabase dbHelper = ExerciseDatabase.instance;
  List<Map<String, dynamic>> workouts = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/img/drawer_img.jpg'), context);
  }

  Future<void> _loadWorkouts() async {
    setState(() => isLoading = true);
    workouts = await dbHelper.getAllWorkouts();
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      drawerScrimColor: Colors.black45,
      backgroundColor: theme.colorScheme.secondary,
      appBar: TrainingAppBar(title: 'Упражнения для вас'),
      drawer: MainDrawer(
        drawerItems: drawerItems,
        drawerRoutes: drawerRoutes,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : workouts.isEmpty
              ? Center(child: Text('Нет тренировок'))
              : ListView.builder(
                  itemCount: workouts.length,
                  itemBuilder: (context, index) {
                    final workout = workouts[index];
                    return TrainingCard(
                      title: workout['title'],
                      workoutId: workout['id'],
                      onDeleted: () => setState(() {
                        workouts = workouts.where((w) => w['id'] != workout['id']).toList();
                      }),
                    );
                  },
                ),
    );
  }
}
