extension DateOnly on DateTime {
  String toIsoDate() => '${year}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
}