import 'package:flutter/material.dart';
import '../models/allergy_incident.dart';
import '../services/incident_storage_service.dart';
import '../widgets/loading_indicator.dart';
import '../models/user_profile.dart';
import 'dart:math' as math;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<AllergyIncident> _recentIncidents = [];
  Map<String, int> _allergenStats = {};
  String? _mostFrequentAllergen;
  
  // Mock user profile - would come from a user service in a real app
  final UserProfile _mockUserProfile = UserProfile(
    name: 'John Doe',
    email: 'john@example.com',
    confirmedAllergens: ['Dairy', 'Nuts', 'Shellfish'],
    suspectedAllergens: ['Wheat'],
    emergencyContacts: [
      {'name': 'Jane Doe', 'phone': '555-1234'},
    ],
  );

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _loadData();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Load recent incidents
      final incidents = await IncidentStorageService.getRecentIncidents();
      
      // Get allergen frequency stats
      final stats = await IncidentStorageService.getAllergenFrequencyStats();
      
      // Get most frequent allergen
      final mostFrequent = await IncidentStorageService.getMostFrequentAllergen();
      
      setState(() {
        _recentIncidents = incidents;
        _allergenStats = stats;
        _mostFrequentAllergen = mostFrequent;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Top section - Greeting and animation
          Expanded(
            flex: 5,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
              decoration: const BoxDecoration(
                color: Color(0xFF000000),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // Radar animation
                  Center(
                    child: AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return SizedBox(
                          height: 160,
                          width: 160,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer circle
                              Container(
                                height: 160,
                                width: 160,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.grey.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                              ),
                              // Middle circle
                              Container(
                                height: 120,
                                width: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.grey.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                              ),
                              // Inner circle
                              Container(
                                height: 80,
                                width: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.grey.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                              ),
                              // Center dot
                              Container(
                                height: 4,
                                width: 4,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              // Radar sweep
                              Transform.rotate(
                                angle: _animationController.value * 2 * math.pi,
                                child: Container(
                                  height: 160,
                                  width: 160,
                                  alignment: Alignment.topCenter,
                                  child: Container(
                                    width: 2,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Theme.of(context).colorScheme.primary,
                                          Theme.of(context).colorScheme.primary.withOpacity(0.0),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 40),
                  // App purpose text
                  Text(
                    "CHECK YOUR FOOD SAFELY",
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Identify food allergens quickly and safely",
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom section - Actions
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: const Color(0xFF121212),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          context: context,
                          icon: Icons.camera_alt_outlined,
                          label: "SCAN FOOD",
                          onTap: () => Navigator.pushNamed(context, '/food-scanner'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildActionButton(
                          context: context,
                          icon: Icons.sick_outlined,
                          label: "REPORT SYMPTOMS",
                          onTap: () => Navigator.pushNamed(context, '/symptom-checker'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          context: context,
                          icon: Icons.history_outlined,
                          label: "HISTORY",
                          onTap: () => Navigator.pushNamed(context, '/history'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildActionButton(
                          context: context,
                          icon: Icons.person_outline,
                          label: "PROFILE",
                          onTap: () => Navigator.pushNamed(context, '/profile'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: Colors.white,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                letterSpacing: 1.0,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
