import 'package:equatable/equatable.dart';

import '../../../domain/entities/article_draft.dart';

enum PublishArticleFailureReason { publishFailed, galleryUnavailable }

sealed class PublishArticleState extends Equatable {
  final ArticleDraftEntity draft;

  const PublishArticleState(this.draft);

  bool get hasUnsavedChanges => draft != const ArticleDraftEntity();

  /// Field errors to show. Empty until the journalist first tries to publish.
  Set<ArticleDraftError> get visibleErrors => const {};

  @override
  List<Object?> get props => [draft];
}

/// Initial state, and the state the form returns to after any edit.
final class PublishArticleEditing extends PublishArticleState {
  const PublishArticleEditing(super.draft);
}

final class PublishArticleInvalid extends PublishArticleState {
  final Set<ArticleDraftError> errors;

  const PublishArticleInvalid(super.draft, this.errors);

  @override
  Set<ArticleDraftError> get visibleErrors => errors;

  @override
  List<Object?> get props => [draft, errors];
}

final class PublishArticlePublishing extends PublishArticleState {
  const PublishArticlePublishing(super.draft);
}

final class PublishArticleSuccess extends PublishArticleState {
  const PublishArticleSuccess(super.draft);
}

final class PublishArticleFailure extends PublishArticleState {
  final PublishArticleFailureReason reason;

  const PublishArticleFailure(super.draft, this.reason);

  @override
  List<Object?> get props => [draft, reason];
}
