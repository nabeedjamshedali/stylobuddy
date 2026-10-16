import 'package:intl/intl.dart';

/// Port of `pkDate`: `yyyy-MM-dd` -> `'Oct 5'`; blank/invalid -> `'Choose
/// dates'`.
String pkDateLabel(String value) {
  if (value.isEmpty) return 'Choose dates';
  try {
    return DateFormat('MMM d').format(DateTime.parse(value));
  } on FormatException {
    return 'Choose dates';
  }
}
