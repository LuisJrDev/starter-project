/// Plain-text views of an article's Markdown content, shared by the entities.
///
/// Keep in sync with deriveDescription() in backend/scripts/seed.mjs.

final _markdownImage = RegExp(r'!\[[^\]]*\]\([^)]*\)');
final _markdownLink = RegExp(r'\[([^\]]*)\]\([^)]*\)');
final _markdownLinePrefix = RegExp(r'^\s{0,3}(#{1,6}|>|[-*+]|\d+\.)\s+', multiLine: true);
final _markdownInlineMarker = RegExp(r'(\*\*|__|\*|_|~~|`)');
final _whitespace = RegExp(r'\s+');

/// The content without Markdown syntax, on a single line.
String markdownToPlainText(String markdown) {
  return _stripMarkdown(markdown).replaceAll(_whitespace, ' ').trim();
}

/// Every non-empty line of the content (heading, list item or paragraph) without Markdown syntax.
List<String> markdownToPlainLines(String markdown) {
  return _stripMarkdown(markdown)
      .split('\n')
      .map((line) => line.replaceAll(_whitespace, ' ').trim())
      .where((line) => line.isNotEmpty)
      .toList();
}

String _stripMarkdown(String markdown) {
  return markdown
      .replaceAll(_markdownImage, '')
      .replaceAllMapped(_markdownLink, (match) => match[1]!)
      .replaceAll(_markdownLinePrefix, '')
      .replaceAll(_markdownInlineMarker, '');
}
