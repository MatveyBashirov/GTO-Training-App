import 'package:flutter/material.dart';
import 'package:trainings_app/models/profile.dart';
import 'package:trainings_app/services/auth_service.dart';

class PersonalCabinetScreen extends StatefulWidget {
  const PersonalCabinetScreen({super.key});

  @override
  _PersonalCabinetScreenState createState() => _PersonalCabinetScreenState();
}

class _PersonalCabinetScreenState extends State<PersonalCabinetScreen> {
  Profile? _profile;
  bool _isLoading = true;
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await authService.getUserProfile();
    setState(() {
      _profile = profile;
      _isLoading = false;
    });

    if (profile != null && (profile.firstName == null || profile.lastName == null)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showProfileDialog(context);
      });
    }
  }
  
void _showProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Введите ФИО'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'Имя'),
              ),
              TextField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Фамилия'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final firstName = _firstNameController.text.trim();
                final lastName = _lastNameController.text.trim();
                if (firstName.isEmpty || lastName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Введите имя и фамилию')),
                  );
                  return;
                }

                final success = await authService.updateUserProfile(firstName, lastName);
                if (success) {
                  setState(() {
                    _profile = Profile(firstName: firstName, lastName: lastName);
                  });
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ошибка сохранения профиля')),
                  );
                }
              },
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Личный кабинет')),
      body: Center(
        child: user == null
            ? const Text('Пожалуйста, войдите в аккаунт')
            : _isLoading
                ? const CircularProgressIndicator()
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_profile?.firstName != null)
                        Text(
                          'Имя: ${_profile!.firstName}',
                          style: const TextStyle(fontSize: 18),
                        ),
                      if (_profile?.lastName != null)
                        Text(
                          'Фамилия: ${_profile!.lastName}',
                          style: const TextStyle(fontSize: 18),
                        ),
                      Text(
                        'Email: ${user.email}',
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () async {
                          await authService.signOut();
                        },
                        child: const Text('Выйти'),
                      ),
                    ],
                  ),
      ),
    );
  }
}