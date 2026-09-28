import 'dart:math';

import '../../entities/article_draft.dart';
import '../../entities/published_article.dart';
import '../../params/get_published_articles_params.dart';

/// TEMPORARY in-memory stand-in for the backend, shared by the use cases until the
/// data layer exists (phase 2.3). It lets the presentation layer publish an article and
/// then see it in the list, with a simulated network latency.
class MockPublishedArticlesStore {
  // Mock uploads cannot store the picked image, so new articles reuse a sample thumbnail.
  static const String _placeholderThumbnailUrl =
      'https://firebasestorage.googleapis.com/v0/b/backend-news-symmetry.firebasestorage.app/o/media%2Farticles%2Fuf6vZSr0ZiUAYhBkx4YN.jpg?alt=media&token=0369e607-8bcb-4f75-9bea-4eaf6ce1667c';
  static const String _idAlphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

  final Duration latency;
  final List<PublishedArticleEntity> _articles;
  final Random _random = Random();

  MockPublishedArticlesStore({
    this.latency = const Duration(milliseconds: 800),
    List<PublishedArticleEntity>? initialArticles,
  }) : _articles = [...initialArticles ?? _sampleArticles()];

  Future<void> addArticleFrom(ArticleDraftEntity draft) async {
    await Future.delayed(latency);
    _articles.add(_publishedArticleFrom(draft));
  }

  Future<List<PublishedArticleEntity>> findPage(GetPublishedArticlesParams params) async {
    await Future.delayed(latency);
    final newestFirst = [..._articles]..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    final startIndex = _indexAfter(newestFirst, params.startAfter);
    return newestFirst.skip(startIndex).take(params.pageSize).toList();
  }

  int _indexAfter(List<PublishedArticleEntity> articles, PublishedArticleEntity? startAfter) {
    if (startAfter == null) return 0;
    return articles.indexWhere((article) => article.id == startAfter.id) + 1;
  }

  PublishedArticleEntity _publishedArticleFrom(ArticleDraftEntity draft) {
    return PublishedArticleEntity(
      id: _newFirestoreLikeId(),
      title: draft.title,
      content: draft.content,
      description: draft.description,
      author: draft.author,
      thumbnailUrl: _placeholderThumbnailUrl,
      publishedAt: DateTime.now(),
    );
  }

  String _newFirestoreLikeId() {
    return List.generate(20, (_) => _idAlphabet[_random.nextInt(_idAlphabet.length)]).join();
  }
}

/// The two articles seeded in the real backend (backend/scripts/seed-data/articles.json).
List<PublishedArticleEntity> _sampleArticles() => [_newsroomSampleArticle(), _gardenSampleArticle()];

PublishedArticleEntity _newsroomSampleArticle() {
  const draft = ArticleDraftEntity(
    title: 'Breaking News: Journalists can now publish from the app',
    author: 'Daily News Staff',
    content: '## A newsroom in your pocket\n\n'
        'Starting today, **any journalist** can write and publish an article directly from the Daily News app.\n\n'
        '### How it works\n\n'
        '1. Tap the **+** button on the home screen.\n'
        '2. Write a title, attach a thumbnail from your gallery and write your story.\n'
        '3. Press **Publish Article**.\n\n'
        'Articles support *Markdown*, so you can use **bold text**, headings and lists to structure your story.',
  );
  return PublishedArticleEntity(
    id: 'uf6vZSr0ZiUAYhBkx4YN',
    title: draft.title,
    content: draft.content,
    description: draft.description,
    author: draft.author,
    thumbnailUrl: MockPublishedArticlesStore._placeholderThumbnailUrl,
    publishedAt: DateTime.utc(2026, 9, 28, 16, 23, 33),
  );
}

PublishedArticleEntity _gardenSampleArticle() {
  const draft = ArticleDraftEntity(
    title: 'Neighbours turn an empty lot into a community garden',
    author: 'Local Desk',
    content: '## From concrete to tomatoes\n\n'
        'What used to be an abandoned parking lot is now home to **seven fruit trees** and more than forty vegetable beds.\n\n'
        '### Get involved\n\n'
        '- Volunteer sessions run every *Saturday morning*.\n'
        '- Tools and seeds are provided.\n'
        '- Everyone is welcome, no experience needed.\n\n'
        '> "We wanted a place where kids could see where food comes from", said one of the organisers.',
  );
  return PublishedArticleEntity(
    id: '0Xiew9LulX68dBb26qlf',
    title: draft.title,
    content: draft.content,
    description: draft.description,
    author: draft.author,
    thumbnailUrl:
        'https://firebasestorage.googleapis.com/v0/b/backend-news-symmetry.firebasestorage.app/o/media%2Farticles%2F0Xiew9LulX68dBb26qlf.png?alt=media&token=df232e6c-28b6-4506-aa25-273dadb3e23c',
    publishedAt: DateTime.utc(2026, 9, 28, 16, 23, 34),
  );
}
