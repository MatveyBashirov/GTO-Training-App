import 'package:flutter/material.dart';

class PointsNotifier extends ChangeNotifier {
  double _points = 0;
  
  double get points => _points;
  
  void updatePoints(double newPoints) {
    _points = newPoints;
    notifyListeners();
  }
}