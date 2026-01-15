import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'medicine.g.dart';

@HiveType(typeId: 0)
class Medicine extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String dosage;

  @HiveField(3)
  final DateTime scheduledTime;

  @HiveField(4)
  final Map<int, String>
      history; // Key: timestamp (day level), Value: 'TAKEN' | 'SKIPPED' | 'MISSED'

  Medicine({
    String? id,
    required this.name,
    this.dosage = '',
    required this.scheduledTime,
    Map<int, String>? history,
  })  : id = id ?? const Uuid().v4(),
        history = history ?? {};

  String get timeFormatted {
    final hour =
        scheduledTime.hour > 12 ? scheduledTime.hour - 12 : scheduledTime.hour;
    final period = scheduledTime.hour >= 12 ? 'PM' : 'AM';
    final minute = scheduledTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }
}
