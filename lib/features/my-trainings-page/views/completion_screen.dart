import 'package:flutter/material.dart';
import 'package:trainings_app/features/appbar/training-appbar.dart';
import 'package:trainings_app/models/user_data.dart';
import 'package:trainings_app/training_database.dart';

class CompletionScreen extends StatefulWidget{

  final double caloriesBurned;
  final Duration duration;
  
  const CompletionScreen({
    super.key,
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
    // Получаем текущую статистику за сегодня
    final todayStats = await _db.getStats(today, today);
    final existingStat = todayStats.isNotEmpty ? todayStats.first : UserStats(date: today);

    // Обновляем статистику: +1 тренировка, добавляем калории
    final newStat = UserStats(
      date: today,
      workoutCount: existingStat.workoutCount + 1,
      caloriesBurned: existingStat.caloriesBurned + widget.caloriesBurned,
      weight: existingStat.weight,
    );

    await _db.saveStats(newStat);
  }

  Future<void> _checkFirstWorkout() async {
    final isFirst = await _db.isFirstWorkoutToday();
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
                final todayStats = await _db.getStats(today, today);
                final existingStat = todayStats.isNotEmpty ? todayStats.first : UserStats(date: today);

                // Обновляем статистику с новым весом
                final newStat = UserStats(
                  date: today,
                  workoutCount: existingStat.workoutCount,
                  caloriesBurned: existingStat.caloriesBurned,
                  weight: weight,
                );

                await _db.saveStats(newStat);
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
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Тренировка завершена!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),),
              SizedBox(height: 20),
            Text(
              'Соженно калорий за тренировку: ${widget.caloriesBurned.toStringAsFixed(1)} kcal',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 10),
            Text(
              'Время тренировки: ${_formatDuration(widget.duration)}',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('На главную'),
            ),
          ],
        ),
      )
    );
  }
}