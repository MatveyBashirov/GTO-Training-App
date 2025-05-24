import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trainings_app/features/my-trainings-page/views/exercises_page.dart';
import 'package:trainings_app/models/exercise.dart';
import 'package:trainings_app/services/database/exercise_manager.dart';
import 'package:trainings_app/services/database/workout_manager.dart';
import 'package:trainings_app/training_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'exercise_page_test.mocks.dart';

@GenerateMocks([ExerciseDatabase, ExerciseManager, WorkoutManager, SupabaseClient])
void main(){
  
  late MockExerciseDatabase mockDbHelper;
  late MockExerciseManager mockExerciseManager;
  late MockWorkoutManager mockWorkoutManager;
  late MockSupabaseClient mockSupabaseClient;

  setUpAll(() async {
    await Supabase.initialize(
      url: 'http://fake-url',
      anonKey: 'fake-anon-key',
    );

    mockSupabaseClient = MockSupabaseClient();
    when(Supabase.instance.client).thenReturn(mockSupabaseClient);
  });

  setUp(() {
    mockDbHelper = MockExerciseDatabase();
    mockExerciseManager = MockExerciseManager();
    mockWorkoutManager = MockWorkoutManager();

    when(ExerciseDatabase.instance).thenReturn(mockDbHelper);
    when(mockDbHelper.exerciseManager).thenReturn(mockExerciseManager);
    when(mockDbHelper.workoutManager).thenReturn(mockWorkoutManager);

    when(mockExerciseManager.getExercises()).thenAnswer(
      (_) async => [
        Exercise(
          id: 1,
          name: 'Push-up',
          description: 'Basic push-up exercise',
          imageUrl: 'assets/pushup.gif',
          category: 1,
          ccals: 0.5,
          points: 10.0,
        ),
      ],
    );

    when(mockWorkoutManager.getCategories()).thenAnswer(
      (_) async => [
        {'id': 1, 'name': 'Strength'},
      ],
    );

    when(mockWorkoutManager.getWorkout(any)).thenAnswer(
      (_) async => {'title': 'Test Workout'},
    );
    when(mockWorkoutManager.getWorkoutExercises(any)).thenAnswer(
      (_) async => [],
    );
  });

  group('ExercisesPage Виджет тесты', () {
    testWidgets('Функция addExercise добавляет упражнение в список selectedExercises',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ExercisesPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.add), findsOneWidget);
      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pumpAndSettle();

      expect(find.text('Push-up'), findsOneWidget);
      expect(find.text('Нет выбранных упражнений'), findsNothing);
    });

    testWidgets('Функция removeExercise удаляет упражнение из списка selectedExercises',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ExercisesPage(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pumpAndSettle();

      expect(find.text('Push-up'), findsOneWidget);

      expect(find.byIcon(Icons.delete), findsOneWidget);
      await tester.tap(find.byIcon(Icons.delete).first);
      await tester.pumpAndSettle();

      expect(find.text('Push-up'), findsNothing);
      expect(find.text('Нет выбранных упражнений'), findsOneWidget);
    });
  });
}