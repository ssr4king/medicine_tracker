import 'package:flutter/material.dart';
import 'bmi_result_screen.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  String _selectedGender = 'Male';

  void _calculateBmi() {
    if (_ageController.text.isEmpty ||
        _heightController.text.isEmpty ||
        _weightController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    double heightCm = double.tryParse(_heightController.text) ?? 0;
    double weightKg = double.tryParse(_weightController.text) ?? 0;

    if (heightCm <= 0 || weightKg <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid positive values')),
      );
      return;
    }

    // Formula: BMI = weight (kg) / (height (m))^2
    double heightM = heightCm / 100;
    double bmi = weightKg / (heightM * heightM);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BmiResultScreen(
          bmi: bmi,
          heightCm: heightCm.toInt(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BMI Calculator',
                style: Theme.of(context)
                    .textTheme
                    .displayLarge
                    ?.copyWith(fontSize: 32),
              ),
              const SizedBox(height: 8),
              Text(
                'Check your body mass index',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 30),

              // Gender Selector
              Row(
                children: [
                  Expanded(
                    child: _buildGenderCard(
                        "Male", Icons.male, _selectedGender == "Male"),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildGenderCard(
                        "Female", Icons.female, _selectedGender == "Female"),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Input Fields
              _buildInputField("Age", "years", _ageController),
              const SizedBox(height: 16),
              _buildInputField("Height", "cm", _heightController),
              const SizedBox(height: 16),
              _buildInputField("Weight", "kg", _weightController),

              const SizedBox(height: 40),

              // Calculate Button
              ElevatedButton(
                onPressed: _calculateBmi,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD68C45), // Terracotta
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  shadowColor: const Color(0xFFD68C45).withOpacity(0.4),
                ),
                child: const Text(
                  'Calculate BMI',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenderCard(String gender, IconData icon, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _selectedGender = gender),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8DA390) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF8DA390) : Colors.grey[200]!,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: const Color(0xFF8DA390).withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ]
              : [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2))
                ],
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 40, color: isSelected ? Colors.white : Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              gender,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(
      String label, String suffix, TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E36)),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: "0",
              suffixText: suffix,
              suffixStyle: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
