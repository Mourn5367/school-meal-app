// frontend/lib/utils/date_utils.dart - 안드로이드 시간 문제 완전 해결
import 'dart:io';

class DateUtils {
  // 모든 날짜를 한국 시간대(UTC+9)로 통일하여 처리
  static DateTime? parseDate(String dateStr) {
    try {
      print('🕐 [DateUtils] 시간 파싱 시작: $dateStr');
      print('🤖 [DateUtils] 플랫폼: ${Platform.isAndroid ? "Android" : "기타"}');
      print('🌏 [DateUtils] 현재 시간대 오프셋: ${DateTime.now().timeZoneOffset}');

      DateTime? parsed;

      // RFC 2822 형식 처리 (예: "Sun, 01 Jun 2025 09:58:40 GMT")
      if (dateStr.contains(',') && (dateStr.contains('GMT') || dateStr.contains('UTC'))) {
        parsed = _parseRFC2822(dateStr);
      }
      // ISO 8601 형식 처리 (예: "2025-06-01T09:58:40.000Z" 또는 "2025-06-01T09:58:40.000")
      else if (dateStr.contains('-') && dateStr.contains('T')) {
        parsed = _parseISO8601(dateStr);
      }
      // YYYY-MM-DD 형식 (날짜만)
      else if (dateStr.contains('-') && !dateStr.contains('T')) {
        parsed = _parseSimpleDate(dateStr);
      }
      // 기본 파싱 시도
      else {
        try {
          parsed = DateTime.parse(dateStr);
        } catch (e) {
          print('❌ [DateUtils] 기본 파싱 실패: $e');
          return null;
        }
      }

      if (parsed == null) {
        print('❌ [DateUtils] 파싱 실패: $dateStr');
        return null;
      }

      // 안드로이드에서는 항상 로컬 시간으로 변환
      DateTime finalTime;
      if (Platform.isAndroid) {
        // 안드로이드: 무조건 로컬 시간으로 처리
        if (parsed.isUtc) {
          finalTime = parsed.toLocal();
          print('📱 [Android] UTC → 로컬 변환: $parsed → $finalTime');
        } else {
          finalTime = parsed;
          print('📱 [Android] 이미 로컬 시간: $finalTime');
        }
      } else {
        // 다른 플랫폼: 기존 로직
        finalTime = parsed.isUtc ? parsed.toLocal() : parsed;
        print('💻 [Other Platform] 결과: $finalTime');
      }

      print('✅ [DateUtils] 최종 결과: $finalTime (UTC: ${finalTime.isUtc})');
      return finalTime;

    } catch (e) {
      print('❌ [DateUtils] 전체 파싱 실패: $dateStr - $e');
      return null;
    }
  }

  // RFC 2822 형식 파싱 (서버에서 오는 created_at 필드)
  static DateTime? _parseRFC2822(String dateStr) {
    try {
      print('📧 [RFC2822] 파싱 시작: $dateStr');

      // HttpDate.parse 시도 (가장 안정적)
      try {
        final utcTime = HttpDate.parse(dateStr);
        print('📧 [RFC2822] HttpDate.parse 성공: $utcTime (UTC)');
        return utcTime; // UTC 시간 반환, 나중에 toLocal() 적용됨
      } catch (e) {
        print('⚠️ [RFC2822] HttpDate.parse 실패, 수동 파싱 시도: $e');
      }

      // 수동 파싱
      return _parseRFC2822Manually(dateStr);
    } catch (e) {
      print('❌ [RFC2822] 파싱 실패: $e');
      return null;
    }
  }

  // ISO 8601 형식 파싱
  static DateTime? _parseISO8601(String dateStr) {
    try {
      print('📅 [ISO8601] 파싱 시작: $dateStr');

      final parsed = DateTime.parse(dateStr);
      print('📅 [ISO8601] 파싱 결과: $parsed (UTC: ${parsed.isUtc})');

      return parsed;
    } catch (e) {
      print('❌ [ISO8601] 파싱 실패: $e');
      return null;
    }
  }

  // 단순 날짜 형식 파싱 (YYYY-MM-DD)
  static DateTime? _parseSimpleDate(String dateStr) {
    try {
      print('📆 [SimpleDate] 파싱 시작: $dateStr');

      final parts = dateStr.split('-');
      if (parts.length == 3) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);

        // 로컬 시간대로 생성 (자정)
        final parsed = DateTime(year, month, day);
        print('📆 [SimpleDate] 결과: $parsed');
        return parsed;
      }
      return null;
    } catch (e) {
      print('❌ [SimpleDate] 파싱 실패: $e');
      return null;
    }
  }

  // RFC 2822 수동 파싱
  static DateTime? _parseRFC2822Manually(String dateStr) {
    try {
      print('🔧 [Manual RFC2822] 시작: $dateStr');

      // "Sun, 01 Jun 2025 09:58:40 GMT" → 분해
      final cleaned = dateStr.replaceAll(',', '').trim();
      final parts = cleaned.split(' ');

      if (parts.length >= 6) {
        final day = int.tryParse(parts[1]);
        final monthStr = parts[2];
        final year = int.tryParse(parts[3]);
        final timePart = parts[4];

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

            // 항상 UTC로 생성 (GMT/UTC 표시가 있으므로)
            final utcDateTime = DateTime.utc(year, month, day, hour, minute, second);
            print('🔧 [Manual RFC2822] UTC 결과: $utcDateTime');

            return utcDateTime;
          }
        }
      }

      print('❌ [Manual RFC2822] 파싱 실패: 형식 불일치');
      return null;
    } catch (e) {
      print('❌ [Manual RFC2822] 예외 발생: $e');
      return null;
    }
  }

  // API 전송용 날짜 포맷 (YYYY-MM-DD)
  static String formatToApiDate(String dateStr) {
    final parsedDate = parseDate(dateStr);
    if (parsedDate != null) {
      final formatted = '${parsedDate.year.toString().padLeft(4, '0')}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.day.toString().padLeft(2, '0')}';
      print('🔄 [API Format] $dateStr → $formatted');
      return formatted;
    }
    print('⚠️ [API Format] 변환 실패, 원본 반환: $dateStr');
    return dateStr;
  }

  // 화면 표시용 날짜 포맷
  static String formatForDisplay(String dateStr) {
    final parsedDate = parseDate(dateStr);
    if (parsedDate != null) {
      final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
      final weekday = weekdays[parsedDate.weekday - 1];
      final formatted = '${parsedDate.month}월 ${parsedDate.day}일 ($weekday)';
      print('🎨 [Display Format] $dateStr → $formatted');
      return formatted;
    }
    print('⚠️ [Display Format] 변환 실패, 원본 반환: $dateStr');
    return dateStr;
  }

  // 상대 시간 계산 (몇 분 전, 몇 시간 전 등)
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();

    print('⏰ [RelativeTime] 계산 시작');
    print('   게시 시간: $dateTime (UTC: ${dateTime.isUtc})');
    print('   현재 시간: $now (UTC: ${now.isUtc})');
    print('   플랫폼: ${Platform.isAndroid ? "Android" : "기타"}');

    // 시간 통일 (둘 다 로컬 시간으로)
    DateTime finalPostTime = dateTime.isUtc ? dateTime.toLocal() : dateTime;
    DateTime finalNowTime = now.isUtc ? now.toLocal() : now;

    print('   통일 후 게시: $finalPostTime');
    print('   통일 후 현재: $finalNowTime');

    final difference = finalNowTime.difference(finalPostTime);
    print('   시간 차이: ${difference.inMinutes}분 (${difference.inHours}시간, ${difference.inDays}일)');

    // 미래 시간 처리 (시간대 오류나 동기화 문제)
    if (difference.isNegative) {
      print('⚠️ [RelativeTime] 미래 시간 감지, 절댓값으로 계산');
      final absDiff = difference.abs();

      if (absDiff.inMinutes < 1) {
        return '방금 전';
      } else if (absDiff.inMinutes < 60) {
        return '${absDiff.inMinutes}분 전';
      } else if (absDiff.inHours < 24) {
        return '${absDiff.inHours}시간 전';
      } else {
        return '${absDiff.inDays}일 전';
      }
    }

    // 정상적인 과거 시간
    if (difference.inSeconds < 30) {
      return '방금 전';
    } else if (difference.inMinutes < 1) {
      return '1분 미만';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      // 일주일 이상은 구체적 날짜
      return '${finalPostTime.month}.${finalPostTime.day} ${finalPostTime.hour.toString().padLeft(2, '0')}:${finalPostTime.minute.toString().padLeft(2, '0')}';
    }
  }
}