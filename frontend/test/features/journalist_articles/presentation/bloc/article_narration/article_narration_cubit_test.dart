import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/domain/entities/published_article.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/domain/usecases/read_article_aloud.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/domain/usecases/stop_reading_aloud.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/presentation/bloc/article_narration/article_narration_cubit.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/presentation/bloc/article_narration/article_narration_state.dart';

import '../../../../../helpers/cubit_states.dart';

class MockReadArticleAloudUseCase extends Mock implements ReadArticleAloudUseCase {}

class MockStopReadingAloudUseCase extends Mock implements StopReadingAloudUseCase {}

final article = PublishedArticleEntity(
  id: 'article-1',
  title: 'Breaking News',
  content: 'Body.',
  description: 'Body.',
  author: 'Daily News Staff',
  thumbnailUrl: 'https://example.com/1.jpg',
  publishedAt: DateTime.utc(2026, 9, 28),
);

void main() {
  late MockReadArticleAloudUseCase readAloud;
  late MockStopReadingAloudUseCase stopReading;
  late ArticleNarrationCubit cubit;
  late Completer<DataState<void>> reading;

  setUpAll(() => registerFallbackValue(article));

  setUp(() {
    readAloud = MockReadArticleAloudUseCase();
    stopReading = MockStopReadingAloudUseCase();
    cubit = ArticleNarrationCubit(readAloud, stopReading);
    reading = Completer();
    when(() => readAloud(params: any(named: 'params'))).thenAnswer((_) => reading.future);
    when(() => stopReading()).thenAnswer((_) async {
      if (!reading.isCompleted) reading.complete(const DataSuccess(null));
      return const DataSuccess(null);
    });
  });

  tearDown(() => cubit.close());

  test('starts idle', () {
    expect(cubit.state, const ArticleNarrationIdle());
  });

  test('reads the article and goes back to idle when it ends', () async {
    final states = await statesEmittedBy(cubit, () async {
      final toggle = cubit.toggleReading(article);
      reading.complete(const DataSuccess(null));
      await toggle;
    });

    expect(states, const [ArticleNarrationReading(), ArticleNarrationIdle()]);
    verify(() => readAloud(params: article)).called(1);
  });

  test('stops when toggled while reading', () async {
    final firstToggle = cubit.toggleReading(article);
    await Future<void>.delayed(Duration.zero);

    await cubit.toggleReading(article);
    await firstToggle;

    verify(() => stopReading()).called(1);
    expect(cubit.state, const ArticleNarrationIdle());
  });

  test('reports when the device cannot read aloud', () async {
    reading.complete(DataFailed(Exception('no engine')));

    await cubit.toggleReading(article);

    expect(cubit.state, const ArticleNarrationUnavailable());
  });

  test('stops the voice when the article is closed', () async {
    unawaited(cubit.toggleReading(article));
    await Future<void>.delayed(Duration.zero);

    await cubit.close();

    verify(() => stopReading()).called(1);
  });
}
