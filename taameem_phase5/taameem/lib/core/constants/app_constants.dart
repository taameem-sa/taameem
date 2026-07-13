class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'تعميم';
  static const String appNameEn = 'TAAMEEM';
  static const String appVersion = '1.0.0';

  // تعريف مدة التلاشي الزمني بالأيام لكل نوع تعميم
  static const Map<String, int> decayDays = {
    'missingPerson':  7,  // فقدان أشخاص — أطول مدة
    'foundItem':      3,  // إيجاد شيء
    'lostItem':       5,  // فقدان شيء
    'theft':          5,  // سرقة واعتداء
    'helpRequest':    1,  // استغاثة — مؤقتة
    'humanitarian':  14,  // إنساني — أطول مدة
    'emergency':      1,  // طارئ — مؤقت جداً
    'generalWarning': 3,  // تحذير عام
    'lostAnimal':     5,  // فقدان حيوانات
    'inquiry':        3,  // استفسار
  };

  // أسماء أنواع التعميمات بالعربية
  static const Map<String, String> categoryNames = {
    'missingPerson':  'فقدان شخص',
    'foundItem':      'إيجاد شيء',
    'lostItem':       'فقدان شيء',
    'theft':          'سرقة',
    'helpRequest':    'استغاثة',
    'humanitarian':   'إنساني',
    'emergency':      'طارئ',
    'generalWarning': 'تحذير',
    'lostAnimal':     'فقدان حيوان',
    'inquiry':        'استفسار',
  };

  // ملصق الحالة على الخريطة
  static const Map<String, String> mapLabels = {
    'missingPerson':  'مفقود',
    'foundItem':      'موجود',
    'lostItem':       'مفقود',
    'theft':          'مسروق',
    'helpRequest':    'استغاثة',
    'humanitarian':   'إنساني',
    'emergency':      'طارئ',
    'generalWarning': 'تحذير',
    'lostAnimal':     'حيوان مفقود',
    'inquiry':        'استفسار',
  };

  // رسائل النظام
  static const String aiWelcomeMessage =
      'أكتب التعميم، بأي شكل تريده، أنا سأهتم بالباقي';

  static const String aiIdentity =
      'أنا تعميم، مساعدك الذكي داخل التطبيق. '
      'يمكنك إخباري بما تريد نشره أو البحث عنه.';
}

