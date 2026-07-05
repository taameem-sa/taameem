import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:taameem/core/models/taameem_model.dart';
import 'package:taameem/core/services/ai_service.dart';

/// خدمة مطابقة التعميمات — تربط فقدان + إيجاد تلقائياً
class MatchingService {
  MatchingService._();
  static final MatchingService instance = MatchingService._();

  final _db = FirebaseFirestore.instance;

  // ─── أزواج المطابقة ────────────────────────────────────────────────────────
  static const Map<String, String> _matchPairs = {
    'lostItem': 'foundItem',
    'foundItem': 'lostItem',
    'missingPerson': 'missingPerson',
    'lostAnimal': 'lostAnimal',
  };

  // ─── البحث عن تطابقات عند رفع تعميم جديد ─────────────────────────────────
  Future<List<TaameemModel>> findMatches(TaameemModel newTaameem) async {
    final matchType = _matchPairs[newTaameem.type];
    if (matchType == null) return [];

    // جلب التعميمات من النوع المقابل
    final snapshot = await _db
        .collection('taameems')
        .where('type', isEqualTo: matchType)
        .where('status', isEqualTo: 'active')
        .limit(30)
        .get();

    final candidates = snapshot.docs
        .map(TaameemModel.fromFirestore)
        .where((c) => c.id != newTaameem.id)
        .toList();

    final scored = <MapEntry<TaameemModel, double>>[];

    for (final candidate in candidates) {
      final score = await getMatchScoreAsync(newTaameem, candidate);
      if (score >= 0.35) {
        scored.add(MapEntry(candidate, score));
      }
    }

    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.map((e) => e.key).toList();
  }

  double _textScore(TaameemModel a, TaameemModel b) {
    final aWords = _tokenize(a.title + ' ' + a.description);
    final bWords = _tokenize(b.title + ' ' + b.description);

    final common = aWords.intersection(bWords);
    if (common.isEmpty) return 0;

    final ratio =
        common.length / (aWords.length + bWords.length - common.length);
    return ratio.clamp(0, 1).toDouble();
  }

  double _distanceKm(TaameemModel a, TaameemModel b) {
    final dx = a.latitude - b.latitude;
    final dy = a.longitude - b.longitude;
    // Haversine approximation is overkill here; this approximation is enough for ranking.
    return sqrt(dx * dx + dy * dy) * 111;
  }

  double _locationScore(TaameemModel a, TaameemModel b) {
    if (a.latitude == 0 ||
        a.longitude == 0 ||
        b.latitude == 0 ||
        b.longitude == 0) {
      return 0;
    }
    final km = _distanceKm(a, b);
    if (km <= 1) return 1;
    if (km <= 5) return 0.8;
    if (km <= 15) return 0.55;
    if (km <= 40) return 0.3;
    return 0.1;
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
      'status': 'pending',
      'createdAt': Timestamp.now(),
    });
  }

  // ─── جلب نسبة التطابق (للعرض) ────────────────────────────────────────────
  double getMatchScore(TaameemModel a, TaameemModel b) {
    final text = _textScore(a, b);
    final location = _locationScore(a, b);
    return (text * 0.75 + location * 0.25).clamp(0, 1).toDouble();
  }

  Future<double> getMatchScoreAsync(TaameemModel a, TaameemModel b) async {
    final text = _textScore(a, b);
    final location = _locationScore(a, b);

    // إذا لا يوجد تشابه نصي مبدئي، تجنب كلفة المطابقة البصرية.
    if (text < 0.08) {
      return (text * 0.75 + location * 0.25).clamp(0, 1).toDouble();
    }

    double? imageScore;
    if (a.imageUrls.isNotEmpty && b.imageUrls.isNotEmpty) {
      imageScore = await AiService.instance.scoreImageMatchByUrls(
        a.imageUrls.first,
        b.imageUrls.first,
      );
    }

    if (imageScore == null) {
      return (text * 0.75 + location * 0.25).clamp(0, 1).toDouble();
    }

    return (text * 0.45 + location * 0.2 + imageScore * 0.35)
        .clamp(0, 1)
        .toDouble();
  }
}
