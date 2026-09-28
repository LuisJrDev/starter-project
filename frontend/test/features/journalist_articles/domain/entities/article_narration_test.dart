import 'package:flutter_test/flutter_test.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/domain/entities/article_narration.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/domain/entities/published_article.dart';

PublishedArticleEntity articleWith({required String title, required String content}) {
  return PublishedArticleEntity(
    id: 'article-1',
    title: title,
    content: content,
    description: '',
    author: 'Daily News Staff',
    thumbnailUrl: 'https://example.com/1.jpg',
    publishedAt: DateTime.utc(2026, 9, 28),
  );
}

void main() {
  group('text', () {
    test('reads the title, the byline and then the content', () {
      final narration = ArticleNarrationEntity.of(articleWith(title: 'Breaking News', content: 'The body.'));

      expect(narration.text, 'Breaking News. Written by Daily News Staff. The body.');
    });

    test('turns Markdown headings, lists and paragraphs into sentences, so the voice pauses', () {
      const content = '## A newsroom in your pocket\n\n'
          'Starting today, **any journalist** can publish.\n\n'
          '### How it works\n\n'
          '1. Tap the button\n'
          '2. Write your story\n\n'
          '> "It is easy", said the editor';

      final narration = ArticleNarrationEntity.of(articleWith(title: 'Title', content: content));

      expect(
        narration.text,
        'Title. Written by Daily News Staff. A newsroom in your pocket. '
        'Starting today, any journalist can publish. How it works. '
        'Tap the button. Write your story. "It is easy", said the editor.',
      );
    });

    test('keeps the punctuation a sentence already has', () {
      final narration = ArticleNarrationEntity.of(articleWith(title: 'Is it true?', content: 'Yes!\nIndeed.'));

      expect(narration.text, 'Is it true? Written by Daily News Staff. Yes! Indeed.');
    });

    test('reads link texts but not image descriptions', () {
      final narration = ArticleNarrationEntity.of(
        articleWith(title: 'T', content: 'See [the report](https://example.com) ![chart](https://example.com/c.png)'),
      );

      expect(narration.text, 'T. Written by Daily News Staff. See the report.');
    });
  });

  group('languageTag', () {
    test('is Spanish for Spanish articles', () {
      final narration = ArticleNarrationEntity.of(articleWith(
        title: 'Vecinos convierten un solar en un huerto',
        content: 'Lo que antes era un aparcamiento abandonado es ahora un huerto para los niños del barrio.',
      ));

      expect(narration.languageTag, 'es-ES');
    });

    test('reads the byline in the language of the article', () {
      final narration = ArticleNarrationEntity.of(articleWith(
        title: 'Vecinos convierten un solar en un huerto',
        content: 'Lo que antes era un aparcamiento es ahora un huerto para los niños.',
      ));

      expect(narration.text, startsWith('Vecinos convierten un solar en un huerto. Escrito por Daily News Staff.'));
    });

    test('is English for English articles', () {
      final narration = ArticleNarrationEntity.of(articleWith(
        title: 'Neighbours turn an empty lot into a garden',
        content: 'What used to be an abandoned parking lot is now home to the trees of the neighbourhood.',
      ));

      expect(narration.languageTag, 'en-US');
    });

    test('defaults to English when there is nothing to tell them apart', () {
      expect(ArticleNarrationEntity.of(articleWith(title: 'OK', content: '1234')).languageTag, 'en-US');
    });
  });
}
