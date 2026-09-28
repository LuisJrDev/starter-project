import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/domain/entities/published_article.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/domain/usecases/read_article_aloud.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/domain/usecases/stop_reading_aloud.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/presentation/bloc/article_narration/article_narration_cubit.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/presentation/pages/published_article_detail/published_article_detail.dart';

class MockReadArticleAloudUseCase extends Mock implements ReadArticleAloudUseCase {}

class MockStopReadingAloudUseCase extends Mock implements StopReadingAloudUseCase {}

final article = PublishedArticleEntity(
  id: 'article-1',
  title: 'Breaking News',
  content: '## Subtitle\n\nThis is **breaking** news.',
  description: 'Subtitle This is breaking news.',
  author: 'Daily News Staff',
  thumbnailUrl: 'https://example.com/1.jpg',
  publishedAt: DateTime.utc(2026, 9, 28),
);

void main() {
  late MockReadArticleAloudUseCase readAloud;
  late MockStopReadingAloudUseCase stopReading;
  late Completer<DataState<void>> reading;

  setUpAll(() => registerFallbackValue(article));

  // Created inside each test body, not in setUp: futures created outside testWidgets' fake-async
  // zone do not resolve while the test pumps frames.
  void stubReadingAloud() {
    readAloud = MockReadArticleAloudUseCase();
    stopReading = MockStopReadingAloudUseCase();
    reading = Completer();
    when(() => readAloud(params: any(named: 'params'))).thenAnswer((_) => reading.future);
    when(() => stopReading()).thenAnswer((_) async {
      if (!reading.isCompleted) reading.complete(const DataSuccess(null));
      return const DataSuccess(null);
    });
  }

  Future<void> openArticle(WidgetTester tester) async {
    stubReadingAloud();
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: BlocProvider(
        create: (_) => ArticleNarrationCubit(readAloud, stopReading),
        child: PublishedArticleDetail(article: article),
      ),
    ));
  }

  testWidgets('renders the Markdown content', (tester) async {
    await openArticle(tester);

    expect(find.textContaining('Subtitle', findRichText: true), findsOneWidget);
  });

  testWidgets('listening turns the button into Stop, and stopping turns it back', (tester) async {
    await openArticle(tester);

    await tester.tap(find.text('Listen to this article'));
    await tester.pump();
    expect(find.text('Stop reading'), findsOneWidget);
    verify(() => readAloud(params: article)).called(1);

    await tester.tap(find.text('Stop reading'));
    await tester.pump(); // stop request
    await tester.pump(); // the reading completes and the cubit goes back to idle
    expect(find.text('Listen to this article'), findsOneWidget);
    verify(() => stopReading()).called(1);
  });

  testWidgets('explains when the device cannot read aloud', (tester) async {
    await openArticle(tester);
    reading.complete(DataFailed(Exception('no engine')));

    await tester.tap(find.text('Listen to this article'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500)); // snackbar entrance

    expect(find.textContaining('cannot read aloud'), findsOneWidget);
  });
}
