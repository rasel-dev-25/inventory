import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ImageService {
  static final ImageService _instance = ImageService._();
  factory ImageService() => _instance;
  ImageService._();

  final _picker = ImagePicker();

  Future<File?> pickFromCamera({
    int quality = 30,
    int maxWidth = 600,
    int maxHeight = 600,
  }) async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: quality,
      maxWidth: maxWidth.toDouble(),
      maxHeight: maxHeight.toDouble(),
    );
    return picked != null ? File(picked.path) : null;
  }

  Future<File?> pickFromGallery({
    int quality = 30,
    int maxWidth = 600,
    int maxHeight = 600,
  }) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: quality,
      maxWidth: maxWidth.toDouble(),
      maxHeight: maxHeight.toDouble(),
    );
    return picked != null ? File(picked.path) : null;
  }
}
