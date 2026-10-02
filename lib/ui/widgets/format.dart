/// Small date/time formatting helpers shared by the UI.
String formatDateTime(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
}

String formatDay(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.month)}/${two(d.day)}';
}
