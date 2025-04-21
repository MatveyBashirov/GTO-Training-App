import 'package:flutter/material.dart';
import 'package:trainings_app/features/homepage/views/login_screen.dart';
import 'package:trainings_app/features/homepage/views/signup_screen.dart';
import 'package:trainings_app/features/homepage/views/training_home_page.dart';
import 'package:trainings_app/features/my-trainings-page/views/my_trainings_page.dart';
import 'package:trainings_app/features/my-trainings-page/views/workout_exercises_page.dart';
import 'package:trainings_app/services/auth_wrapper.dart';
import 'package:trainings_app/theme/theme.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main () async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!, // Получаем URL из .env
    anonKey: dotenv.env['SUPABASE_KEY']!, // Получаем ключ из .env
  );

  runApp(TrainingApp());
}

class TrainingApp extends StatelessWidget {
  const TrainingApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: maintheme,
      home: AuthWrapper(),
      routes: {
        '/homepage': (context) => const TrainingHomePage(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/myworkouts': (context) => const SelectWorkoutScreen(),
        '/workout_exercises': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as int?;
          if (args == null) {
            return const Scaffold(body: Center(child: Text('Ошибка: workoutId не передан')));
          }
          return WorkoutExercisesPage(workoutId: args);
        },
       }
    );
  }
}
