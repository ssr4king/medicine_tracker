import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/medicine_provider.dart';
import 'edit_profile_screen.dart';
import 'emergency_contact_screen.dart';
import '../services/pdf_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F0),
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const EditProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<MedicineProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Avatar & Name
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF8DA390),
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8DA390).withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                          image: provider.profileImagePath != null
                              ? DecorationImage(
                                  image: FileImage(
                                      File(provider.profileImagePath!)),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: provider.profileImagePath == null
                            ? const Icon(Icons.person,
                                size: 50, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        provider.userName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E36),
                        ),
                      ),
                      Text(
                        'Keep up the good work!',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Medical Section
                _buildSectionHeader('Medical Details'),
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      _buildListTile(
                        context,
                        icon: Icons.contact_emergency_outlined,
                        title: 'Emergency Contact',
                        subtitle: provider.emergencyContactName != null
                            ? '${provider.emergencyContactName} • ${provider.emergencyContactPhone}'
                            : 'Add details',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const EmergencyContactScreen()),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      _buildListTile(
                        context,
                        icon: Icons.picture_as_pdf_outlined,
                        title: 'Medication PDF Export',
                        subtitle: 'Download your history',
                        onTap: () {
                          PdfService.generateAndPrint(
                              provider.medicines, provider.userName);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Settings Section
                _buildSectionHeader('Settings'),
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      // Custom Switch Tile for cleaner look
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: const Color(0xFFE0F2F1),
                              borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.notifications_outlined,
                              color: Color(0xFF00695C)),
                        ),
                        title: const Text('Notifications',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        trailing: Switch.adaptive(
                            value: true,
                            onChanged: (v) {},
                            activeColor: const Color(0xFF8DA390)),
                      ),
                      const Divider(height: 1),
                      _buildListTile(
                        context,
                        icon: Icons.delete_outline,
                        iconColor: Colors.red[400],
                        title: 'Clear All Data',
                        textColor: Colors.red[700],
                        onTap: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Clear Data?'),
                              content: const Text(
                                  'This will delete all your medicines and history. This action cannot be undone.'),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel')),
                                TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Delete',
                                        style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            Provider.of<MedicineProvider>(context,
                                    listen: false)
                                .clearAllData();
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('All data cleared')));
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.2),
        ),
      ),
    );
  }

  Widget _buildListTile(BuildContext context,
      {required IconData icon,
      required String title,
      String? subtitle,
      Color? iconColor,
      Color? textColor,
      required VoidCallback onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: (iconColor ?? const Color(0xFF8DA390)).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: iconColor ?? const Color(0xFF8DA390)),
      ),
      title: Text(title,
          style: TextStyle(
              fontWeight: FontWeight.w600,
              color: textColor ?? const Color(0xFF2C3E36))),
      subtitle: subtitle != null
          ? Text(subtitle,
              style: TextStyle(color: Colors.grey[500], fontSize: 12))
          : null,
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}
