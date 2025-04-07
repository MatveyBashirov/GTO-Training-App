// import 'package:trainings_app/models/exercise.dart';

class Workout {
  final int id;
  final String title;

  Workout({
    required this.id,
    required this.title,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
    };
  }

  factory Workout.fromMap(Map<String, dynamic> map) {
    return Workout(
      id: map['id'] as int,
      title: map['title'] as String,
    );
  }
}