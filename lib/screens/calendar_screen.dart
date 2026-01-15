import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/medicine_provider.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EA), // Warm Beige
      appBar: AppBar(
        title: const Text('Calendar',
            style: TextStyle(
                color: Color(0xFF2C3E36),
                fontWeight: FontWeight.bold)), // Dark Green text
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<MedicineProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Custom Month View
              _buildMonthView(provider),
              _buildNotificationSoundOption(),
              const Divider(),
              Expanded(
                child: _buildHistoryList(provider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMonthView(MedicineProvider provider) {
    // Simplified month view logic for standard 30-day grid
    // In production, use table_calendar. Here we build a simple grid for the current month.
    final now = DateTime.now();
    // Use _selectedDate for navigation if we supported it, but user didn't ask for month navigation.
    // However, we must ensure the display matches the generated days.
    // The existing code used `now` for days generation but `_selectedDate` for selection logic.
    // We will stick to `now` for the displayed month as per original code, effectively showing "Current Month".

    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    // Weekday: Mon=1 ... Sun=7. We want Sun to be index 0.
    final int firstWeekdayOffset = firstDayOfMonth.weekday % 7;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Month Name Header
          Text(
            DateFormat('MMMM yyyy').format(now),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E36),
            ),
          ),
          const SizedBox(height: 16),
          // Weekday Headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                .map((day) => Text(
                      day,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6A8E7F),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            // Add offset items + actual days
            itemCount: daysInMonth + firstWeekdayOffset,
            itemBuilder: (context, index) {
              // Handle offset
              if (index < firstWeekdayOffset) {
                return Container();
              }

              final day = index - firstWeekdayOffset + 1;

              final date = DateTime(now.year, now.month, day);
              final isSelected = DateUtils.isSameDay(date, _selectedDate);

              // Determine status for this day
              // If ANY medicine was TAKEN, show Green.
              // If ANY medicine was MISSED, show Red.
              // If MIXED, show Orange?
              // Let's simplify: Green dot if all taken/some taken. Red if any missed.

              bool hasMissed = false;
              bool hasTaken = false;

              for (var med in provider.medicines) {
                final status = provider.getStatusOnDate(med, date);
                if (status == 'MISSED') hasMissed = true;
                if (status == 'TAKEN') hasTaken = true;
              }

              Color? dotColor;
              if (hasMissed)
                dotColor = Colors.red;
              else if (hasTaken) dotColor = Colors.green;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = date;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF6A8E7F)
                        : Colors.transparent, // Sage Green selection
                    shape: BoxShape.rectangle, // Rounded rectangle/capsule
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(color: const Color(0xFF6A8E7F), width: 2)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$day',
                          style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF2C3E36),
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal)),
                      if (dotColor != null)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: dotColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(MedicineProvider provider) {
    final meds = provider.medicines;
    if (meds.isEmpty) {
      return const Center(child: Text('No medicines tracked.'));
    }

    return ListView.builder(
      itemCount: meds.length,
      itemBuilder: (context, index) {
        final med = meds[index];
        final status = provider.getStatusOnDate(med, _selectedDate);

        return ListTile(
          leading: const Icon(Icons.spa_outlined,
              color: Color(0xFFD68C45)), // Terracotta Icon
          title: Text(med.name,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Color(0xFF2C3E36))),
          subtitle: Text(med.dosage),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _getStatusColor(status)),
            ),
            child: Text(status,
                style: TextStyle(
                    color: _getStatusColor(status),
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'TAKEN':
        return Colors.green;
      case 'SKIPPED':
        return Colors.orange;
      case 'MISSED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildNotificationSoundOption() {
    return ListTile(
      leading: const Icon(Icons.music_note, color: Color(0xFF2C3E36)),
      title: const Text('Notification Sound',
          style:
              TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C3E36))),
      subtitle: FutureBuilder<String?>(
        future: _getCustomSoundName(),
        builder: (context, snapshot) {
          return Text(snapshot.data ?? 'Default System Sound');
        },
      ),
      onTap: _pickNotificationSound,
      trailing: const Icon(Icons.arrow_forward_ios,
          size: 16, color: Color(0xFF2C3E36)),
    );
  }

  Future<String?> _getCustomSoundName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('custom_sound_name');
  }

  Future<void> _pickNotificationSound() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);

        // Use a public directory accessible by valid Android Notification System
        // /storage/emulated/0/Music is a safe standard path
        Directory musicDir = Directory('/storage/emulated/0/Music');
        if (!await musicDir.exists()) {
          await musicDir.create(recursive: true);
        }

        // We'll rename it to a fixed name to keep it simple for the notification service,
        // OR we can keep the original name.
        // Let's use a fixed name + extension from original.
        String extension = result.files.single.extension ?? 'mp3';
        String fileName = 'medicine_tracker_sound.$extension';

        // Ensure unique path or overwrite? Overwrite is good to clean up.
        final savedFile = await file.copy('${musicDir.path}/$fileName');

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('custom_sound_path', savedFile.path);
        await prefs.setString('custom_sound_name', result.files.single.name);

        setState(() {}); // Refresh UI to show new name
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error custom sound: $e')),
        );
      }
    }
  }
}
