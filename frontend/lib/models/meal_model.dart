class Meal {
  final int id;
  final String date;
  final String mealType;
  final String content;

  Meal({
    required this.id,
    required this.date,
    required this.mealType,
    required this.content,
  });

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      id: json['id'],
      date: json['date'],
      mealType: json['meal_type'],
      content: json['content'],
    );
  }
}