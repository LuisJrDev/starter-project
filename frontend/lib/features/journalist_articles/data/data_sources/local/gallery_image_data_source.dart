import 'package:image_picker/image_picker.dart';

import '../../models/article_thumbnail.dart';

class GalleryImageDataSource {
  // Downscaled on the device: plenty for a full-width thumbnail and keeps uploads well under 5 MB.
  static const double _maxDimensionInPixels = 1920;
  static const int _jpegQuality = 85;

  final ImagePicker _imagePicker;

  GalleryImageDataSource(this._imagePicker);

  /// Returns `null` when the journalist closes the gallery without choosing an image.
  /// Throws a PlatformException when the gallery cannot be opened.
  Future<ArticleThumbnailModel?> pickImage() async {
    final file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: _maxDimensionInPixels,
      maxHeight: _maxDimensionInPixels,
      imageQuality: _jpegQuality,
      // No EXIF metadata needed, so no extra photo permissions are requested.
      requestFullMetadata: false,
    );
    if (file == null) return null;
    return ArticleThumbnailModel.fromRawData(localPath: file.path, sizeInBytes: await file.length());
  }
}
