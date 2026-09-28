import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/core/usecase/usecase.dart';

import '../entities/published_article.dart';
import '../params/get_published_articles_params.dart';
import 'mock/mock_published_articles_store.dart';

/// Returns one page of published articles, newest first.
class GetPublishedArticlesUseCase
    implements UseCase<DataState<List<PublishedArticleEntity>>, GetPublishedArticlesParams> {
  // TODO(phase 2.3): replace the mock store with PublishedArticleRepository.
  final MockPublishedArticlesStore _mockStore;

  GetPublishedArticlesUseCase(this._mockStore);

  @override
  Future<DataState<List<PublishedArticleEntity>>> call({GetPublishedArticlesParams? params}) async {
    final page = await _mockStore.findPage(params ?? const GetPublishedArticlesParams());
    return DataSuccess(page);
  }
}
