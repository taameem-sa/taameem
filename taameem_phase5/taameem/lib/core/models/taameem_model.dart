import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import 'package:flutter/material.dart';

class TaameemModel {
  final String id;
  final String userId;
  final String userPhone;
  final String
      type; // 'missingPerson' | 'foundItem' | 'lostItem' | 'theft' | 'helpRequest' | 'humanitarian' | 'emergency' | 'generalWarning' | 'lostAnimal' | 'inquiry'
  final String title;
  final String description;
  final double latitude;
  final double longitude;
  final List<String> imageUrls;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String status; // 'active' | 'expired' | 'resolved'
  final String city;
  final double radiusKm;
  final bool allKingdom;
  final double? scopeCenterLat;
  final double? scopeCenterLng;
  final String neighborhood;
  final int viewCount;

  TaameemModel({
    required this.id,
    required this.userId,
    required this.userPhone,
    required this.type,
    required this.title,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.imageUrls,
    required this.createdAt,
    required this.expiresAt,
    required this.status,
    this.city = '',
    this.radiusKm = 10,
    this.allKingdom = false,
    this.scopeCenterLat,
    this.scopeCenterLng,
    this.neighborhood = '',
    this.viewCount = 0,
  });

  // ─── هل التعميم منتهي الصلاحية؟ ──────────────────────────────────────────
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  // ─── كم تبقى من الوقت؟ ────────────────────────────────────────────────────
  Duration get timeLeft => expiresAt.difference(DateTime.now());

  // ─── نص الوقت المنقضي ─────────────────────────────────────────────────────
  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    return 'منذ ${diff.inDays} يوم';
  }

  // ─── اللون الخاص بنوع التعميم ─────────────────────────────────────────────
  Color get typeColor {
    switch (type) {
      case 'missingPerson':
        return AppColors.missingPerson;
      case 'foundItem':
        return AppColors.foundItem;
      case 'lostItem':
        return AppColors.lostItem;
      case 'theft':
        return AppColors.theft;
      case 'helpRequest':
        return AppColors.helpRequest;
      case 'humanitarian':
        return AppColors.humanitarian;
      case 'emergency':
        return AppColors.emergency;
      case 'generalWarning':
        return AppColors.generalWarning;
      case 'lostAnimal':
        return AppColors.lostAnimal;
      case 'inquiry':
        return AppColors.inquiry;
      default:
        return AppColors.grey;
    }
  }

  // ─── الاسم العربي للنوع ───────────────────────────────────────────────────
  String get typeName => AppConstants.categoryNames[type] ?? 'تعميم';

  // ─── ملصق الخريطة ─────────────────────────────────────────────────────────
  String get mapLabel => AppConstants.mapLabels[type] ?? 'تعميم';

  // ─── التحويل من Firestore ──────────────────────────────────────────────────
  factory TaameemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    double parseDouble(dynamic value, [double fallback = 0.0]) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? fallback;
      return fallback;
    }

    final lat = data['latitude'] ?? data['lat'];
    final lng = data['longitude'] ?? data['lng'];

    return TaameemModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userPhone: data['userPhone'] ?? '',
      type: data['type'] ?? 'inquiry',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      latitude: parseDouble(lat),
      longitude: parseDouble(lng),
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
      status: data['status'] ?? 'active',
      city: data['city'] ?? '',
      radiusKm: parseDouble(data['radiusKm'], 10),
      allKingdom: data['allKingdom'] == true,
      scopeCenterLat: data['scopeCenterLat'] is num
          ? (data['scopeCenterLat'] as num).toDouble()
          : null,
      scopeCenterLng: data['scopeCenterLng'] is num
          ? (data['scopeCenterLng'] as num).toDouble()
          : null,
      neighborhood: data['neighborhood'] ?? '',
      viewCount: data['viewCount'] ?? 0,
    );
  }

  // ─── التحويل إلى Map لرفعه في Firestore ───────────────────────────────────
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userPhone': userPhone,
      'type': type,
      'title': title,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrls': imageUrls,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'status': status,
      'city': city,
      'radiusKm': radiusKm,
      'allKingdom': allKingdom,
      'scopeCenterLat': scopeCenterLat,
      'scopeCenterLng': scopeCenterLng,
      'neighborhood': neighborhood,
      'viewCount': viewCount,
    };
  }

  // ─── نسخة معدّلة ──────────────────────────────────────────────────────────
  TaameemModel copyWith({String? status, int? viewCount}) {
    return TaameemModel(
      id: id,
      userId: userId,
      userPhone: userPhone,
      type: type,
      title: title,
      description: description,
      latitude: latitude,
      longitude: longitude,
      imageUrls: imageUrls,
      createdAt: createdAt,
      expiresAt: expiresAt,
      status: status ?? this.status,
      city: city,
      radiusKm: radiusKm,
      allKingdom: allKingdom,
      scopeCenterLat: scopeCenterLat,
      scopeCenterLng: scopeCenterLng,
      neighborhood: neighborhood,
      viewCount: viewCount ?? this.viewCount,
    );
  }
}
