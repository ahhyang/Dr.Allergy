import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/gemini_service.dart';
import '../services/allergen_database.dart';
import '../widgets/loading_indicator.dart';
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
      final geminiService = GeminiService();
      final result = await geminiService.analyzeFoodSafety(
        imageFile: _imageFile,
        description: _foodDescriptionController.text,
        userAllergens: [
          ..._mockUserProfile.confirmedAllergens,
          ..._mockUserProfile.suspectedAllergens,
        ],
      );
      
      // Check food against the database
      final foodName = _foodDescriptionController.text;
      List<String> detectedAllergens = [];
      
      // If we have a food name, check for allergens in our database
      if (foodName.isNotEmpty) {
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
      }
      
      // Simple parsing of result to determine if food is safe
      final isSafe = !result.toLowerCase().contains('not safe') && 
                     !result.toLowerCase().contains('unsafe') &&
                     detectedAllergens.isEmpty;
      
      // Calculate risk percentages (in a real app, this would come from the analysis API)
      double allergyRisk = 0.0;
      double populationRisk = 0.0;
      
      if (detectedAllergens.isNotEmpty) {
        // Calculate user's personal risk based on number of detected allergens
        allergyRisk = detectedAllergens.length / _mockUserProfile.confirmedAllergens.length * 100;
        // Cap at 100%
        allergyRisk = allergyRisk > 100 ? 100 : allergyRisk;
        
        // Set a simulated population risk (would be real data in production)
        populationRisk = allergyRisk * 0.3; // Simulating that general population has lower risk
      }
      
      _animationController.stop();
      setState(() {
        _analysisResult = result;
        _isSafe = isSafe;
        _detectedAllergens = detectedAllergens.isNotEmpty ? detectedAllergens : null;
        _allergyRiskPercent = allergyRisk;
        _populationRiskPercent = populationRisk;
        _isLoading = false;
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
                TextField(
                  controller: _foodDescriptionController,
                  decoration: const InputDecoration(
                    hintText: 'e.g., pasta with tomato sauce and cheese',
                    border: InputBorder.none,
                    filled: true,
                  ),
                  style: const TextStyle(fontSize: 16),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
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
                      'ANALYZE FOOD',
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
    return Container(
      color: const Color(0xFF000000),
      child: Column(
        children: [
          // Food image or indicator
          Container(
            height: 200,
            width: double.infinity,
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: _imageFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      _imageFile!,
                      fit: BoxFit.cover,
                    ),
                  )
                : Center(
                    child: Icon(
                      Icons.restaurant,
                      size: 72,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
          ),
          
          // Results container
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF121212),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 100,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[700],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Result indicator
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      decoration: BoxDecoration(
                        color: _isSafe ? const Color(0xFF1B5E20) : const Color(0xFF7F0000),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _isSafe ? Icons.check_circle : Icons.warning,
                            size: 64,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _isSafe ? "SAFE TO EAT" : "RISK DETECTED",
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Risk Percentage Indicators (new section)
                    if (!_isSafe) ...[
                      const Text(
                        "ALLERGY RISK ASSESSMENT",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // User's personal risk
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "YOUR RISK",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "${_allergyRiskPercent.toStringAsFixed(0)}%",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: _allergyRiskPercent / 100,
                            backgroundColor: Colors.grey[800],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _allergyRiskPercent > 70
                                ? const Color(0xFFFF2D55)
                                : _allergyRiskPercent > 30
                                  ? const Color(0xFFFFCC00)
                                  : const Color(0xFF00D1FF),
                            ),
                            minHeight: 10,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // General population risk
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "GENERAL POPULATION RISK",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "${_populationRiskPercent.toStringAsFixed(0)}%",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: _populationRiskPercent / 100,
                            backgroundColor: Colors.grey[800],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _populationRiskPercent > 70
                                ? const Color(0xFFFF2D55)
                                : _populationRiskPercent > 30
                                  ? const Color(0xFFFFCC00)
                                  : const Color(0xFF00D1FF),
                            ),
                            minHeight: 10,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                    
                    // Allergens section
                    if (_detectedAllergens != null && _detectedAllergens!.isNotEmpty) ...[
                      const Text(
                        "DETECTED ALLERGENS",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _detectedAllergens!.map((allergen) => Chip(
                          label: Text(allergen),
                          backgroundColor: const Color(0xFF7F0000).withOpacity(0.7),
                        )).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],
                    
                    // Analysis result
                    const Text(
                      "ANALYSIS",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _analysisResult!,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    
                    // Safe alternatives
                    if (_safeAlternatives != null && _safeAlternatives!.isNotEmpty) ...[
                      const Text(
                        "SAFE ALTERNATIVES",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...(_safeAlternatives!.take(3).map((food) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Theme.of(context).colorScheme.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(food)),
                          ],
                        ),
                      )).toList()),
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
                            label: const Text('SAVE'),
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
      builder: (context) => SimpleDialog(
        title: const Text('Select Image Source'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              _getImage(ImageSource.camera);
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Icon(Icons.camera_alt, size: 24.0),
                  SizedBox(width: 16.0),
                  Text('Take a Photo', style: TextStyle(fontSize: 16.0)),
                ],
              ),
            ),
          ),
          const Divider(),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              _getImage(ImageSource.gallery);
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Icon(Icons.photo_library, size: 24.0),
                  SizedBox(width: 16.0),
                  Text('Choose from Gallery', style: TextStyle(fontSize: 16.0)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
