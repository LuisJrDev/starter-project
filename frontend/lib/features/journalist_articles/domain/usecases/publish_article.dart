import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/core/usecase/usecase.dart';

import '../entities/article_draft.dart';
import '../entities/invalid_article_draft_exception.dart';
import '../repository/author_signature_repository.dart';
import '../repository/published_article_repository.dart';

/// Publishes a journalist's draft. Drafts that break the publishing rules are rejected
/// with an [InvalidArticleDraftException] listing every error, and nothing is published.
/// Once published, the signature is remembered to prefill the journalist's next article.
class PublishArticleUseCase implements UseCase<DataState<void>, ArticleDraftEntity> {
  final PublishedArticleRepository _publishedArticleRepository;
  final AuthorSignatureRepository _authorSignatureRepository;

  PublishArticleUseCase(this._publishedArticleRepository, this._authorSignatureRepository);

  @override
  Future<DataState<void>> call({ArticleDraftEntity? params}) async {
    final draft = (params ?? const ArticleDraftEntity()).trimmed();
    if (!draft.isValid) {
      return DataFailed(InvalidArticleDraftException(draft.errors));
    }
    final result = await _publishedArticleRepository.publishArticle(draft);
    if (result is DataSuccess) {
      // Best effort: failing to remember the signature must not turn a publication into a failure.
      await _authorSignatureRepository.saveAuthorName(draft.author);
    }
    return result;
  }
}
