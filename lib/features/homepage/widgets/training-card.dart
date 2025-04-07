import 'package:flutter/material.dart';

class TrainingCard extends StatelessWidget {
  const TrainingCard ({
    super.key,
    required this.title,
    required this.workoutId,
  });

  final String title;
  final int workoutId;
  
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
            ],
          ),
        ),
      ),
    );
  }
}