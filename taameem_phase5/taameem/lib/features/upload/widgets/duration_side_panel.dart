import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

class DurationSidePanel extends StatefulWidget {
  final Duration selectedDuration;
  final ValueChanged<Duration> onSave;

  const DurationSidePanel({
    super.key,
    required this.selectedDuration,
    required this.onSave,
  });

  @override
  State<DurationSidePanel> createState() => _DurationSidePanelState();
}

class _DurationSidePanelState extends State<DurationSidePanel> {
  late FixedExtentScrollController _hoursCtrl;
  late FixedExtentScrollController _daysCtrl;
  late FixedExtentScrollController _weeksCtrl;
  late FixedExtentScrollController _yearsCtrl;

  int _hours = 0, _days = 0, _weeks = 0, _years = 0;

  // ط§ط®طھطµط§ط±ط§طھ ط³ط±ظٹط¹ط©
  static const List<Map<String, dynamic>> _quickPicks = [
    {'label': 'ط³ط§ط¹ط©',  'hours': 1,  'days': 0, 'weeks': 0, 'years': 0},
    {'label': 'ظٹظˆظ…',   'hours': 0,  'days': 1, 'weeks': 0, 'years': 0},
    {'label': 'ط£ط³ط¨ظˆط¹', 'hours': 0,  'days': 0, 'weeks': 1, 'years': 0},
    {'label': 'ط´ظ‡ط±',   'hours': 0,  'days': 30,'weeks': 0, 'years': 0},
  ];

  @override
  void initState() {
    super.initState();
    final d = widget.selectedDuration;
    _years  = d.inDays ~/ 365;
    _weeks  = (d.inDays % 365) ~/ 7;
    _days   = (d.inDays % 365) % 7;
    _hours  = d.inHours % 24;

    _hoursCtrl = FixedExtentScrollController(initialItem: _hours);
    _daysCtrl  = FixedExtentScrollController(initialItem: _days);
    _weeksCtrl = FixedExtentScrollController(initialItem: _weeks);
    _yearsCtrl = FixedExtentScrollController(initialItem: _years);
  }

  @override
  void dispose() {
    _hoursCtrl.dispose(); _daysCtrl.dispose();
    _weeksCtrl.dispose(); _yearsCtrl.dispose();
    super.dispose();
  }

  Duration get _total => Duration(
    hours: _hours,
    days:  _days + _weeks * 7 + _years * 365,
  );

  String get _summary {
    final parts = <String>[];
    if (_years  > 0) parts.add('$_years ط³ظ†ط©');
    if (_weeks  > 0) parts.add('$_weeks ط£ط³ط¨ظˆط¹');
    if (_days   > 0) parts.add('$_days ظٹظˆظ…');
    if (_hours  > 0) parts.add('$_hours ط³ط§ط¹ط©');
    return parts.isEmpty ? 'ظ„ظ… ظٹظڈط­ط¯ط¯' : parts.join(' ظˆ ');
  }

  Widget _column(String label, int max, int value,
      FixedExtentScrollController ctrl, ValueChanged<int> onChanged) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: GoogleFonts.cairo(
            fontSize: 12, fontWeight: FontWeight.w600,
            color: AppColors.forestGreen)),
          const SizedBox(height: 8),
          SizedBox(
            height: 180,
            child: ListWheelScrollView.useDelegate(
              controller: ctrl,
              itemExtent: 52,
              physics: const FixedExtentScrollPhysics(),
              perspective: 0.003,
              onSelectedItemChanged: onChanged,
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: max + 1,
                builder: (_, i) {
                  final isSelected = i == value;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    alignment: Alignment.center,
                    margin: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 3),
                    decoration: isSelected ? BoxDecoration(
                      color: AppColors.emerald.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.emerald.withValues(alpha: 0.3)),
                    ) : null,
                    child: Text('$i',
                      style: GoogleFonts.cairo(
                        fontSize: isSelected ? 24 : 18,
                        fontWeight: isSelected
                            ? FontWeight.w800 : FontWeight.w400,
                        color: isSelected
                            ? AppColors.emerald : AppColors.grey,
                      )),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ط±ط£ط³ + ط­ظپط¸
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ظ…ط¯ط© ط§ظ„طھط¹ظ…ظٹظ…',
                    style: GoogleFonts.cairo(
                      fontSize: 18, fontWeight: FontWeight.w800,
                      color: AppColors.nearBlack)),
                  Text(_summary,
                    style: GoogleFonts.cairo(
                      fontSize: 12, color: AppColors.emerald)),
                ],
              ),
              const Spacer(),
              GestureDetector(
                onTap: () { widget.onSave(_total); Navigator.pop(context); },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 9),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.emerald, AppColors.forestGreen]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('ط­ظپط¸',
                    style: GoogleFonts.cairo(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: Colors.white)),
                ),
              ),
            ],
          ),
        ),

        Container(height: 1, color: AppColors.glassBorder),

        // ط§ط®طھطµط§ط±ط§طھ ط³ط±ظٹط¹ط©
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12),
          child: Row(
            children: _quickPicks.map((q) {
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _hours = q['hours'] as int;
                      _days  = q['days']  as int;
                      _weeks = q['weeks'] as int;
                      _years = q['years'] as int;
                    });
                    _hoursCtrl.jumpToItem(_hours);
                    _daysCtrl .jumpToItem(_days);
                    _weeksCtrl.jumpToItem(_weeks);
                    _yearsCtrl.jumpToItem(_years);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.warmBeige,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: Center(
                      child: Text(q['label'] as String,
                        style: GoogleFonts.cairo(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: AppColors.forestGreen)),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // ط§ظ„ط¹ط¬ظ„ط§طھ
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                _column('ط³ط§ط¹ط§طھ', 23, _hours, _hoursCtrl,
                    (v) => setState(() => _hours = v)),
                _divider(),
                _column('ط£ظٹط§ظ…',   6, _days,  _daysCtrl,
                    (v) => setState(() => _days = v)),
                _divider(),
                _column('ط£ط³ط§ط¨ظٹط¹',51, _weeks, _weeksCtrl,
                    (v) => setState(() => _weeks = v)),
                _divider(),
                _column('ط³ظ†ظˆط§طھ',  1, _years, _yearsCtrl,
                    (v) => setState(() => _years = v)),
              ],
            ),
          ),
        ),

        // طھظ†ط¨ظٹظ‡ ط§ظ„ط­ط¯ ط§ظ„ط£ظ‚طµظ‰
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Text(
            '* ط§ظ„ط­ط¯ ط§ظ„ط£ظ‚طµظ‰ ظ„ظ…ط¯ط© ط§ظ„طھط¹ظ…ظٹظ… ط³ظ†ط© ظˆط§ط­ط¯ط©',
            style: GoogleFonts.cairo(
                fontSize: 11, color: AppColors.grey)),
        ),
      ],
    );
  }

  Widget _divider() => Container(
    width: 1, height: 180,
    color: AppColors.glassBorder,
    margin: const EdgeInsets.symmetric(horizontal: 2));
}

