import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/data/data_sources/local/text_to_speech_data_source.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/data/repository/article_narrator_repository_impl.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/domain/entities/article_narration.dart';

class MockTextToSpeechDataSource extends Mock implements TextToSpeechDataSource {}

const narration = ArticleNarrationEntity(text: 'Title.', languageTag: 'en-US');

void main() {
  late MockTextToSpeechDataSource dataSource;
  late ArticleNarratorRepositoryImpl repository;

  setUpAll(() => registerFallbackValue(narration));

  setUp(() {
    dataSource = MockTextToSpeechDataSource();
    repository = ArticleNarratorRepositoryImpl(dataSource);
  });

  test('reads the narration', () async {
    when(() => dataSource.speak(any())).thenAnswer((_) async {});

    expect(await repository.read(narration), isA<DataSuccess<void>>());
    verify(() => dataSource.speak(narration)).called(1);
  });

  test('fails when the device cannot speak', () async {
    final error = Exception('no text-to-speech engine');
    when(() => dataSource.speak(any())).thenThrow(error);

    expect((await repository.read(narration)).error, same(error));
  });

  test('stops reading', () async {
    when(() => dataSource.stop()).thenAnswer((_) async {});

    expect(await repository.stopReading(), isA<DataSuccess<void>>());
    verify(() => dataSource.stop()).called(1);
  });
}
