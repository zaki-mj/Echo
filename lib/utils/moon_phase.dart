class MoonPhase {
  static String getMoonEmoji(DateTime date) {
    final phase = calculatePhase(date);
    switch (phase) {
      case 0:
        return '🌑'; // New Moon
      case 1:
        return '🌒'; // Waxing Crescent
      case 2:
        return '🌓'; // First Quarter
      case 3:
        return '🌔'; // Waxing Gibbous
      case 4:
        return '🌕'; // Full Moon
      case 5:
        return '🌖'; // Waning Gibbous
      case 6:
        return '🌗'; // Last Quarter
      case 7:
        return '🌘'; // Waning Crescent
      default:
        return '🌑';
    }
  }

  static int calculatePhase(DateTime date) {
    // Julian Day calculation
    final year = date.year;
    final month = date.month;
    final day = date.day;

    if (month <= 2) {
      final year2 = year - 1;
      final month2 = month + 12;
      final jd = (365.25 * (year2 + 4716)).floor() +
          (30.6001 * (month2 + 1)).floor() +
          day +
          2 -
          (year2 / 100).floor() +
          ((year2 / 100).floor() / 4).floor() -
          1524.5;
      final daysSinceNew = (jd - 2451549.5) % 29.53058867;
      return ((daysSinceNew / 29.53058867) * 8).floor() % 8;
    } else {
      final jd = (365.25 * (year + 4716)).floor() +
          (30.6001 * (month + 1)).floor() +
          day +
          2 -
          (year / 100).floor() +
          ((year / 100).floor() / 4).floor() -
          1524.5;
      final daysSinceNew = (jd - 2451549.5) % 29.53058867;
      return ((daysSinceNew / 29.53058867) * 8).floor() % 8;
    }
  }

  static String getPhaseName(DateTime date) {
    final phase = calculatePhase(date);
    switch (phase) {
      case 0:
        return 'New Moon';
      case 1:
        return 'Waxing Crescent';
      case 2:
        return 'First Quarter';
      case 3:
        return 'Waxing Gibbous';
      case 4:
        return 'Full Moon';
      case 5:
        return 'Waning Gibbous';
      case 6:
        return 'Last Quarter';
      case 7:
        return 'Waning Crescent';
      default:
        return 'New Moon';
    }
  }
}

