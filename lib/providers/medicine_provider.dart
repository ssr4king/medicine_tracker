import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/medicine.dart';
import '../services/notification_service.dart';

class MedicineProvider extends ChangeNotifier {
  static const String _boxName = 'medicines';
  late Box<Medicine> _box;
  bool _isInitialized = false;
  late SharedPreferences _prefs;

  // Profile Data
  String _userName = 'User';
  String? _profileImagePath;
  String? _emergencyContactName;
  String? _emergencyContactPhone;

  String get userName => _userName;
  String? get profileImagePath => _profileImagePath;
  String? get emergencyContactName => _emergencyContactName;
  String? get emergencyContactPhone => _emergencyContactPhone;

  bool get isInitialized => _isInitialized;

  List<Medicine> get medicines => _box.values.toList();

  List<Medicine> get todaysMedicines {
    // Sort by time
    final meds = medicines.toList()
      ..sort((a, b) {
        final timeA = a.scheduledTime.hour * 60 + a.scheduledTime.minute;
        final timeB = b.scheduledTime.hour * 60 + b.scheduledTime.minute;
        return timeA.compareTo(timeB);
      });
    return meds;
  }

  int get streak {
    int count = 0;
    final now = DateTime.now();
    // Check back up to 365 days
    for (int i = 0; i < 365; i++) {
      // Start from today? Or yesterday?
      // Usually if I haven't finished today, my streak from yesterday is still valid.
      // But if I finished today, it should increment.
      // Let's check Yesterday backwards FIRST.
      // Then we can speculatively add Today if it's complete.
      // Actually, let's start from Yesterday.
      final date = now.subtract(Duration(days: i + 1));
      if (_allTakenOnDate(date)) {
        count++;
      } else {
        break;
      }
    }
    // Check today separately
    if (_allTakenOnDate(now)) {
      count++;
    }
    return count;
  }

  bool _allTakenOnDate(DateTime date) {
    if (medicines.isEmpty) return false;
    // For a specific date, every medicine that "exists" (we assume all exist always for now)
    // must have status TAKEN.
    // Realistically we should check start dates, but for this simple app, we assume they apply every day.

    // If no medicines, maybe streak is 0?

    // We only care about medicines that have a history entry or should have one.
    // But wait, `getStatusOnDate` returns PENDING if missing.
    // So if any is PENDING or MISSED on that date, return false.
    // SKIPPED might maintain streak? Let's say yes for user friendliness, or no?
    // Request said "Mark as Taken", so likely TAKEN is key.
    // Let's be strict: TAKEN only.

    bool allTaken = true;
    for (var med in medicines) {
      final status = getStatusOnDate(med, date);
      if (status != 'TAKEN') {
        allTaken = false;
        break;
      }
    }
    return allTaken;
  }

  Future<void> initialize() async {
    await Hive.initFlutter();
    Hive.registerAdapter(MedicineAdapter());
    _box = await Hive.openBox<Medicine>(_boxName);

    // Initialize SharedPrefs
    _prefs = await SharedPreferences.getInstance();
    _loadProfileData();

    // Check for missed meds on startup
    _checkMissedMedicines();

    _isInitialized = true;
    notifyListeners();
  }

  void _loadProfileData() {
    _userName = _prefs.getString('userName') ?? 'User';
    _profileImagePath = _prefs.getString('profileImagePath');
    _emergencyContactName = _prefs.getString('emergencyContactName');
    _emergencyContactPhone = _prefs.getString('emergencyContactPhone');
  }

  Future<void> updateProfile({required String name, String? imagePath}) async {
    _userName = name;
    await _prefs.setString('userName', name);

    if (imagePath != null) {
      _profileImagePath = imagePath;
      await _prefs.setString('profileImagePath', imagePath);
    }
    notifyListeners();
  }

  Future<void> updateEmergencyContact(
      {required String name, required String phone}) async {
    _emergencyContactName = name;
    _emergencyContactPhone = phone;
    await _prefs.setString('emergencyContactName', name);
    await _prefs.setString('emergencyContactPhone', phone);
    notifyListeners();
  }

  Future<void> addMedicine({
    required String name,
    required String dosage,
    required DateTime scheduledTime,
  }) async {
    final newMedicine = Medicine(
      name: name,
      dosage: dosage,
      scheduledTime: scheduledTime,
    );

    await _box.add(
        newMedicine); // Hive manages IDs if we extended HiveObject correctly, but we used UUID.
    // Actually HiveObject handles save/delete, but we need to key it.
    // Let's safe-guard by putting it with its ID if possible, or just add.
    // _box.put(newMedicine.id, newMedicine); -> Better for retrieval by ID.
    // But for list, add is okay. Let's stick to _box.add() and rely on filtering.

    // Schedule Notification
    // We use a simple hash of the ID or a random int for the notification ID.
    // Since ID is String UUID, let's create a unique int ID.
    final notificationId = newMedicine.key as int? ?? newMedicine.hashCode;

    await NotificationService().scheduleDailyNotification(
      id: notificationId,
      title: 'Time to take $name',
      body: 'Take ${dosage.isNotEmpty ? dosage : "your medicine"} now!',
      scheduledTime: scheduledTime,
    );

    notifyListeners();
  }

  Future<void> updateStatus(
      Medicine medicine, DateTime date, String status) async {
    // We normalize date to just the day (yyyy-mm-dd) represented as int timestamp
    final dayKey =
        DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;

    medicine.history[dayKey] = status;
    await medicine.save();
    notifyListeners();
  }

  String getStatusOnDate(Medicine medicine, DateTime date) {
    final dayKey =
        DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
    return medicine.history[dayKey] ?? 'PENDING';
  }

  void _checkMissedMedicines() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    for (var med in medicines) {
      // Check for yesterday and before? Or just today that passed?
      // Logic: If last recorded status for TODAY is absent, and Time < Now, mark MISSED.

      final status = getStatusOnDate(med, now);
      if (status == 'PENDING') {
        final medTime = DateTime(now.year, now.month, now.day,
            med.scheduledTime.hour, med.scheduledTime.minute);

        // Use a buffer of say 60 minutes? Or strict?
        // User asked: "If time passes and user does not tap TAKE -> mark as MISSED automatically"
        if (now.isAfter(medTime.add(const Duration(minutes: 60)))) {
          updateStatus(med, now, 'MISSED');
        }
      }
    }
  }

  Future<void> clearAllData() async {
    await _box.clear();
    await NotificationService().cancelAll();
    notifyListeners();
  }
}
