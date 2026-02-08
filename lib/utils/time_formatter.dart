class TimeFormatter {
  static String formatSecondsToHm(int totalSeconds) {
    if (totalSeconds <= 0) return "0m";
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;

    if (hours > 0) {
      if (minutes > 0) {
        return "${hours}h ${minutes}m";
      } else {
        return "${hours}h";
      }
    } else {
      return "${minutes}m";
    }
  }
}
