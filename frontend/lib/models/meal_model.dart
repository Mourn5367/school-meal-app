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
    // ID가 없는 경우 기본값 0 사용
    final id = json['id'] ?? 0;
    
    // 날짜 필드가 없거나 null인 경우 현재 날짜 사용
    String dateStr;
    if (json['date'] == null) {
      dateStr = DateTime.now().toIso8601String().split('T')[0]; // yyyy-MM-dd
    } else {
      dateStr = json['date'].toString();
    }
    
    // 식사 유형이 없는 경우 '정보 없음' 사용
    final mealType = json['meal_type'] ?? '정보 없음';
    
    // 내용이 없는 경우 '정보 없음' 사용
    final content = json['content'] ?? '정보 없음';
    
    return Meal(
      id: id,
      date: dateStr,
      mealType: mealType,
      content: content,
    );
  }
}