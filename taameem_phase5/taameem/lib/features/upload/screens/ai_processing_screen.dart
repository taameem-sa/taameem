import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_colors.dart';
import 'package:latlong2/latlong.dart';

// نتيجة تحليل الذكاء الاصطناعي
class AiAnalysisResult {
  final String type;
  final String title;
  final String description;
  final Duration duration;
  final double radius;
  AiAnalysisResult({
    required this.type,
    required this.title,
    required this.description,
    required this.duration,
    required this.radius,
  });
}

class AiProcessingScreen extends StatefulWidget {
  final List<File>  media;
  final String?     manualType;
  final String?     manualTitle;
  final LatLng?     location;
  final double      radius;
  final Duration    duration;

  const AiProcessingScreen({
    super.key,
    required this.media,
    this.manualType,
    this.manualTitle,
    this.location,
    required this.radius,
    required this.duration,
  });

  @override
  State<AiProcessingScreen> createState() => _AiProcessingScreenState();
}

class _AiProcessingScreenState extends State<AiProcessingScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _pulseCtrl;
  int  _activeStep  = 0;
  bool _done        = false;
  AiAnalysisResult? _result;

  static const _steps = [
    'تحليل الصورة',
    'تحديد الفئة والعنوان',
    'تحديد الموقع الجغرافي',
    'تجهيز المعاينة',
  ];

  static const _catMap = {
    'missingPerson':   'فقدان شخص',
    'foundItem':       'إيجاد شيء',
    'lostItem':        'فقدان شيء',
    'theft':           'سرقة',
    'helpRequest':     'استغاثة',
    'humanitarian':    'إنساني',
    'emergency':       'طارئ',
    'generalWarning':  'تحذير عام',
    'lostAnimal':      'حيوان مفقود',
    'inquiry':         'استفسار',
  };

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _runFlow();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _runFlow() async {
    // خطوة 1 — تحليل الصورة
    setState(() => _activeStep = 0);
    await Future.delayed(const Duration(milliseconds: 700));

    // خطوة 2 — AI
    setState(() => _activeStep = 1);
    AiAnalysisResult result;
    try {
      result = await _callClaudeAI();
    } catch (_) {
      result = _fallback();
    }
    _result = result;

    await Future.delayed(const Duration(milliseconds: 600));

    // خطوة 3 — الموقع
    setState(() => _activeStep = 2);
    await Future.delayed(const Duration(milliseconds: 700));

    // خطوة 4 — تجهيز المعاينة
    setState(() => _activeStep = 3);
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() => _done = true);
    if (mounted) Navigator.pop(context, _result);
  }

  Future<AiAnalysisResult> _callClaudeAI() async {
    final prompt = '''
أنت مساعد ذكي لتطبيق تعميم (منصة تنبيهات مجتمعية).
${widget.media.isNotEmpty ? "المستخدم رفع ${widget.media.length} صورة/فيديو." : ""}
${widget.manualTitle != null ? "كتب المستخدم: ${widget.manualTitle}" : ""}
${widget.manualType != null ? "الفئة المحددة: ${widget.manualType}" : ""}

بناءً على السياق أعلاه، استجب بـ JSON فقط بدون أي نص آخر:
{
  "type": "أحد هذه: missingPerson/foundItem/lostItem/theft/helpRequest/humanitarian/emergency/generalWarning/lostAnimal/inquiry",
  "title": "عنوان مختصر بالعربية",
  "description": "وصف مختصر جداً بالعربية"
}
''';

    final messages = <Map<String, dynamic>>[];

    if (widget.media.isNotEmpty) {
      final file = widget.media.first;
      final bytes = await file.readAsBytes();
      final b64 = base64Encode(bytes);
      final ext = file.path.toLowerCase();
      final mime = ext.endsWith('.png') ? 'image/png' : 'image/jpeg';

      messages.add({
        'role': 'user',
        'content': [
          {'type': 'image', 'source': {'type': 'base64', 'media_type': mime, 'data': b64}},
          {'type': 'text', 'text': prompt},
        ],
      });
    } else {
      messages.add({'role': 'user', 'content': prompt});
    }

    final res = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'Content-Type':            'application/json',
        'anthropic-version':       '2023-06-01',
      },
      body: jsonEncode({
        'model':      'claude-haiku-4-5-20251001',
        'max_tokens': 300,
        'messages':   messages,
      }),
    ).timeout(const Duration(seconds: 15));

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final text = (data['content'] as List).firstWhere(
        (c) => c['type'] == 'text', orElse: () => {'text': ''})['text'] as String;
      final cleaned = text.trim().replaceAll(RegExp(r'^```json|^```|```$', multiLine: true), '').trim();
      final parsed  = jsonDecode(cleaned) as Map<String, dynamic>;

      return AiAnalysisResult(
        type:        parsed['type']        ?? 'inquiry',
        title:       parsed['title']       ?? 'تعميم جديد',
        description: parsed['description'] ?? '',
        duration:    widget.duration,
        radius:      widget.radius,
      );
    }
    return _fallback();
  }

  AiAnalysisResult _fallback() {
    final t = widget.manualType ?? 'inquiry';
    return AiAnalysisResult(
      type:        t,
      title:       widget.manualTitle ?? _catMap[t] ?? 'تعميم جديد',
      description: '',
      duration:    widget.duration,
      radius:      widget.radius,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050C06),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // أيقونة نابضة
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) {
                final v = _pulseCtrl.value;
                return Container(
                  width: 88, height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.gold.withValues(alpha: 0.1 + v * 0.15),
                        AppColors.emerald.withValues(alpha: 0.1 + v * 0.1),
                      ],
                    ),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.3 + v * 0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: v * 0.35),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.gold,
                    size: 38,
                  ),
                );
              },
            ),

            const SizedBox(height: 10),
            Text('الذكاء الاصطناعي يحلل تعميمك',
              style: GoogleFonts.cairo(
                fontSize: 14, color: Colors.white70,
                fontWeight: FontWeight.w600)),

            const SizedBox(height: 40),

            // خطوات التحليل
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: _steps.asMap().entries.map((e) {
                  final i     = e.key;
                  final label = e.value;
                  final isActive = i == _activeStep;
                  final isDone   = i < _activeStep || _done;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(13),
                      color: isActive
                          ? AppColors.gold.withValues(alpha: 0.08)
                          : isDone
                              ? AppColors.emerald.withValues(alpha: 0.05)
                              : Colors.white.withValues(alpha: 0.03),
                      border: Border.all(
                        color: isActive
                            ? AppColors.gold.withValues(alpha: 0.35)
                            : isDone
                                ? AppColors.emerald.withValues(alpha: 0.3)
                                : Colors.white.withValues(alpha: 0.07),
                      ),
                    ),
                    child: Row(children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive
                              ? AppColors.gold
                              : isDone
                                  ? AppColors.emerald
                                  : Colors.white.withValues(alpha: 0.2),
                          boxShadow: isActive ? [BoxShadow(
                            color: AppColors.gold.withValues(alpha: 0.6),
                            blurRadius: 8)] : [],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(label,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: isActive
                              ? FontWeight.w700 : FontWeight.w500,
                          color: isActive
                              ? Colors.white
                              : isDone
                                  ? Colors.white.withValues(alpha: 0.6)
                                  : Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      const Spacer(),
                      if (isDone)
                        const Icon(Icons.check_rounded,
                            color: AppColors.emerald, size: 14),
                      if (isActive)
                        const SizedBox(
                          width: 14, height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: AppColors.gold,
                          ),
                        ),
                    ]),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
