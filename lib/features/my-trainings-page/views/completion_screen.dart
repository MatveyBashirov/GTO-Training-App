import 'package:flutter/material.dart';
import 'package:trainings_app/features/appbar/training-appbar.dart';
import 'package:trainings_app/models/user_data.dart';
import 'package:trainings_app/training_database.dart';

class CompletionScreen extends StatefulWidget{

  final double points;
  final double caloriesBurned;
  final Duration duration;
  
  const CompletionScreen({
    super.key,
    required this.points,
    required this.caloriesBurned,
    required this.duration
  });

  @override
  State<StatefulWidget> createState() => CompletionScreenState();
}

class CompletionScreenState extends State<CompletionScreen> {

  final ExerciseDatabase _db = ExerciseDatabase.instance;
  final TextEditingController _weightController = TextEditingController();  

  @override
  void initState() {
    super.initState();
    _saveWorkoutData();
    _checkFirstWorkout();
  }

  Future<void> _saveWorkoutData() async {
  final today = DateTime.now();
    
  final todayStats = await _db.userStatsManager.getStats(today, today);

  final existingTodayStat = todayStats.isNotEmpty ? todayStats.first : UserStats(date: today);
  double currentPoints = existingTodayStat.points ?? 0;
  currentPoints = currentPoints + widget.points;

  final newStat = UserStats(
    date: today,
    workoutCount: (existingTodayStat.workoutCount ?? 0) + 1,
    caloriesBurned: (existingTodayStat.caloriesBurned ?? 0) + widget.caloriesBurned,
    weight: existingTodayStat.weight ?? 0,
    points: currentPoints,
  );

  await _db.userStatsManager.saveStats(newStat);
  }

  Future<void> _checkFirstWorkout() async {
    final isFirst = await _db.userStatsManager.isFirstWorkoutToday();
    if (isFirst) {
      _showWeightDialog();
    }
  }

  Future<void> _showWeightDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ваш вес сегодня (кг):'),
        content: TextField(
          controller: _weightController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: 'Введите вес'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final weight = double.tryParse(_weightController.text);
              if (weight != null && weight > 0) {
                final today = DateTime.now();
                final todayStats = await _db.userStatsManager.getStats(today, today);
                final existingStat = todayStats.isNotEmpty ? todayStats.first : UserStats(date: today);

                final newStat = UserStats(
                  date: today,
                  workoutCount: existingStat.workoutCount,
                  caloriesBurned: existingStat.caloriesBurned,
                  weight: weight,
                );

                await _db.userStatsManager.saveStats(newStat);
                Navigator.pop(context);
                _weightController.clear();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Неверный формат данных! Повторите попытку')),
                );
              }
            },
            child: Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TrainingAppBar(title: 'Результаты'),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Theme.of(context).primaryColor, size: 32),
                  const SizedBox(width: 10),
                  const Text(
                    'Тренировка завершена!',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      shadows: [
                        Shadow(
                          color: Colors.grey,
                          offset: Offset(1, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.local_fire_department, color: Theme.of(context).primaryColor , size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Сожжено: ${widget.caloriesBurned.toStringAsFixed(1)} ккал',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Icon(Icons.timer, color: Theme.of(context).primaryColor, size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Время: ${_formatDuration(widget.duration)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/myworkouts',
                    (route) => route.settings.name == '/myworkouts' || route.isFirst,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'Назад',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      )
    );
  }
}