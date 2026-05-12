import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

/// Thin singleton wrapper around the `health` plugin, scoped to the subset
/// of Health Connect data NutriCore actually reads today: steps, weight,
/// active calories, and exercise time. Read-only — no writes here.
///
/// Call [isAvailable] first to detect whether Health Connect is installed
/// on the device, then [requestPermissions] to drive the system prompt.
/// Subsequent reads ([readStepsForDay], [readLatestWeightKg],
/// [readActiveCaloriesToday]) silently return zero / null when the user
/// hasn't granted access yet, so callers can treat them as best-effort.
class HealthConnectService {
  HealthConnectService._();
  static final HealthConnectService instance = HealthConnectService._();

  final Health _health = Health();
  bool _configured = false;

  // health: 11.x removed EXERCISE_TIME — workouts are now read via the
  // WORKOUT type, which we don't need for the dashboard yet. Keep this
  // list minimal so requestAuthorization doesn't fail on unknown types.
  static const List<HealthDataType> _types = <HealthDataType>[
    HealthDataType.STEPS,
    HealthDataType.WEIGHT,
    HealthDataType.ACTIVE_ENERGY_BURNED,
  ];

  static const List<HealthDataAccess> _permissions = <HealthDataAccess>[
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
  ];

  Future<void> _configure() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  /// True only when Health Connect is installed on the device and the
  /// plugin reports `sdkAvailable`. On non-Android targets this throws
  /// internally; we swallow and return false so callers can render an
  /// "unsupported" state without exception handling.
  Future<bool> isAvailable() async {
    try {
      await _configure();
      final status = await _health.getHealthConnectSdkStatus();
      if (kDebugMode) {
        debugPrint('HealthConnectService.isAvailable: status=$status');
      }
      // Treat both "sdkAvailable" and "providerUpdateRequired" as available
      // — in the latter case the user has Health Connect installed but the
      // bundled provider just needs an update from Play Store. The system
      // permission UI will guide them.
      return status == HealthConnectSdkStatus.sdkAvailable ||
          status ==
              HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('HealthConnectService.isAvailable: $e');
      }
      return false;
    }
  }

  /// The raw status enum — exposed for diagnostics so the UI can surface
  /// a "Update Health Connect from Play Store" hint when needed.
  Future<HealthConnectSdkStatus?> rawStatus() async {
    try {
      await _configure();
      return await _health.getHealthConnectSdkStatus();
    } catch (_) {
      return null;
    }
  }

  /// Routes the user to the Play Store listing for Health Connect so
  /// they can install or update it. Uses the plugin's built-in helper
  /// when present, falling back silently.
  Future<void> openPlayStoreForInstall() async {
    try {
      await _configure();
      await _health.installHealthConnect();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('HealthConnectService.openPlayStoreForInstall: $e');
      }
    }
  }

  /// Drives the system permission picker. Returns true only when every
  /// requested data type was granted. The user can grant partial access
  /// in the system UI — we treat partial as failure for now to keep the
  /// connected-state simple.
  Future<bool> requestPermissions() async {
    try {
      await _configure();
      return await _health.requestAuthorization(
        _types,
        permissions: _permissions,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('HealthConnectService.requestPermissions: $e');
      }
      return false;
    }
  }

  Future<bool> hasPermissions() async {
    try {
      await _configure();
      final granted = await _health.hasPermissions(
        _types,
        permissions: _permissions,
      );
      return granted ?? false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('HealthConnectService.hasPermissions: $e');
      }
      return false;
    }
  }

  /// Total step count for the calendar day containing [day] in local time.
  Future<int> readStepsForDay(DateTime day) async {
    try {
      await _configure();
      final start = DateTime(day.year, day.month, day.day);
      final end = start.add(const Duration(days: 1));
      final steps = await _health.getTotalStepsInInterval(start, end);
      return steps ?? 0;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('HealthConnectService.readStepsForDay: $e');
      }
      return 0;
    }
  }

  /// Most recent weight reading within the last 90 days, in kilograms.
  /// Returns null when no sample exists or permission was refused.
  Future<double?> readLatestWeightKg() async {
    try {
      await _configure();
      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 90));
      final samples = await _health.getHealthDataFromTypes(
        types: const <HealthDataType>[HealthDataType.WEIGHT],
        startTime: start,
        endTime: now,
      );
      if (samples.isEmpty) return null;
      samples.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
      final value = samples.first.value;
      if (value is NumericHealthValue) {
        return value.numericValue.toDouble();
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('HealthConnectService.readLatestWeightKg: $e');
      }
      return null;
    }
  }

  /// Sum of active calories (kcal) burned since local midnight.
  Future<double> readActiveCaloriesToday() async {
    try {
      await _configure();
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);
      final samples = await _health.getHealthDataFromTypes(
        types: const <HealthDataType>[HealthDataType.ACTIVE_ENERGY_BURNED],
        startTime: start,
        endTime: now,
      );
      double total = 0;
      for (final s in samples) {
        final v = s.value;
        if (v is NumericHealthValue) {
          total += v.numericValue.toDouble();
        }
      }
      return total;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('HealthConnectService.readActiveCaloriesToday: $e');
      }
      return 0;
    }
  }
}
