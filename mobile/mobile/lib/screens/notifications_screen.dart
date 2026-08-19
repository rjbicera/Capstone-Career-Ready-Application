import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class _NotificationItem {
  _NotificationItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.timeAgo,
    required this.group,
    this.isRead = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String timeAgo;
  final String group; // 'Today' or 'Earlier'
  bool isRead;
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _resumeUpdates = true;
  bool _interviewReminders = true;
  bool _skillsReminders = false;
  bool _productUpdates = false;
  bool _quietHours = false;

  final List<_NotificationItem> _notifications = [
    _NotificationItem(
      icon: Icons.description_rounded,
      title: 'Resume analysis complete',
      subtitle: 'Your resume scored 84/100 with 3 new suggestions.',
      timeAgo: '2h ago',
      group: 'Today',
      isRead: false,
    ),
    _NotificationItem(
      icon: Icons.bar_chart_rounded,
      title: 'Skills assessment reminder',
      subtitle: 'You\'re 36% away from completing Cloud fundamentals.',
      timeAgo: '1d ago',
      group: 'Earlier',
      isRead: false,
    ),
    _NotificationItem(
      icon: Icons.mic_rounded,
      title: 'Mock interview streak',
      subtitle: 'Keep it up — 2 sessions completed this week.',
      timeAgo: '3d ago',
      group: 'Earlier',
      isRead: true,
    ),
  ];

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  void _markAllRead() {
    setState(() {
      for (final n in _notifications) {
        n.isRead = true;
      }
    });
  }

  Widget _toggleRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _groupLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 4),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
            letterSpacing: 0.4,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final today = _notifications.where((n) => n.group == 'Today').toList();
    final earlier = _notifications.where((n) => n.group == 'Earlier').toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            const Text('Preferences', style: AppTextStyles.title),
            const SizedBox(height: 12),
            _toggleRow(
              title: 'Resume updates',
              subtitle: 'When AI feedback on your resume is ready.',
              value: _resumeUpdates,
              onChanged: (v) => setState(() => _resumeUpdates = v),
            ),
            _toggleRow(
              title: 'Interview reminders',
              subtitle: 'Nudges to keep up your mock interview practice.',
              value: _interviewReminders,
              onChanged: (v) => setState(() => _interviewReminders = v),
            ),
            _toggleRow(
              title: 'Skills assessment reminders',
              subtitle: 'When a skill category needs re-checking.',
              value: _skillsReminders,
              onChanged: (v) => setState(() => _skillsReminders = v),
            ),
            _toggleRow(
              title: 'Product updates',
              subtitle: 'New features and app announcements.',
              value: _productUpdates,
              onChanged: (v) => setState(() => _productUpdates = v),
            ),
            _toggleRow(
              title: 'Quiet hours',
              subtitle: 'Pause notifications from 10 PM to 7 AM.',
              value: _quietHours,
              onChanged: (v) => setState(() => _quietHours = v),
            ),
            const SizedBox(height: 20),

            if (today.isNotEmpty) ...[
              _groupLabel('TODAY'),
              ...today.map((n) => _NotificationTile(item: n)),
            ],
            if (earlier.isNotEmpty) ...[
              _groupLabel('EARLIER'),
              ...earlier.map((n) => _NotificationTile(item: n)),
            ],
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item});
  final _NotificationItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: item.isRead ? Colors.white : AppColors.blueLight,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: item.isRead ? AppColors.border : AppColors.blueSoft,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: item.isRead ? AppColors.blueLight : Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, size: 18, color: AppColors.blue),
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
                        item.title,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (!item.isRead)
                      Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.only(left: 6, top: 3),
                        decoration: const BoxDecoration(
                          color: AppColors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.timeAgo,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
