import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  static const String _cloudName = 'wenh15me';
  static const String _uploadPreset = 'taameem_preset';

  final ImagePicker _picker = ImagePicker();

  void initialize() {}

  Uri get _imageEndpoint =>
      Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');

  Uri get _autoEndpoint =>
      Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/auto/upload');

  void _ensureConfigured() {
    if (_cloudName == 'YOUR_CLOUD_NAME' ||
        _uploadPreset == 'YOUR_UPLOAD_PRESET') {
      throw Exception(
        'إعدادات Cloudinary غير مضبوطة — عدّل _cloudName و _uploadPreset في storage_service.dart',
      );
    }
  }

  // ─── اختيار صورة من المعرض ────────────────────────────────────────────────
  Future<File?> pickImage({bool fromCamera = false}) async {
    final XFile? picked = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 85,
    );
    if (picked == null) return null;
    return File(picked.path);
  }

  // ─── اختيار عدة صور ──────────────────────────────────────────────────────
  Future<List<File>> pickMultipleImages() async {
    final List<XFile> picked = await _picker.pickMultiImage(
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 85,
    );
    return picked.map((f) => File(f.path)).toList();
  }

  Future<String> uploadImage(File image, String folder) async {
    _ensureConfigured();
    return _uploadFile(
      file: image,
      folder: folder,
      endpoint: _imageEndpoint,
      missingUrlMessage:
          'لم يُرجع Cloudinary رابط صورة — تحقق من إعدادات upload preset',
    );
  }

  Future<List<String>> uploadImages(List<File> images, String taameemId) async {
    if (images.isEmpty) return [];
    final urls = <String>[];
    for (final image in images) {
      try {
        final url = await uploadImage(image, taameemId);
        urls.add(url);
      } catch (e) {
        // ignore: avoid_print
        print('فشل رفع ${image.path}: $e');
      }
    }
    return urls;
  }

  Future<String> uploadAttachment(File file, String folder) async {
    _ensureConfigured();
    return _uploadFile(
      file: file,
      folder: folder,
      endpoint: _autoEndpoint,
      missingUrlMessage:
          'لم يُرجع Cloudinary رابط مرفق — تحقق من إعدادات upload preset',
    );
  }

  Future<List<String>> uploadMediaFiles(List<File> files, String taameemId) async {
    if (files.isEmpty) return [];
    final urls = <String>[];
    for (final file in files) {
      try {
        final url = await uploadAttachment(file, taameemId);
        urls.add(url);
      } catch (e) {
        // ignore: avoid_print
        print('فشل رفع ${file.path}: $e');
      }
    }
    return urls;
  }

  Future<void> deleteMedia(String url) async {}

  Future<String> _uploadFile({
    required File file,
    required String folder,
    required Uri endpoint,
    required String missingUrlMessage,
  }) async {
    if (!await file.exists()) {
      throw Exception('الملف غير موجود: ${file.path}');
    }

    final request = http.MultipartRequest('POST', endpoint)
      ..fields['upload_preset'] = _uploadPreset
      ..fields['folder'] = 'taameem/$folder'
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamed = await request.send().timeout(const Duration(seconds: 60));
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode != 200) {
      String reason = 'رمز الحالة ${streamed.statusCode}';
      try {
        final err = jsonDecode(body) as Map<String, dynamic>;
        reason = err['error']?['message']?.toString() ?? reason;
      } catch (_) {}
      throw Exception('رفض Cloudinary الرفع: $reason');
    }

    final data = jsonDecode(body) as Map<String, dynamic>;
    final url = data['secure_url'] ?? data['url'];
    if (url == null || url.toString().isEmpty) {
      throw Exception(missingUrlMessage);
    }

    return url.toString();
  }

}
