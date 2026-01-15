import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/medicine_provider.dart';
import '../models/medicine.dart';
import 'add_medicine_screen.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    String greeting = 'Good Night,';
    if (hour >= 5 && hour < 12) {
      greeting = 'Good Morning,';
    } else if (hour >= 12 && hour < 17) {
      greeting = 'Good Afternoon,';
    } else if (hour >= 17 && hour < 21) {
      greeting = 'Good Evening,';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F0), // Cream background
      body: Stack(
        children: [
          // 1. Organic Background Shape
          Container(
            height: 320,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF8DA390), // Sage Green
                  Color(0xFF7B9480), // Slightly darker sage
                ],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(60),
                bottomRight: Radius.circular(60),
              ),
            ),
          ),

          // 2. Content
          SafeArea(
            child: Consumer<MedicineProvider>(
              builder: (context, provider, child) {
                if (!provider.isInitialized) {
                  return const Center(child: CircularProgressIndicator());
                }

                final meds = provider.todaysMedicines;
                final totalDoses = meds.length;
                final takenDoses = meds
                    .where((m) =>
                        provider.getStatusOnDate(m, DateTime.now()) == 'TAKEN')
                    .length;
                final progress =
                    totalDoses == 0 ? 0.0 : takenDoses / totalDoses;
                final streak = provider.streak;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    // Header Row: Greeting & Streak
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                greeting,
                                style: Theme.of(context)
                                    .textTheme
                                    .displayLarge
                                    ?.copyWith(
                                      fontSize: 28,
                                      color: const Color(0xFFF9F6F0),
                                      height: 1.2,
                                    ),
                              ),
                              Text(
                                'Maintain your health',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      fontSize: 16,
                                      color: const Color(0xFFF9F6F0)
                                          .withOpacity(0.8),
                                    ),
                              ),
                            ],
                          ),
                          // Streak Badge
                          if (streak > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Text('🔥',
                                      style: TextStyle(fontSize: 18)),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$streak Day Streak',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Progress Indicator Area
                    Center(
                      child: _buildAnimatedProgressRing(
                          takenDoses, totalDoses, progress),
                    ),

                    const SizedBox(height: 60),

                    // Daily Review / List
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Text(
                        'Daily Review',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800]),
                      ),
                    ),
                    const SizedBox(height: 10),

                    Expanded(
                      child: meds.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                              itemCount: meds.length,
                              itemBuilder: (context, index) {
                                return _buildGlassMedicationCard(
                                    context, meds[index], provider);
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddMedicineScreen()),
          );
        },
        label: const Text('Add Med', style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
        backgroundColor: const Color(0xFFD68C45), // Terracotta
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }

  Widget _buildAnimatedProgressRing(int taken, int total, double progress) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(seconds: 1),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: 0, end: progress),
      builder: (context, value, child) {
        return SizedBox(
          width: 150,
          height: 150,
          child: Stack(
            children: [
              // Background Ring
              Center(
                child: SizedBox(
                  width: 150,
                  height: 150,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 12,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withOpacity(0.2)),
                  ),
                ),
              ),
              // Filter used for glow effect?
              // Custom Painter for Gradient Ring
              Center(
                child: CustomPaint(
                  size: const Size(150, 150),
                  painter: GradientRingPainter(
                    progress: value,
                    strokeWidth: 12,
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFD68C45),
                        Color(0xFFFFD180)
                      ], // Terracotta to Gold
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              // Inner Text
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$taken of $total',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Completed',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.spa, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No medicines for today',
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassMedicationCard(
      BuildContext context, Medicine med, MedicineProvider provider) {
    final status = provider.getStatusOnDate(med, DateTime.now());
    final isTaken = status == 'TAKEN';

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6), // Glass effect
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.4)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8DA390).withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F6F0),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.medication, color: Color(0xFF8DA390)),
              ),
              const SizedBox(width: 16),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      med.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E36),
                      ),
                    ),
                    if (med.dosage.isNotEmpty)
                      Text(
                        med.dosage,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    const SizedBox(height: 4),
                    // Dose History Link
                    GestureDetector(
                      onTap: () {
                        // TODO: Show history log
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('History feature coming soon')),
                        );
                      },
                      child: const Text(
                        'Dose History ›',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFFD68C45),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Time & Tick
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    med.timeFormatted,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      if (!isTaken) {
                        provider.updateStatus(med, DateTime.now(), 'TAKEN');
                      } else {
                        // Toggle back? Maybe. For now allow undo.
                        provider.updateStatus(med, DateTime.now(), 'PENDING');
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isTaken
                            ? const Color(0xFF8DA390)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isTaken
                              ? const Color(0xFF8DA390)
                              : Colors.grey[400]!,
                          width: 2,
                        ),
                      ),
                      child: isTaken
                          ? const Icon(Icons.check,
                              size: 20, color: Colors.white)
                          : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom Painter for the Gradient Ring
class GradientRingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Gradient gradient;

  GradientRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.gradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background arc (simple circle is handled by widget, but we can do it here too if needed)

    // Foreground Gradient Arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = gradient.createShader(rect);

    // Draw arc starting from top (-pi/2)
    canvas.drawArc(rect, -pi / 2, 2 * pi * progress, false, paint);
  }

  @override
  bool shouldRepaint(GradientRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
