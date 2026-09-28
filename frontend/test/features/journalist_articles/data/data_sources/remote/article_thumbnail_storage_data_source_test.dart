import 'dart:io';

import 'package:firebase_storage_mocks/firebase_storage_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/data/data_sources/remote/article_thumbnail_storage_data_source.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/domain/entities/article_thumbnail.dart';

void main() {
  late MockFirebaseStorage storage;
  late ArticleThumbnailStorageDataSource dataSource;
  late Directory gallery;

  setUp(() async {
    storage = MockFirebaseStorage();
    dataSource = ArticleThumbnailStorageDataSource(storage);
    gallery = await Directory.systemTemp.createTemp('gallery');
  });

  tearDown(() => gallery.delete(recursive: true));

  Future<ArticleThumbnailEntity> galleryImage(String fileName) async {
    final file = await File('${gallery.path}/$fileName').writeAsBytes(List.filled(64, 0));
    return ArticleThumbnailEntity(localPath: file.path, sizeInBytes: 64);
  }

  test('uploads to media/articles/{articleId}.{extension}, with jpeg stored as jpg', () async {
    await dataSource.uploadThumbnail('article1', await galleryImage('IMG_0001.jpeg'));

    expect(storage.storedFilesMap.keys, ['media/articles/article1.jpg']);
  });

  test('declares the content type that storage.rules expects for the extension', () async {
    final thumbnail = await galleryImage('photo.png');

    await dataSource.uploadThumbnail('article1', thumbnail);

    final metadata = await storage.ref('media/articles/article1.png').getMetadata();
    expect(metadata.contentType, 'image/png');
  });

  test('deletes the thumbnail of an article', () async {
    final thumbnail = await galleryImage('photo.webp');
    await dataSource.uploadThumbnail('article1', thumbnail);

    await dataSource.deleteThumbnail('article1', thumbnail);

    expect(storage.storedFilesMap, isEmpty);
  });

  test('returns the download URL of the uploaded thumbnail', () async {
    final thumbnail = await galleryImage('photo.jpg');
    await dataSource.uploadThumbnail('article1', thumbnail);

    expect(await dataSource.getThumbnailUrl('article1', thumbnail), contains('article1.jpg'));
  });
}
