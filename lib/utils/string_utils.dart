String capitalizeFirstLetter(String text) {
  if (text.isEmpty) {
    return text;
  }
  return text.replaceFirstMapped(
    RegExp(r'^[a-z]'),
    (match) => match.group(0)!.toUpperCase(),
  );
}

String formatHyphenatedName(String text) {
  if (text.isEmpty) {
    return text;
  }
  return text.split('-').map((word) => capitalizeFirstLetter(word)).join(' ');
}
