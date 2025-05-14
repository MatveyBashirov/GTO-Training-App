import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:trainings_app/features/appbar/training-appbar.dart';
import 'package:intl/intl.dart';
import 'package:trainings_app/models/user_data.dart';
import 'package:trainings_app/training_database.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatefulWidget> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final ExerciseDatabase _db = ExerciseDatabase.instance;
  List<UserStats> _stats = [];
  final TextEditingController _weightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _db.userStatsManager.initStats().then((_) => _loadStats());
  }

  Future<void> _loadStats() async {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: 7));
    final stats = await _db.userStatsManager.getStats(start, now);
    setState(() {
      _stats = stats;
    });
  }

  Future<void> _updateWeight() async {
    final weight = double.tryParse(_weightController.text);
    if (weight != null && weight > 0) {
      final today = DateTime.now();
      final existingStat = _stats.firstWhere(
        (stat) =>
            stat.date.day == today.day &&
            stat.date.month == today.month &&
            stat.date.year == today.year,
        orElse: () => UserStats(date: today),
      );
      final newStat = UserStats(
        date: today,
        workoutCount: existingStat.workoutCount,
        caloriesBurned: existingStat.caloriesBurned,
        weight: weight,
      );
      await _db.userStatsManager.saveStats(newStat);
      await _loadStats();
      _weightController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TrainingAppBar(title: 'Статистика'),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                height: 300,
                child: BarChart(
                  BarChartData(
                    barGroups: _stats
                        .asMap()
                        .entries
                        .map(
                          (e) => BarChartGroupData(
                            x: e.key,
                            barRods: [
                              BarChartRodData(
                                  toY: e.value.caloriesBurned ?? 0.0,
                                  color: Colors.blue,
                                  width: 10,
                                  borderRadius: BorderRadius.all(Radius.zero)),
                            ],
                          ),
                        )
                        .toList(),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= _stats.length) return Text('');
                            final date = _stats[value.toInt()].date;
                            return Text(DateFormat('dd.MM').format(date));
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              if (value % 2 == 0) {
                                return Text('${value.toInt()}');
                              }
                              return Text('');
                            }),
                      ),
                      topTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: true),
                    gridData: FlGridData(show: false),
                    alignment: BarChartAlignment.spaceAround,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _weightController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(border: OutlineInputBorder(), labelText: 'Ваш вес сегодня (кг)'),
                ),
              ),
              ElevatedButton(
                onPressed: _updateWeight,
                child: Text('Сохранить'),
              ),
              SizedBox(height: 20),
              Container(
                height: 300,
                child: BarChart(
                  BarChartData(
                    barGroups: _stats
                        .asMap()
                        .entries
                        .map(
                          (e) => BarChartGroupData(
                            x: e.key,
                            barRods: [
                              BarChartRodData(
                                  toY: e.value.weight ?? 0.0,
                                  color: Colors.blue,
                                  width: 10,
                                  borderRadius: BorderRadius.all(Radius.zero)),
                            ],
                          ),
                        )
                        .toList(),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= _stats.length) return Text('');
                            final date = _stats[value.toInt()].date;
                            return Text(DateFormat('dd.MM').format(date));
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              if (value % 2 == 0) {
                                return Text('${value.toInt()}');
                              }
                              return Text('');
                            }),
                      ),
                      topTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: true),
                    gridData: FlGridData(show: false),
                    alignment: BarChartAlignment.spaceAround,
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
