// Fallback for platforms without dart:io or dart:html. No real target exists,
// so report the file as not delivered.
Future<bool> saveAndShareExcel(List<int> bytes, String filename) async {
  return false;
}
