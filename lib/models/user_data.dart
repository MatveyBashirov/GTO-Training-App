class UserStats {
  final DateTime date;
  final int? workoutCount;
  final double? caloriesBurned;
  final double? weight;

  UserStats({
    required this.date,
    this.workoutCount,
    this.caloriesBurned,
    this.weight,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String().substring(0, 10),
        'workout_count': workoutCount,
        'calories_burned': caloriesBurned,
        'weight': weight ?? 0.0,
      };

  factory UserStats.fromJson(Map<String, dynamic> json) {
    double? parseNumber(dynamic value) {
      if (value == null) return null;
      if (value is int) return value.toDouble();
      if (value is double) return value;
      return null;
    }

    return UserStats(
      date: DateTime.parse(json['date'] as String),
      workoutCount: json['workout_count'] as int?,
      caloriesBurned: parseNumber(json['calories_burned']),
      weight: parseNumber(json['weight']),
    );
  }

  Map<String, dynamic> toMap() => {
        'date': date.toIso8601String().substring(0, 10),
        'workout_count': workoutCount,
        'calories_burned': caloriesBurned,
        'weight': weight ?? 0.0,
      };

  factory UserStats.fromMap(Map<String, dynamic> map) => UserStats(
        date: DateTime.parse(map['date'] as String),
        workoutCount: map['workout_count'] as int?,
        caloriesBurned: map['calories_burned'] as double?,
        weight: map['weight'] as double?,
      );
}