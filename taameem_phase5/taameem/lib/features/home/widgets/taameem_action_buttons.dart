import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/taameem_model.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  أزرار التفاعل الكاملة — تصميم زجاجي شفاف
// ══════════════════════════════════════════════════════════════════════════════
class TaameemActionButtons extends StatelessWidget {
  final TaameemModel taameem;
  final String       currentUserId;
  final String       currentUserName;
  final bool         isOwner; // هل المستخدم الحالي هو الناشر؟

  const TaameemActionButtons({
    super.key,
    required this.taameem,
    required this.currentUserId,
    required this.currentUserName,
    required this.isOwner,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [

      // ── أزرار الناشر فقط ────────────────────────────────────────────────
      if (isOwner) ...[
        _OwnerButtons(taameem: taameem),
        const SizedBox(height: 10),
      ],

      // ── صف 1: أنا قادم + أنا شاهد ──────────────────────────────────────
      Row(children: [
        Expanded(child: _RespondBtn(
          taameem:         taameem,
          currentUserId:   currentUserId,
          currentUserName: currentUserName,
        )),
        const SizedBox(width: 8),
        Expanded(child: _WitnessBtn(
          taameem:         taameem,
          currentUserId:   currentUserId,
          currentUserName: currentUserName,
        )),
      ]),

      const SizedBox(height: 8),

      // ── صف 2: مشاركة + حفظ + ثلاث نقاط ────────────────────────────────
      Row(children: [
        Expanded(child: _GlassBtn(
          icon:  Icons.share_rounded,
          label: 'مشاركة',
          color: AppColors.emerald,
          onTap: () => _share(context),
        )),
        const SizedBox(width: 8),
        Expanded(child: _SaveBtn(
          taameem:       taameem,
          currentUserId: currentUserId,
        )),
        const SizedBox(width: 8),
        _MoreBtn(taameem: taameem, currentUserId: currentUserId),
      ]),
    ]);
  }

  void _share(BuildContext context) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('جاري مشاركة التعميم...',
          style: GoogleFonts.cairo()),
      backgroundColor: AppColors.emerald,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  أزرار الناشر — حذف وتعديل
// ════════════════════════════════════════════════════════════════════════════
class _OwnerButtons extends StatelessWidget {
  final TaameemModel taameem;
  const _OwnerButtons({required this.taameem});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: AppColors.gold.withOpacity(0.35), width: 1.5),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.manage_accounts_rounded,
                  size: 14, color: AppColors.gold),
              const SizedBox(width: 6),
              Text('إدارة تعميمك',
                style: GoogleFonts.cairo(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: AppColors.gold)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              // تعديل
              Expanded(child: _GlassBtn(
                icon:  Icons.edit_rounded,
                label: 'تعديل التعميم',
                color: AppColors.teal,
                onTap: () => _showEditSnack(context),
              )),
              const SizedBox(width: 8),
              // حذف
              Expanded(child: _GlassBtn(
                icon:  Icons.delete_outline_rounded,
                label: 'حذف التعميم',
                color: AppColors.error,
                onTap: () => _confirmDelete(context),
              )),
            ]),
          ]),
        ),
      ),
    );
  }

  void _showEditSnack(BuildContext ctx) {
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: Text('سيُفتح محرر التعميم قريباً',
          style: GoogleFonts.cairo()),
      backgroundColor: AppColors.teal,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _confirmDelete(BuildContext ctx) {
    showDialog(context: ctx, builder: (dialogCtx) => Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Colors.white.withOpacity(0.2))),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.error.withOpacity(0.4))),
                child: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.error, size: 26)),
              const SizedBox(height: 14),
              Text('حذف التعميم؟',
                style: GoogleFonts.cairo(
                  fontSize: 17, fontWeight: FontWeight.w800,
                  color: Colors.white)),
              const SizedBox(height: 8),
              Text('لا يمكن التراجع عن هذه العملية',
                style: GoogleFonts.cairo(
                  fontSize: 12, color: Colors.white70),
                textAlign: TextAlign.center),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: GestureDetector(
                  onTap: () => Navigator.pop(dialogCtx),
                  child: Container(
                    height: 42, decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.3))),
                    child: Center(child: Text('إلغاء',
                      style: GoogleFonts.cairo(
                        fontSize: 13, color: Colors.white70)))),
                )),
                const SizedBox(width: 10),
                Expanded(child: GestureDetector(
                  onTap: () {
                    Navigator.pop(dialogCtx);
                    Navigator.pop(ctx);
                    // FirestoreService.instance.deleteTaameem(taameem.id);
                  },
                  child: Container(
                    height: 42, decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12)),
                    child: Center(child: Text('حذف',
                      style: GoogleFonts.cairo(
                        fontSize: 13, fontWeight: FontWeight.w800,
                        color: Colors.white)))),
                )),
              ]),
            ]),
          ),
        ),
      ),
    ));
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  زر "أنا قادم / الاستجابة"
// ════════════════════════════════════════════════════════════════════════════
class _RespondBtn extends StatefulWidget {
  final TaameemModel taameem;
  final String currentUserId, currentUserName;
  const _RespondBtn({
    required this.taameem,
    required this.currentUserId,
    required this.currentUserName,
  });
  @override State<_RespondBtn> createState() => _RespondBtnState();
}

class _RespondBtnState extends State<_RespondBtn> {
  final _db = FirebaseFirestore.instance;

  String get _label {
    switch (widget.taameem.type) {
      case 'helpRequest':
      case 'emergency':
      case 'humanitarian': return 'أنا قادم للمساعدة';
      case 'missingPerson': return 'سأبحث معك';
      case 'theft':        return 'شاهدت الموقع';
      default:             return 'أنا قادم';
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _db
        .collection('taameems').doc(widget.taameem.id)
        .collection('responses').doc(widget.currentUserId)
        .snapshots(),
      builder: (_, snap) {
        final responded = snap.data?.exists ?? false;
        return Column(children: [
          // الزر الرئيسي
          GestureDetector(
            onTap: () => _toggle(context, responded),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 48,
                  decoration: BoxDecoration(
                    color: responded
                      ? AppColors.emerald.withOpacity(0.25)
                      : Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: responded
                        ? AppColors.emerald.withOpacity(0.6)
                        : Colors.white.withOpacity(0.2),
                      width: 1.5),
                    boxShadow: responded ? [BoxShadow(
                      color: AppColors.emerald.withOpacity(0.3),
                      blurRadius: 12)] : [],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        responded
                          ? Icons.directions_run_rounded
                          : Icons.directions_run_outlined,
                        color: responded
                          ? AppColors.emerald
                          : Colors.white70,
                        size: 17),
                      const SizedBox(width: 6),
                      Text(_label,
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: responded
                            ? AppColors.emerald
                            : Colors.white70)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // عداد المستجيبين
          StreamBuilder<QuerySnapshot>(
            stream: _db
              .collection('taameems').doc(widget.taameem.id)
              .collection('responses').snapshots(),
            builder: (_, s) {
              final count = s.data?.docs.length ?? 0;
              if (count == 0) return const SizedBox(height: 4);
              return GestureDetector(
                onTap: () => _showResponders(context),
                child: Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_alt_rounded,
                          size: 11,
                          color: AppColors.emerald.withOpacity(0.8)),
                      const SizedBox(width: 4),
                      Text('$count ${count == 1 ? 'شخص' : 'أشخاص'} في الطريق',
                        style: GoogleFonts.cairo(
                          fontSize: 10,
                          color: AppColors.emerald.withOpacity(0.9),
                          fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              );
            },
          ),
        ]);
      },
    );
  }

  Future<void> _toggle(BuildContext ctx, bool responded) async {
    HapticFeedback.mediumImpact();
    final ref = _db
      .collection('taameems').doc(widget.taameem.id)
      .collection('responses').doc(widget.currentUserId);

    if (responded) {
      await ref.delete();
    } else {
      await ref.set({
        'userId':    widget.currentUserId,
        'userName':  widget.currentUserName,
        'timestamp': FieldValue.serverTimestamp(),
        'type':      widget.taameem.type,
      });
      if (ctx.mounted) _showResponseNotice(ctx);
    }
  }

  void _showResponseNotice(BuildContext ctx) {
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.directions_run_rounded,
            color: Colors.white, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(
          'تم إخطار الناشر بأنك في الطريق',
          style: GoogleFonts.cairo(fontSize: 12))),
      ]),
      backgroundColor: AppColors.emerald,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
    ));
  }

  void _showResponders(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (_) => _RespondersList(taameemId: widget.taameem.id),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  قائمة المستجيبين
// ════════════════════════════════════════════════════════════════════════════
class _RespondersList extends StatelessWidget {
  final String taameemId;
  const _RespondersList({required this.taameemId});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.creamWhite.withOpacity(0.92),
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24)),
            border: Border(top: BorderSide(
                color: AppColors.glassBorder))),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 40, height: 4, margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: AppColors.warmBeige,
                borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
              child: Row(children: [
                const Icon(Icons.directions_run_rounded,
                    color: AppColors.emerald, size: 18),
                const SizedBox(width: 8),
                Text('في الطريق للمساعدة',
                  style: GoogleFonts.cairo(
                    fontSize: 16, fontWeight: FontWeight.w800,
                    color: AppColors.nearBlack)),
              ]),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                .collection('taameems').doc(taameemId)
                .collection('responses').snapshots(),
              builder: (_, snap) {
                final docs = snap.data?.docs ?? [];
                return SizedBox(
                  height: docs.length * 60.0 + 20,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    itemCount: docs.length,
                    itemBuilder: (_, i) {
                      final d = docs[i].data() as Map<String, dynamic>;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.emerald,
                                    AppColors.forestGreen]),
                              shape: BoxShape.circle),
                            child: Center(child: Text(
                              (d['userName'] as String? ?? 'م')
                                  .substring(0, 1),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800)))),
                          const SizedBox(width: 10),
                          Text(d['userName'] as String? ?? 'مستخدم',
                            style: GoogleFonts.cairo(
                              fontSize: 14, fontWeight: FontWeight.w600,
                              color: AppColors.nearBlack)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.emerald.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: AppColors.emerald.withOpacity(0.3))),
                            child: Text('في الطريق',
                              style: GoogleFonts.cairo(
                                fontSize: 10, fontWeight: FontWeight.w700,
                                color: AppColors.emerald))),
                        ]),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ]),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  زر "أنا شاهد"
// ════════════════════════════════════════════════════════════════════════════
class _WitnessBtn extends StatelessWidget {
  final TaameemModel taameem;
  final String currentUserId, currentUserName;
  const _WitnessBtn({
    required this.taameem,
    required this.currentUserId,
    required this.currentUserName,
  });

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;
    return StreamBuilder<DocumentSnapshot>(
      stream: db
        .collection('taameems').doc(taameem.id)
        .collection('witnesses').doc(currentUserId)
        .snapshots(),
      builder: (_, snap) {
        final isWitness = snap.data?.exists ?? false;
        return Column(children: [
          GestureDetector(
            onTap: () => _toggle(context, isWitness),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 48,
                  decoration: BoxDecoration(
                    color: isWitness
                      ? AppColors.gold.withOpacity(0.2)
                      : Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isWitness
                        ? AppColors.gold.withOpacity(0.6)
                        : Colors.white.withOpacity(0.2),
                      width: 1.5),
                    boxShadow: isWitness ? [BoxShadow(
                      color: AppColors.gold.withOpacity(0.25),
                      blurRadius: 12)] : [],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isWitness
                          ? Icons.visibility_rounded
                          : Icons.visibility_outlined,
                        color: isWitness
                          ? AppColors.gold : Colors.white70,
                        size: 17),
                      const SizedBox(width: 6),
                      Text('أنا شاهد',
                        style: GoogleFonts.cairo(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: isWitness
                            ? AppColors.gold : Colors.white70)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: db
              .collection('taameems').doc(taameem.id)
              .collection('witnesses').snapshots(),
            builder: (_, s) {
              final count = s.data?.docs.length ?? 0;
              if (count == 0) return const SizedBox(height: 4);
              return GestureDetector(
                onTap: () => _showWitnesses(context),
                child: Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.remove_red_eye_rounded,
                          size: 11,
                          color: AppColors.gold.withOpacity(0.8)),
                      const SizedBox(width: 4),
                      Text('$count ${count == 1 ? 'شاهد' : 'شهود'}',
                        style: GoogleFonts.cairo(
                          fontSize: 10,
                          color: AppColors.gold.withOpacity(0.9),
                          fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              );
            },
          ),
        ]);
      },
    );
  }

  Future<void> _toggle(BuildContext ctx, bool isWitness) async {
    HapticFeedback.lightImpact();
    final ref = FirebaseFirestore.instance
      .collection('taameems').doc(taameem.id)
      .collection('witnesses').doc(currentUserId);
    isWitness
      ? await ref.delete()
      : await ref.set({
          'userId':    currentUserId,
          'userName':  currentUserName,
          'timestamp': FieldValue.serverTimestamp(),
        });
  }

  void _showWitnesses(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (_) => _WitnessesList(taameemId: taameem.id),
    );
  }
}

// قائمة الشهود
class _WitnessesList extends StatelessWidget {
  final String taameemId;
  const _WitnessesList({required this.taameemId});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.creamWhite.withOpacity(0.92),
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24)),
            border: Border(top: BorderSide(color: AppColors.glassBorder))),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: AppColors.warmBeige,
                borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
              child: Row(children: [
                const Icon(Icons.visibility_rounded,
                    color: AppColors.gold, size: 18),
                const SizedBox(width: 8),
                Text('الشهود',
                  style: GoogleFonts.cairo(
                    fontSize: 16, fontWeight: FontWeight.w800,
                    color: AppColors.nearBlack)),
              ]),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                .collection('taameems').doc(taameemId)
                .collection('witnesses').snapshots(),
              builder: (_, snap) {
                final docs = snap.data?.docs ?? [];
                return SizedBox(
                  height: (docs.length * 56.0 + 20).clamp(80, 300),
                  child: docs.isEmpty
                    ? Center(child: Text('لا يوجد شهود بعد',
                        style: GoogleFonts.cairo(color: AppColors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: docs.length,
                        itemBuilder: (_, i) {
                          final d = docs[i].data() as Map<String, dynamic>;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(children: [
                              Container(
                                width: 34, height: 34,
                                decoration: BoxDecoration(
                                  color: AppColors.gold.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: AppColors.gold.withOpacity(0.4))),
                                child: Center(child: Icon(
                                    Icons.visibility_rounded,
                                    size: 16, color: AppColors.gold))),
                              const SizedBox(width: 10),
                              Text(d['userName'] as String? ?? 'مستخدم',
                                style: GoogleFonts.cairo(
                                  fontSize: 14, fontWeight: FontWeight.w600,
                                  color: AppColors.nearBlack)),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.gold.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: AppColors.gold.withOpacity(0.3))),
                                child: Text('شاهد',
                                  style: GoogleFonts.cairo(
                                    fontSize: 10, fontWeight: FontWeight.w700,
                                    color: AppColors.gold))),
                            ]),
                          );
                        }),
                );
              },
            ),
            const SizedBox(height: 16),
          ]),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  زر الحفظ
// ════════════════════════════════════════════════════════════════════════════
class _SaveBtn extends StatelessWidget {
  final TaameemModel taameem;
  final String currentUserId;
  const _SaveBtn({required this.taameem, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseFirestore.instance
      .collection('users').doc(currentUserId)
      .collection('saved').doc(taameem.id);

    return StreamBuilder<DocumentSnapshot>(
      stream: ref.snapshots(),
      builder: (_, snap) {
        final saved = snap.data?.exists ?? false;
        return GestureDetector(
          onTap: () async {
            HapticFeedback.lightImpact();
            saved ? await ref.delete()
                  : await ref.set({
                      'taameemId': taameem.id,
                      'savedAt':   FieldValue.serverTimestamp(),
                    });
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                  saved ? 'تم إلغاء الحفظ' : 'تم حفظ التعميم',
                  style: GoogleFonts.cairo()),
                backgroundColor: AppColors.forestGreen,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ));
            }
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 44,
                decoration: BoxDecoration(
                  color: saved
                    ? AppColors.forestGreen.withOpacity(0.2)
                    : Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: saved
                      ? AppColors.forestGreen.withOpacity(0.5)
                      : Colors.white.withOpacity(0.2),
                    width: 1.5)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      saved ? Icons.bookmark_rounded
                             : Icons.bookmark_border_rounded,
                      color: saved ? AppColors.forestGreen : Colors.white70,
                      size: 16),
                    const SizedBox(width: 5),
                    Text('حفظ',
                      style: GoogleFonts.cairo(
                        fontSize: 12, fontWeight: FontWeight.w700,
                        color: saved
                          ? AppColors.forestGreen : Colors.white70)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  قائمة ثلاث نقاط — الإبلاغ
// ════════════════════════════════════════════════════════════════════════════
class _MoreBtn extends StatelessWidget {
  final TaameemModel taameem;
  final String currentUserId;
  const _MoreBtn({required this.taameem, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showMore(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: Colors.white.withOpacity(0.2), width: 1.5)),
            child: const Icon(Icons.more_horiz_rounded,
                color: Colors.white70, size: 20),
          ),
        ),
      ),
    );
  }

  void _showMore(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.creamWhite.withOpacity(0.92),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24)),
              border: Border(top: BorderSide(color: AppColors.glassBorder))),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.warmBeige,
                  borderRadius: BorderRadius.circular(2))),
              _MenuItem(
                icon:  Icons.flag_outlined,
                label: 'الإبلاغ عن التعميم',
                color: AppColors.error,
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _showReportDialog(context);
                }),
              const SizedBox(height: 8),
              _MenuItem(
                icon:  Icons.block_rounded,
                label: 'حظر الناشر',
                color: AppColors.grey,
                onTap: () => Navigator.pop(sheetCtx)),
            ]),
          ),
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext ctx) {
    final reasons = ['معلومات مضللة', 'محتوى مسيء', 'تعميم مكرر',
        'محتوى غير لائق', 'أخرى'];
    showDialog(context: ctx, builder: (dialogCtx) => Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.creamWhite.withOpacity(0.95),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.glassBorder)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('الإبلاغ عن التعميم',
                style: GoogleFonts.cairo(
                  fontSize: 16, fontWeight: FontWeight.w800,
                  color: AppColors.nearBlack)),
              const SizedBox(height: 4),
              Text('اختر سبب الإبلاغ',
                style: GoogleFonts.cairo(
                    fontSize: 12, color: AppColors.grey)),
              const SizedBox(height: 14),
              ...reasons.map((r) => GestureDetector(
                onTap: () {
                  Navigator.pop(dialogCtx);
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                    content: Text('تم إرسال الإبلاغ، شكراً لك',
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
                    border: Border.all(color: AppColors.glassBorder)),
                  child: Text(r, style: GoogleFonts.cairo(
                      fontSize: 13, color: AppColors.nearBlack))),
              )),
            ]),
          ),
        ),
      ),
    ));
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon; final String label; final Color color;
  final VoidCallback onTap;
  const _MenuItem({required this.icon, required this.label,
      required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25))),
      child: Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 12),
        Text(label, style: GoogleFonts.cairo(
          fontSize: 14, fontWeight: FontWeight.w600, color: color)),
      ]),
    ),
  );
}

// ════════════════════════════════════════════════════════════════════════════
//  زر زجاجي عام
// ════════════════════════════════════════════════════════════════════════════
class _GlassBtn extends StatelessWidget {
  final IconData icon; final String label;
  final Color color;   final VoidCallback onTap;
  const _GlassBtn({required this.icon, required this.label,
      required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () { HapticFeedback.lightImpact(); onTap(); },
    child: ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.35), width: 1.5)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.cairo(
              fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          ]),
        ),
      ),
    ),
  );
}
