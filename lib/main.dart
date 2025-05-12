import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/food_scanner_screen.dart';
import 'screens/symptom_checker_screen.dart';
import 'screens/history_screen.dart';
import 'services/allergen_database.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set up logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });
  
  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize the allergen database
  await AllergenDatabaseService.initialize();
  
  runApp(const DrAllergyApp());
}

class DrAllergyApp extends StatelessWidget {
  const DrAllergyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dr.Allergy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.radioAppTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const MainScreen(),
        '/home': (context) => const HomeScreen(),
        '/symptom-checker': (context) => const SymptomCheckerScreen(),
        '/food-scanner': (context) => const FoodScannerScreen(),
        '/history': (context) => const HistoryScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  
  final List<Widget> _screens = [
    const HomeScreen(),
    const SymptomCheckerScreen(),
    const FoodScannerScreen(),
    const HistoryScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      extendBody: true,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            selectedItemColor: Theme.of(context).colorScheme.secondary,
            unselectedItemColor: Colors.grey,
            backgroundColor: Colors.white,
            elevation: 0,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 11,
            ),
            items: [
              _buildNavItem(Icons.home_rounded, Icons.home_outlined, 'Home'),
              _buildNavItem(Icons.medical_services_rounded, Icons.medical_services_outlined, 'Symptoms'),
              _buildNavItem(Icons.camera_alt_rounded, Icons.camera_alt_outlined, 'Scan'),
              _buildNavItem(Icons.history_rounded, Icons.history_outlined, 'History'),
              _buildNavItem(Icons.person_rounded, Icons.person_outline, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
  
  BottomNavigationBarItem _buildNavItem(IconData selectedIcon, IconData unselectedIcon, String label) {
    return BottomNavigationBarItem(
      icon: Padding(
        padding: const EdgeInsets.only(bottom: 4, top: 4),
        child: Icon(_selectedIndex == _getIndexForLabel(label) ? selectedIcon : unselectedIcon),
      ),
      label: label,
    );
  }
  
  int _getIndexForLabel(String label) {
    switch (label) {
      case 'Home': return 0;
      case 'Symptoms': return 1;
      case 'Scan': return 2;
      case 'History': return 3;
      case 'Profile': return 4;
      default: return 0;
    }
  }
}
