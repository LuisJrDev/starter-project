import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/core/usecase/usecase.dart';

import '../entities/article_draft.dart';
import '../entities/invalid_article_draft_exception.dart';
import 'mock/mock_published_articles_store.dart';

/// Publishes a journalist's draft. Drafts that break the publishing rules are rejected
/// with an [InvalidArticleDraftException] listing every error, and nothing is published.
class PublishArticleUseCase implements UseCase<DataState<void>, ArticleDraftEntity> {
  // TODO(phase 2.3): replace the mock store with PublishedArticleRepository.
  final MockPublishedArticlesStore _mockStore;

  PublishArticleUseCase(this._mockStore);

  @override
  Future<DataState<void>> call({ArticleDraftEntity? params}) async {
    final draft = (params ?? const ArticleDraftEntity()).trimmed();
    if (!draft.isValid) {
      return DataFailed(InvalidArticleDraftException(draft.errors));
    }
    await _mockStore.addArticleFrom(draft);
    return const DataSuccess(null);
  }
}
