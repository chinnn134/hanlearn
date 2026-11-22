import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

enum ImageSelectionSource { gallery, camera }

class SelectedImage {
  const SelectedImage({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
    required this.width,
    required this.height,
  });

  final Uint8List bytes;
  final String fileName;
  final String mimeType;
  final int width;
  final int height;

  int get pixelCount => width * height;
}

class ImageSelectionException implements Exception {
  const ImageSelectionException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract class ImageSelectionService {
  Future<SelectedImage?> pick(ImageSelectionSource source);
}

class ImagePickerSelectionService implements ImageSelectionService {
  ImagePickerSelectionService(this._picker);

  static const maxBytes = 8 * 1024 * 1024;
  static const maxPixels = 20 * 1000 * 1000;

  final ImagePicker _picker;

  @override
  Future<SelectedImage?> pick(ImageSelectionSource source) async {
    final file = await _picker.pickImage(
      source: source == ImageSelectionSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      maxWidth: 6000,
      maxHeight: 6000,
      requestFullMetadata: false,
    );
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw const ImageSelectionException('Tệp ảnh trống hoặc bị hỏng.');
    }
    if (bytes.length > maxBytes) {
      throw const ImageSelectionException('Ảnh vượt quá giới hạn 8 MiB.');
    }
    final mimeType = _detectMimeType(bytes);
    if (mimeType == null) {
      throw const ImageSelectionException(
        'Chỉ hỗ trợ ảnh JPEG, PNG hoặc WebP hợp lệ.',
      );
    }
    ui.Codec? codec;
    try {
      codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final width = frame.image.width;
      final height = frame.image.height;
      frame.image.dispose();
      if (width <= 0 || height <= 0) {
        throw const ImageSelectionException('Không đọc được kích thước ảnh.');
      }
      if (width * height > maxPixels) {
        throw const ImageSelectionException('Ảnh vượt quá giới hạn 20 MP.');
      }
      return SelectedImage(
        bytes: bytes,
        fileName: file.name,
        mimeType: mimeType,
        width: width,
        height: height,
      );
    } on ImageSelectionException {
      rethrow;
    } catch (_) {
      throw const ImageSelectionException(
        'Tệp ảnh bị hỏng hoặc không đọc được.',
      );
    } finally {
      codec?.dispose();
    }
  }

  String? _detectMimeType(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff) {
      return 'image/jpeg';
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4e &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0d &&
        bytes[5] == 0x0a &&
        bytes[6] == 0x1a &&
        bytes[7] == 0x0a) {
      return 'image/png';
    }
    if (bytes.length >= 12 &&
        String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
      return 'image/webp';
    }
    return null;
  }
}

final imageSelectionServiceProvider = Provider<ImageSelectionService>(
  (ref) => ImagePickerSelectionService(ImagePicker()),
);
