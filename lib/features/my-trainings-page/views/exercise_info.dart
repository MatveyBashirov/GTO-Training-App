import 'package:flutter/material.dart';
import 'package:gif/gif.dart';
import 'package:trainings_app/features/appbar/training-appbar.dart';

class ExerciseInfo extends StatefulWidget {
  final String exerciseName;
  final String description;
  final String imageUrl;

  const ExerciseInfo(
      {super.key,
      required this.exerciseName,
      required this.description,
      required this.imageUrl});

  @override
  State<ExerciseInfo> createState() => ExerciseInfoState();
}

class ExerciseInfoState extends State<ExerciseInfo> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: TrainingAppBar(title: widget.exerciseName),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 200,
              color: theme.primaryColor,
              child: Center(
                child: Gif(
                      image: AssetImage(widget.imageUrl),
                      autostart:
                          Autostart.loop,
                      fit: BoxFit.contain,
                      placeholder: (context) => const Center(
                        child: Icon(Icons.fitness_center, size: 30),
                      ),
                    ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.exerciseName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
