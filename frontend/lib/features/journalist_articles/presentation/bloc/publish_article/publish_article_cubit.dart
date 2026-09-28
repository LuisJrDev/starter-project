import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';

import '../../../domain/entities/article_draft.dart';
import '../../../domain/entities/invalid_article_draft_exception.dart';
import '../../../domain/usecases/pick_thumbnail_from_gallery.dart';
import '../../../domain/usecases/publish_article.dart';
import 'publish_article_state.dart';

class PublishArticleCubit extends Cubit<PublishArticleState> {
  final PublishArticleUseCase _publishArticleUseCase;
  final PickThumbnailFromGalleryUseCase _pickThumbnailFromGalleryUseCase;

  PublishArticleCubit(this._publishArticleUseCase, this._pickThumbnailFromGalleryUseCase)
      : super(const PublishArticleEditing(ArticleDraftEntity()));

  void changeTitle(String title) => _updateDraft(state.draft.withTitle(title));

  void changeContent(String content) => _updateDraft(state.draft.withContent(content));

  void changeAuthor(String author) => _updateDraft(state.draft.withAuthor(author));

  Future<void> pickThumbnail() async {
    final result = await _pickThumbnailFromGalleryUseCase();
    if (result is DataFailed) {
      emit(PublishArticleFailure(state.draft, PublishArticleFailureReason.galleryUnavailable));
      return;
    }
    final thumbnail = result.data;
    if (thumbnail != null) _updateDraft(state.draft.withThumbnail(thumbnail));
  }

  Future<void> publish() async {
    if (state is PublishArticlePublishing || state is PublishArticleSuccess) return;
    final errors = state.draft.trimmed().errors;
    if (errors.isNotEmpty) {
      emit(PublishArticleInvalid(state.draft, errors));
      return;
    }
    emit(PublishArticlePublishing(state.draft));
    _emitPublishResult(await _publishArticleUseCase(params: state.draft));
  }

  void _emitPublishResult(DataState<void> result) {
    final error = result.error;
    if (error == null) {
      emit(PublishArticleSuccess(state.draft));
    } else if (error is InvalidArticleDraftException) {
      emit(PublishArticleInvalid(state.draft, error.errors));
    } else {
      emit(PublishArticleFailure(state.draft, PublishArticleFailureReason.publishFailed));
    }
  }

  void _updateDraft(ArticleDraftEntity draft) {
    if (state is PublishArticlePublishing) return;
    if (state is! PublishArticleInvalid) {
      emit(PublishArticleEditing(draft));
      return;
    }
    final errors = draft.trimmed().errors;
    emit(errors.isEmpty ? PublishArticleEditing(draft) : PublishArticleInvalid(draft, errors));
  }
}
