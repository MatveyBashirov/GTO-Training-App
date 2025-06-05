import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:trainings_app/features/appbar/training-appbar.dart';
import 'package:trainings_app/models/profile.dart';
import 'package:trainings_app/services/auth_service.dart';
import 'package:url_launcher/url_launcher.dart';

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

    if (profile != null &&
        (profile.firstName == null || profile.lastName == null)) {
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

                final success =
                    await authService.updateUserProfile(firstName, lastName);
                if (success) {
                  setState(() {
                    _profile =
                        Profile(firstName: firstName, lastName: lastName);
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
    final theme = Theme.of(context);
    final user = authService.currentUser;

    return Scaffold(
      appBar: TrainingAppBar(title: 'Личный кабинет'),
      body: Center(
        child: user == null
            ? const Text('Пожалуйста, войдите в аккаунт')
            : _isLoading
                ? const CircularProgressIndicator()
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 2,
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundColor: theme.colorScheme.primary,
                                child: Icon(
                                  Icons.person,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (_profile?.firstName != null)
                                Text(
                                  'Имя: ${_profile!.firstName}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              const SizedBox(height: 8),
                              if (_profile?.lastName != null)
                                Text(
                                  'Фамилия: ${_profile!.lastName}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              const SizedBox(height: 8),
                              Text(
                                'Email: ${user.email}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        Card(
                          elevation: 2,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ExpansionTile(
                            title: Text(
                              'Система начисления баллов',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  'Баллы начисляются за выполнение упражнений и тренировок. '
                                  'Каждое упражнение имеет определённое количество баллов, '
                                  'которое зависит от сложности и затраченных калорий. ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Card(
                          elevation: 2,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ExpansionTile(
                            title: Text(
                              'Сдача ГТО',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: RichText(
                                    text: TextSpan(
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade800,
                                        ),
                                        children: [
                                      TextSpan(
                                          text:
                                              'ГТО (Готов к труду и обороне) — это программа физической подготовки.'
                                              'Данное приложение поможет вам развить ваши навыки '
                                              'для успешной сдачи нормативов для получения '),
                                      TextSpan(
                                        text: 'налогового вычета',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          decoration: TextDecoration.underline,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () async {
                                            const url = 'https://www.nalog.gov.ru/rn37/news/activities_fts/15941877/';
                                              await launchUrl(Uri.parse(url));
                                          },
                                      ),
                                      TextSpan(
                                          text:
                                              '! Подробную информацию Вы можете получить '),
                                      TextSpan(
                                        text: 'здесь',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          decoration: TextDecoration.underline,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () async {
                                            const url = 'https://sh-morozovskaya-r24.gosweb.gosuslugi.ru/netcat_files/userfiles/proekt_novyh_normativov_GTO_2023.pdf';
                                              await launchUrl(Uri.parse(url)); 
                                          },
                                      ),
                                      TextSpan(text: '.'),
                                    ])),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: () async {
                            await authService.signOut();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 2,
                          ),
                          child: const Text(
                            'Выйти',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
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
