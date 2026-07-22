import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/taameem_model.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  أزرار التفاعل — تصميم محسّن بتوهج واضح + سهم قائمة + قائمة حسابات
// ══════════════════════════════════════════════════════════════════════════════
class TaameemActionButtons extends StatelessWidget {
  final TaameemModel taameem;
  final String currentUserId;
  final String currentUserName;
  final bool isOwner;

  const TaameemActionButtons({
    super.key,
    required this.taameem,
    required this.currentUserId,
    required this.currentUserName,
    required this.isOwner,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isOwner) ...[
          _OwnerButtons(taameem: taameem),
          const SizedBox(height: 10),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _RespondBtn(
                taameem: taameem,
                currentUserId: currentUserId,
                currentUserName: currentUserName,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _WitnessBtn(
                taameem: taameem,
                currentUserId: currentUserId,
                currentUserName: currentUserName,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _SimpleBtn(
                icon: Icons.share_rounded,
                label: 'مشاركة',
                color: AppColors.emerald,
                filled: true,
                onTap: () {
                  HapticFeedback.lightImpact();
                  _snack(context, 'جاري المشاركة...', AppColors.emerald);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SaveBtn(taameem: taameem, currentUserId: currentUserId),
            ),
            const SizedBox(width: 8),
            _MoreBtn(taameem: taameem, currentUserId: currentUserId),
          ],
        ),
      ],
    );
  }

  static void _snack(BuildContext c, String msg, Color color) {
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.cairo()),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  أزرار المالك — إنهاء التعميم + حذف
// ══════════════════════════════════════════════════════════════════════════════
class _OwnerButtons extends StatelessWidget {
  final TaameemModel taameem;

  const _OwnerButtons({required this.taameem});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SimpleBtn(
            icon: Icons.check_circle_outline_rounded,
            label: 'إنهاء التعميم',
            color: AppColors.forestGreen,
            onTap: () => _markResolved(context),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SimpleBtn(
            icon: Icons.delete_outline_rounded,
            label: 'حذف التعميم',
            color: AppColors.error,
            onTap: () => _deleteTaameem(context),
          ),
        ),
      ],
    );
  }

  Future<void> _markResolved(BuildContext context) async {
    HapticFeedback.lightImpact();
    await FirebaseFirestore.instance
        .collection('taameems')
        .doc(taameem.id)
        .update({
      'status': 'resolved',
      'resolvedAt': FieldValue.serverTimestamp(),
    });

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('تم إنهاء التعميم', style: GoogleFonts.cairo()),
      backgroundColor: AppColors.forestGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Future<void> _deleteTaameem(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('حذف التعميم؟', style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
        content: Text('لا يمكن التراجع عن هذا الإجراء.', style: GoogleFonts.cairo()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('حذف', style: GoogleFonts.cairo(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (ok != true) return;
    await FirebaseFirestore.instance
        .collection('taameems')
        .doc(taameem.id)
        .delete();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('تم حذف التعميم', style: GoogleFonts.cairo()),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  زر "أنا قادم" — يتغير اسمه حسب فئة التعميم + توهج + عداد بسهم
// ══════════════════════════════════════════════════════════════════════════════
class _RespondBtn extends StatelessWidget {
  final TaameemModel taameem;
  final String currentUserId;
  final String currentUserName;

  const _RespondBtn({
    required this.taameem,
    required this.currentUserId,
    required this.currentUserName,
  });

  // اسم الزر حسب فئة التعميم
  String get _label {
    switch (taameem.type) {
      case 'helpRequest':
      case 'emergency':
      case 'humanitarian':
        return 'أنا قادم للمساعدة';
      case 'missingPerson':
        return 'سأبحث معك';
      case 'lostAnimal':
        return 'سأبحث عنه';
      case 'theft':
        return 'شاهدت الموقع';
      case 'generalWarning':
        return 'أنا على علم';
      case 'foundItem':
      case 'lostItem':
        return 'سأتواصل';
      case 'inquiry':
        return 'لدي إجابة';
      default:
        return 'أنا قادم';
    }
  }

  // نص العداد حسب الفئة
  String _counterText(int n) {
    switch (taameem.type) {
      case 'missingPerson':
      case 'lostAnimal':
        return '$n ${n == 1 ? "شخص يبحث" : "أشخاص يبحثون"}';
      case 'theft':
        return '$n ${n == 1 ? "شخص شاهد" : "أشخاص شاهدوا"}';
      case 'generalWarning':
        return '$n ${n == 1 ? "شخص على علم" : "أشخاص على علم"}';
      case 'foundItem':
      case 'lostItem':
      case 'inquiry':
        return '$n ${n == 1 ? "رد" : "ردود"}';
      default:
        return '$n ${n == 1 ? "شخص في الطريق" : "أشخاص في الطريق"}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseFirestore.instance
        .collection('taameems')
        .doc(taameem.id)
        .collection('responses')
        .doc(currentUserId);

    return StreamBuilder<DocumentSnapshot>(
      stream: ref.snapshots(),
      builder: (context, snap) {
        final active = snap.data?.exists ?? false;
        return Column(
          children: [
            _InteractiveButton(
              active: active,
              label: _label,
              activeColor: AppColors.emerald,
              icon: active
                  ? Icons.directions_run_rounded
                  : Icons.directions_run_outlined,
              onTap: () => _toggle(context, ref, active),
            ),
            _CounterChip(
              taameemId: taameem.id,
              collection: 'responses',
              color: AppColors.emerald,
              builder: _counterText,
              onTap: () => _openList(context),
            ),
          ],
        );
      },
    );
  }

  Future<void> _toggle(
      BuildContext context, DocumentReference ref, bool active) async {
    HapticFeedback.mediumImpact();
    if (active) {
      await ref.delete();
    } else {
      await ref.set({
        'userId': currentUserId,
        'userName': currentUserName,
        'timestamp': FieldValue.serverTimestamp(),
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('تم إخطار الناشر باستجابتك',
              style: GoogleFonts.cairo()),
          backgroundColor: AppColors.emerald,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  void _openList(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AccountsSheet(
        taameemId: taameem.id,
        collection: 'responses',
        title: 'المستجيبون',
        chipLabel: _respondChip,
        color: AppColors.emerald,
        icon: Icons.directions_run_rounded,
      ),
    );
  }

  String get _respondChip {
    switch (taameem.type) {
      case 'missingPerson':
      case 'lostAnimal':
        return 'يبحث';
      case 'theft':
        return 'شاهد';
      case 'generalWarning':
        return 'على علم';
      default:
        return 'في الطريق';
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  زر "أنا شاهد" — توهج ذهبي + عداد بسهم
// ══════════════════════════════════════════════════════════════════════════════
class _WitnessBtn extends StatelessWidget {
  final TaameemModel taameem;
  final String currentUserId;
  final String currentUserName;

  const _WitnessBtn({
    required this.taameem,
    required this.currentUserId,
    required this.currentUserName,
  });

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseFirestore.instance
        .collection('taameems')
        .doc(taameem.id)
        .collection('witnesses')
        .doc(currentUserId);

    return StreamBuilder<DocumentSnapshot>(
      stream: ref.snapshots(),
      builder: (context, snap) {
        final active = snap.data?.exists ?? false;
        return Column(
          children: [
            _InteractiveButton(
              active: active,
              label: 'أنا شاهد',
              activeColor: AppColors.gold,
              icon: active
                  ? Icons.visibility_rounded
                  : Icons.visibility_outlined,
              onTap: () => _toggle(ref, active),
            ),
            _CounterChip(
              taameemId: taameem.id,
              collection: 'witnesses',
              color: AppColors.gold,
              builder: (n) => '$n ${n == 1 ? "شاهد" : "شهود"}',
              onTap: () => _openList(context),
            ),
          ],
        );
      },
    );
  }

  Future<void> _toggle(DocumentReference ref, bool active) async {
    HapticFeedback.lightImpact();
    if (active) {
      await ref.delete();
    } else {
      await ref.set({
        'userId': currentUserId,
        'userName': currentUserName,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  void _openList(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AccountsSheet(
        taameemId: taameem.id,
        collection: 'witnesses',
        title: 'الشهود',
        chipLabel: 'شاهد',
        color: AppColors.gold,
        icon: Icons.visibility_rounded,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  الزر التفاعلي المشترك — توهج واضح + علامة صح
// ══════════════════════════════════════════════════════════════════════════════
class _InteractiveButton extends StatelessWidget {
  final bool active;
  final String label;
  final Color activeColor;
  final IconData icon;
  final VoidCallback onTap;

  const _InteractiveButton({
    required this.active,
    required this.label,
    required this.activeColor,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
        height: 48,
        decoration: BoxDecoration(
          // توهج واضح عند التفعيل
          gradient: active
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    activeColor.withValues(alpha: 0.22),
                    activeColor.withValues(alpha: 0.12),
                  ],
                )
              : null,
          color: active ? null : AppColors.warmBeige,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? activeColor : AppColors.glassBorder,
            width: 1.5,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.30),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 17,
                  color: active ? activeColor : AppColors.forestGreen,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: active ? activeColor : AppColors.forestGreen,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            // علامة الصح عند التفعيل
            if (active)
              Positioned(
                top: 5,
                left: 6,
                child: Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    color: activeColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      size: 10, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  عداد المشاركين — بسهم يدل على وجود قائمة
// ══════════════════════════════════════════════════════════════════════════════
class _CounterChip extends StatelessWidget {
  final String taameemId;
  final String collection;
  final Color color;
  final String Function(int) builder;
  final VoidCallback onTap;

  const _CounterChip({
    required this.taameemId,
    required this.collection,
    required this.color,
    required this.builder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('taameems')
          .doc(taameemId)
          .collection(collection)
          .snapshots(),
      builder: (_, snap) {
        final n = snap.data?.docs.length ?? 0;
        if (n == 0) return const SizedBox(height: 6);
        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // السهم يدل على قائمة قابلة للفتح
                  Icon(Icons.chevron_left_rounded, size: 13, color: color),
                  const SizedBox(width: 1),
                  Text(
                    builder(n),
                    style: GoogleFonts.cairo(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  قائمة الحسابات — Bottom Sheet
// ══════════════════════════════════════════════════════════════════════════════
class _AccountsSheet extends StatelessWidget {
  final String taameemId;
  final String collection;
  final String title;
  final String chipLabel;
  final Color color;
  final IconData icon;

  const _AccountsSheet({
    required this.taameemId,
    required this.collection,
    required this.title,
    required this.chipLabel,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: const BoxDecoration(
        color: AppColors.creamWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // مقبض
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.warmBeige,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // الرأس
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 16, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.nearBlack,
                  ),
                ),
                const Spacer(),
                _CountBadge(
                  taameemId: taameemId,
                  collection: collection,
                  color: color,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.glassBorder),
          // القائمة
          Flexible(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('taameems')
                  .doc(taameemId)
                  .collection(collection)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(30),
                    child: Center(
                      child: CircularProgressIndicator(
                          color: AppColors.emerald, strokeWidth: 2),
                    ),
                  );
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(30),
                    child: Text('لا يوجد أحد بعد',
                        style: GoogleFonts.cairo(color: AppColors.grey)),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final d = docs[i].data() as Map<String, dynamic>;
                    return _AccountTile(
                      name: d['userName'] as String? ?? 'مستخدم',
                      chipLabel: chipLabel,
                      color: color,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final String taameemId;
  final String collection;
  final Color color;

  const _CountBadge({
    required this.taameemId,
    required this.collection,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('taameems')
          .doc(taameemId)
          .collection(collection)
          .snapshots(),
      builder: (_, snap) {
        final n = snap.data?.docs.length ?? 0;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$n',
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        );
      },
    );
  }
}

// ── عنصر حساب في القائمة ──────────────────────────────────────────────────────
class _AccountTile extends StatelessWidget {
  final String name;
  final String chipLabel;
  final Color color;

  const _AccountTile({
    required this.name,
    required this.chipLabel,
    required this.color,
  });

  Color get _avatarColor {
    const colors = [
      AppColors.emerald,
      AppColors.gold,
      Color(0xFF3A8AA8),
      Color(0xFFA0287A),
      Color(0xFFC84C10),
      Color(0xFF7A3A8A),
    ];
    return colors[name.codeUnits.fold(0, (a, b) => a + b) % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          // الأفاتار
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _avatarColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0] : 'م',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 11),
          // الاسم
          Expanded(
            child: Text(
              name,
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.nearBlack,
              ),
            ),
          ),
          // الشارة
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              chipLabel,
              style: GoogleFonts.cairo(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // زر المراسلة
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.emerald.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.emerald.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.chat_bubble_outline_rounded,
                size: 15, color: AppColors.emerald),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  زر الحفظ
// ══════════════════════════════════════════════════════════════════════════════
class _SaveBtn extends StatelessWidget {
  final TaameemModel taameem;
  final String currentUserId;

  const _SaveBtn({required this.taameem, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('saved')
        .doc(taameem.id);

    return StreamBuilder<DocumentSnapshot>(
      stream: ref.snapshots(),
      builder: (context, snap) {
        final saved = snap.data?.exists ?? false;
        return GestureDetector(
          onTap: () async {
            HapticFeedback.lightImpact();
            if (saved) {
              await ref.delete();
            } else {
              await ref.set({
                'taameemId': taameem.id,
                'savedAt': FieldValue.serverTimestamp(),
              });
            }
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(saved ? 'تم إلغاء الحفظ' : 'تم الحفظ',
                    style: GoogleFonts.cairo()),
                backgroundColor: AppColors.forestGreen,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ));
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: 44,
            decoration: BoxDecoration(
              color: saved
                  ? AppColors.forestGreen.withValues(alpha: 0.12)
                  : AppColors.warmBeige,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: saved ? AppColors.forestGreen : AppColors.glassBorder,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  saved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: AppColors.forestGreen,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'حفظ',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.forestGreen,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  زر بسيط عام
// ══════════════════════════════════════════════════════════════════════════════
class _SimpleBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool filled;
  final VoidCallback onTap;

  const _SimpleBtn({
    required this.icon,
    required this.label,
    required this.color,
    this.filled = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: filled ? color.withValues(alpha: 0.09) : AppColors.warmBeige,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: filled ? color.withValues(alpha: 0.4) : AppColors.glassBorder,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  زر ثلاث نقاط — الإبلاغ + حظر
// ══════════════════════════════════════════════════════════════════════════════
class _MoreBtn extends StatelessWidget {
  final TaameemModel taameem;
  final String currentUserId;

  const _MoreBtn({required this.taameem, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showSheet(context),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.warmBeige,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.glassBorder, width: 1.5),
        ),
        child: const Icon(Icons.more_horiz_rounded,
            color: AppColors.forestGreen, size: 20),
      ),
    );
  }

  void _showSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.creamWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.warmBeige,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _MenuItem(
              icon: Icons.flag_outlined,
              label: 'الإبلاغ عن التعميم',
              color: AppColors.error,
              onTap: () {
                Navigator.pop(ctx);
                _showReport(context);
              },
            ),
            const SizedBox(height: 8),
            _MenuItem(
              icon: Icons.block_rounded,
              label: 'حظر الناشر',
              color: AppColors.grey,
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  void _showReport(BuildContext context) {
    const reasons = [
      'معلومات مضللة',
      'محتوى مسيء',
      'تعميم مكرر',
      'محتوى غير لائق',
      'أخرى',
    ];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.creamWhite,
        title: Text('سبب الإبلاغ',
            style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.nearBlack)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: reasons
              .map((r) => GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('تم الإبلاغ، شكراً لك',
                            style: GoogleFonts.cairo()),
                        backgroundColor: AppColors.forestGreen,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ));
                    },
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 7),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: AppColors.warmBeige,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                      child: Text(r,
                          style: GoogleFonts.cairo(
                              fontSize: 13, color: AppColors.nearBlack)),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 12),
            Text(label,
                style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color)),
          ],
        ),
      ),
    );
  }
}
