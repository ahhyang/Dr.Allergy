import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/app_theme.dart';
import 'dart:ui';
import 'package:permission_handler/permission_handler.dart';
import '../services/food_detection_service.dart';
import '../models/user_profile.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  File? _image;
  bool _isAnalyzing = false;
  bool _permissionGranted = false;
  String _statusMessage = '';
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  
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

  @override
  void initState() {
    super.initState();
    _checkCameraPermission();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Initialize the food detection service in the background
    _initializeFoodDetection();
  }
  
  Future<void> _initializeFoodDetection() async {
    try {
      await FoodDetectionService.initialize();
    } catch (e) {
      debugPrint('Error initializing food detection: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) {
      setState(() {
        _permissionGranted = true;
      });
    } else {
      _requestCameraPermission();
    }
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    setState(() {
      _permissionGranted = status.isGranted;
      if (!_permissionGranted) {
        _statusMessage = 'Camera permission is required to scan food.';
      }
    });
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        // Remove preferredCameraDevice for compatibility with older versions
      );
      
      if (photo != null) {
        setState(() {
          _image = File(photo.path);
          _isAnalyzing = true;
          _statusMessage = 'Analyzing image for allergens...';
        });
        
        // Use the food detection service to analyze the image
        final userAllergens = [
          ..._mockUserProfile.confirmedAllergens,
          ..._mockUserProfile.suspectedAllergens,
        ];
        
        final result = await FoodDetectionService.analyzeImage(_image!, userAllergens);
        
        setState(() {
          _isAnalyzing = false;
          _statusMessage = '';
        });
        
        // Show the analysis results
        _showAnalysisResults(result);
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error capturing image: $e';
        _isAnalyzing = false;
      });
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      
      if (photo != null) {
        setState(() {
          _image = File(photo.path);
          _isAnalyzing = true;
          _statusMessage = 'Analyzing image for allergens...';
        });
        
        // Use the food detection service to analyze the image
        final userAllergens = [
          ..._mockUserProfile.confirmedAllergens,
          ..._mockUserProfile.suspectedAllergens,
        ];
        
        final result = await FoodDetectionService.analyzeImage(_image!, userAllergens);
        
        setState(() {
          _isAnalyzing = false;
          _statusMessage = '';
        });
        
        // Show the analysis results
        _showAnalysisResults(result);
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error selecting image: $e';
        _isAnalyzing = false;
      });
    }
  }

  void _showAnalysisResults(DetectionResult result) {
    // Show the results dialog
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                result.containsAllergens ? Icons.warning : Icons.check_circle,
                color: result.containsAllergens ? Colors.red : Colors.green,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(result.containsAllergens ? 'Allergens Detected!' : 'Analysis Complete'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image preview
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _image!,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
              
              // Display food name if it's a food image
              if (result.imageType == ImageType.food && result.foodName != null)
                Text(
                  'Detected Food: ${result.foodName}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              
              // Display image type
              Text(
                'Image Type: ${result.imageType == ImageType.food ? 'Food Photo' : 'Ingredient Label'}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Warning message
              Text(
                result.message,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: result.containsAllergens ? FontWeight.bold : FontWeight.normal,
                  color: result.containsAllergens ? Colors.red[700] : Colors.black,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // List detected allergens
              if (result.detectedAllergens.isNotEmpty) ...[
                const Text('Allergens Detected:'),
                const SizedBox(height: 4),
                ...result.detectedAllergens.map((allergen) => _buildAllergenChip(allergen, true)),
              ],
              
              // List other detected items if any
              if (result.detectedItems.length > result.detectedAllergens.length) ...[
                const SizedBox(height: 12),
                const Text('Other Detected Items:'),
                const SizedBox(height: 4),
                ...result.detectedItems
                    .where((item) => !result.detectedAllergens.contains(item))
                    .take(5) // Limit to 5 items
                    .map((item) => _buildAllergenChip(item, false)),
              ],
              
              const SizedBox(height: 16),
              
              // Disclaimer
              Text(
                'Note: This analysis is performed by AI and may not be 100% accurate. Always check ingredient labels for confirmation.',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('DISMISS'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Here you would save the results to history
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kBrandColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('SAVE TO HISTORY'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllergenChip(String name, bool isAllergen) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isAllergen ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAllergen ? Colors.red.withOpacity(0.3) : Colors.green.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAllergen ? Icons.warning_rounded : Icons.check_circle,
            color: isAllergen ? Colors.red : Colors.green,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            name,
            style: TextStyle(
              color: isAllergen ? Colors.red : Colors.green,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Food Allergen Scanner',
          style: TextStyle(
            color: kTextPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: kBrandColor),
      ),
      body: Column(
        children: [
          // Instructions and image preview area
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        // Image preview or placeholder
                        _buildImagePreview(),
                        
                        const SizedBox(height: 24),
                        
                        // Status message
                        if (_statusMessage.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _isAnalyzing 
                                ? kBrandColor.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                _isAnalyzing
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(kBrandColor),
                                        ),
                                      )
                                    : Icon(
                                        _permissionGranted ? Icons.info_outline : Icons.error_outline,
                                        color: _permissionGranted ? Colors.grey[600] : Colors.red,
                                      ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _statusMessage,
                                    style: TextStyle(
                                      color: _permissionGranted ? Colors.grey[800] : Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                        const SizedBox(height: 20),
                        
                        // Instructions
                        const Text(
                          'Take a photo of food or an ingredient label to scan for allergens',
                          style: TextStyle(
                            fontSize: 16,
                            color: kTextSecondaryColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 8),
                        
                        Text(
                          'Our AI will detect if your allergens are present',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // User allergen info
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: kBrandColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: kBrandColor.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Your Allergens:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: kTextPrimaryColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  ..._mockUserProfile.confirmedAllergens
                                    .map((allergen) => _buildUserAllergenChip(allergen, true)),
                                  ..._mockUserProfile.suspectedAllergens
                                    .map((allergen) => _buildUserAllergenChip(allergen, false)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom action area
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _permissionGranted ? _takePhoto : _requestCameraPermission,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kBrandColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text(
                          'TAKE PHOTO',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _pickFromGallery,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kBrandColor,
                    side: const BorderSide(color: kBrandColor),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text(
                    'CHOOSE FROM GALLERY',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
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

  Widget _buildImagePreview() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return GestureDetector(
          onTap: _permissionGranted ? _takePhoto : _requestCameraPermission,
          child: Container(
            height: 280,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: kBrandColor.withOpacity(0.2),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: kBrandColor.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: _image != null
                ? Image.file(
                    _image!,
                    fit: BoxFit.cover,
                  )
                : Stack(
                    alignment: Alignment.center,
                    children: [
                      // Background
                      Container(
                        color: Colors.grey[100],
                      ),
                      
                      // Camera icon and text
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: kBrandColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt_outlined,
                                size: 42,
                                color: kBrandColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Tap to take a photo',
                            style: TextStyle(
                              color: kBrandColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildUserAllergenChip(String allergen, bool isConfirmed) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isConfirmed 
            ? Colors.red.withOpacity(0.1) 
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isConfirmed 
              ? Colors.red.withOpacity(0.3)
              : Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isConfirmed ? Icons.error_outline : Icons.help_outline,
            size: 14,
            color: isConfirmed ? Colors.red : Colors.orange,
          ),
          const SizedBox(width: 4),
          Text(
            allergen,
            style: TextStyle(
              fontSize: 13,
              color: isConfirmed ? Colors.red[700] : Colors.orange[800],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
} 