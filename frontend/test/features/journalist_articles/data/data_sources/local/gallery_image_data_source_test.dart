import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/data/data_sources/local/gallery_image_data_source.dart';

class MockImagePicker extends Mock implements ImagePicker {}

void main() {
  late MockImagePicker imagePicker;
  late GalleryImageDataSource dataSource;

  setUpAll(() => registerFallbackValue(ImageSource.gallery));

  setUp(() {
    imagePicker = MockImagePicker();
    dataSource = GalleryImageDataSource(imagePicker);
  });

  void givenPickedFile(XFile? file) {
    when(() => imagePicker.pickImage(
          source: any(named: 'source'),
          maxWidth: any(named: 'maxWidth'),
          maxHeight: any(named: 'maxHeight'),
          imageQuality: any(named: 'imageQuality'),
          requestFullMetadata: any(named: 'requestFullMetadata'),
        )).thenAnswer((_) async => file);
  }

  test('opens the gallery only, never the camera', () async {
    givenPickedFile(null);

    await dataSource.pickImage();

    final source = verify(() => imagePicker.pickImage(
          source: captureAny(named: 'source'),
          maxWidth: any(named: 'maxWidth'),
          maxHeight: any(named: 'maxHeight'),
          imageQuality: any(named: 'imageQuality'),
          requestFullMetadata: any(named: 'requestFullMetadata'),
        )).captured.single;
    expect(source, ImageSource.gallery);
  });

  test('returns the picked image path and size', () async {
    givenPickedFile(XFile.fromData(Uint8List(2048), path: '/gallery/photo.jpg'));

    final thumbnail = await dataSource.pickImage();

    expect(thumbnail!.localPath, '/gallery/photo.jpg');
    expect(thumbnail.sizeInBytes, 2048);
  });

  test('returns null when the journalist cancels', () async {
    givenPickedFile(null);

    expect(await dataSource.pickImage(), isNull);
  });
}
