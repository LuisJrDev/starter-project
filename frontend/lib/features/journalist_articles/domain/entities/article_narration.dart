import 'package:equatable/equatable.dart';

import 'markdown_text.dart';
import 'published_article.dart';

/// What the device reads aloud for an article: title, byline and content as plain sentences
/// (so the voice pauses after headings and list items), in the article's language.
class ArticleNarrationEntity extends Equatable {
  static const String english = 'en-US';
  static const String spanish = 'es-ES';

  final String text;

  /// BCP 47 tag of the voice to use.
  final String languageTag;

  const ArticleNarrationEntity({required this.text, required this.languageTag});

  factory ArticleNarrationEntity.of(PublishedArticleEntity article) {
    final contentLines = markdownToPlainLines(article.content);
    final languageTag = _guessLanguageTag([article.title, ...contentLines].join(' '));
    final byline = '${languageTag == spanish ? 'Escrito por' : 'Written by'} ${article.author}';
    final sentences = [article.title, byline, ...contentLines].map(_asSentence);
    return ArticleNarrationEntity(text: sentences.join(' '), languageTag: languageTag);
  }

  @override
  List<Object?> get props => [text, languageTag];
}

final _sentenceEnding = RegExp(r'[.!?:;…"]$');

String _asSentence(String line) => _sentenceEnding.hasMatch(line) ? line : '$line.';

const _spanishWords = {
  'el', 'la', 'los', 'las', 'de', 'del', 'que', 'y', 'en', 'un', 'una', 'es', 'por', 'para', 'con', 'su', 'lo', 'al', 'se',
};
const _englishWords = {
  'the', 'and', 'of', 'to', 'is', 'in', 'that', 'for', 'with', 'it', 'on', 'by', 'an', 'this', 'are', 'what', 'from',
};
final _nonLetters = RegExp(r'[^a-záéíóúüñ]+');

/// English or Spanish, whichever has more of its most common words. English when tied.
String _guessLanguageTag(String text) {
  final words = text.toLowerCase().split(_nonLetters);
  final spanishCount = words.where(_spanishWords.contains).length;
  final englishCount = words.where(_englishWords.contains).length;
  return spanishCount > englishCount ? ArticleNarrationEntity.spanish : ArticleNarrationEntity.english;
}
