import 'dart:async';

import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:FitnessPlus/features/appbar/training-appbar.dart';
import 'package:FitnessPlus/features/homepage/services/snakbar_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isHiddenPassword = true;
  bool isLoading = false;
  TextEditingController emailTextInputController = TextEditingController();
  TextEditingController passwordTextInputController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final supabase = Supabase.instance.client;

  @override
  void dispose() {
    emailTextInputController.dispose();
    passwordTextInputController.dispose();

    super.dispose();
  }

  void togglePasswordView() {
    setState(() {
      isHiddenPassword = !isHiddenPassword;
    });
  }

  Future<void> login() async {

    final isValid = formKey.currentState!.validate();
    if (!isValid) return;

    setState(() => isLoading = true);

    try {
      final response = await supabase.auth.signInWithPassword(
        email: emailTextInputController.text.trim(),
        password: passwordTextInputController.text.trim(),
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        throw TimeoutException('Превышено время ожидания сервера');});

      if (response.user == null) {
        throw Exception('Ошибка авторизации: пользователь не найден!');
      }
  } on AuthException catch (e) {
      if (mounted) {
        if (e.code == 'email_not_confirmed') {
          SnackBarService.showSnackBar(
            context,
            'Пожалуйста, подтвердите ваш email перед входом',
            true,
          );
        } else if (e.code == 'invalid_credentials') {
          SnackBarService.showSnackBar(
            context,
            'Пользователь не найден или неверный пароль',
            true,
          );
        } else {
          SnackBarService.showSnackBar(
            context,
            'Ошибка авторизации: ${e.message}',
            true,
          );
        }
      }
    } on TimeoutException catch (e) {
      if (mounted) {
        SnackBarService.showSnackBar(
          context,
          e.message ?? 'Ошибка сети',
          true,
        );
      }
    } 
  finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: TrainingAppBar(title: 'Войти'),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              TextFormField(
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                controller: emailTextInputController,
                validator: (email) =>
                    email != null && !EmailValidator.validate(email)
                        ? 'Введите правильный Email'
                        : null,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Введите Email',
                ),
              ),
              const SizedBox(height: 30),
              TextFormField(
                autocorrect: false,
                controller: passwordTextInputController,
                obscureText: isHiddenPassword,
                validator: (value) => value != null && value.length < 6
                    ? 'Минимум 6 символов'
                    : null,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: 'Введите пароль',
                  suffix: InkWell(
                    onTap: togglePasswordView,
                    child: Icon(
                      isHiddenPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed:isLoading ? null : login,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Center(child: Text('Войти')),
              ),
              const SizedBox(height: 30),
              TextButton(
                onPressed: () => Navigator.of(context).pushNamed('/signup'),
                child: const Text(
                  'Регистрация',
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}