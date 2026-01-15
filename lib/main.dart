import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'providers/medicine_provider.dart';
import 'services/notification_service.dart';
import 'screens/today_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/activity_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Notifications
  await NotificationService().initialize();

  // Initialize Hive and Provider
  final medicineProvider = MedicineProvider();
  await medicineProvider.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => medicineProvider),
      ],
      child: const MedicineTrackerApp(),
    ),
  );
}

class MedicineTrackerApp extends StatelessWidget {
  const MedicineTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medicine Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: GoogleFonts.merriweather().fontFamily,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8DA390), // Sage Green
          background: const Color(0xFFF9F6F0), // Cream
          surface: const Color(0xFFFFFFFF), // White
          secondary: const Color(0xFFD68C45), // Terracotta (keeping for accent)
          tertiary: const Color(0xFFA5A58D), // Olive
          onBackground: const Color(0xFF2C3E36), // Dark Green/Grey Text
        ),
        scaffoldBackgroundColor: const Color(0xFFF9F6F0),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Color(0xFF2C3E36),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Color(0xFF2C3E36)),
        ),
        textTheme: TextTheme(
          displayLarge: GoogleFonts.playfairDisplay(
            color: const Color(0xFF2C3E36),
            fontWeight: FontWeight.bold,
          ),
          bodyLarge: GoogleFonts.lato(
            color: const Color(0xFF2C3E36),
          ),
          bodyMedium: GoogleFonts.lato(
            color: const Color(0xFF2C3E36),
          ),
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const TodayScreen(),
    const CalendarScreen(),
    const ActivityScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_walk),
            selectedIcon: Icon(Icons.directions_walk),
            label: 'Activity',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
