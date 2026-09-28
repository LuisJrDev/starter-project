import 'package:flutter_test/flutter_test.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/domain/entities/article_draft.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/domain/entities/article_thumbnail.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/domain/entities/invalid_article_draft_exception.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/domain/entities/published_article.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/domain/params/get_published_articles_params.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/domain/usecases/get_published_articles.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/domain/usecases/mock/mock_published_articles_store.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/domain/usecases/publish_article.dart';

const validDraft = ArticleDraftEntity(
  title: 'Breaking News!',
  content: '## Subtitle\n\nThis is **breaking** news.',
  author: 'Daily News Staff',
  thumbnail: ArticleThumbnailEntity(localPath: '/gallery/photo.jpg', sizeInBytes: 1024),
);

void main() {
  late PublishArticleUseCase publishArticle;
  late GetPublishedArticlesUseCase getPublishedArticles;

  setUp(() {
    final store = MockPublishedArticlesStore(latency: Duration.zero, initialArticles: const []);
    publishArticle = PublishArticleUseCase(store);
    getPublishedArticles = GetPublishedArticlesUseCase(store);
  });

  Future<List<PublishedArticleEntity>> listPublishedArticles() async {
    final page = await getPublishedArticles(params: const GetPublishedArticlesParams());
    return page.data!;
  }

  test('publishes a valid draft', () async {
    final result = await publishArticle(params: validDraft);

    expect(result, isA<DataSuccess<void>>());
    expect(await listPublishedArticles(), hasLength(1));
  });

  test('stores the trimmed text, the derived description and a Firestore-like id', () async {
    await publishArticle(params: validDraft.withTitle('  Breaking News!  ').withAuthor(' Staff '));

    final article = (await listPublishedArticles()).single;
    expect(article.title, 'Breaking News!');
    expect(article.author, 'Staff');
    expect(article.content, validDraft.content);
    expect(article.description, 'Subtitle This is breaking news.');
    expect(article.id, matches(RegExp(r'^[A-Za-z0-9]{20}$')));
    expect(DateTime.now().difference(article.publishedAt).inSeconds, lessThan(5));
  });

  test('rejects an invalid draft with every error and publishes nothing', () async {
    final result = await publishArticle(params: const ArticleDraftEntity(title: 'Only a title'));

    expect(result, isA<DataFailed<void>>());
    expect((result.error! as InvalidArticleDraftException).errors, {
      ArticleDraftError.contentEmpty,
      ArticleDraftError.authorEmpty,
      ArticleDraftError.thumbnailMissing,
    });
    expect(await listPublishedArticles(), isEmpty);
  });

  test('treats a missing draft as an empty one', () async {
    final result = await publishArticle();

    expect((result.error! as InvalidArticleDraftException).errors, contains(ArticleDraftError.titleEmpty));
  });
}
