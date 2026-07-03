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

  // ─── حذف صورة ────────────────────────────────────────────────────────────
  Future<void> deleteImage(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (_) {
      // تجاهل خطأ إذا الصورة غير موجودة
    }
  }
}
