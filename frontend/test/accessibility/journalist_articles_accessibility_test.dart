import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:news_app_clean_architecture/config/theme/app_themes.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/entities/article.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/widgets/article_tile.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/domain/entities/article_draft.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/domain/entities/article_narration.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/domain/entities/article_narration_progress.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/domain/entities/published_article.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/domain/usecases/discard_draft.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/domain/usecases/get_published_articles.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/domain/usecases/pick_thumbnail_from_gallery.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/domain/usecases/publish_article.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/domain/usecases/read_article_aloud.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/domain/usecases/resume_draft.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/domain/usecases/save_draft.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/domain/usecases/stop_reading_aloud.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/presentation/bloc/article_narration/article_narration_cubit.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/presentation/bloc/publish_article/publish_article_cubit.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/presentation/bloc/published_articles/published_articles_cubit.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/presentation/pages/publish_article/publish_article.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/presentation/pages/published_article_detail/published_article_detail.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/presentation/widgets/follow_along_text.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/presentation/widgets/published_articles_list.dart';

import '../helpers/localized_app.dart';

class MockPublishArticleUseCase extends Mock implements PublishArticleUseCase {}

class MockPickThumbnailFromGalleryUseCase extends Mock implements PickThumbnailFromGalleryUseCase {}

class MockResumeDraftUseCase extends Mock implements ResumeDraftUseCase {}

class MockSaveDraftUseCase extends Mock implements SaveDraftUseCase {}

class MockDiscardDraftUseCase extends Mock implements DiscardDraftUseCase {}

class MockReadArticleAloudUseCase extends Mock implements ReadArticleAloudUseCase {}

class MockStopReadingAloudUseCase extends Mock implements StopReadingAloudUseCase {}

class MockGetPublishedArticlesUseCase extends Mock implements GetPublishedArticlesUseCase {}

final article = PublishedArticleEntity(
  id: 'article-1',
  title: 'Breaking News: journalists can now publish from the app',
  content: '## A newsroom in your pocket\n\nStarting today, **any journalist** can publish.\n\n1. Tap the button\n2. Write',
  description: 'A newsroom in your pocket Starting today, any journalist can publish.',
  author: 'Daily News Staff',
  thumbnailUrl: 'https://example.com/1.jpg',
  publishedAt: DateTime.utc(2026, 9, 28, 12),
);

/// Every combination the app can be shown in.
final variants = ValueVariant<({String name, ThemeData theme, Locale locale})>({
  (name: 'light, English', theme: theme(), locale: const Locale('en')),
  (name: 'dark, English', theme: darkTheme(), locale: const Locale('en')),
  (name: 'light, Spanish', theme: theme(), locale: const Locale('es')),
  (name: 'dark, Spanish', theme: darkTheme(), locale: const Locale('es')),
});

void main() {
  setUpAll(() {
    registerFallbackValue(const ArticleDraftEntity());
    registerFallbackValue(article);
  });

  // Not pumpAndSettle: the thumbnails never load in tests, so their loading indicator never stops.
  Future<void> settle(WidgetTester tester) async {
    for (var frame = 0; frame < 10; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> show(WidgetTester tester, Widget screen, {double textScale = 1}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final variant = variants.currentValue!;
    await tester.pumpWidget(localizedApp(
      theme: variant.theme,
      locale: variant.locale,
      home: MediaQuery.withClampedTextScaling(
        minScaleFactor: textScale,
        maxScaleFactor: textScale,
        child: screen,
      ),
    ));
    await settle(tester);
  }

  /// Buttons big enough to tap and labeled for screen readers.
  Future<void> expectUsableTapTargets(WidgetTester tester) async {
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  }

  /// Every combination of the guidelines. The contrast check renders the screen for real, so it
  /// only runs on screens without network images: loading them needs plugins tests do not have.
  Future<void> expectAccessible(WidgetTester tester) async {
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    await expectUsableTapTargets(tester);
  }

  Widget publishForm() {
    final resumeDraft = MockResumeDraftUseCase();
    final saveDraft = MockSaveDraftUseCase();
    final discardDraft = MockDiscardDraftUseCase();
    when(() => resumeDraft()).thenAnswer((_) async => const DataSuccess(ArticleDraftEntity()));
    when(() => saveDraft(params: any(named: 'params'))).thenAnswer((_) async => const DataSuccess(null));
    when(() => discardDraft()).thenAnswer((_) async => const DataSuccess(null));
    return BlocProvider(
      create: (_) => PublishArticleCubit(
        MockPublishArticleUseCase(),
        MockPickThumbnailFromGalleryUseCase(),
        resumeDraft,
        saveDraft,
        discardDraft,
      )..resumeDraft(),
      child: const PublishArticleForm(),
    );
  }

  Widget articleScreen() {
    final readAloud = MockReadArticleAloudUseCase();
    final stopReading = MockStopReadingAloudUseCase();
    when(() => readAloud(params: any(named: 'params'))).thenAnswer((_) => const Stream.empty());
    when(() => stopReading()).thenAnswer((_) async => const DataSuccess(null));
    return BlocProvider(
      create: (_) => ArticleNarrationCubit(readAloud, stopReading),
      child: PublishedArticleDetail(article: article),
    );
  }

  Widget communityList(DataState<List<PublishedArticleEntity>> result) {
    final getArticles = MockGetPublishedArticlesUseCase();
    when(() => getArticles(params: any(named: 'params'))).thenAnswer((_) async => result);
    return Scaffold(
      body: BlocProvider(
        create: (_) => PublishedArticlesCubit(getArticles)..loadArticles(),
        child: PublishedArticlesList(onArticlePressed: (_) {}, onPublishPressed: () {}),
      ),
    );
  }

  group('publish form', () {
    testWidgets('meets the accessibility guidelines', (tester) async {
      await show(tester, publishForm());

      await expectAccessible(tester);
    }, variant: variants);

    testWidgets('meets them while showing every field error', (tester) async {
      await show(tester, publishForm());
      await tester.tap(find.byIcon(Icons.login)); // Publish Article
      await settle(tester);

      await expectAccessible(tester);
    }, variant: variants);

    testWidgets('fits with the text at 200 %', (tester) async {
      await show(tester, publishForm(), textScale: 2);

      expect(tester.takeException(), isNull);
    }, variant: variants);
  });

  group('article screen', () {
    testWidgets('has usable, labeled buttons', (tester) async {
      await show(tester, articleScreen());

      await expectUsableTapTargets(tester);
    }, variant: variants);

    testWidgets('fits with the text at 200 %', (tester) async {
      await show(tester, articleScreen(), textScale: 2);

      expect(tester.takeException(), isNull);
    }, variant: variants);

    testWidgets('keeps the sentence being read aloud readable', (tester) async {
      final narration = ArticleNarrationEntity.of(article);
      await show(
        tester,
        Scaffold(
          body: FollowAlongText(progress: ArticleNarrationProgressEntity(narration: narration, sentenceIndex: 3)),
        ),
      );

      await expectLater(tester, meetsGuideline(textContrastGuideline));
    }, variant: variants);
  });

  group('community list', () {
    testWidgets('has usable, labeled buttons', (tester) async {
      await show(tester, communityList(DataSuccess([article])));

      await expectUsableTapTargets(tester);
    }, variant: variants);

    testWidgets('fits with the text at 200 %', (tester) async {
      await show(tester, communityList(DataSuccess([article])), textScale: 2);

      expect(tester.takeException(), isNull);
    }, variant: variants);

    testWidgets('meets the guidelines when there are no articles yet', (tester) async {
      await show(tester, communityList(const DataSuccess([])));

      await expectAccessible(tester);
    }, variant: variants);

    testWidgets('meets the guidelines when the articles cannot be loaded', (tester) async {
      await show(tester, communityList(DataFailed(Exception('offline'))));

      await expectAccessible(tester);
    }, variant: variants);
  });

  group('top news tile', () {
    testWidgets('fits with the text at 200 %', (tester) async {
      const newsArticle = ArticleEntity(
        title: 'Nvidia announces a jaw-dropping stock buyback, the largest in its history',
        description: 'The valuation on Nvidia is too appetizing for its chief executive',
        urlToImage: 'https://example.com/nvidia.jpg',
        publishedAt: '2026-09-28T12:13:42Z',
      );
      await show(tester, const Scaffold(body: ArticleWidget(article: newsArticle)), textScale: 2);

      expect(tester.takeException(), isNull);
    }, variant: variants);
  });
}
