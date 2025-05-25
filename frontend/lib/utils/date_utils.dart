// frontend/lib/utils/date_utils.dart
class DateUtils {
  // RFC 2822 형식 날짜를 파싱하는 함수
  static DateTime? parseDate(String dateStr) {
    try {
      // 기본 ISO 형식 시도 (yyyy-MM-dd)
      if (dateStr.contains('-') && !dateStr.contains(',')) {
        return DateTime.parse(dateStr);
      }
      
      // RFC 2822 형식 파싱 (예: "Sun, 25 May 2025 10:10:59 GMT")
      if (dateStr.contains(',')) {
        final parts = dateStr.split(' ');
        if (parts.length >= 4) {
          final day = int.tryParse(parts[1]);
          final monthStr = parts[2];
          final year = int.tryParse(parts[3]);
          
          final monthMap = {
            'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
            'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12
          };
          
          final month = monthMap[monthStr];
          
          if (day != null && month != null && year != null) {
            return DateTime(year, month, day);
          }
        }
      }
      
      return null;
    } catch (e) {
      print('날짜 파싱 실패: $dateStr - $e');
      return null;
    }
  }
  
  // 날짜를 YYYY-MM-DD 형식으로 포맷
  static String formatToApiDate(String dateStr) {
    final parsedDate = parseDate(dateStr);
    if (parsedDate != null) {
      return '${parsedDate.year.toString().padLeft(4, '0')}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.day.toString().padLeft(2, '0')}';
    }
    return dateStr; // 파싱 실패 시 원본 반환
  }
  
  // 날짜를 화면 표시용으로 포맷
  static String formatForDisplay(String dateStr) {
    final parsedDate = parseDate(dateStr);
    if (parsedDate != null) {
      final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
      final weekday = weekdays[parsedDate.weekday - 1];
      return '${parsedDate.month}월 ${parsedDate.day}일 ($weekday)';
    }
    return dateStr;
  }
}