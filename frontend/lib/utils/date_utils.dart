// frontend/lib/utils/date_utils.dart - 안드로이드 시간 문제 해결 버전
import 'dart:io';

class DateUtils {
  // RFC 2822 형식과 ISO 8601 형식 모두 처리
  static DateTime? parseDate(String dateStr) {
    try {
      print('🕐 시간 파싱 시작: $dateStr');
      print('🤖 플랫폼: ${Platform.isAndroid ? "Android" : "기타"}');

      // RFC 2822 형식 처리 (예: "Sun, 01 Jun 2025 09:58:40 GMT")
      if (dateStr.contains(',') && dateStr.contains('GMT')) {
        // HttpDate.parse를 사용하여 RFC 2822 파싱
        try {
          final parsed = HttpDate.parse(dateStr);
          final localTime = parsed.toLocal(); // UTC를 로컬 시간으로 변환

          print('📅 RFC 2822 파싱 성공:');
          print('   원본(UTC): $parsed');
          print('   로컬시간: $localTime');
          print('   시간대차이: ${localTime.timeZoneOffset}');

          return localTime;
        } catch (e) {
          print('❌ HttpDate.parse 실패: $e');
          // 수동 파싱 시도
          return _parseRFC2822Manually(dateStr);
        }
      }

      // ISO 8601 형식 처리 (예: "2025-06-01T09:58:40.000Z")
      if (dateStr.contains('-') && !dateStr.contains(',')) {
        final parsed = DateTime.parse(dateStr);
        final localTime = parsed.isUtc ? parsed.toLocal() : parsed;

        print('📅 ISO 8601 파싱 성공:');
        print('   원본: $parsed (UTC: ${parsed.isUtc})');
        print('   로컬시간: $localTime');

        return localTime;
      }

      // 기본 파싱 시도
      final parsed = DateTime.parse(dateStr);
      return parsed.isUtc ? parsed.toLocal() : parsed;

    } catch (e) {
      print('❌ 날짜 파싱 완전 실패: $dateStr - $e');
      return null;
    }
  }

  // RFC 2822 수동 파싱 (HttpDate.parse 실패 시 백업)
  static DateTime? _parseRFC2822Manually(String dateStr) {
    try {
      // "Sun, 01 Jun 2025 09:58:40 GMT" 형식 분해
      final parts = dateStr.replaceAll(',', '').split(' ');
      if (parts.length >= 6) {
        final day = int.tryParse(parts[1]);
        final monthStr = parts[2];
        final year = int.tryParse(parts[3]);
        final timePart = parts[4]; // "09:58:40"

        final monthMap = {
          'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
          'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12
        };

        final month = monthMap[monthStr];

        if (day != null && month != null && year != null) {
          final timeComponents = timePart.split(':');
          if (timeComponents.length == 3) {
            final hour = int.tryParse(timeComponents[0]) ?? 0;
            final minute = int.tryParse(timeComponents[1]) ?? 0;
            final second = int.tryParse(timeComponents[2]) ?? 0;

            // UTC 시간으로 생성 후 로컬 시간으로 변환
            final utcDateTime = DateTime.utc(year, month, day, hour, minute, second);
            final localDateTime = utcDateTime.toLocal();

            print('🔧 수동 파싱 성공:');
            print('   UTC: $utcDateTime');
            print('   로컬: $localDateTime');

            return localDateTime;
          }
        }
      }
      return null;
    } catch (e) {
      print('❌ 수동 파싱 실패: $e');
      return null;
    }
  }

  // 날짜를 YYYY-MM-DD 형식으로 포맷
  static String formatToApiDate(String dateStr) {
    final parsedDate = parseDate(dateStr);
    if (parsedDate != null) {
      return '${parsedDate.year.toString().padLeft(4, '0')}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.day.toString().padLeft(2, '0')}';
    }
    return dateStr;
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