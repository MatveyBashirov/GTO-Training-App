import 'dart:math';

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
  final List<String> drawerItems = [
    "Мои тренировки",
    "Статистика",
    // "Нормативы ГТО",
    "Личный кабинет",
  ];

  final List<String> drawerRoutes = [
    "/myworkouts",
    "/stats",
    // "/",
    "/profile",
  ];

  final ExerciseDatabase dbHelper = ExerciseDatabase.instance;
  Map<String, dynamic>? randomWorkout;
  bool isLoading = false;
  int _totalPoints = 0;

  @override
  void initState() {
    super.initState();
    _loadRandomWorkout();
    _loadTotalPoints();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/img/drawer_img.jpg'), context);
    _loadTotalPoints();
  }

  Future<void> _loadTotalPoints() async {
    final points = await dbHelper.userStatsManager.getTotalPoints();
    setState(() {
      _totalPoints = points;
    });
  }

  Future<void> _loadRandomWorkout() async {
    setState(() => isLoading = true);
    final workouts = await dbHelper.workoutManager.getAllWorkouts();
    if (workouts.isNotEmpty) {
      final randomIndex = Random().nextInt(workouts.length);
      randomWorkout = workouts[randomIndex];
    } else {
      randomWorkout = null;
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);
    return Scaffold(
      drawerScrimColor: Colors.black45,
      backgroundColor: theme.colorScheme.secondary,
      appBar: TrainingAppBar(title: 'Главная страница'),
      drawer: MainDrawer(
        drawerItems: drawerItems,
        drawerRoutes: drawerRoutes,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.background,
              theme.colorScheme.surface.withOpacity(0.9),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Text(
                    'Попробуйте эту тренировку!',
                    style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(
                            color: Colors.grey.withOpacity(0.7),
                            offset: Offset(2, 2),
                            blurRadius: 20,
                          ),
                        ]),
                  ),
                ),
              ),
              Container(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : randomWorkout == null
                        ? Center(
                            child: Text(
                              'Нет тренировок',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onBackground
                                    .withOpacity(0.6),
                              ),
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.all(0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                const SizedBox(height: 16),
                                AnimatedOpacity(
                                  opacity: 1.0,
                                  duration: const Duration(milliseconds: 600),
                                  curve: Curves.easeOut,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(),
                                    child: TrainingCard(
                                      title: randomWorkout!['title'],
                                      workoutId: randomWorkout!['id'],
                                      onDeleted: () async {
                                        await dbHelper.workoutManager
                                            .deleteWorkout(
                                                randomWorkout!['id']);
                                        await _loadRandomWorkout();
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Center(
                                  child: ElevatedButton.icon(
                                    onPressed: _loadRandomWorkout,
                                    icon: const Icon(Icons.refresh, size: 20),
                                    label: const Text('Выбрать другую'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          theme.colorScheme.primary,
                                      foregroundColor:
                                          theme.colorScheme.onPrimary,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 32,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 2,
                                      textStyle:
                                          theme.textTheme.labelLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 70, 20, 0),
                  child: Text(
                    textAlign: TextAlign.center,
                    'Тренеруйтесь\nи получайте баллы',
                    style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(
                            color: Colors.grey.withOpacity(0.7),
                            offset: Offset(2, 2),
                            blurRadius: 20,
                          ),
                        ]),
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Text(
                    textAlign: TextAlign.center,
                    'Ваше текущее количество баллов:',
                    style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.blueGrey,
                        fontSize: 12,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(
                            color: Colors.grey.withOpacity(0.7),
                            offset: Offset(2, 2),
                            blurRadius: 20,
                          ),
                        ]),
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Text(
                    textAlign: TextAlign.center,
                    '$_totalPoints',
                    style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 100,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(
                            color: Colors.grey.withOpacity(0.7),
                            offset: Offset(2, 2),
                            blurRadius: 20,
                          ),
                        ]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
