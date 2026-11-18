import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

enum PhotoOrigin { library, camera }

/// Where chat photos come from. Throws if the platform can't provide one
/// (no camera on a simulator, permission denied…) — callers fall back to the
/// built-in demo photo.
abstract interface class PhotoSource {
  /// Returns a file path, or `null` if the user cancelled.
  Future<String?> pick(PhotoOrigin origin);
}

class ImagePickerPhotoSource implements PhotoSource {
  ImagePickerPhotoSource([ImagePicker? picker])
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<String?> pick(PhotoOrigin origin) async {
    final file = await _picker.pickImage(
      source: origin == PhotoOrigin.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    return file?.path;
  }
}

final photoSourceProvider = Provider<PhotoSource>(
  (ref) => ImagePickerPhotoSource(),
);
