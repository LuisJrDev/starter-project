import 'package:flutter_test/flutter_test.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/domain/entities/published_article.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/domain/params/get_published_articles_params.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/domain/usecases/get_published_articles.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/domain/usecases/mock/mock_published_articles_store.dart';

PublishedArticleEntity articlePublishedOn(int day) {
  return PublishedArticleEntity(
    id: 'article-$day',
    title: 'Article of day $day',
    content: 'Content',
    description: 'Content',
    author: 'Author',
    thumbnailUrl: 'https://example.com/$day.jpg',
    publishedAt: DateTime(2026, 9, day),
  );
}

List<String> idsOf(DataState<List<PublishedArticleEntity>> page) {
  return page.data!.map((article) => article.id).toList();
}

void main() {
  late GetPublishedArticlesUseCase getPublishedArticles;

  setUp(() {
    final unsortedArticles = [articlePublishedOn(2), articlePublishedOn(5), articlePublishedOn(1), articlePublishedOn(4), articlePublishedOn(3)];
    final store = MockPublishedArticlesStore(latency: Duration.zero, initialArticles: unsortedArticles);
    getPublishedArticles = GetPublishedArticlesUseCase(store);
  });

  test('returns the newest articles first', () async {
    final page = await getPublishedArticles(params: const GetPublishedArticlesParams());

    expect(page, isA<DataSuccess<List<PublishedArticleEntity>>>());
    expect(idsOf(page), ['article-5', 'article-4', 'article-3', 'article-2', 'article-1']);
  });

  test('returns at most pageSize articles', () async {
    final page = await getPublishedArticles(params: const GetPublishedArticlesParams(pageSize: 2));

    expect(idsOf(page), ['article-5', 'article-4']);
  });

  test('continues after the last article of the previous page', () async {
    final page = await getPublishedArticles(
      params: GetPublishedArticlesParams(pageSize: 2, startAfter: articlePublishedOn(4)),
    );

    expect(idsOf(page), ['article-3', 'article-2']);
  });

  test('returns an empty page after the last article', () async {
    final page = await getPublishedArticles(params: GetPublishedArticlesParams(startAfter: articlePublishedOn(1)));

    expect(idsOf(page), isEmpty);
  });

  test('uses the default page when no params are given', () async {
    final page = await getPublishedArticles();

    expect(idsOf(page), hasLength(5));
  });

  test('the default mock store starts with the sample articles seeded in the backend', () async {
    final page = await GetPublishedArticlesUseCase(MockPublishedArticlesStore(latency: Duration.zero))();

    expect(page.data, isNotEmpty);
  });
}
