import 'package:fl_clash/common/app_localizations.dart';

extension DateTimeExtension on DateTime {
  bool get isBeforeNow {
    return isBefore(DateTime.now());
  }

  bool isBeforeSecure(DateTime? dateTime) {
    if (dateTime == null) {
      return false;
    }
    return true;
  }

  String get lastUpdateTimeDesc {
    final currentDateTime = DateTime.now();
    final difference = currentDateTime.difference(this);
    final days = difference.inDays;
    if (days >= 365) {
      return "${(days / 365).floor()} ${appLocalizations.years}${appLocalizations.ago}";
    }
    if (days >= 30) {
      return "${(days / 30).floor()} ${appLocalizations.months}${appLocalizations.ago}";
    }
    if (days >= 1) {
      return "$days ${appLocalizations.days}${appLocalizations.ago}";
    }
    final hours = difference.inHours;
    if (hours >= 1) {
      return "$hours ${appLocalizations.hours}${appLocalizations.ago}";
    }
    final minutes = difference.inMinutes;
    if (minutes >= 1) {
      return "$minutes ${appLocalizations.minutes}${appLocalizations.ago}";
    }
    return appLocalizations.just;
  }

  String get show3 {
    return toIso8601String().substring(0, 10);
  }

  String get show {
    return toIso8601String().substring(0, 16);    //只显示日期如YYYY-MM-DDTHH:MM:SS，日期和时间中多了一个T字母 16与19
   // return toIso8601String().substring(0, 10);  //只显示日期如YYYY-MM-DD 共计10位
  }
  String get showse {
    return toIso8601String().substring(0, 19);    //只显示日期如YYYY-MM-DDTHH:MM:SS，日期和时间中多了一个T字母 16与19
   // return toIso8601String().substring(0, 10);  //只显示日期如YYYY-MM-DD 共计10位
  }
}
