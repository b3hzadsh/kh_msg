import 'dart:math';

class CourseSpec {
  const CourseSpec({
    required this.title,
    required this.totalSessions,
    required this.sessionLinks,
  });

  final String title;
  final int totalSessions;
  final Map<int, String> sessionLinks;

  String? linkForSession(int sessionNumber) => sessionLinks[sessionNumber];
}

enum CourseType {
  courseA(
    CourseSpec(
      title: 'دوره جامع نمونه ۱',
      totalSessions: 8,
      sessionLinks: {
        1: 'https://example.com/course-a/s1.mp4',
        2: 'https://example.com/course-a/s2.mp4',
        3: 'https://example.com/course-a/s3.mp4',
        4: 'https://example.com/course-a/s4.mp4',
        5: 'https://example.com/course-a/s5.mp4',
        6: 'https://example.com/course-a/s6.mp4',
        7: 'https://example.com/course-a/s7.mp4',
        8: 'https://example.com/course-a/s8.mp4',
      },
    ),
  ),
  courseB(
    CourseSpec(
      title: 'دوره تخصصی نمونه ۲',
      totalSessions: 6,
      sessionLinks: {
        1: 'https://example.com/course-b/s1.mp4',
        2: 'https://example.com/course-b/s2.mp4',
        3: 'https://example.com/course-b/s3.mp4',
        4: 'https://example.com/course-b/s4.mp4',
        5: 'https://example.com/course-b/s5.mp4',
        6: 'https://example.com/course-b/s6.mp4',
      },
    ),
  ),
  courseC(
    CourseSpec(
      title: 'دوره فشرده نمونه ۳',
      totalSessions: 4,
      sessionLinks: {
        1: 'https://example.com/course-c/s1.mp4',
        2: 'https://example.com/course-c/s2.mp4',
        3: 'https://example.com/course-c/s3.mp4',
        4: 'https://example.com/course-c/s4.mp4',
      },
    ),
  );

  const CourseType(this.spec);
  final CourseSpec spec;
}

class MessageGenerator {
  MessageGenerator({Random? random}) : _random = random ?? Random();

  final Random _random;

  static const List<String> quotes = [
    'آموزش تنها سلاح قدرتمندی است که با آن میتوان دنیا را تغییر داد',
    'استمرار کوچک اما روزانه، معجزه‌ای می‌سازد که جهش‌های مقطعی نمی‌توانند',
    'هر قدمی که امروز برای یادگیری برداری، فردای تو را ساده‌تر می‌کند',
    'دانش وقتی ارزشمند است که در عمل به کار گرفته شود',
    'بهترین زمان برای شروع، همین لحظه‌ای است که تصمیم می‌گیری',
  ];

  static const Map<int, String> _ordinalWords = {
    1: 'اول',
    2: 'دوم',
    3: 'سوم',
    4: 'چهارم',
    5: 'پنجم',
    6: 'ششم',
    7: 'هفتم',
    8: 'هشتم',
    9: 'نهم',
    10: 'دهم',
    11: 'یازدهم',
    12: 'دوازدهم',
  };

  static String sessionOrdinal(int number) {
    return _ordinalWords[number] ?? '${number}ام';
  }

  static String toPersianDigits(Object value) {
    const map = {
      '0': '۰',
      '1': '۱',
      '2': '۲',
      '3': '۳',
      '4': '۴',
      '5': '۵',
      '6': '۶',
      '7': '۷',
      '8': '۸',
      '9': '۹',
    };
    return value.toString().replaceAllMapped(
      RegExp(r'[0-9]'),
      (match) => map[match.group(0)!]!,
    );
  }

  (String quote, List<String> updatedUsedQuotes) pickQuote(
    List<String> usedQuotes,
  ) {
    final nextUsed = List<String>.from(usedQuotes);
    var available = quotes.where((q) => !nextUsed.contains(q)).toList();

    if (available.isEmpty) {
      nextUsed.clear();
      available = List<String>.from(quotes);
    }

    final chosen = available[_random.nextInt(available.length)];
    nextUsed.add(chosen);
    return (chosen, nextUsed);
  }

  String buildFinalMessage({
    required String senderTitle,
    required String orgTitle,
    required String quote,
    required CourseType course,
    required int sessionNumber,
  }) {
    final spec = course.spec;
    if (sessionNumber < 1 || sessionNumber > spec.totalSessions) {
      throw ArgumentError(
        'شماره جلسه باید بین ۱ و ${spec.totalSessions} باشد.',
      );
    }

    final link = spec.linkForSession(sessionNumber);
    if (link == null || link.trim().isEmpty) {
      throw StateError(
        'لینک جلسه $sessionNumber برای ${spec.title} تعریف نشده است.',
      );
    }

    final ordinal = sessionOrdinal(sessionNumber);
    final header = '${senderTitle.trim()}-${orgTitle.trim()}';
    final linkBlock =
        '▪️ لینک دانلود مستقیم جلسه $ordinal 👇🏻\n\n${link.trim()}';

    final footer = sessionNumber == spec.totalSessions
        ? 'این ${toPersianDigits(spec.totalSessions)} جلسه به عنوان هدیه خدمت شما🙏🏻🌹بعد از مشاهده حتما اطلاع بدید'
        : 'لطفا بعد از گوش کردن به فایل صوتی ، خلاصه نویسی هاتون رو برام ارسال کنید تا جلسه ی بعدی رو براتون بفرستم .';

    return '$header\n$quote\nدرنگ نکن انجامش بده \n\n$linkBlock\n\n$footer';
  }
}
