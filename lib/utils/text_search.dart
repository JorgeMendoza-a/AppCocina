/// Normaliza texto para búsquedas: minúsculas y sin tildes,
/// así "brocoli" encuentra "Brócoli".
String normalizeForSearch(String input) {
  const from = 'áéíóúüñ';
  const to = 'aeiouun';
  final lower = input.toLowerCase().trim();
  final buffer = StringBuffer();
  for (final rune in lower.runes) {
    final char = String.fromCharCode(rune);
    final index = from.indexOf(char);
    buffer.write(index >= 0 ? to[index] : char);
  }
  return buffer.toString().replaceAll(RegExp(r'\s+'), ' ');
}
