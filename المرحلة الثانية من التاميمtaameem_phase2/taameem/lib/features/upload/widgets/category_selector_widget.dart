import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';

class CategorySelectorWidget extends StatelessWidget {
  final String? selectedType;
  final Function(String) onSelected;

  const CategorySelectorWidget({
    super.key,
    required this.selectedType,
    required this.onSelected,
  });

  // بيانات الأنواع: [key, اسم, أيقونة]
  static const List<Map<String, dynamic>> _categories = [
    {'key': 'missingPerson',  'name': 'فقدان شخص',     'icon': Icons.person_search_rounded},
    {'key': 'foundItem',      'name': 'إيجاد شيء',     'icon': Icons.find_in_page_rounded},
    {'key': 'lostItem',       'name': 'فقدان شيء',     'icon': Icons.search_off_rounded},
    {'key': 'theft',          'name': 'سرقة',           'icon': Icons.car_crash_rounded},
    {'key': 'helpRequest',    'name': 'استغاثة',        'icon': Icons.sos_rounded},
    {'key': 'humanitarian',   'name': 'إنساني',         'icon': Icons.volunteer_activism_rounded},
    {'key': 'emergency',      'name': 'طارئ',           'icon': Icons.emergency_rounded},
    {'key': 'generalWarning', 'name': 'تحذير عام',     'icon': Icons.warning_amber_rounded},
    {'key': 'lostAnimal',     'name': 'فقدان حيوان',   'icon': Icons.pets_rounded},
    {'key': 'inquiry',        'name': 'استفسار',        'icon': Icons.help_outline_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 3.2,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final cat = _categories[index];
        final key = cat['key'] as String;
        final isSelected = selectedType == key;
        final color = _colorForKey(key);

        return GestureDetector(
          onTap: () => onSelected(key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.15) : AppColors.warmBeige,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? color : AppColors.glassBorder,
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.25),
                        blurRadius: 8,
                      ),
                    ]
                  : [],
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(cat['icon'] as IconData, size: 17, color: color),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    cat['name'] as String,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? color : AppColors.forestGreen,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle_rounded, size: 16, color: color),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _colorForKey(String key) {
    switch (key) {
      case 'missingPerson':  return AppColors.missingPerson;
      case 'foundItem':      return AppColors.foundItem;
      case 'lostItem':       return AppColors.lostItem;
      case 'theft':          return AppColors.theft;
      case 'helpRequest':    return AppColors.helpRequest;
      case 'humanitarian':   return AppColors.humanitarian;
      case 'emergency':      return AppColors.emergency;
      case 'generalWarning': return AppColors.generalWarning;
      case 'lostAnimal':     return AppColors.lostAnimal;
      case 'inquiry':        return AppColors.inquiry;
      default:               return AppColors.grey;
    }
  }
}
