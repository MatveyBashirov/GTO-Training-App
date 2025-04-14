import 'package:flutter/material.dart';
import 'package:trainings_app/features/appbar/training-appbar.dart';

class CompletionScreen extends StatefulWidget{
  @override
  State<StatefulWidget> createState() => CompletionScreenState();
}

class CompletionScreenState extends State<CompletionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TrainingAppBar(title: 'Результаты'),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Text(
              'Поздравляем!'
            ),
          ),
        ],
      ),
    );
  }
}