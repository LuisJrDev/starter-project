import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

import '../../../domain/entities/article_thumbnail.dart';

/// Article thumbnails in Cloud Storage: `media/articles/{articleId}.{extension}`
/// (see backend/docs/DB_SCHEMA.md and backend/storage.rules).
class ArticleThumbnailStorageDataSource {
  static const String _folder = 'media/articles';

  final FirebaseStorage _storage;

  ArticleThumbnailStorageDataSource(this._storage);

  Future<void> uploadThumbnail(String articleId, ArticleThumbnailEntity thumbnail) async {
    final metadata = SettableMetadata(contentType: _contentTypeOf(thumbnail));
    await _referenceFor(articleId, thumbnail).putFile(File(thumbnail.localPath), metadata);
  }

  Future<String> getThumbnailUrl(String articleId, ArticleThumbnailEntity thumbnail) {
    return _referenceFor(articleId, thumbnail).getDownloadURL();
  }

  /// Only allowed by the rules while no article document uses the thumbnail (orphan cleanup).
  Future<void> deleteThumbnail(String articleId, ArticleThumbnailEntity thumbnail) {
    return _referenceFor(articleId, thumbnail).delete();
  }

  Reference _referenceFor(String articleId, ArticleThumbnailEntity thumbnail) {
    return _storage.ref('$_folder/$articleId.${thumbnail.extension}');
  }

  String _contentTypeOf(ArticleThumbnailEntity thumbnail) {
    return thumbnail.extension == 'jpg' ? 'image/jpeg' : 'image/${thumbnail.extension}';
  }
}
