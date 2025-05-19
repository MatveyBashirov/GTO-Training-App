import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trainings_app/features/homepage/views/login_screen.dart';
import 'package:trainings_app/features/homepage/views/training_home_page.dart';
import 'package:trainings_app/services/auth_service.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final authState = snapshot.data;
        final session = authState?.session;
        
        if (session != null) {
          return const TrainingHomePage();
        }
        
        return const LoginScreen();
      },
    );
  }
}