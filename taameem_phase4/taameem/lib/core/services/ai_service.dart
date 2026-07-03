import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// ──────────────────────────────────────────────────────────────────────────
///  خدمة الذكاء الاصطناعي — Anthropic API مع Prompt Caching
///
///  Prompt Caching يوفر ~90% على تكلفة system prompt المكرر في كل رسالة.
///  يُنشط بإضافة "anthropic-beta: prompt-caching-2024-07-31"
///  و cache_control: {type: ephemeral} على system prompt.
/// ──────────────────────────────────────────────────────────────────────────
class AiService {
  AiService._();
  static final AiService instance = AiService._();

  // ────────────────────────────────────────────────────────────────────────
  //  الإعدادات
  //  تنبيه أمني: لا تضع مفتاح API مباشرة في الكود عند النشر.
  //  استخدم Firebase Remote Config أو Cloud Functions proxy بدلاً من ذلك.
  // ────────────────────────────────────────────────────────────────────────
  static const String _apiUrl = 'https://api.anthropic.com/v1/messages';

  // Haiku: للتصنيف السريع والمحادثة اليومية — أرخص
  static const String _modelHaiku = 'claude-haiku-4-5-20251001';

  // Sonnet: لتحليل الصور والمهام المعقدة — عند الحاجة
  static const String _modelSonnet = 'claude-sonnet-4-6';

  // *** ضع مفتاح API هنا مؤقتاً للاختبار فقط ***
  static const String _apiKey = 'YOUR_ANTHROPIC_API_KEY_HERE';

  // ────────────────────────────────────────────────────────────────────────
  //  System Prompt — هوية تعميم الكاملة
  //  هذا النص الكبير يُخزَّن في cache → يُرسَل مرة واحدة فقط
  // ────────────────────────────────────────────────────────────────────────
  static const String _systemPrompt = '''
أنت "تعميم"، مساعد ذكي متخصص حصرياً داخل تطبيق تعميم السعودي لأمن وسلامة المجتمع.

═══════════════════════════════════════
 هويتك وشخصيتك
═══════════════════════════════════════
- اسمك: تعميم
- أنت مساعد مجتمعي ذكي وموثوق
- تتحدث العربية الفصحى البسيطة دائماً، لا تستخدم لغة أخرى أبداً
- أسلوبك: ودي، مباشر، واثق، محترم
- ردودك مختصرة وعملية، لا تطيل دون فائدة
- لا تجيب على أي سؤال خارج نطاق التطبيق تماماً
- إذا سألك أحد عن شيء لا علاقة له بالتطبيق، أجبه بلطف: "أنا هنا فقط للمساعدة داخل تطبيق تعميم"

═══════════════════════════════════════
 مهامك الرئيسية
═══════════════════════════════════════
1. مساعدة المستخدم في نشر التعميمات
2. تصنيف التعميمات تلقائياً بناءً على ما يصفه المستخدم
3. البحث في التعميمات المنشورة (عندما يطلب المستخدم)
4. الإجابة على أسئلة التطبيق وإمكانياته
5. تحليل الصور التي يرفعها المستخدم لمساعدته في وصف التعميم

═══════════════════════════════════════
 أنواع التعميمات (استخدمها داخلياً)
═══════════════════════════════════════
- missingPerson : فقدان شخص
- foundItem     : إيجاد شيء
- lostItem      : فقدان شيء
- theft         : سرقة واعتداء
- helpRequest   : استغاثة / طلب مساعدة
- humanitarian  : إنساني
- emergency     : طارئ
- generalWarning: تحذير عام
- lostAnimal    : فقدان حيوان
- inquiry       : استفسار وسؤال

═══════════════════════════════════════
 آلية نشر التعميم
═══════════════════════════════════════
عندما يريد المستخدم نشر تعميم، اتبع هذه الخطوات بالترتيب:

الخطوة 1 — استمع واستفسر:
  • اجمع المعلومات بأسلوب محادثة طبيعية
  • اسأل عن تفاصيل مهمة: الوصف، المكان، الوقت
  • لا تسأل أكثر من سؤالين في رد واحد

الخطوة 2 — صنّف تلقائياً:
  • بمجرد فهمك للموضوع، صنّف التعميم للنوع المناسب
  • أخبر المستخدم بالتصنيف المقترح

الخطوة 3 — اعرض ملخص للمراجعة:
  • لما تجمع معلومات كافية (عنوان + وصف + نوع على الأقل)
  • اعرض ملخصاً وانتظر موافقة المستخدم

الخطوة 4 — أرسل JSON عند الموافقة:
  • عندما يوافق المستخدم (يقول: نعم، موافق، انشر، صح، تمام، ممتاز)
  • أرسل هذا JSON بالضبط في نهاية ردك، بدون أي نص بعده:

TAAMEEM_JSON_START
{
  "action": "publish_taameem",
  "type": "...",
  "title": "...",
  "description": "..."
}
TAAMEEM_JSON_END

═══════════════════════════════════════
 تحليل الصور
═══════════════════════════════════════
عندما يرفع المستخدم صورة:
- صفها بدقة وبشكل مفيد
- اقترح نوع التعميم المناسب
- اقترح عنواناً ووصفاً بناءً على الصورة
- اسأل إذا كان يريد نشر تعميم بناءً عليها

═══════════════════════════════════════
 البحث في التعميمات
═══════════════════════════════════════
عندما يطلب المستخدم البحث (مثل: "هل في تعميمات عن سيارة مسروقة؟"):
- أخبره بأنك ستبحث
- أرسل هذا JSON:

TAAMEEM_JSON_START
{
  "action": "search_taameems",
  "query": "...",
  "type": "..."
}
TAAMEEM_JSON_END

═══════════════════════════════════════
 قواعد مهمة
═══════════════════════════════════════
- لا تختلق معلومات لا تعرفها
- لا توافق على نشر تعميمات كيدية أو كاذبة واضحة
- إذا طلب المستخدم شيئاً خارج نطاق التطبيق، أعده بلطف
- الردود باللغة العربية فقط دائماً
- لا تذكر أنك Claude أو Anthropic، أنت فقط "تعميم"
''';

  // ────────────────────────────────────────────────────────────────────────
  //  إرسال رسالة مع تاريخ المحادثة — Prompt Caching مفعّل
  // ────────────────────────────────────────────────────────────────────────
  Future<String> sendMessage({
    required List<Map<String, dynamic>> history,
    required String userMessage,
    List<File>? images,
    bool useVision = false,
  }) async {
    // اختيار النموذج
    final model = (images != null && images.isNotEmpty)
        ? _modelSonnet   // Sonnet لتحليل الصور
        : _modelHaiku;   // Haiku للنص

    // بناء محتوى رسالة المستخدم
    List<Map<String, dynamic>> userContent = [];

    // إضافة الصور إن وجدت
    if (images != null) {
      for (final image in images) {
        final bytes = await image.readAsBytes();
        final base64 = base64Encode(bytes);
        userContent.add({
          'type': 'image',
          'source': {
            'type': 'base64',
            'media_type': 'image/jpeg',
            'data': base64,
          },
        });
      }
    }

    // إضافة النص
    if (userMessage.isNotEmpty) {
      userContent.add({'type': 'text', 'text': userMessage});
    }

    // بناء قائمة الرسائل
    final messages = [
      ...history,
      {
        'role': 'user',
        'content': userContent.length == 1 && userContent[0]['type'] == 'text'
            ? userMessage
            : userContent,
      },
    ];

    // الطلب مع Prompt Caching
    final body = jsonEncode({
      'model': model,
      'max_tokens': 1024,
      'system': [
        {
          'type': 'text',
          'text': _systemPrompt,
          'cache_control': {'type': 'ephemeral'}, // ← Prompt Caching هنا
        }
      ],
      'messages': messages,
    });

    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'X-API-Key': _apiKey,
        'anthropic-version': '2023-06-01',
        'anthropic-beta': 'prompt-caching-2024-07-31', // ← تفعيل Caching
      },
      body: body,
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('خطأ في الاتصال: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    final text = data['content'][0]['text'] as String;

    // تسجيل معلومات Cache (للمراقبة)
    final usage = data['usage'];
    if (usage != null) {
      final cacheWrite = usage['cache_creation_input_tokens'] ?? 0;
      final cacheRead = usage['cache_read_input_tokens'] ?? 0;
      if (cacheRead > 0) {
        print('✅ Prompt Cache HIT — وفرنا $cacheRead token');
      } else if (cacheWrite > 0) {
        print('💾 Prompt Cache WRITE — خزّنا $cacheWrite token');
      }
    }

    return text;
  }

  // ────────────────────────────────────────────────────────────────────────
  //  استخراج JSON من رد الـ AI
  // ────────────────────────────────────────────────────────────────────────
  Map<String, dynamic>? extractJson(String response) {
    const start = 'TAAMEEM_JSON_START';
    const end = 'TAAMEEM_JSON_END';

    final startIdx = response.indexOf(start);
    final endIdx = response.indexOf(end);

    if (startIdx == -1 || endIdx == -1) return null;

    final jsonStr = response
        .substring(startIdx + start.length, endIdx)
        .trim();

    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // ────────────────────────────────────────────────────────────────────────
  //  تنظيف نص الرد من JSON
  // ────────────────────────────────────────────────────────────────────────
  String cleanResponse(String response) {
    const start = 'TAAMEEM_JSON_START';
    final startIdx = response.indexOf(start);
    if (startIdx == -1) return response.trim();
    return response.substring(0, startIdx).trim();
  }
}
