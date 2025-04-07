class WorkoutExercise {
  final int id;
  final int workoutId;
  final int exerciseId;
  final int reps;
  final int orderIndex;

  const WorkoutExercise({
    required this.id,
    required this.workoutId,
    required this.exerciseId,
    this.reps = 10,
    this.orderIndex = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workout_id': workoutId,
      'exercise_id': exerciseId,
      'reps': reps,
      'order_index': orderIndex,
    };
  }

  factory WorkoutExercise.fromMap(Map<String, dynamic> map) {
    return WorkoutExercise(
      id: map['id'] as int,
      workoutId: map['workout_id'] as int,
      exerciseId: map['exercise_id'] as int,
      reps: map['reps'] as int? ?? 10,
      orderIndex: map['order_index'] as int? ?? 0,
    );
  }
}