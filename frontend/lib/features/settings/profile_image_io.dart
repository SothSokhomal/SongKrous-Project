import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Reads a picked image file. Rejects anything over 15 MB so a huge photo can
/// never exhaust memory. Injectable so tests don't touch the file system.
Future<Uint8List> readImageBytes(String path) async {
  final file = File(path);
  if (await file.length() > 15 * 1024 * 1024) {
    throw const FileSystemException('Image too large');
  }
  return file.readAsBytes();
}

final profileImageLoaderProvider =
    Provider<Future<Uint8List> Function(String path)>((ref) => readImageBytes);
