import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/widgets/animated_background.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late List<AppNotification> _notifications;
  String _activeFilter = 'all';

  @override
  void initState() {
    super.initState();
    _notifications = NotificationService.getMockNotifications();
  }

  List<AppNotification> get _filtered {
    if (_activeFilter == 'all') return _notifications;
    return _notifications
        .where((n) => n.type == _activeFilter)
        .toList();
  }

  int get _unreadCount =>
      _notifications.where((n) => !n.isRead).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildFilterTabs(),
              Expanded(child: _buildList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Text(
            'الإشعارات',
            style: GoogleFonts.cairo(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.nearBlack,
            ),
          ),
          const SizedBox(width: 10),
          if (_unreadCount > 0)
            Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: AppColors.emergency,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$_unreadCount',
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          const Spacer(),
          if (_unreadCount > 0)
            GestureDetector(
              onTap: () {
                setState(() {
                  _notifications = _notifications
                      .map((n) => AppNotification(
                            id: n.id,
                            title: n.title,
                            body: n.body,
                            type: n.type,
                            taameemId: n.taameemId,
                            createdAt: n.createdAt,
                            isRead: true,
                          ))
                      .toList();
                });
              },
              child: Text(
                'تمييز الكل كمقروء',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: AppColors.emerald,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ).animate().fadeIn(duration: 300.ms),
    );
  }

  Widget _buildFilterTabs() {
    final tabs = [
      {'key': 'all',     'label': 'الكل'},
      {'key': 'nearby',  'label': 'قريبة'},
      {'key': 'match',   'label': 'تطابق'},
      {'key': 'update',  'label': 'تحديثات'},
      {'key': 'expiry',  'label': 'انتهاء'},
    ];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: tabs.length,
        itemBuilder: (_, i) {
          final t = tabs[i];
          final isActive = _activeFilter == t['key'];
          return GestureDetector(
            onTap: () => setState(() => _activeFilter = t['key']!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isActive ? AppColors.emerald : AppColors.warmBeige,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive
                      ? AppColors.emerald
                      : AppColors.glassBorder,
                ),
              ),
              child: Center(
                child: Text(
                  t['label']!,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.white : AppColors.forestGreen,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 100.ms);
  }

  Widget _buildList() {
    final list = _filtered;

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none_rounded,
                size: 64, color: AppColors.grey.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              'لا توجد إشعارات',
              style: GoogleFonts.cairo(
                fontSize: 16, color: AppColors.grey),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms),
      );
    }

    // تجميع حسب اليوم
    final today     = list.where(_isToday).toList();
    final yesterday = list.where(_isYesterday).toList();
    final older     = list
        .where((n) => !_isToday(n) && !_isYesterday(n))
        .toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 90, top: 8),
      children: [
        if (today.isNotEmpty) ...[
          _sectionLabel('اليوم'),
          ...today.asMap().entries.map((e) =>
              _NotificationCard(
                notification: e.value,
                onTap: () => _markRead(e.value),
              ).animate(delay: Duration(milliseconds: 60 * e.key))
                  .fadeIn(duration: 300.ms)
                  .slideX(begin: 0.1, end: 0)),
        ],
        if (yesterday.isNotEmpty) ...[
          _sectionLabel('أمس'),
          ...yesterday.asMap().entries.map((e) =>
              _NotificationCard(
                notification: e.value,
                onTap: () => _markRead(e.value),
              ).animate(delay: Duration(milliseconds: 60 * e.key))
                  .fadeIn(duration: 300.ms)),
        ],
        if (older.isNotEmpty) ...[
          _sectionLabel('سابقاً'),
          ...older.asMap().entries.map((e) =>
              _NotificationCard(
                notification: e.value,
                onTap: () => _markRead(e.value),
              ).animate(delay: Duration(milliseconds: 60 * e.key))
                  .fadeIn(duration: 300.ms)),
        ],
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Text(
        text,
        style: GoogleFonts.cairo(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.grey,
        ),
      ),
    );
  }

  void _markRead(AppNotification n) {
    setState(() {
      final idx = _notifications.indexWhere((x) => x.id == n.id);
      if (idx >= 0) {
        _notifications[idx] = AppNotification(
          id: n.id, title: n.title, body: n.body,
          type: n.type, taameemId: n.taameemId,
          createdAt: n.createdAt, isRead: true,
        );
      }
    });
  }

  bool _isToday(AppNotification n) {
    final now = DateTime.now();
    final d   = n.createdAt;
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  bool _isYesterday(AppNotification n) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final d = n.createdAt;
    return d.year == yesterday.year &&
        d.month == yesterday.month &&
        d.day == yesterday.day;
  }
}

// ─── بطاقة الإشعار ──────────────────────────────────────────────────────────
class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = notification.color;
    final isUnread = !notification.isRead;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUnread
                    ? AppColors.glassBackground
                    : AppColors.warmBeige.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isUnread
                      ? color.withValues(alpha: 0.35)
                      : AppColors.glassBorder,
                  width: isUnread ? 1.5 : 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // أيقونة النوع
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(notification.icon, size: 20, color: color),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: GoogleFonts.cairo(
                                  fontSize: 13,
                                  fontWeight: isUnread
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: AppColors.nearBlack,
                                ),
                              ),
                            ),
                            if (isUnread)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.body,
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: AppColors.forestGreen,
                            height: 1.5,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          notification.timeAgo,
                          style: GoogleFonts.cairo(
                            fontSize: 10,
                            color: AppColors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
