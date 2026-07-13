import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

class CategorySidePanel extends StatefulWidget {
  final String? selectedType;
  final ValueChanged<String?> onSave;

  const CategorySidePanel({
    super.key,
    required this.selectedType,
    required this.onSave,
  });

  @override
  State<CategorySidePanel> createState() => _CategorySidePanelState();
}

class _CategorySidePanelState extends State<CategorySidePanel> {
  String? _selected;

  static const List<Map<String, dynamic>> _cats = [
    {'key':'missingPerson',  'name':'فقدان شخص',    'icon':'👤', 'color':AppColors.missingPerson},
    {'key':'foundItem',      'name':'إيجاد شيء',    'icon':'📦', 'color':AppColors.foundItem},
    {'key':'lostItem',       'name':'فقدان شيء',    'icon':'🔍', 'color':AppColors.lostItem},
    {'key':'theft',          'name':'سرقة',          'icon':'🚨', 'color':AppColors.theft},
    {'key':'helpRequest',    'name':'استغاثة',       'icon':'🆘', 'color':AppColors.helpRequest},
    {'key':'humanitarian',   'name':'إنساني',        'icon':'🤝', 'color':AppColors.humanitarian},
    {'key':'emergency',      'name':'طارئ',          'icon':'🚑', 'color':AppColors.emergency},
    {'key':'generalWarning', 'name':'تحذير عام',    'icon':'⚠️', 'color':AppColors.generalWarning},
    {'key':'lostAnimal',     'name':'فقدان حيوان',  'icon':'🐾', 'color':AppColors.lostAnimal},
    {'key':'inquiry',        'name':'استفسار',       'icon':'💬', 'color':AppColors.inquiry},
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedType;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // زر الحفظ
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            children: [
              const Text('فئة التعميم',
                style: TextStyle(fontFamily: 'Tajawal',
                  fontSize: 18, fontWeight: FontWeight.w800,
                  color: AppColors.nearBlack)),
              const Spacer(),
              GestureDetector(
                onTap: () { widget.onSave(_selected); Navigator.pop(context); },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.emerald, AppColors.forestGreen]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('حفظ',
                    style: TextStyle(fontFamily: 'Tajawal',
                      fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),

        Container(height: 1, color: AppColors.glassBorder),

        // قائمة الفئات كبطاقات
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(14),
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _cats.asMap().entries.map((e) {
                  final c = e.value;
                  final key = c['key'] as String;
                  final color = c['color'] as Color;
                  final isSelected = _selected == key;

                  return GestureDetector(
                    onTap: () => setState(() =>
                      _selected = isSelected ? null : key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: (MediaQuery.of(context).size.width * 0.82 - 38) / 2,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withValues(alpha: 0.15)
                            : AppColors.warmBeige,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? color : AppColors.glassBorder,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.25),
                            blurRadius: 10)
                        ] : [],
                      ),
                      child: Row(
                        children: [
                          Text(c['icon'] as String,
                            style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(c['name'] as String,
                              style: TextStyle(fontFamily: 'Tajawal',
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? color : AppColors.nearBlack,
                              )),
                          ),
                          if (isSelected)
                            Icon(Icons.check_circle_rounded,
                                size: 16, color: color),
                        ],
                      ),
                    ),
                  ).animate(
                    delay: Duration(milliseconds: 40 * e.key))
                      .fadeIn(duration: 250.ms)
                      .slideX(begin: 0.2, end: 0);
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


