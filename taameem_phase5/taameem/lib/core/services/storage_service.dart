import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = const Uuid();

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

  // ─── رفع صورة واحدة ──────────────────────────────────────────────────────
  Future<String> uploadImage(File image, String folder) async {
    final fileName = '${_uuid.v4()}.jpg';
    final ref = _storage.ref().child('$folder/$fileName');

    final uploadTask = ref.putFile(
      image,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  // ─── رفع عدة صور ─────────────────────────────────────────────────────────
  Future<List<String>> uploadImages(
      List<File> images, String taameemId) async {
    final urls = <String>[];
    for (final image in images) {
      final url = await uploadImage(image, 'taameems/$taameemId');
      urls.add(url);
    }
    return urls;
  }

  // ─── رفع مرفق واحد (صورة / فيديو / ملف) ───────────────────────────────
  Future<String> uploadAttachment(File file, String folder) async {
    final ext = _extension(file.path);
    final fileName = '${_uuid.v4()}$ext';
    final ref = _storage.ref().child('$folder/$fileName');

    final uploadTask = ref.putFile(
      file,
      SettableMetadata(contentType: _contentTypeForExt(ext)),
    );

    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  // ─── رفع جميع المرفقات ─────────────────────────────────────────────────
  Future<List<String>> uploadMediaFiles(
      List<File> files, String taameemId) async {
    final urls = <String>[];
    for (final file in files) {
      final url = await uploadAttachment(file, 'taameems/$taameemId');
      urls.add(url);
    }
    return urls;
  }

  // ─── حذف صورة ────────────────────────────────────────────────────────────
  Future<void> deleteImage(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (_) {
      // تجاهل خطأ إذا الصورة غير موجودة
    }
  }

  String _extension(String path) {
    final idx = path.lastIndexOf('.');
    if (idx < 0 || idx == path.length - 1) return '';
    return path.substring(idx).toLowerCase();
  }

  String _contentTypeForExt(String ext) {
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.heic':
        return 'image/heic';
      case '.mp4':
        return 'video/mp4';
      case '.mov':
        return 'video/quicktime';
      case '.avi':
        return 'video/x-msvideo';
      case '.pdf':
        return 'application/pdf';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case '.xls':
        return 'application/vnd.ms-excel';
      case '.xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case '.ppt':
        return 'application/vnd.ms-powerpoint';
      case '.pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case '.txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }
}
