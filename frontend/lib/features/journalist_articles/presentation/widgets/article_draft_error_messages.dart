import '../../domain/entities/article_draft.dart';
import '../../domain/entities/article_thumbnail.dart';

/// User-facing message for each field of the publish form, or `null` when the field is fine.
class ArticleDraftErrorMessages {
  final Set<ArticleDraftError> _errors;

  const ArticleDraftErrorMessages(this._errors);

  String? get title => _firstOf([ArticleDraftError.titleEmpty, ArticleDraftError.titleTooLong]);

  String? get author => _firstOf([ArticleDraftError.authorEmpty, ArticleDraftError.authorTooLong]);

  String? get content => _firstOf([ArticleDraftError.contentEmpty, ArticleDraftError.contentTooLong]);

  String? get thumbnail => _firstOf([
        ArticleDraftError.thumbnailMissing,
        ArticleDraftError.thumbnailUnsupportedFormat,
        ArticleDraftError.thumbnailTooLarge,
      ]);

  String? _firstOf(List<ArticleDraftError> fieldErrors) {
    for (final error in fieldErrors) {
      if (_errors.contains(error)) return _messageFor(error);
    }
    return null;
  }

  static String _messageFor(ArticleDraftError error) {
    return switch (error) {
      ArticleDraftError.titleEmpty => 'Add a title for your article.',
      ArticleDraftError.titleTooLong => 'The title can have up to ${ArticleDraftEntity.titleMaxLength} characters.',
      ArticleDraftError.authorEmpty => 'Sign the article with your name.',
      ArticleDraftError.authorTooLong => 'Your name can have up to ${ArticleDraftEntity.authorMaxLength} characters.',
      ArticleDraftError.contentEmpty => 'Write your article before publishing it.',
      ArticleDraftError.contentTooLong =>
        'The article can have up to ${ArticleDraftEntity.contentMaxLength} characters.',
      ArticleDraftError.thumbnailMissing => 'Attach an image to illustrate your article.',
      ArticleDraftError.thumbnailUnsupportedFormat => 'Choose a JPG, PNG or WebP image.',
      ArticleDraftError.thumbnailTooLarge =>
        'Choose an image of ${ArticleThumbnailEntity.maxSizeInBytes ~/ (1024 * 1024)} MB or less.',
    };
  }
}
