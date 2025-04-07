import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trainings_app/features/homepage/services/snakbar_service.dart';
import 'package:trainings_app/features/homepage/views/training_home_page.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool isEmailVerified = false;
  bool canResendEmail = false;
  bool isLoading = false;
  Timer? timer;
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _checkEmailVerificationStatus();
  }

  Future<void> _checkEmailVerificationStatus() async {
    // Получаем текущую сессию
    final session = supabase.auth.currentSession;
    
    if (session == null) {
      // Если нет сессии, возможно нужно перенаправить на вход
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
      return;
    }

    // Проверяем, подтвержден ли email
    final user = session.user;
    isEmailVerified = user.emailConfirmedAt != null;

    if (!isEmailVerified) {
      await _sendVerificationEmail();
      
      // Запускаем таймер для периодической проверки
      timer = Timer.periodic(
        const Duration(seconds: 5),
        (_) => _verifyEmail(),
      );
    }
  }

  Future<void> _verifyEmail() async {
    try {
      // Обновляем сессию
      final response = await supabase.auth.refreshSession();
      final user = response.user;
      
      if (user?.emailConfirmedAt != null) {
        setState(() {
          isEmailVerified = true;
        });
        timer?.cancel();
      }
    } catch (e) {
      if (mounted) {
        SnackBarService.showSnackBar(
          context,
          'Ошибка проверки email: ${e.toString()}',
          true,
        );
      }
    }
  }

  Future<void> _sendVerificationEmail() async {
    if (isLoading) return;
    
    setState(() => isLoading = true);
    
    try {
      await supabase.auth.resend(
        type: OtpType.signup,
        email: supabase.auth.currentUser?.email ?? '',
      );
      
      setState(() => canResendEmail = false);
      await Future.delayed(const Duration(seconds: 30));
      setState(() => canResendEmail = true);
      
      if (mounted) {
        SnackBarService.showSnackBar(
          context,
          'Письмо с подтверждением отправлено!',
          false,
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarService.showSnackBar(
          context,
          'Ошибка отправки письма: ${e.toString()}',
          true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => isEmailVerified
      ? const TrainingHomePage()
      : Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            title: const Text('Верификация Email адреса'),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Письмо с подтверждением было отправлено на вашу электронную почту.',
                    style: TextStyle(
                      fontSize: 20,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: canResendEmail && !isLoading 
                          ? _sendVerificationEmail 
                          : null,
                    icon: const Icon(Icons.email),
                    label: const Text('Повторно отправить'),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: isLoading
                          ? null
                          : () async {
                              await supabase.auth.signOut();
                              if (mounted) {
                                Navigator.of(context).popUntil((route) => route.isFirst);
                              }
                            },
                    child: const Text(
                      'Отменить',
                      style: TextStyle(
                        color: Colors.blue,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
}