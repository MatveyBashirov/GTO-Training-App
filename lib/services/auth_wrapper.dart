import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trainings_app/features/homepage/views/login_screen.dart';
import 'package:trainings_app/features/homepage/views/training_home_page.dart';
import 'package:trainings_app/services/auth_service.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService(Supabase.instance.client);
  bool _isLoading = true;
  Session? _initialSession;

  @override
  void initState() {
    super.initState();
    _checkInitialSession();
  }

  Future<void> _checkInitialSession() async {
    final session = await _authService.getCurrentSession();
    setState(() {
      _initialSession = session;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return StreamBuilder<AuthState>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final authState = snapshot.data;
        final session = authState?.session ?? _initialSession;
        
        if (session != null) {
          return const TrainingHomePage();
        }
        
        return const LoginScreen();
      },
    );
  }
}