class UserStats {
  final DateTime date;
  final int? workoutCount;
  final double? caloriesBurned;
  final double? weight;
  final double? points;

  UserStats({
    required this.date,
    this.workoutCount,
    this.caloriesBurned,
    this.weight,
    this.points
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String().substring(0, 10),
      'workout_count': workoutCount,
      'calories_burned': caloriesBurned,
      'weight': weight,
      'points': points,
    };
  }

  factory UserStats.fromMap(Map<String, dynamic> map) {
    return UserStats(
      date: DateTime.parse(map['date']),
      workoutCount: map['workout_count'],
      caloriesBurned: map['calories_burned']?.toDouble(),
      weight: map['weight']?.toDouble(),
      points: map['points']?.toDouble(),
    );
  }

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      date: DateTime.parse(json['date']),
      workoutCount: json['workout_count'],
      caloriesBurned: json['calories_burned']?.toDouble(),
      weight: json['weight']?.toDouble(),
      points: json['points']?.toDouble(),
    );
  }
}