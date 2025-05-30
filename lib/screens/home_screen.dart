import 'package:flutter/material.dart';
import 'dart:ui';
import '../models/allergy_incident.dart';
import '../services/incident_storage_service.dart';
import '../models/user_profile.dart';
import 'dart:math' as math;
import '../utils/app_theme.dart';
import '../widgets/feature_card.dart';

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
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;
  
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
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _loadData();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    
    // Add pulse animation for interactive elements
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
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
    final appBarOpacity = (_scrollOffset / 150).clamp(0.0, 1.0);
    
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: appBarOpacity * 4,
        backgroundColor: Colors.white.withOpacity(0.8 * appBarOpacity),
        title: AnimatedOpacity(
          opacity: appBarOpacity,
          duration: const Duration(milliseconds: 250),
          child: const Text(
            'Dr. Allergy',
            style: TextStyle(
              color: kBrandColor,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: kBrandColor),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Colors.white.withOpacity(0.5),
            ),
                                  ),
                                ),
                              ),
      body: Stack(
        children: [
          // Background pattern
                              Container(
                                decoration: BoxDecoration(
              color: Colors.white,
              // Remove the image reference that might be causing issues
              // image: DecorationImage(
              //   image: const AssetImage('assets/images/subtle_pattern.png'),
              //   fit: BoxFit.cover,
              //   colorFilter: ColorFilter.mode(
              //     Colors.white.withOpacity(0.95),
              //     BlendMode.lighten,
              //   ),
              // ),
            ),
          ),
          
          // Main content
          SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // Header section with hero title
                _buildHeaderSection(),
                
                // Welcome section
                _buildWelcomeSection(),
                
                // Features grid
                _buildFeaturesGrid(context),
                
                // Recent incidents section
                _buildRecentIncidentsSection(),
                
                // Bottom spacing
                const SizedBox(height: 24),
              ],
                                ),
                              ),
          
          // Floating action button
          Positioned(
            right: 24,
            bottom: 24,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value * 0.95,
                  child: FloatingActionButton(
                    onPressed: () {},
                    backgroundColor: kBrandColor,
                    elevation: 4,
                    child: const Icon(Icons.add_outlined, size: 28),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHeaderSection() {
    return Container(
      height: 180,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 120, 24, 0),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
            Colors.white.withOpacity(0.0),
            Colors.white.withOpacity(0.5),
            Colors.white,
          ],
          stops: const [0.0, 0.7, 1.0],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: kBrandColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                                      ),
                child: const Icon(
                  Icons.local_hospital_outlined,
                  color: kBrandColor,
                  size: 20,
                                    ),
                                  ),
              const SizedBox(width: 12),
              const Text(
                "Dr. Allergy",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: kBrandColor,
                  letterSpacing: -0.5,
                ),
              ),
            ],
                              ),
                            ],
                          ),
                        );
  }
  
  Widget _buildWelcomeSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: kBrandColor.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: kBrandColor.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Profile photo
                    Hero(
                      tag: 'profile-photo',
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              kBrandColor.withOpacity(0.8),
                              kBrandColor.withOpacity(0.6),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: kBrandColor.withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: kBrandColor.withOpacity(0.1),
                          child: const Text(
                            'JD',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // User info
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back,',
                          style: TextStyle(
                            fontSize: 14,
                            color: kTextSecondaryColor,
                          ),
                        ),
                        Text(
                          'John Doe',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: kTextPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Settings button
                    Container(
                      decoration: BoxDecoration(
                        color: kBrandColor.withOpacity(0.05),
                        shape: BoxShape.circle,
                    ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.settings_outlined,
                          color: kBrandColor,
                          size: 22,
                        ),
                        onPressed: () {},
                      ),
                    ),
                  ],
                  ),
                const SizedBox(height: 24),
                // Allergen guard card
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value * 0.97,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: kBrandColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: kBrandColor.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Radar animation with new style
                            SizedBox(
                              height: 60,
                              width: 60,
                              child: CustomPaint(
                                painter: RadarPainter(
                                  animation: _animationController,
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Your Allergen Guard',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: kTextPrimaryColor,
                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Keeping you safe from your allergens: Dairy, Nuts, Shellfish',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: kTextSecondaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  ),
                ],
              ),
            ),
          ),
      ),
    );
  }
  
  Widget _buildFeaturesGrid(BuildContext context) {
    return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: kTextPrimaryColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: kBrandColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: kBrandColor.withOpacity(0.1),
                  ),
                ),
                child: const Row(
                    children: [
                    Icon(
                      Icons.view_module_outlined,
                      size: 16,
                      color: kBrandColor,
                      ),
                    SizedBox(width: 4),
                    const Text(
                      'Grid View',
                      style: TextStyle(
                        fontSize: 12,
                        color: kBrandColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                        ),
                      ),
                    ],
                  ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: const [
              FeatureCard(
                title: 'Scan Food',
                description: 'Scan food labels to detect allergens',
                icon: Icons.camera_alt_outlined,
                route: '/camera',
              ),
              FeatureCard(
                title: 'Symptom Checker',
                description: 'Log and track allergy symptoms',
                icon: Icons.sick_outlined,
                route: '/symptom-checker',
              ),
              FeatureCard(
                title: 'History',
                description: 'View your past scans and reports',
                icon: Icons.history_outlined,
                route: '/history',
              ),
              FeatureCard(
                title: 'Profile',
                description: 'Manage your allergens and settings',
                icon: Icons.person_outline,
                route: '/profile',
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildRecentIncidentsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
                  Row(
                    children: [
                  const Text(
                    'Recent Incidents',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: kTextPrimaryColor,
                        ),
                      ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: kBrandColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _recentIncidents.isEmpty ? '0' : _recentIncidents.length.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: kBrandColor,
                        fontWeight: FontWeight.bold,
                        ),
                      ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/history'),
                icon: const Icon(
                  Icons.arrow_forward,
                  size: 16,
                ),
                label: const Text(
                  'See All',
                  style: TextStyle(
                    color: kBrandColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: kBrandColor,
                  ),
                )
              : _recentIncidents.isEmpty
                  ? _buildEmptyState()
                  : Column(
                      children: _recentIncidents
                          .take(3)
                          .map((incident) => _buildIncidentItem(incident))
                          .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Container(
          padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: kBrandColor.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              ShaderMask(
                shaderCallback: (bounds) {
                  return LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      kBrandColor,
                      kBrandColor.withOpacity(0.5),
                    ],
                  ).createShader(bounds);
                },
                child: const Icon(
                  Icons.sentiment_satisfied_alt,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No incidents recorded yet',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: kTextPrimaryColor,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your recent allergy incidents will appear here',
                style: TextStyle(
                  fontSize: 14,
                  color: kTextSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Record New Incident'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBrandColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildIncidentItem(AllergyIncident incident) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
        padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: kBrandColor.withOpacity(0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: kBrandColor.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: incident.severity == AllergyIncident.severe
                          ? Colors.red.withOpacity(0.1)
                          : kBrandColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: incident.severity == AllergyIncident.severe
                            ? Colors.red.withOpacity(0.3)
                            : kBrandColor.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      incident.severity == AllergyIncident.severe ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
                      color: incident.severity == AllergyIncident.severe ? Colors.red : kBrandColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          incident.foodsEaten,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: kTextPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
          children: [
            const Icon(
                              Icons.calendar_today_outlined,
                              size: 12,
                              color: kTextSecondaryColor,
            ),
                            const SizedBox(width: 4),
            Text(
                              _formatDate(incident.date),
                              style: const TextStyle(
                                fontSize: 13,
                                color: kTextSecondaryColor,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getSeverityColor(incident.severity).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _getSeverityText(incident.severity),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: _getSeverityColor(incident.severity),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: kBrandColor.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.chevron_right,
                        color: kBrandColor.withOpacity(0.7),
                        size: 22,
                      ),
                      onPressed: () {},
                    ),
            ),
          ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  
  String _getSeverityText(String severity) {
    switch (severity) {
      case AllergyIncident.mild:
        return 'Mild';
      case AllergyIncident.moderate:
        return 'Moderate';
      case AllergyIncident.severe:
        return 'Severe';
      default:
        return 'Unknown';
    }
  }
  
  Color _getSeverityColor(String severity) {
    switch (severity) {
      case AllergyIncident.mild:
        return Colors.amber;
      case AllergyIncident.moderate:
        return Colors.orange;
      case AllergyIncident.severe:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

// Custom painter for radar animation
class RadarPainter extends CustomPainter {
  final Animation<double> animation;

  RadarPainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Draw outer circles
    final outerPaint = Paint()
      ..color = kBrandColor.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    canvas.drawCircle(center, radius * 0.9, outerPaint);
    canvas.drawCircle(center, radius * 0.6, outerPaint);
    canvas.drawCircle(center, radius * 0.3, outerPaint);
    
    // Draw scanning line
    final scanPaint = Paint()
      ..color = kBrandColor.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    final angle = animation.value * 2 * math.pi;
    final scanX = center.dx + math.cos(angle) * radius;
    final scanY = center.dy + math.sin(angle) * radius;
    
    canvas.drawLine(center, Offset(scanX, scanY), scanPaint);
    
    // Draw gradient arcs
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;
    
    final rect = Rect.fromCircle(center: center, radius: radius * 0.95);
    final gradient = SweepGradient(
      center: Alignment.center,
      startAngle: 0,
      endAngle: math.pi * 2,
      colors: [
        kBrandColor.withOpacity(0.7),
        kBrandColor.withOpacity(0.5),
        kBrandColor.withOpacity(0.3),
        kBrandColor.withOpacity(0.1),
        kBrandColor.withOpacity(0.0),
      ],
      stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      transform: GradientRotation(angle),
    );
    
    arcPaint.shader = gradient.createShader(rect);
    canvas.drawArc(rect, angle, math.pi / 2, false, arcPaint);
    
    // Draw pulsing center point
    final pulseFactor = (math.sin(animation.value * 10 * math.pi) + 1) / 2;
    final centerPaint = Paint()
      ..color = kBrandColor.withOpacity(0.4 + (pulseFactor * 0.3))
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, radius * 0.1 * (1 + pulseFactor * 0.3), centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
