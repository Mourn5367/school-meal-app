// frontend/lib/utils/date_utils.dart - 백엔드에서 시간 처리하므로 간소화

import 'dart:io';
class DateUtils {
  // 다양한 날짜 형식 지원 (RFC 2822, ISO 8601, 단순 날짜)
  static DateTime? parseDate(String dateStr) {
    try {
      print('📅 [DateUtils] 날짜 파싱: $dateStr');
      
      // RFC 2822 형식 처리 (예: "Fri, 06 Jun 2025 00:00:00 GMT")
      if (dateStr.contains(',') && (dateStr.contains('GMT') || dateStr.contains('UTC'))) {
        try {
          final utcTime = HttpDate.parse(dateStr);
          final localTime = utcTime.toLocal(); // UTC를 한국 시간으로 변환
          print('📅 [DateUtils] RFC 2822 파싱 성공: $dateStr → $localTime');
          return localTime;
        } catch (e) {
          print('⚠️ [DateUtils] HttpDate.parse 실패, 수동 파싱 시도: $e');
          return _parseRFC2822Manually(dateStr);
        }
      }
      
      // ISO 8601 형식 파싱 (백엔드에서 한국 시간으로 변환해서 보냄)
      if (dateStr.contains('T') || dateStr.contains('Z')) {
        final parsed = DateTime.parse(dateStr);
        print('📅 [DateUtils] ISO 8601 파싱 결과: $parsed');
        return parsed;
      }
      
      // 기본 날짜 형식 시도 (YYYY-MM-DD)
      if (dateStr.contains('-') && !dateStr.contains('T')) {
        final parts = dateStr.split('-');
        if (parts.length == 3) {
          final year = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final day = int.parse(parts[2]);
          final parsed = DateTime(year, month, day);
          print('📅 [DateUtils] 단순 날짜 파싱 결과: $parsed');
          return parsed;
        }
      }
      
      // 기본 DateTime.parse 시도
      final parsed = DateTime.parse(dateStr);
      print('📅 [DateUtils] 기본 파싱 결과: $parsed');
      return parsed;
      
    } catch (e) {
      print('❌ [DateUtils] 모든 파싱 실패: $dateStr - $e');
      return null;
    }
  }

  // RFC 2822 수동 파싱 (HttpDate.parse 실패 시 백업)
  static DateTime? _parseRFC2822Manually(String dateStr) {
    try {
      print('🔧 [Manual RFC2822] 시작: $dateStr');
      
      // "Fri, 06 Jun 2025 00:00:00 GMT" → 분해
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

            // UTC로 생성 후 로컬 시간으로 변환
            final utcDateTime = DateTime.utc(year, month, day, hour, minute, second);
            final localDateTime = utcDateTime.toLocal();
            print('🔧 [Manual RFC2822] 성공: $utcDateTime → $localDateTime');
            
            return localDateTime;
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

  // 상대 시간 계산 (백엔드에서 한국 시간으로 보내주므로 간단함)
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();

    print('⏰ [RelativeTime] 계산 시작');
    print('   게시 시간: $dateTime');
    print('   현재 시간: $now');

    // 백엔드에서 이미 한국 시간으로 변환했으므로 직접 계산
    final difference = now.difference(dateTime);

    print('   시간 차이: ${difference.inMinutes}분 (${difference.inHours}시간)');

    // 미래 시간인 경우 (서버 시간과 클라이언트 시간 차이)
    if (difference.isNegative) {
      print('⚠️ [RelativeTime] 미래 시간 감지');
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
      return '${dateTime.month}.${dateTime.day} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}