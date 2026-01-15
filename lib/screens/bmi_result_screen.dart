import 'package:flutter/material.dart';

class BmiResultScreen extends StatelessWidget {
  final double bmi;
  final int heightCm;

  const BmiResultScreen({
    super.key,
    required this.bmi,
    required this.heightCm,
  });

  String getCategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 24.9) return 'Normal';
    if (bmi < 29.9) return 'Overweight';
    return 'Obese';
  }

  Color getCategoryColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 24.9) return Colors.green;
    if (bmi < 29.9) return Colors.orange;
    return Colors.red;
  }

  String getAnalysis(double bmi) {
    if (bmi < 18.5)
      return 'You are underweight. Maintaining a balanced diet is important.';
    if (bmi < 24.9) return 'You have a normal body weight. Keep it up!';
    if (bmi < 29.9) return 'You are slightly overweight. Exercise can help.';
    return 'You are in the obese range. Please consult a doctor for advice.';
  }

  @override
  Widget build(BuildContext context) {
    String category = getCategory(bmi);
    Color color = getCategoryColor(bmi);

    // Suggested Weight Calculation
    double minWeight = 18.5 * (heightCm / 100) * (heightCm / 100);
    double maxWeight = 24.9 * (heightCm / 100) * (heightCm / 100);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F0),
      appBar: AppBar(
        title: const Text('BMI Result',
            style: TextStyle(color: Color(0xFF2C3E36))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2C3E36)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Your current BMI',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 10),
              Text(
                bmi.toStringAsFixed(1),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const Text(
                'Body mass index',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  category,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Scale
              SizedBox(
                height: 50,
                child: Stack(
                  children: [
                    Container(
                      height: 10,
                      margin: const EdgeInsets.only(top: 20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        gradient: const LinearGradient(
                          colors: [
                            Colors.blue,
                            Colors.green,
                            Colors.orange,
                            Colors.red
                          ],
                        ),
                      ),
                    ),
                    // Indicator logic: clamp bmi between 15 and 35 for display
                    LayoutBuilder(builder: (context, constraints) {
                      double minBmi = 15;
                      double maxBmi = 35;
                      double fraction =
                          ((bmi - minBmi) / (maxBmi - minBmi)).clamp(0.0, 1.0);

                      return Positioned(
                        left: fraction *
                            (constraints.maxWidth -
                                20), // Adjust for icon width
                        child:
                            Icon(Icons.arrow_drop_down, size: 30, color: color),
                      );
                    }),
                  ],
                ),
              ),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Underweight",
                      style: TextStyle(fontSize: 10, color: Colors.blue)),
                  Text("Normal",
                      style: TextStyle(fontSize: 10, color: Colors.green)),
                  Text("Overweight",
                      style: TextStyle(fontSize: 10, color: Colors.orange)),
                  Text("Obese",
                      style: TextStyle(fontSize: 10, color: Colors.red)),
                ],
              ),

              const SizedBox(height: 40),

              // Analysis Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    _buildRow("Height", "$heightCm cm"),
                    const Divider(height: 24),
                    _buildRow("Suggested Weight",
                        "${minWeight.toStringAsFixed(1)} - ${maxWeight.toStringAsFixed(1)} kg"),
                  ],
                ),
              ),

              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8DA390),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Recalculate"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey)),
        Text(value,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E36))),
      ],
    );
  }
}
