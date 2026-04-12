extension StringCasingExtension on String {
  String toTitleCase() {
    if (isEmpty) return this;
    return split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }
}

extension DateTimeFormatExtension on DateTime {
  /// Returns "dd/MM/yyyy" formatted string.
  String toDisplayDate() {
    return '${day.toString().padLeft(2, '0')}/'
        '${month.toString().padLeft(2, '0')}/'
        '$year';
  }

  /// Returns "dd/MM/yyyy HH:mm" formatted string.
  String toDisplayDateTime() {
    return '${toDisplayDate()} '
        '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
  }
}
