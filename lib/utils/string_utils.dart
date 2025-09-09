/// Capitalizes the first letter of the given [text].
///
/// If the [text] is empty, it returns an empty string.
/// For example, `capitalizeFirstLetter("bulbasaur")` returns `"Bulbasaur"`.
String capitalizeFirstLetter(String text) {
  if (text.isEmpty) {
    return text;
  }
  return text.replaceFirstMapped(
    RegExp(r'^[a-z]'),
    (match) => match.group(0)!.toUpperCase(),
  );
}

/// Formats a hyphenated string into a capitalized, space-separated string.
///
/// Each word in the hyphenated [text] is capitalized.
/// If the [text] is empty, it returns an empty string.
/// For example, `formatHyphenatedName("special-attack")` returns `"Special Attack"`.
String formatHyphenatedName(String text) {
  if (text.isEmpty) {
    return text;
  }
  return text.split('-').map((word) => capitalizeFirstLetter(word)).join(' ');
}
