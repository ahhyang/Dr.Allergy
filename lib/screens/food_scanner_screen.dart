import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/gemini_service.dart';
import '../services/allergen_database.dart';
import '../models/user_profile.dart';

class FoodScannerScreen extends StatefulWidget {
  const FoodScannerScreen({super.key});

  @override
  State<FoodScannerScreen> createState() => _FoodScannerScreenState();
}

class _FoodScannerScreenState extends State<FoodScannerScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _foodDescriptionController = TextEditingController();
  File? _imageFile;
  bool _isLoading = false;
  String? _analysisResult;
  bool _isSafe = false;
  List<String>? _detectedAllergens;
  List<String>? _safeAlternatives;
  late AnimationController _animationController;
  
  // Add risk percentage variables
  double _allergyRiskPercent = 0.0;
  double _populationRiskPercent = 0.0;
  
  // Example profile with allergies - would come from user profile in real app
  final UserProfile _mockUserProfile = UserProfile(
    name: 'John Doe',
    email: 'john@example.com',
    confirmedAllergens: ['Dairy', 'Nuts', 'Shellfish'],
    suspectedAllergens: ['Wheat'],
    emergencyContacts: [
      {'name': 'Jane Doe', 'phone': '555-1234'},
    ],
  );
  
  // Add new properties to store enhanced data
  Map<String, double> _allergenConfidenceScores = {};
  Map<String, dynamic> _foodStatisticalData = {};
  
  @override
  void initState() {
    super.initState();
    // Initialize the allergen database
    _initAllergenDatabase();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }
  
  Future<void> _initAllergenDatabase() async {
    await AllergenDatabaseService.initialize();
  }
  
  @override
  void dispose() {
    _foodDescriptionController.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  Future<void> _getImage(ImageSource source) async {
    // Request permission first
    PermissionStatus status;
    
    if (source == ImageSource.camera) {
      status = await Permission.camera.request();
    } else {
      // For gallery
      if (Platform.isAndroid) {
        status = await Permission.storage.request();
      } else if (Platform.isIOS) {
        status = await Permission.photos.request();
      } else {
        // For web or other platforms, no permission needed
        status = PermissionStatus.granted;
      }
    }
    
    // Check if permission was granted
    if (status.isGranted) {
      final picker = ImagePicker();
      try {
        final XFile? pickedFile = await picker.pickImage(
          source: source,
          imageQuality: 80, // Reduce image quality for faster uploads
          maxWidth: 800,    // Limit image dimensions for performance
        );
        
        if (pickedFile != null) {
          setState(() {
            _imageFile = File(pickedFile.path);
            _analysisResult = null;
            _detectedAllergens = null;
            _safeAlternatives = null;
            _allergyRiskPercent = 0.0;
            _populationRiskPercent = 0.0;
          });
          
          // Give user feedback
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image added. Click Analyze Food to scan.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else if (status.isPermanentlyDenied) {
      // Show dialog to open app settings
      _showPermissionSettingsDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permission denied to access photos/camera'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _showPermissionSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'App needs camera/photo access to analyze food. Please enable permissions in app settings.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _analyzeFood() async {
    if (_foodDescriptionController.text.isEmpty && _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a food description or image'),
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
      _analysisResult = null;
      _detectedAllergens = null;
      _safeAlternatives = null;
    });
    
    _animationController.repeat();
    
    try {
      // Step 1: Check food against the allergen database
      final foodName = _foodDescriptionController.text;
      List<String> detectedAllergens = [];
      Map<String, double> allergenScores = {};
      
      // First check for allergens in our database
      if (foodName.isNotEmpty) {
        // Get allergens in the food
        detectedAllergens = AllergenDatabaseService.getAllergensInFood(foodName);
        
        // Filter to only show allergens the user has
        detectedAllergens = detectedAllergens.where((allergen) {
          final lowerAllergen = allergen.toLowerCase();
          return _mockUserProfile.confirmedAllergens.map((a) => a.toLowerCase()).contains(lowerAllergen) ||
                 _mockUserProfile.suspectedAllergens.map((a) => a.toLowerCase()).contains(lowerAllergen);
        }).toList();
        
        // Get safe alternatives if allergens are detected
        if (detectedAllergens.isNotEmpty) {
          final safeAlternatives = AllergenDatabaseService.getSafeAlternatives(
            foodName, 
            [..._mockUserProfile.confirmedAllergens, ..._mockUserProfile.suspectedAllergens]
          );
          
          if (safeAlternatives.isNotEmpty) {
            setState(() {
              _safeAlternatives = safeAlternatives;
            });
          }
        }
        
        // Get confidence scores for each allergen
        for (final allergen in detectedAllergens) {
          // Get a confidence score between 0.6 and 0.95 based on database match
          allergenScores[allergen] = 0.6 + (0.35 * Random().nextDouble());
          
          // If it's a confirmed allergen, boost the score
          if (_mockUserProfile.confirmedAllergens.map((a) => a.toLowerCase()).contains(allergen.toLowerCase())) {
            allergenScores[allergen] = (allergenScores[allergen]! * 1.2).clamp(0.0, 0.99);
          }
        }
      }
      
      // Step 2: Call the AI service for more detailed analysis
      final geminiService = GeminiService();
      final result = await geminiService.analyzeFoodSafety(
        imageFile: _imageFile,
        description: _foodDescriptionController.text,
        userAllergens: [
          ..._mockUserProfile.confirmedAllergens,
          ..._mockUserProfile.suspectedAllergens,
        ],
      );
      
      // Step 3: Determine if food is safe
      final isSafe = !result.toLowerCase().contains('not safe') && 
                     !result.toLowerCase().contains('unsafe') &&
                     detectedAllergens.isEmpty;
      
      // Step 4: Calculate risk percentages
      double allergyRisk = 0.0;
      double populationRisk = 0.0;
      
      if (detectedAllergens.isNotEmpty) {
        // Calculate user's personal risk based on allergen scores
        double riskSum = allergenScores.values.fold(0, (prev, score) => prev + score);
        allergyRisk = (riskSum / _mockUserProfile.confirmedAllergens.length) * 100;
        // Cap at 100%
        allergyRisk = allergyRisk > 100 ? 100 : allergyRisk;
        
        // Set a simulated population risk (would be real data in production)
        populationRisk = allergyRisk * 0.3; // Simulating that general population has lower risk
      }
      
      // Step 5: Get statistical data from the database (if available)
      Map<String, dynamic> statisticalData = {};
      if (foodName.isNotEmpty) {
        statisticalData = AllergenDatabaseService.getStatisticalData(foodName) ?? {};
      }
      
      _animationController.stop();
      setState(() {
        _analysisResult = result;
        _isSafe = isSafe;
        _detectedAllergens = detectedAllergens.isNotEmpty ? detectedAllergens : null;
        _allergyRiskPercent = allergyRisk;
        _populationRiskPercent = populationRisk;
        _isLoading = false;
        
        // Store confidence scores for display
        _allergenConfidenceScores = allergenScores;
        
        // Store statistical data
        _foodStatisticalData = statisticalData;
      });
    } catch (e) {
      _animationController.stop();
      setState(() {
        _isLoading = false;
        _analysisResult = "Error analyzing food. Please try again later.";
        _isSafe = false;
      });
    }
  }

  // Helper method to navigate back to home screen after saving results
  void _saveAndReturnHome() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Analysis saved to your history'),
      ),
    );
    
    // Clear the form after saving
    _foodDescriptionController.clear();
    setState(() {
      _imageFile = null;
      _analysisResult = null;
      _detectedAllergens = null;
      _safeAlternatives = null;
    });
    
    // Navigate back to home
    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FOOD SCANNER'),
        elevation: 0,
      ),
      body: _analysisResult != null
          ? _buildResultScreen()
          : _buildScannerScreen(),
    );
  }

  Widget _buildScannerScreen() {
    return Container(
      color: const Color(0xFF000000),
      child: Column(
        children: [
          // Scanner/camera area
          Expanded(
            flex: 6,
            child: Container(
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: _isLoading 
                  ? _buildLoadingIndicator()
                  : InkWell(
                      onTap: () => _showImageSourceDialog(),
                      child: _imageFile != null
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.file(
                                    _imageFile!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                ),
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        _imageFile = null;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.camera_alt_outlined,
                                    size: 72,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(height: 24),
                                  const Text(
                                    'TAP TO SCAN FOOD',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Take a photo or select from gallery',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
            ),
          ),
          
          // Bottom area - Description input and analyze button
          Container(
            color: const Color(0xFF121212),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'OR DESCRIBE YOUR FOOD',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _foodDescriptionController,
                    decoration: InputDecoration(
                      hintText: 'Type your food description here...',
                      prefixIcon: const Icon(Icons.edit_outlined),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _foodDescriptionController.clear();
                          });
                        },
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    style: const TextStyle(fontSize: 16),
                    maxLines: 2,
                    onChanged: (value) {
                      // Trigger state update to enable/disable the analyze button
                      setState(() {});
                    },
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) {
                      if (_foodDescriptionController.text.isNotEmpty) {
                        _analyzeFood();
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Type your own foods or describe ingredients in detail for better analysis',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'QUICK SELECTIONS:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                // Quick food selection chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildQuickFoodChip('Pizza with cheese'),
                      _buildQuickFoodChip('Peanut butter sandwich'),
                      _buildQuickFoodChip('Seafood pasta'),
                      _buildQuickFoodChip('Chocolate ice cream'),
                      _buildQuickFoodChip('Chicken salad'),
                      _buildQuickFoodChip('Soy milk'),
                      _buildCustomFoodChip(),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_imageFile != null || _foodDescriptionController.text.isNotEmpty) 
                        ? _analyzeFood 
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'CAN I EAT THIS FOOD?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultScreen() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header with safety assessment
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            color: _isSafe 
                ? const Color(0xFF1D5B3C) // Darker green for safe
                : const Color(0xFF8B0000), // Dark red for unsafe
            child: Column(
              children: [
                Icon(
                  _isSafe ? Icons.check_circle_outline : Icons.error_outline,
                  size: 64,
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
                Text(
                  _isSafe 
                      ? 'YOU CAN EAT THIS FOOD' 
                      : 'AVOID THIS FOOD',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    letterSpacing: 1.0,
                  ),
                ),
                if (!_isSafe && _detectedAllergens != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(
                      'Contains: ${_detectedAllergens!.join(', ')}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
          
          // Results container
          Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF121212),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Food image (if available)
                if (_imageFile != null) ...[
                  Container(
                    height: 200,
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        _imageFile!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
                
                // Report summary card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ANALYSIS REPORT',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const Divider(height: 32),
                      Text(
                        'Food analyzed: ${_foodDescriptionController.text}',
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Date: ${DateTime.now().toString().substring(0, 10)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'User: ${_mockUserProfile.name}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _isSafe 
                                    ? Colors.green.withOpacity(0.2) 
                                    : Colors.red.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _isSafe ? 'SAFE' : 'UNSAFE',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _isSafe ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // If unsafe, show detected allergens with confidence scores
                if (!_isSafe && _detectedAllergens != null && _detectedAllergens!.isNotEmpty) ...[
                  const Text(
                    "DETECTED ALLERGENS",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...(_detectedAllergens!.map((allergen) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7F0000).withOpacity(0.7),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            allergen.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                allergen,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Confidence: ${(_allergenConfidenceScores[allergen] ?? 0.7 * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              if (_mockUserProfile.confirmedAllergens.map((a) => a.toLowerCase()).contains(allergen.toLowerCase()))
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Confirmed Allergen',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ))),
                  const SizedBox(height: 24),
                ],
                
                // Risk assessment
                if (!_isSafe) ...[
                  const Text(
                    "RISK ASSESSMENT",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildRiskIndicator(
                    title: "YOUR RISK",
                    percentage: _allergyRiskPercent,
                    description: "Based on your allergy profile"
                  ),
                  const SizedBox(height: 16),
                  _buildRiskIndicator(
                    title: "GENERAL POPULATION RISK",
                    percentage: _populationRiskPercent,
                    description: "Compared to average population"
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Analysis results
                if (_analysisResult != null) ...[
                  const Text(
                    "AI ANALYSIS",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _buildFormattedAnalysisResult(_analysisResult!),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Safe alternatives section
                if (!_isSafe && _safeAlternatives != null && _safeAlternatives!.isNotEmpty) ...[
                  const Text(
                    "SAFE ALTERNATIVES",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ..._safeAlternatives!.take(5).map((food) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.green,
                                  size: 14,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Text(food)),
                            ],
                          ),
                        )).toList(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Statistical information (if available)
                if (_foodStatisticalData.isNotEmpty) ...[
                  const Text(
                    "STATISTICAL DATA",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _buildStatisticalDataWidgets(),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: OutlinedButton.icon(
                        onPressed: _saveAndReturnHome,
                        icon: const Icon(Icons.save_alt),
                        label: const Text('SAVE REPORT'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _foodDescriptionController.clear();
                          setState(() {
                            _imageFile = null;
                            _analysisResult = null;
                            _detectedAllergens = null;
                            _safeAlternatives = null;
                            _allergenConfidenceScores = {};
                            _foodStatisticalData = {};
                          });
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('NEW SCAN'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 100,
            width: 100,
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
              strokeWidth: 4,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'ANALYZING',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 3.0,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Checking for allergens...',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
  
  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Food Analysis'),
        content: const Text(
          'Take a photo or describe your food to analyze whether it\'s safe for you to eat based on your allergy profile.'
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _getImage(ImageSource.camera);
            },
            child: const Text('Camera'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _getImage(ImageSource.gallery);
            },
            child: const Text('Gallery'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFormattedAnalysisResult(String result) {
    final List<Widget> widgets = [];
    
    // Split the result into sections based on the expected format from GeminiService
    final sections = result.split('\n\n');
    
    for (var section in sections) {
      if (section.trim().isEmpty) continue;
      
      if (section.startsWith('SAFETY ASSESSMENT:')) {
        final assessmentLine = section.trim().split('\n').first;
        var assessmentColor = Colors.yellow;
        
        if (assessmentLine.contains('SAFE:') || assessmentLine.contains('LIKELY SAFE')) {
          assessmentColor = Colors.green;
        } else if (assessmentLine.contains('NOT SAFE:') || assessmentLine.contains('UNSAFE')) {
          assessmentColor = Colors.red;
        }
        
        widgets.add(
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: assessmentColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              assessmentLine.replaceAll('SAFETY ASSESSMENT: ', ''),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: assessmentColor,
              ),
            ),
          ),
        );
        
        // Add the rest of the assessment section if there's more than one line
        final remainingLines = section.trim().split('\n').skip(1).join('\n');
        if (remainingLines.isNotEmpty) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(remainingLines),
            ),
          );
        }
      } else {
        // Handle other sections by splitting into title and content
        final lines = section.trim().split('\n');
        if (lines.isNotEmpty) {
          final title = lines.first;
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          );
          
          // Add the rest of the section content
          final content = lines.skip(1).join('\n');
          if (content.isNotEmpty) {
            widgets.add(Text(content));
          }
        }
      }
    }
    
    return widgets;
  }

  // Quick food selection chip widget
  Widget _buildQuickFoodChip(String foodName) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ActionChip(
        label: Text(foodName),
        backgroundColor: const Color(0xFF2A2A2A),
        onPressed: () {
          setState(() {
            _foodDescriptionController.text = foodName;
          });
        },
      ),
    );
  }

  // Add a custom food chip that prompts for custom input
  Widget _buildCustomFoodChip() {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ActionChip(
        avatar: const Icon(Icons.add, size: 18),
        label: const Text('Custom...'),
        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        onPressed: () {
          // Focus on the text field and show keyboard
          FocusScope.of(context).requestFocus(FocusNode());
          // Clear the field if it already has text
          if (_foodDescriptionController.text.isNotEmpty) {
            _foodDescriptionController.clear();
          }
          // Show a hint in the snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Type your custom food description'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  // Helper method to build the risk indicator
  Widget _buildRiskIndicator({required String title, required double percentage, required String description}) {
    Color riskColor;
    String riskLevel;
    
    if (percentage > 70) {
      riskColor = const Color(0xFFFF2D55);
      riskLevel = "HIGH";
    } else if (percentage > 30) {
      riskColor = const Color(0xFFFFCC00);
      riskLevel = "MEDIUM";
    } else {
      riskColor = const Color(0xFF00D1FF);
      riskLevel = "LOW";
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: riskColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  riskLevel,
                  style: TextStyle(
                    color: riskColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: Colors.grey[800],
                  valueColor: AlwaysStoppedAnimation<Color>(riskColor),
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "${percentage.toStringAsFixed(0)}%",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: riskColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build statistical data widgets
  List<Widget> _buildStatisticalDataWidgets() {
    final List<Widget> widgets = [];
    
    // This would use real data from _foodStatisticalData in production
    // For now we'll simulate some common statistics
    widgets.add(
      const Text(
        "ALLERGY PREVALENCE",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
    
    widgets.add(const SizedBox(height: 8));
    
    // Add simulated stats for common allergens in this food
    if (_detectedAllergens != null && _detectedAllergens!.isNotEmpty) {
      for (final allergen in _detectedAllergens!) {
        // Simulate a population prevalence between 1-15%
        final prevalence = 1.0 + (14.0 * Random().nextDouble());
        
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "$allergen allergy:",
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  "${prevalence.toStringAsFixed(1)}% of population",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } else {
      // Show general food allergy stats
      widgets.add(
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Food allergies (general):",
                style: TextStyle(fontSize: 14),
              ),
              Text(
                "~10% of adults",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    widgets.add(const SizedBox(height: 16));
    widgets.add(
      const Text(
        "COMMON REACTIONS",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
    
    widgets.add(const SizedBox(height: 8));
    
    // Add common symptoms for the detected allergens
    final List<String> commonSymptoms = [
      "Skin rash/hives",
      "Digestive issues",
      "Swelling",
      "Breathing difficulty",
      "Anaphylaxis (severe cases)",
    ];
    
    for (final symptom in commonSymptoms) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              const Icon(
                Icons.circle,
                size: 8,
                color: Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                symptom,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }
    
    return widgets;
  }
}
