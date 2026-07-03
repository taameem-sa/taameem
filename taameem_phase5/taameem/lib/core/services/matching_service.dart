import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:taameem/core/models/taameem_model.dart';

/// خدمة مطابقة التعميمات — تربط فقدان + إيجاد تلقائياً
class MatchingService {
  MatchingService._();
  static final MatchingService instance = MatchingService._();

  final _db = FirebaseFirestore.instance;

  // ─── أزواج المطابقة ────────────────────────────────────────────────────────
  static const Map<String, String> _matchPairs = {
    'lostItem':      'foundItem',
    'foundItem':     'lostItem',
    'missingPerson': 'missingPerson',
    'lostAnimal':    'lostAnimal',
  };

  // ─── البحث عن تطابقات عند رفع تعميم جديد ─────────────────────────────────
  Future<List<TaameemModel>> findMatches(TaameemModel newTaameem) async {
    final matchType = _matchPairs[newTaameem.type];
    if (matchType == null) return [];

    // جلب التعميمات من النوع المقابل في نفس المدينة
    final snapshot = await _db.collection('taameems')
        .where('type', isEqualTo: matchType)
        .where('status', isEqualTo: 'active')
        .where('city', isEqualTo: newTaameem.city)
        .limit(20)
        .get();

    final candidates = snapshot.docs
        .map(TaameemModel.fromFirestore)
        .toList();

    // تصفية حسب التشابه النصي البسيط
    return candidates.where((c) => _isSimilar(newTaameem, c)).toList();
  }

  bool _isSimilar(TaameemModel a, TaameemModel b) {
    // كلمات مشتركة بين العنوانين
    final aWords = _tokenize(a.title + ' ' + a.description);
    final bWords = _tokenize(b.title + ' ' + b.description);

    final common = aWords.intersection(bWords);
    if (common.isEmpty) return false;

    // نسبة التشابه > 20%
    final ratio = common.length / (aWords.length + bWords.length - common.length);
    return ratio > 0.20;
  }

  Set<String> _tokenize(String text) {
    return text
        .split(RegExp(r'[\s،,.-]+'))
        .where((w) => w.length > 2)
        .map((w) => w.trim())
        .toSet();
  }

  // ─── حفظ التطابق في Firestore ─────────────────────────────────────────────
  Future<void> saveMatch(String taameemId1, String taameemId2) async {
    await _db.collection('matches').add({
      'taameemIds': [taameemId1, taameemId2],
      'status':    'pending',
      'createdAt': Timestamp.now(),
    });
  }

  // ─── جلب نسبة التطابق (للعرض) ────────────────────────────────────────────
  double getMatchScore(TaameemModel a, TaameemModel b) {
    final aWords = _tokenize(a.title + ' ' + a.description);
    final bWords = _tokenize(b.title + ' ' + b.description);
    final common = aWords.intersection(bWords);
    if (common.isEmpty) return 0;
    return common.length / (aWords.length + bWords.length - common.length);
  }
}
