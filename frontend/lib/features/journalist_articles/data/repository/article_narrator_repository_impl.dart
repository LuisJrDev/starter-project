import 'package:news_app_clean_architecture/core/resources/data_state.dart';

import '../../domain/entities/article_narration.dart';
import '../../domain/repository/article_narrator_repository.dart';
import '../data_sources/local/text_to_speech_data_source.dart';

class ArticleNarratorRepositoryImpl implements ArticleNarratorRepository {
  final TextToSpeechDataSource _textToSpeechDataSource;

  ArticleNarratorRepositoryImpl(this._textToSpeechDataSource);

  @override
  Future<DataState<void>> read(ArticleNarrationEntity narration) async {
    try {
      await _textToSpeechDataSource.speak(narration);
      return const DataSuccess(null);
    } on Exception catch (error) {
      return DataFailed(error);
    }
  }

  @override
  Future<DataState<void>> stopReading() async {
    try {
      await _textToSpeechDataSource.stop();
      return const DataSuccess(null);
    } on Exception catch (error) {
      return DataFailed(error);
    }
  }
}
