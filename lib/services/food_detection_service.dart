import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../models/user_profile.dart';

enum ImageType {
  food,
  ingredientLabel,
  unknown
}

class DetectionResult {
  final bool containsAllergens;
  final List<String> detectedAllergens;
  final List<String> detectedItems;
  final String? foodName;
  final double confidence;
  final String message;
  final ImageType imageType;

  DetectionResult({
    required this.containsAllergens,
    required this.detectedAllergens,
    required this.detectedItems,
    this.foodName,
    required this.confidence,
    required this.message,
    required this.imageType,
  });
}

class FoodDetectionService {
  static const List<String> _commonAllergens = [
    'peanut', 'peanuts', 'tree nut', 'tree nuts', 'milk', 'dairy', 'egg', 'eggs',
    'soy', 'wheat', 'fish', 'shellfish', 'crustacean', 'sesame', 'mustard',
    'celery', 'lupin', 'sulphite', 'gluten', 'lactose', 'casein',
    'almond', 'hazelnut', 'pecan', 'cashew', 'pistachio', 'walnut',
    'shrimp', 'crab', 'lobster', 'clam', 'mussel', 'oyster',
    'sulfite', 'sulphite',
  ];

  // Keywords that indicate this is an ingredient list
  static const List<String> _ingredientKeywords = [
    'ingredients', 'contains', 'allergens', 'may contain',
    'manufactured in', 'processed in', 'nutrition', 'facts',
  ];

  // Common food ingredients that aren't allergens
  static const List<String> _commonFoodIngredients = [
    'water', 'salt', 'sugar', 'flour', 'oil', 'vinegar', 'starch',
    'yeast', 'baking powder', 'spice', 'spices', 'vitamin', 'mineral',
    'preservative', 'color', 'flavour', 'flavor', 'acid', 'sodium',
    'calcium', 'iron', 'natural', 'artificial',
  ];
  
  static final TextRecognizer _textRecognizer = TextRecognizer();
  static ImageLabeler? _imageLabeler;
  static Interpreter? _foodClassifierInterpreter;
  static bool _isInitialized = false;
  
  // Initialize models and resources
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Initialize ML Kit image labeler
      final ImageLabelerOptions options = ImageLabelerOptions(confidenceThreshold: 0.7);
      _imageLabeler = ImageLabeler(options: options);
      
      // Initialize TensorFlow Lite model for food classification
      // First, check if model exists in assets, if not, we'll rely on ML Kit only
      try {
        final modelFile = await _getModel('assets/models/food_classifier.tflite');
        if (modelFile != null) {
          _foodClassifierInterpreter = await Interpreter.fromFile(modelFile);
        } else {
          debugPrint('Food classifier model file not available, will use ML Kit only');
        }
      } catch (e) {
        debugPrint('Food classifier model not available: $e');
        // We'll still work with ML Kit if the model is not available
      }
      
      _isInitialized = true;
    } catch (e) {
      debugPrint('Failed to initialize FoodDetectionService: $e');
      rethrow;
    }
  }
  
  static Future<File?> _getModel(String assetPath) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final modelFile = File('${appDir.path}/food_classifier.tflite');
      
      if (!await modelFile.exists()) {
        try {
          final byteData = await rootBundle.load(assetPath);
          final buffer = byteData.buffer;
          await modelFile.writeAsBytes(
            buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes)
          );
        } catch (e) {
          debugPrint('Could not load model from assets: $e');
          return null;
        }
      }
      
      return modelFile;
    } catch (e) {
      debugPrint('Error in _getModel: $e');
      return null;
    }
  }
  
  // Main method to analyze an image and detect allergens
  static Future<DetectionResult> analyzeImage(File imageFile, List<String> userAllergens) async {
    await initialize();
    
    try {
      // Preprocess image using OpenCV
      final preprocessedImage = await _preprocessImage(imageFile);
      
      // Detect if this is a food image or ingredient label
      final imageType = await _determineImageType(preprocessedImage);
      
      if (imageType == ImageType.ingredientLabel) {
        // Process as an ingredient label using OCR
        return await _processIngredientLabel(preprocessedImage, userAllergens);
      } else {
        // Process as a food item using image classification
        return await _processFoodImage(preprocessedImage, userAllergens);
      }
    } catch (e) {
      debugPrint('Error analyzing image: $e');
      return DetectionResult(
        containsAllergens: false,
        detectedAllergens: [],
        detectedItems: [],
        confidence: 0.0,
        message: 'Error analyzing image: $e',
        imageType: ImageType.unknown,
      );
    } finally {
      // Clean up resources
      // Note: don't call close() on the image labeler or text recognizer here
      // as they can be reused for multiple analyses and should be closed when the app is done
    }
  }
  
  // Preprocess image using OpenCV
  static Future<File> _preprocessImage(File imageFile) async {
    try {
      // Read the image file
      final bytes = await imageFile.readAsBytes();
      
      // Load image with OpenCV
      final mat = cv.imdecode(bytes, cv.IMREAD_COLOR);
      
      // Resize image to a manageable size
      final resized = cv.resize(mat, (600, 800));
      
      // Convert to grayscale
      final gray = cv.cvtColor(resized, cv.COLOR_BGR2GRAY);
      
      // Apply adaptive threshold for text enhancement (mainly for ingredient labels)
      final thresholded = cv.adaptiveThreshold(
        gray, 
        255, 
        cv.ADAPTIVE_THRESH_GAUSSIAN_C, 
        cv.THRESH_BINARY, 
        11, 
        2
      );
      
      // Apply Gaussian blur to reduce noise
      final blurred = cv.gaussianBlur(thresholded, (3, 3), 1.5);
      
      // Encode the processed image
      final result = cv.imencode(".jpg", blurred);
      final processedBytes = result.$2;
      
      // Compress the image for efficient storage
      final compressedBytes = await FlutterImageCompress.compressWithList(
        processedBytes,
        quality: 85,
        format: CompressFormat.jpeg,
      );
      
      // Save preprocessed image to a temporary file
      final tempDir = await getTemporaryDirectory();
      final preprocessedFile = File('${tempDir.path}/preprocessed_image.jpg');
      await preprocessedFile.writeAsBytes(compressedBytes);
      
      // Clean up OpenCV resources
      mat.release();
      resized.release();
      gray.release();
      thresholded.release();
      blurred.release();
      
      return preprocessedFile;
    } catch (e) {
      debugPrint('Error preprocessing image: $e');
      // If preprocessing fails, return the original image
      return imageFile;
    }
  }
  
  // Determine if the image is a food photo or an ingredient label
  static Future<ImageType> _determineImageType(File imageFile) async {
    try {
      // Use OCR to detect text in the image
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      // If there's a significant amount of text, it's likely an ingredient label
      if (recognizedText.text.length > 50) {
        // Check for specific keywords that would indicate an ingredient list
        final lowerCaseText = recognizedText.text.toLowerCase();
        for (final keyword in _ingredientKeywords) {
          if (lowerCaseText.contains(keyword)) {
            return ImageType.ingredientLabel;
          }
        }
      }
      
      // Use image labeling as a backup to detect if this is food
      if (_imageLabeler != null) {
        final labels = await _imageLabeler!.processImage(inputImage);
        
        for (final label in labels) {
          if (label.label.toLowerCase().contains('food') || 
              label.label.toLowerCase().contains('dish') ||
              label.label.toLowerCase().contains('meal')) {
            return ImageType.food;
          }
        }
      }
      
      // If we're not confident it's a label and there's not much text, assume it's food
      if (recognizedText.text.length < 20) {
        return ImageType.food;
      }
      
      // Default: if we're not sure, treat it as an ingredient label to be safe
      return ImageType.ingredientLabel;
    } catch (e) {
      debugPrint('Error determining image type: $e');
      // Default to food if we can't determine
      return ImageType.food;
    }
  }
  
  // Process an image of food using ML Kit and TensorFlow Lite
  static Future<DetectionResult> _processFoodImage(File imageFile, List<String> userAllergens) async {
    String? foodName;
    double confidence = 0.0;
    final List<String> detectedItems = [];
    
    try {
      final inputImage = InputImage.fromFile(imageFile);
      
      // First try using the TFLite food classifier if available
      if (_foodClassifierInterpreter != null) {
        // Load and process the image for TensorFlow Lite
        final imageData = await _loadAndProcessImageForTensorFlow(imageFile);
        
        // Allocate tensors for the model
        final outputShape = _foodClassifierInterpreter!.getOutputTensor(0).shape;
        final outputBuffer = List<List<double>>.filled(
          outputShape[0], 
          List<double>.filled(outputShape[1], 0.0)
        );
        
        // Run the model
        _foodClassifierInterpreter!.run(imageData, outputBuffer);
        
        // Process results
        int maxIndex = 0;
        double maxScore = outputBuffer[0][0];
        
        for (int i = 1; i < outputBuffer[0].length; i++) {
          if (outputBuffer[0][i] > maxScore) {
            maxScore = outputBuffer[0][i];
            maxIndex = i;
          }
        }
        
        // Get food name from model labels (simplified example)
        // In a real app, you'd map this index to a food label from a file
        foodName = 'Food item $maxIndex';
        confidence = maxScore;
        
        if (maxScore > 0.7) {
          detectedItems.add(foodName);
        }
      }
      
      // Fall back or supplement with ML Kit image labeling
      if (_imageLabeler != null && (detectedItems.isEmpty || confidence < 0.8)) {
        final labels = await _imageLabeler!.processImage(inputImage);
        
        for (final label in labels) {
          detectedItems.add(label.label);
          
          // If we don't have a food name yet, use the highest confidence label
          if (foodName == null || label.confidence > confidence) {
            foodName = label.label;
            confidence = label.confidence;
          }
        }
      }
      
      // Check if any detected items match user allergens
      final List<String> detectedAllergens = _checkForAllergens(detectedItems, userAllergens);
      
      // Prepare the result
      String message;
      if (detectedAllergens.isEmpty) {
        message = 'No known allergens detected. This appears to be: ${foodName ?? 'Unknown food'}';
      } else {
        message = 'Warning: This food may contain: ${detectedAllergens.join(', ')}';
      }
      
      return DetectionResult(
        containsAllergens: detectedAllergens.isNotEmpty,
        detectedAllergens: detectedAllergens,
        detectedItems: detectedItems,
        foodName: foodName,
        confidence: confidence,
        message: message,
        imageType: ImageType.food,
      );
      
    } catch (e) {
      debugPrint('Error processing food image: $e');
      return DetectionResult(
        containsAllergens: false,
        detectedAllergens: [],
        detectedItems: [],
        confidence: 0.0,
        message: 'Could not identify the food in the image.',
        imageType: ImageType.food,
      );
    }
  }
  
  // Process an ingredient label using OCR
  static Future<DetectionResult> _processIngredientLabel(File imageFile, List<String> userAllergens) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      if (recognizedText.text.isEmpty) {
        return DetectionResult(
          containsAllergens: false,
          detectedAllergens: [],
          detectedItems: [],
          confidence: 0.0,
          message: 'No text detected in the image.',
          imageType: ImageType.ingredientLabel,
        );
      }
      
      // Extract words and clean up text
      final text = recognizedText.text.toLowerCase();
      final List<String> words = text
          .replaceAll(RegExp(r'[^\w\s,]'), ' ')
          .split(RegExp(r'\s+|,'))
          .where((word) => word.isNotEmpty)
          .toList();
      
      // Look for ingredients
      final List<String> detectedItems = [];
      for (final word in words) {
        if (word.length > 2 && !_commonFoodIngredients.contains(word)) {
          detectedItems.add(word);
        }
      }
      
      // Check for known allergens in the text
      final List<String> detectedAllergens = _checkForAllergens(detectedItems, userAllergens);
      
      // Also check for common allergens that might not be in the user's list
      for (final allergen in _commonAllergens) {
        if (text.contains(allergen) && !detectedAllergens.contains(allergen)) {
          detectedAllergens.add(allergen);
        }
      }
      
      // Add "contains" statements
      final RegExp containsPattern = RegExp(r'contains\s+([^.]+)', caseSensitive: false);
      final Match? containsMatch = containsPattern.firstMatch(text);
      
      if (containsMatch != null) {
        final String containsText = containsMatch.group(1) ?? '';
        final List<String> containsItems = containsText
            .split(RegExp(r'[,\s]+'))
            .where((item) => item.isNotEmpty && item.length > 2)
            .toList();
        
        for (final item in containsItems) {
          if (!detectedItems.contains(item)) {
            detectedItems.add(item);
          }
        }
      }
      
      // Prepare the result
      String message;
      if (detectedAllergens.isEmpty) {
        message = 'No allergens detected in the ingredient list.';
      } else {
        message = 'Warning: This product contains: ${detectedAllergens.join(', ')}';
      }
      
      return DetectionResult(
        containsAllergens: detectedAllergens.isNotEmpty,
        detectedAllergens: detectedAllergens,
        detectedItems: detectedItems,
        confidence: 0.9, // High confidence for text recognition
        message: message,
        imageType: ImageType.ingredientLabel,
      );
      
    } catch (e) {
      debugPrint('Error processing ingredient label: $e');
      return DetectionResult(
        containsAllergens: false,
        detectedAllergens: [],
        detectedItems: [],
        confidence: 0.0,
        message: 'Could not read the ingredient label properly.',
        imageType: ImageType.ingredientLabel,
      );
    }
  }
  
  // Helper method to check for allergens in a list of detected items
  static List<String> _checkForAllergens(List<String> detectedItems, List<String> userAllergens) {
    final List<String> detectedAllergens = [];
    
    // Normalize allergen lists for case-insensitive comparison
    final normalizedUserAllergens = userAllergens
        .map((a) => a.trim().toLowerCase())
        .toList();
    
    // Check each item if it matches or contains user allergens
    for (final item in detectedItems) {
      final normalizedItem = item.trim().toLowerCase();
      
      for (final allergen in normalizedUserAllergens) {
        // Check for direct match or if the item contains the allergen
        if (normalizedItem == allergen || 
            normalizedItem.contains(allergen) ||
            allergen.contains(normalizedItem)) {
          if (!detectedAllergens.contains(allergen)) {
            detectedAllergens.add(allergen);
          }
        }
      }
    }
    
    return detectedAllergens;
  }
  
  // Helper method to load and process an image for TensorFlow Lite
  static Future<List<List<List<List<double>>>>> _loadAndProcessImageForTensorFlow(File imageFile) async {
    // Load the image
    final imageBytes = await imageFile.readAsBytes();
    final image = img.decodeImage(imageBytes);
    
    if (image == null) {
      throw Exception('Failed to decode image');
    }
    
    // Resize to expected dimensions (224x224 for most models)
    final resizedImage = img.copyResize(image, width: 224, height: 224);
    
    // Normalize pixel values and convert to format expected by the model
    final imageMatrix = List.generate(
      1, 
      (_) => List.generate(
        224, 
        (y) => List.generate(
          224, 
          (x) => List.generate(
            3, 
            (c) {
              // Get a pixel from the image
              final pixel = resizedImage.getPixel(x, y);
              
              // Extract RGB components from pixel
              double value;
              if (c == 0) {
                // Red channel
                value = pixel.r.toDouble() / 255.0;
              } else if (c == 1) {
                // Green channel
                value = pixel.g.toDouble() / 255.0;
              } else {
                // Blue channel
                value = pixel.b.toDouble() / 255.0;
              }
              
              return value;
            }
          )
        )
      )
    );
    
    return imageMatrix;
  }
  
  // Cleanup resources
  static void dispose() {
    _textRecognizer.close();
    _imageLabeler?.close();
    _foodClassifierInterpreter?.close();
    _isInitialized = false;
  }
} 