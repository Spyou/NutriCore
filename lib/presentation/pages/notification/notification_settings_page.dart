import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:nutri_check/core/utils/components/custom_flushbar.dart';
import 'package:nutri_check/presentation/services/firebase_notification_service.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  final workingService = NotificationService.to;
  final _storage = GetStorage();

  late bool breakfastEnabled;
  late bool lunchEnabled;
  late bool dinnerEnabled;
  late bool hydrationEnabled;
  late bool proteinAlertsEnabled;
  late bool eveningReviewEnabled;

  late TimeOfDay breakfastTime;
  late TimeOfDay lunchTime;
  late TimeOfDay dinnerTime;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  void _loadCurrentSettings() {
    breakfastEnabled = _storage.read('working_breakfast_enabled') ?? true;
    lunchEnabled = _storage.read('working_lunch_enabled') ?? true;
    dinnerEnabled = _storage.read('working_dinner_enabled') ?? true;
    hydrationEnabled = _storage.read('working_hydration_enabled') ?? true;
    proteinAlertsEnabled = _storage.read('working_protein_enabled') ?? true;
    eveningReviewEnabled = _storage.read('working_evening_enabled') ?? true;

    breakfastTime = _getTimeFromStorage(
      'working_breakfast_time',
      TimeOfDay(hour: 8, minute: 0),
    );
    lunchTime = _getTimeFromStorage(
      'working_lunch_time',
      TimeOfDay(hour: 13, minute: 0),
    );
    dinnerTime = _getTimeFromStorage(
      'working_dinner_time',
      TimeOfDay(hour: 19, minute: 30),
    );
  }

  TimeOfDay _getTimeFromStorage(String key, TimeOfDay defaultTime) {
    final timeString = _storage.read(key);
    if (timeString != null) {
      final parts = timeString.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
    return defaultTime;
  }

  void _saveTimeToStorage(String key, TimeOfDay time) {
    _storage.write(key, '${time.hour}:${time.minute}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Notification Settings',
          style: AppTextStyles.headingMedium(context),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Meal Reminders'),
            const SizedBox(height: 16),
            _buildMealToggleCard(
              'Breakfast Reminder',
              'Get reminded to eat breakfast',
              Icons.wb_sunny,
              breakfastEnabled,
              breakfastTime,
              (enabled) async {
                setState(() => breakfastEnabled = enabled);
                await _updateMealReminders();
              },
              (time) async {
                setState(() => breakfastTime = time);
                await _updateMealReminders();
              },
            ),
            const SizedBox(height: 12),
            _buildMealToggleCard(
              'Lunch Reminder',
              'Get reminded to eat lunch',
              Icons.light_mode,
              lunchEnabled,
              lunchTime,
              (enabled) async {
                setState(() => lunchEnabled = enabled);
                await _updateMealReminders();
              },
              (time) async {
                setState(() => lunchTime = time);
                await _updateMealReminders();
              },
            ),
            const SizedBox(height: 12),
            _buildMealToggleCard(
              'Dinner Reminder',
              'Get reminded to eat dinner',
              Icons.nightlight,
              dinnerEnabled,
              dinnerTime,
              (enabled) async {
                setState(() => dinnerEnabled = enabled);
                await _updateMealReminders();
              },
              (time) async {
                setState(() => dinnerTime = time);
                await _updateMealReminders();
              },
            ),
            const SizedBox(height: 32),

            _buildSectionTitle('Smart Notifications'),
            const SizedBox(height: 16),
            _buildSmartToggleCard(
              'Hydration Reminders',
              'Get reminded to drink water throughout the day',
              Icons.water_drop,
              hydrationEnabled,
              (enabled) async {
                setState(() => hydrationEnabled = enabled);
                await _updateSmartNotifications();
              },
              onTap: () => _showHydrationDetails(),
            ),
            _buildSmartToggleCard(
              'Protein Alerts',
              'Get alerted when you\'re low on protein',
              Icons.fitness_center,
              proteinAlertsEnabled,
              (enabled) async {
                setState(() => proteinAlertsEnabled = enabled);
                await _updateSmartNotifications();
              },
              onTap: () => _showProteinDetails(),
            ),
            _buildSmartToggleCard(
              'Evening Review',
              'Get daily nutrition summary in the evening',
              Icons.assessment,
              eveningReviewEnabled,
              (enabled) async {
                setState(() => eveningReviewEnabled = enabled);
                await _updateSmartNotifications();
              },
              onTap: () => _showEveningReviewDetails(),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.headingSmall(
        context,
      ).copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
    );
  }

  Widget _buildMealToggleCard(
    String title,
    String description,
    IconData icon,
    bool enabled,
    TimeOfDay time,
    Function(bool) onEnabledChanged,
    Function(TimeOfDay) onTimeChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enabled
              ? AppColors.primary.withOpacity(0.3)
              : AppColors.textTertiary,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyLarge(
                        context,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      description,
                      style: AppTextStyles.bodySmall(
                        context,
                      ).copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Switch(
                value: enabled,
                onChanged: onEnabledChanged,
                activeColor: AppColors.primary,
              ),
            ],
          ),
          if (enabled) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => _selectTime(context, time, onTimeChanged),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.access_time, color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      time.format(context),
                      style: AppTextStyles.bodyLarge(context).copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSmartToggleCard(
    String title,
    String description,
    IconData icon,
    bool enabled,
    Function(bool) onEnabledChanged, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: enabled
                ? AppColors.success.withOpacity(0.3)
                : AppColors.textTertiary,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.success, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyLarge(
                      context,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    description,
                    style: AppTextStyles.bodySmall(
                      context,
                    ).copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            if (onTap != null) ...[
              Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 8),
            ],
            Switch(
              value: enabled,
              onChanged: onEnabledChanged,
              activeColor: AppColors.success,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectTime(
    BuildContext context,
    TimeOfDay initialTime,
    Function(TimeOfDay) onTimeChanged,
  ) async {
    final time = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (time != null) {
      onTimeChanged(time);
    }
  }

  void _showHydrationDetails() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.water_drop, color: AppColors.success),
            SizedBox(width: 8),
            Text(
              'Hydration Settings',
              style: AppTextStyles.bodyLarge(
                context,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('8 daily reminders every 2 hours'),
            SizedBox(height: 8),
            Text('Times: 8AM, 10AM, 12PM, 2PM, 4PM, 6PM, 8PM, 10PM'),
            SizedBox(height: 16),
            SwitchListTile(
              title: Text('Enable Hydration Reminders'),
              value: hydrationEnabled,
              onChanged: (enabled) async {
                setState(() => hydrationEnabled = enabled);
                await _updateSmartNotifications();
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showProteinDetails() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.fitness_center, color: AppColors.success),
            SizedBox(width: 8),
            Text(
              'Protein Alert Settings',
              style: AppTextStyles.bodyLarge(
                context,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('2 daily protein checks'),
            SizedBox(height: 8),
            Text('Times: 3:00 PM (afternoon check), 8:30 PM (evening review)'),
            SizedBox(height: 16),
            SwitchListTile(
              title: Text('Enable Protein Alerts'),
              value: proteinAlertsEnabled,
              onChanged: (enabled) async {
                setState(() => proteinAlertsEnabled = enabled);
                await _updateSmartNotifications();
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showEveningReviewDetails() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.assessment, color: AppColors.success),
            SizedBox(width: 8),
            Text(
              'Evening Review Settings',
              style: AppTextStyles.bodyLarge(
                context,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Daily nutrition summary'),
            SizedBox(height: 8),
            Text('Time: 9:00 PM every day'),
            SizedBox(height: 8),
            Text(
              'Review your daily nutrition progress and plan tomorrow\'s meals.',
            ),
            SizedBox(height: 16),
            SwitchListTile(
              title: Text('Enable Evening Review'),
              value: eveningReviewEnabled,
              onChanged: (enabled) async {
                setState(() => eveningReviewEnabled = enabled);
                await _updateSmartNotifications();
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateMealReminders() async {
    try {
      await workingService.scheduleMealReminders(
        breakfastTime: breakfastTime,
        lunchTime: lunchTime,
        dinnerTime: dinnerTime,
        enableBreakfast: breakfastEnabled,
        enableLunch: lunchEnabled,
        enableDinner: dinnerEnabled,
      );

      _storage.write('working_breakfast_enabled', breakfastEnabled);
      _storage.write('working_lunch_enabled', lunchEnabled);
      _storage.write('working_dinner_enabled', dinnerEnabled);
      _saveTimeToStorage('working_breakfast_time', breakfastTime);
      _saveTimeToStorage('working_lunch_time', lunchTime);
      _saveTimeToStorage('working_dinner_time', dinnerTime);

      _showUpdateFeedback('Meal reminders scheduled!');
    } catch (e) {
      _showErrorFeedback('Failed to schedule meal reminders');
    }
  }

  Future<void> _updateSmartNotifications() async {
    try {
      await workingService.scheduleHydrationReminders(
        enabled: hydrationEnabled,
      );

      await workingService.scheduleProteinAlerts(enabled: proteinAlertsEnabled);

      await workingService.scheduleEveningReviews(
        enabled: eveningReviewEnabled,
      );

      _storage.write('working_hydration_enabled', hydrationEnabled);
      _storage.write('working_protein_enabled', proteinAlertsEnabled);
      _storage.write('working_evening_enabled', eveningReviewEnabled);

      _showUpdateFeedback('Smart notifications scheduled!');
    } catch (e) {
      _showErrorFeedback('Failed to update smart notifications');
    }
  }

  void _showUpdateFeedback(String message) {
    CustomThemeFlushbar.show(title: 'Updated', message: message);
  }

  void _showErrorFeedback(String message) {
    CustomThemeFlushbar.show(title: 'Error', message: message);
  }
}
