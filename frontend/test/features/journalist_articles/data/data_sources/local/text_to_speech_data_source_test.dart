import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/data/data_sources/local/text_to_speech_data_source.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/domain/entities/article_narration.dart';

class MockFlutterTts extends Mock implements FlutterTts {}

const narration = ArticleNarrationEntity(text: 'Title. Written by Me. Body.', languageTag: 'es-ES');

void main() {
  late MockFlutterTts tts;
  late TextToSpeechDataSource dataSource;

  setUp(() {
    tts = MockFlutterTts();
    dataSource = TextToSpeechDataSource(tts);
    when(() => tts.awaitSpeakCompletion(any())).thenAnswer((_) async => 1);
    when(() => tts.setSpeechRate(any())).thenAnswer((_) async => 1);
    when(() => tts.isLanguageAvailable(any())).thenAnswer((_) async => true);
    when(() => tts.setLanguage(any())).thenAnswer((_) async => 1);
    when(() => tts.speak(any())).thenAnswer((_) async => 1);
    when(() => tts.stop()).thenAnswer((_) async => 1);
  });

  List<String> spokenChunks() => verify(() => tts.speak(captureAny())).captured.cast<String>();

  test('reads the narration in the article language, waiting for each chunk to finish', () async {
    await dataSource.speak(narration);

    verify(() => tts.awaitSpeakCompletion(true)).called(1);
    verify(() => tts.setLanguage('es-ES')).called(1);
    expect(spokenChunks(), ['Title. Written by Me. Body.']);
  });

  test('keeps the default voice when the article language is not installed', () async {
    when(() => tts.isLanguageAvailable(any())).thenAnswer((_) async => false);

    await dataSource.speak(narration);

    verifyNever(() => tts.setLanguage(any()));
  });

  test('reads long articles in chunks that Android accepts, without losing text', () async {
    const sentence = 'This sentence has exactly fifty characters in it. ';
    final longText = (sentence * 200).trim();

    await dataSource.speak(ArticleNarrationEntity(text: longText, languageTag: 'en-US'));

    final chunks = spokenChunks();
    expect(chunks.length, greaterThan(1));
    expect(chunks.every((chunk) => chunk.length <= TextToSpeechDataSource.maxChunkLength), isTrue);
    expect(chunks.join(' '), longText);
  });

  test('stops before the next chunk when asked to stop', () async {
    final longText = ('Sentence number one is here. ' * 400).trim();
    when(() => tts.speak(any())).thenAnswer((_) async {
      await dataSource.stop();
      return 1;
    });

    await dataSource.speak(ArticleNarrationEntity(text: longText, languageTag: 'en-US'));

    expect(spokenChunks(), hasLength(1));
    verify(() => tts.stop()).called(1);
  });

  test('throws when the device cannot speak', () async {
    when(() => tts.speak(any())).thenAnswer((_) async => 0);

    expect(() => dataSource.speak(narration), throwsException);
  });

  group('splitIntoChunks', () {
    test('keeps a short text in one chunk', () {
      expect(TextToSpeechDataSource.splitIntoChunks('One. Two.'), ['One. Two.']);
    });

    test('cuts a sentence longer than a chunk', () {
      final chunks = TextToSpeechDataSource.splitIntoChunks('a' * (TextToSpeechDataSource.maxChunkLength + 10));

      expect(chunks.map((chunk) => chunk.length), [TextToSpeechDataSource.maxChunkLength, 10]);
    });
  });
}
