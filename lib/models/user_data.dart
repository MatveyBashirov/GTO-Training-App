class UserStats {
  final DateTime date;
  final int workoutCount;
  final double caloriesBurned;
  final double weight; 

  UserStats({
    required this.date,
    this.workoutCount = 0,
    this.caloriesBurned = 0.0,
    this.weight = 0.0,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'workoutCount': workoutCount,
        'caloriesBurned': caloriesBurned,
        'weight': weight,
      };

  factory UserStats.fromJson(Map<String, dynamic> json) => UserStats(
        date: DateTime.parse(json['date']),
        workoutCount: json['workoutCount'],
        caloriesBurned: json['caloriesBurned'],
        weight: json['weight'],
      );

  Map<String, dynamic> toMap() => {
        'date': date.toIso8601String().substring(0, 10), // Формат YYYY-MM-DD
        'workouts_count': workoutCount,
        'calories_burned': caloriesBurned,
        'weight_kg': weight,
      };

  factory UserStats.fromMap(Map<String, dynamic> map) => UserStats(
        date: DateTime.parse(map['date']),
        workoutCount: map['workouts_count'],
        caloriesBurned: map['calories_burned'],
        weight: map['weight_kg'],
      );
}