class Exercise {
  final int id;
  final String name;
  final String description;
  final String imageUrl;
  final int category;

  Exercise({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.category,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      imageUrl: json['image_url'],
      category: json['category'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'category': category,
    };
  }
}