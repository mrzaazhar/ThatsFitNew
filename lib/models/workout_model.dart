class WorkoutModel {
  final String name;
  final String duration;
  final String calories;
  final String difficulty;
  final String description;
  final List<String> exercises;

  WorkoutModel({
    required this.name,
    required this.duration,
    required this.calories,
    required this.difficulty,
    required this.description,
    required this.exercises,
  });

  factory WorkoutModel.fromJson(Map<String, dynamic> json) {
    return WorkoutModel(
      name: json['name'] ?? 'Custom Workout',
      duration: json['duration'] ?? '30 min',
      calories: json['calories'] ?? '200-300',
      difficulty: json['difficulty'] ?? 'Intermediate',
      description: json['description'] ??
          'A personalized workout plan based on your profile and activity.',
      exercises: List<String>.from(
          json['exercises'] ?? ['Custom exercises will be displayed here']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'duration': duration,
      'calories': calories,
      'difficulty': difficulty,
      'description': description,
      'exercises': exercises,
    };
  }
}
