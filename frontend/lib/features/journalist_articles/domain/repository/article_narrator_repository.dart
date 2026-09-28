import 'package:news_app_clean_architecture/core/resources/data_state.dart';

import '../entities/article_narration.dart';

/// Reads articles aloud with the device's text-to-speech engine.
abstract class ArticleNarratorRepository {
  /// Completes when the whole narration has been read, or when [stopReading] is called.
  Future<DataState<void>> read(ArticleNarrationEntity narration);

  Future<DataState<void>> stopReading();
}
