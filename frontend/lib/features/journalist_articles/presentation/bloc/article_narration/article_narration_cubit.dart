import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';

import '../../../domain/entities/published_article.dart';
import '../../../domain/usecases/read_article_aloud.dart';
import '../../../domain/usecases/stop_reading_aloud.dart';
import 'article_narration_state.dart';

class ArticleNarrationCubit extends Cubit<ArticleNarrationState> {
  final ReadArticleAloudUseCase _readArticleAloudUseCase;
  final StopReadingAloudUseCase _stopReadingAloudUseCase;

  ArticleNarrationCubit(this._readArticleAloudUseCase, this._stopReadingAloudUseCase)
      : super(const ArticleNarrationIdle());

  /// Starts reading [article] aloud, or stops if it is already being read.
  Future<void> toggleReading(PublishedArticleEntity article) async {
    if (state is ArticleNarrationReading) {
      await _stopReadingAloudUseCase();
      return;
    }
    emit(const ArticleNarrationReading());
    final result = await _readArticleAloudUseCase(params: article);
    if (isClosed) return;
    emit(result is DataFailed ? const ArticleNarrationUnavailable() : const ArticleNarrationIdle());
  }

  /// Leaving the article stops the voice.
  @override
  Future<void> close() async {
    if (state is ArticleNarrationReading) await _stopReadingAloudUseCase();
    return super.close();
  }
}
