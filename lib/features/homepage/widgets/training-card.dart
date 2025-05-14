import 'package:flutter/material.dart';
import 'package:trainings_app/features/my-trainings-page/views/exercises_page.dart';
import 'package:trainings_app/training_database.dart';

class TrainingCard extends StatelessWidget {
  const TrainingCard ({
    super.key,
    required this.title,
    required this.workoutId,
    required this.onDeleted,
  });

  final String title;
  final int workoutId;
  final VoidCallback  onDeleted;

  void _editWorkout(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ExercisesPage(workoutId: workoutId),
      ),
    );
  }

  Future<void> _deleteWorkout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить тренировку?'),
        content: Text('Вы уверены, что хотите удалить тренировку "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      try {
        final db = ExerciseDatabase.instance;
        await db.workoutManager.deleteWorkout(workoutId);
        
        onDeleted();
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Тренировка "$title" удалена')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка при удалении: $e')),
          );
        }
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(
        left: 30,
        right: 30,
        top: 10,
        bottom: 10,
      ),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () {
            Navigator.of(context).pushNamed('/workout_exercises', arguments: workoutId);
          },
          child: Stack(
            alignment: AlignmentDirectional.center,
            children: [
              Ink.image(
                colorFilter: ColorFilter.mode(
                  theme.colorScheme.primary.withOpacity(0.5),
                  BlendMode.color,
                ),
                height: 180,
                image: AssetImage('assets/img/drawer_img.jpg'),
                fit: BoxFit.cover,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 4.0,
                        color: Colors.black.withOpacity(0.5),
                        offset: Offset(2.0, 2.0),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white),
                      onPressed: () {
                        _editWorkout(context);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.white),
                      onPressed: () {
                        _deleteWorkout(context);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}