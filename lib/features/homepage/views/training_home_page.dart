import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:trainings_app/features/appbar/training-appbar.dart';
import 'package:trainings_app/features/drawer/drawer.dart';
import 'package:trainings_app/features/homepage/widgets/training-card.dart';
import 'package:trainings_app/features/my-trainings-page/views/category_workout_page.dart';
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
    "Личный кабинет",
  ];

  final List<String> drawerRoutes = [
    "/myworkouts",
    "/stats",
    // "/",
    "/profile",
  ];

  final ExerciseDatabase dbHelper = ExerciseDatabase.instance;
  List<Map<String, dynamic>> categories = [];
  bool isLoading = false;
  double _totalPoints = 0;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadTotalPoints();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheImages();
    _loadTotalPoints();
  }

  Future<void> _precacheImages() async {
  try {
    final manifestContent = await DefaultAssetBundle.of(context).loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = jsonDecode(manifestContent);

    final imagePaths = manifestMap.keys
        .where((String key) => key.startsWith('assets/img/'))
        .toList();
    for (final imagePath in imagePaths) {
      await precacheImage(AssetImage(imagePath), context);
    }
  } catch (e) {
    print('Ошибка при предзагрузке изображений: $e');
  }
}

  Future<void> _loadTotalPoints() async {
    final points = await dbHelper.userStatsManager.getTotalPoints();
    setState(() {
      _totalPoints = points;
    });
  }

  Future<void> _loadCategories() async {
    setState(() => isLoading = true);
    final db = await dbHelper.database;
    categories = await db.query('categories');
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
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
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Text(
                    textAlign: TextAlign.center,
                    'Выберите категорию тренировок',
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
              isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : categories.isEmpty
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
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: categories.asMap().entries.map((entry) {
                              final index = entry.key;
                              final category = entry.value;
                              return AnimatedOpacity(
                                opacity: 1.0,
                                duration: const Duration(milliseconds: 600),
                                curve: Curves.easeOut,
                                child: Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  margin: const EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 4),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 36, vertical: 8),
                                    title: Text(
                                      category['name'] ?? 'Без названия',
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    trailing: Icon(
                                      Icons.arrow_forward_ios,
                                      color: theme.colorScheme.primary,
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              CategoryWorkoutsPage(
                                            categoryId: category['id'],
                                            categoryName: category['name'],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
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
      ),
    );
  }
}
