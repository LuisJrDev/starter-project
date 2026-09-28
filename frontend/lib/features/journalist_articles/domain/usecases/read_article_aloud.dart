import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/core/usecase/usecase.dart';

import '../entities/article_narration.dart';
import '../entities/published_article.dart';
import '../repository/article_narrator_repository.dart';

/// Reads an article aloud: title, byline and content, in the article's language.
/// Completes when the reading ends or is stopped.
class ReadArticleAloudUseCase implements UseCase<DataState<void>, PublishedArticleEntity> {
  final ArticleNarratorRepository _articleNarratorRepository;

  ReadArticleAloudUseCase(this._articleNarratorRepository);

  @override
  Future<DataState<void>> call({PublishedArticleEntity? params}) async {
    if (params == null) return const DataSuccess(null);
    return _articleNarratorRepository.read(ArticleNarrationEntity.of(params));
  }
}
