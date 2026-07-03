import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/chat_message.dart';
import '../../../core/models/taameem_model.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/widgets/animated_background.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/taameem_preview_card.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final List<Map<String, dynamic>> _apiHistory = [];
  final List<File> _attachedImages = [];

  bool _isLoading = false;
  bool _showWelcome = true;
  LatLng? _attachedLocation;

  @override
  void initState() {
    super.initState();
    // رسالة ترحيب بعد ثانية
    Future.delayed(const Duration(milliseconds: 800), _showWelcomeMessage);
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showWelcomeMessage() {
    if (!mounted) return;
    setState(() {
      _showWelcome = false;
      _messages.add(ChatMessage.aiText(
        'السلام عليكم! أنا تعميم، مساعدك الذكي 👋\n\n'
        'أكتب لي التعميم الذي تريد نشره بأي شكل، '
        'سواء كان فقدان شخص أو شيء، سرقة، تحذير، أو أي موضوع مجتمعي، '
        'وأنا سأهتم بالباقي.\n\n'
        'أو يمكنك رفع صورة وسأساعدك في وصفها.',
      ));
    });
  }

  // ─── الأسئلة السريعة ──────────────────────────────────────────────────────
  static const List<Map<String, String>> _quickActions = [
    {'text': 'فقدت شيئاً', 'icon': '🔍'},
    {'text': 'أريد إبلاغ عن سرقة', 'icon': '🚨'},
    {'text': 'وجدت شيئاً ضائعاً', 'icon': '📦'},
    {'text': 'شخص مفقود', 'icon': '👤'},
    {'text': 'تحذير للمجتمع', 'icon': '⚠️'},
    {'text': 'استفسار عام', 'icon': '💬'},
  ];

  // ──────────────────────────────────────────────────────────────────────────
  //  إرسال الرسالة
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> _sendMessage([String? quickText]) async {
    final text = quickText ?? _textController.text.trim();
    final images = List<File>.from(_attachedImages);
    final location = _attachedLocation;

    if (text.isEmpty && images.isEmpty) return;

    // بناء نص الرسالة (مع إضافة الموقع إن وُجد)
    String fullText = text;
    if (location != null) {
      fullText +=
          '\n[الموقع: ${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}]';
    }

    // إضافة رسالة المستخدم
    setState(() {
      _messages.add(
        images.isNotEmpty
            ? ChatMessage.userWithImages(fullText, images)
            : ChatMessage.userText(fullText),
      );
      _messages.add(ChatMessage.thinking());
      _isLoading = true;
      _attachedImages.clear();
      _attachedLocation = null;
    });
    _textController.clear();
    _scrollToBottom();

    // إضافة الرسالة لتاريخ API
    _apiHistory.add({'role': 'user', 'content': fullText});

    try {
      // استدعاء AI مع Prompt Caching
      final response = await AiService.instance.sendMessage(
        history: _apiHistory.sublist(
            0, (_apiHistory.length - 1).clamp(0, _apiHistory.length - 1)),
        userMessage: fullText,
        images: images.isNotEmpty ? images : null,
      );

      // إضافة رد AI لتاريخ API
      _apiHistory.add({'role': 'assistant', 'content': response});

      // استخراج JSON إن وُجد
      final jsonData = AiService.instance.extractJson(response);
      final cleanText = AiService.instance.cleanResponse(response);

      if (!mounted) return;

      setState(() {
        // إزالة مؤشر الكتابة
        _messages.removeWhere((m) => m.isThinking);
        _isLoading = false;

        // إضافة النص إذا موجود
        if (cleanText.isNotEmpty) {
          _messages.add(ChatMessage.aiText(cleanText));
        }

        // إضافة بطاقة التعميم إذا استخرج JSON
        if (jsonData != null) {
          final action = jsonData['action'];
          if (action == 'publish_taameem') {
            _messages.add(ChatMessage.aiTaameemPreview(jsonData));
          } else if (action == 'search_taameems') {
            _handleSearch(jsonData);
          }
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.removeWhere((m) => m.isThinking);
        _isLoading = false;
        _messages.add(ChatMessage.aiText(
          'عذراً، حدث خطأ في الاتصال. تأكد من إضافة مفتاح API في الإعدادات وحاول مرة أخرى.',
        ));
      });
    }

    _scrollToBottom();
  }

  // ─── نشر التعميم ────────────────────────────────────────────────────────
  Future<void> _publishTaameem(Map<String, dynamic> draft) async {
    setState(() => _isLoading = true);

    try {
      final location = await LocationService.instance.getCurrentLocation();
      final days = AppConstants.decayDays[draft['type']] ?? 3;
      final now = DateTime.now();

      final taameem = TaameemModel(
        id: '',
        userId: 'temp_user',
        userPhone: '+9665XXXXXXXX',
        type: draft['type'] ?? 'inquiry',
        title: draft['title'] ?? '',
        description: draft['description'] ?? '',
        latitude: location.latitude,
        longitude: location.longitude,
        imageUrls: [],
        createdAt: now,
        expiresAt: now.add(Duration(days: days)),
        status: 'active',
      );

      await FirestoreService.instance.uploadTaameem(taameem);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _messages.add(ChatMessage.aiText(
          '✅ تم نشر تعميمك بنجاح!\n\n'
          'سيظهر على الخريطة الآن وستصل إشعارات للمستخدمين القريبين.\n'
          'هل تحتاج شيئاً آخر؟',
        ));
      });
      _apiHistory.add({
        'role': 'assistant',
        'content': 'تم نشر التعميم بنجاح.',
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _messages.add(ChatMessage.aiText(
          'حدث خطأ أثناء النشر. حاول مرة أخرى.',
        ));
      });
    }
    _scrollToBottom();
  }

  // ─── البحث من خلال AI ────────────────────────────────────────────────────
  Future<void> _handleSearch(Map<String, dynamic> searchData) async {
    // TODO: استدعاء Firestore للبحث وعرض النتائج
    setState(() {
      _messages.add(ChatMessage.aiText(
        'جاري البحث في تعميمات "${searchData['query']}"...\n'
        'هذه الميزة ستُكتمل في المرحلة الرابعة مع صفحة البحث الكاملة.',
      ));
    });
  }

  // ─── رفع الصور ────────────────────────────────────────────────────────────
  Future<void> _pickFromGallery() async {
    if (_attachedImages.length >= 4) return;
    final images = await StorageService.instance.pickMultipleImages();
    setState(() {
      _attachedImages.addAll(images);
      if (_attachedImages.length > 4) _attachedImages.length = 4;
    });
  }

  Future<void> _pickFromCamera() async {
    if (_attachedImages.length >= 4) return;
    final image = await StorageService.instance.pickImage(fromCamera: true);
    if (image != null) setState(() => _attachedImages.add(image));
  }

  Future<void> _attachLocation() async {
    final loc = await LocationService.instance.getCurrentLocation();
    setState(() => _attachedLocation = loc);
    _showSnack('تم إرفاق موقعك تلقائياً');
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.cairo()),
        backgroundColor: AppColors.emerald,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 200,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  الواجهة
  // ──────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamWhite,
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _messages.isEmpty
                    ? _buildWelcomeView()
                    : _buildChatList(),
              ),
              ChatInputBar(
                controller: _textController,
                attachedImages: _attachedImages,
                isLoading: _isLoading,
                onSend: _sendMessage,
                onPickImage: _pickFromGallery,
                onPickCamera: _pickFromCamera,
                onAttachLocation: _attachLocation,
                onRemoveImage: (i) => setState(() => _attachedImages.removeAt(i)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── رأس الصفحة ──────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.glassBackground,
            border: Border(bottom: BorderSide(color: AppColors.glassBorder)),
          ),
          child: Row(
            children: [
              // أفاتار AI
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.emerald, AppColors.forestGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.5), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.emerald.withValues(alpha: 0.3),
                        blurRadius: 10)
                  ],
                ),
                child: Center(
                  child: Text(
                    'ت',
                    style: GoogleFonts.cairo(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .shimmer(
                    duration: 3000.ms,
                    color: AppColors.gold.withValues(alpha: 0.25),
                  ),

              const SizedBox(width: 12),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تعميم AI',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.nearBlack,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.emerald,
                          shape: BoxShape.circle,
                        ),
                      ).animate(onPlay: (c) => c.repeat(reverse: true))
                          .fadeOut(duration: 1200.ms),
                      const SizedBox(width: 5),
                      Text(
                        'متاح الآن',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: AppColors.emerald,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const Spacer(),

              // زر مسح المحادثة
              if (_messages.isNotEmpty)
                GestureDetector(
                  onTap: _clearChat,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.warmBeige,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: const Icon(
                      Icons.refresh_rounded,
                      size: 18,
                      color: AppColors.forestGreen,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
      _apiHistory.clear();
    });
    _showWelcomeMessage();
  }

  // ─── الترحيب (قبل أول رسالة) ──────────────────────────────────────────────
  Widget _buildWelcomeView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.emerald, AppColors.forestGreen],
              ),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.5), width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.emerald.withValues(alpha: 0.3),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Center(
              child: Text(
                'ت',
                style: GoogleFonts.cairo(
                  fontSize: 44,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .shimmer(duration: 2000.ms, color: AppColors.gold.withValues(alpha: 0.3)),

          const SizedBox(height: 16),

          Text(
            AppConstants.aiWelcomeMessage,
            style: GoogleFonts.cairo(
              fontSize: 16,
              color: AppColors.forestGreen,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 600.ms, delay: 300.ms),
        ],
      ),
    );
  }

  // ─── قائمة الرسائل ────────────────────────────────────────────────────────
  Widget _buildChatList() {
    return Column(
      children: [
        // الأسئلة السريعة (تظهر مرة واحدة)
        if (_messages.length <= 1) _buildQuickActions(),

        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: _messages.length,
            itemBuilder: (_, i) {
              final msg = _messages[i];
              if (msg.type == MessageType.taameemPreview) {
                return TaameemPreviewCard(
                  draft: msg.taameemDraft!,
                  onConfirm: () => _publishTaameem(msg.taameemDraft!),
                  onEdit: () {
                    setState(() {
                      _messages.remove(msg);
                    });
                    _textController.text = 'أريد تعديل التعميم: ';
                  },
                );
              }
              return ChatBubble(message: msg);
            },
          ),
        ),
      ],
    );
  }

  // ─── الأسئلة السريعة ──────────────────────────────────────────────────────
  Widget _buildQuickActions() {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        itemCount: _quickActions.length,
        itemBuilder: (_, i) {
          final action = _quickActions[i];
          return GestureDetector(
            onTap: () => _sendMessage(action['text']),
            child: Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.warmBeige,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(action['icon']!, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    action['text']!,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: AppColors.forestGreen,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          )
              .animate(delay: Duration(milliseconds: 100 * i))
              .fadeIn(duration: 300.ms)
              .slideX(begin: 0.3, end: 0);
        },
      ),
    );
  }
}
