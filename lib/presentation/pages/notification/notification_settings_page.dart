import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:nutri_check/core/utils/components/custom_flushbar.dart';
import 'package:nutri_check/presentation/services/firebase_notification_service.dart';

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
      const TimeOfDay(hour: 8, minute: 0),
    );
    lunchTime = _getTimeFromStorage(
      'working_lunch_time',
      const TimeOfDay(hour: 13, minute: 0),
    );
    dinnerTime = _getTimeFromStorage(
      'working_dinner_time',
      const TimeOfDay(hour: 19, minute: 30),
    );
  }

  TimeOfDay _getTimeFromStorage(String key, TimeOfDay defaultTime) {
    final timeString = _storage.read(key);
    if (timeString != null) {
      final parts = timeString.split(':');
      if (parts.length >= 2) {
        final hour = int.tryParse(parts[0]) ?? defaultTime.hour;
        final minute = int.tryParse(parts[1]) ?? defaultTime.minute;
        return TimeOfDay(hour: hour, minute: minute);
      }
    }
    return defaultTime;
  }

  void _saveTimeToStorage(String key, TimeOfDay time) {
    _storage.write(key, '${time.hour}:${time.minute}');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notification Settings',
          style: textTheme.titleLarge?.copyWith(color: scheme.onPrimary),
        ),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
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
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Text(
      title,
      style: textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: scheme.primary,
      ),
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
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enabled
              ? scheme.primary.withValues(alpha: 0.3)
              : scheme.onSurface.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: scheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      description,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: enabled,
                onChanged: onEnabledChanged,
                activeThumbColor: scheme.primary,
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
                  color: scheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: scheme.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.access_time, color: scheme.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      time.format(context),
                      style: textTheme.bodyLarge?.copyWith(
                        color: scheme.primary,
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
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: enabled
                ? scheme.tertiary.withValues(alpha: 0.3)
                : scheme.onSurface.withValues(alpha: 0.45),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: scheme.tertiary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: scheme.tertiary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    description,
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null) ...[
              Icon(
                Icons.chevron_right,
                color: scheme.onSurface.withValues(alpha: 0.65),
                size: 20,
              ),
              const SizedBox(width: 8),
            ],
            Switch(
              value: enabled,
              onChanged: onEnabledChanged,
              activeThumbColor: scheme.tertiary,
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
    );

    if (time != null) {
      onTimeChanged(time);
    }
  }

  void _showHydrationDetails() {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.water_drop, color: scheme.tertiary),
            const SizedBox(width: 8),
            Text(
              'Hydration Settings',
              style: textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('8 daily reminders every 2 hours'),
            const SizedBox(height: 8),
            const Text('Times: 8AM, 10AM, 12PM, 2PM, 4PM, 6PM, 8PM, 10PM'),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable Hydration Reminders'),
              value: hydrationEnabled,
              onChanged: (enabled) async {
                setState(() => hydrationEnabled = enabled);
                await _updateSmartNotifications();
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showProteinDetails() {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.fitness_center, color: scheme.tertiary),
            const SizedBox(width: 8),
            Text(
              'Protein Alert Settings',
              style: textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('2 daily protein checks'),
            const SizedBox(height: 8),
            const Text(
                'Times: 3:00 PM (afternoon check), 8:30 PM (evening review)'),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable Protein Alerts'),
              value: proteinAlertsEnabled,
              onChanged: (enabled) async {
                setState(() => proteinAlertsEnabled = enabled);
                await _updateSmartNotifications();
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showEveningReviewDetails() {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.assessment, color: scheme.tertiary),
            const SizedBox(width: 8),
            Text(
              'Evening Review Settings',
              style: textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Daily nutrition summary'),
            const SizedBox(height: 8),
            const Text('Time: 9:00 PM every day'),
            const SizedBox(height: 8),
            const Text(
              'Review your daily nutrition progress and plan tomorrow\'s meals.',
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable Evening Review'),
              value: eveningReviewEnabled,
              onChanged: (enabled) async {
                setState(() => eveningReviewEnabled = enabled);
                await _updateSmartNotifications();
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
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
