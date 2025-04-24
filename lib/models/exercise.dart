import 'dart:ffi';

class Exercise {
  final int id;
  final String name;
  final String description;
  final String imageUrl;
  final int category;
  final double ccals;

  Exercise({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.category,
    required this.ccals,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      imageUrl: json['image_url'],
      category: json['category'],
      ccals: json['ccals']
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'category': category,
      'ccals': ccals
    };
  }
}