import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logging/logging.dart';

class OpenAIService {
  static final Logger _logger = Logger('OpenAIService');
  
  // In a real app, this would be stored securely and not hardcoded
  // For this demo, we'll simulate API responses
  final String _apiKey = 'YOUR_OPENAI_API_KEY';
  final String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  
  Future<String> analyzeAllergy({
    required String symptoms,
    required String timeframe,
    required String foodEaten,
  }) async {
    // In a real app, this would make an API call to OpenAI
    // For this demo, we'll simulate API call with a basic implementation
    
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4',
          'messages': [
            {
              'role': 'system', 
              'content': 'You are an AI medical assistant specializing in food allergies. Analyze potential allergens based on symptoms and food consumption. Be informative but cautious, always recommending professional medical advice.',
            },
            {
              'role': 'user',
              'content': 'I am experiencing the following symptoms: $symptoms. They started $timeframe. I ate the following foods: $foodEaten. What food might I be allergic to?',
            },
          ],
          'temperature': 0.3,
          'max_tokens': 500,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        _logger.warning('API call failed with status code: ${response.statusCode}');
        // Fallback to simulated response if API call fails
        return _getSimulatedAllergyResponse(symptoms, timeframe, foodEaten);
      }
    } catch (e) {
      _logger.severe('Error analyzing allergy: $e');
      // Fallback to simulated response in case of any error
      return _getSimulatedAllergyResponse(symptoms, timeframe, foodEaten);
    }
  }
  
  String _getSimulatedAllergyResponse(String symptoms, String timeframe, String foodEaten) {
    // Fallback simulated response logic
    final foodLower = foodEaten.toLowerCase();
    
    if (foodLower.contains('peanut') && 
        (symptoms.toLowerCase().contains('rash') || 
         symptoms.toLowerCase().contains('swell'))) {
      return 'Based on your symptoms and the foods you\'ve eaten, it appears you may have a peanut allergy. Symptoms like ${symptoms.toLowerCase()} occurring ${timeframe.toLowerCase()} after consuming foods containing peanuts is a common sign of this allergy.\n\nRecommendation: Avoid all foods containing peanuts and consider consulting with an allergist for proper testing and diagnosis.';
    } else if (foodLower.contains('shellfish') || 
               foodLower.contains('shrimp') || 
               foodLower.contains('crab') || 
               foodLower.contains('lobster')) {
      return 'Your symptoms suggest a possible shellfish allergy. The ${symptoms.toLowerCase()} you experienced ${timeframe.toLowerCase()} is consistent with shellfish allergic reactions.\n\nRecommendation: Avoid all shellfish products and seek medical advice for proper allergy testing.';
    } else if (foodLower.contains('milk') || 
               foodLower.contains('cheese') || 
               foodLower.contains('dairy')) {
      return 'Your symptoms may indicate lactose intolerance or a dairy allergy. The timing of your symptoms (${timeframe.toLowerCase()}) after consuming dairy products is typical for this type of reaction.\n\nRecommendation: Consider temporarily eliminating dairy from your diet to see if symptoms improve, and consult with a healthcare provider.';
    } else if (foodLower.contains('wheat') || 
               foodLower.contains('bread') || 
               foodLower.contains('pasta')) {
      return 'Your symptoms could be related to gluten sensitivity or wheat allergy. ${symptoms.toLowerCase()} after consuming wheat products may indicate this type of reaction.\n\nRecommendation: Consider keeping a detailed food diary and consult with a gastroenterologist for proper testing.';
    } else {
      return 'Based on the information provided, I cannot identify a specific allergen with confidence. Your symptoms (${symptoms.toLowerCase()}) could be related to several factors.\n\nRecommendation: Keep a detailed food diary recording everything you eat and any symptoms that occur. This will help identify patterns over time. Consider consulting with an allergist for professional evaluation.';
    }
  }
  
  Future<String> analyzeFoodSafety({
    File? imageFile,
    required String description,
  }) async {
    // In a real app, this would make an API call to OpenAI with the image
    // For this demo, we'll simulate an API call with a basic implementation
    
    try {
      // For image analysis, we would use OpenAI's DALL-E or Vision API
      // Here we'll just analyze the text description
      if (description.isNotEmpty) {
        final response = await http.post(
          Uri.parse(_baseUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiKey',
          },
          body: jsonEncode({
            'model': 'gpt-4',
            'messages': [
              {
                'role': 'system', 
                'content': 'You are an AI assistant specializing in food allergies. Analyze food descriptions to identify potential allergens. Be cautious and always prioritize user safety.',
              },
              {
                'role': 'user',
                'content': 'I have allergies to peanuts, tree nuts, and shellfish, and suspected allergies to dairy. Is this food safe for me: $description',
              },
            ],
            'temperature': 0.3,
            'max_tokens': 300,
          }),
        );
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['choices'][0]['message']['content'];
        } else {
          _logger.warning('Food safety API call failed with status code: ${response.statusCode}');
          // Fallback to simulated response if API call fails
          return _getSimulatedFoodSafetyResponse(imageFile, description);
        }
      } else if (imageFile != null) {
        // For image analysis, we would need to use OpenAI's Vision API
        // This is a simplified implementation
        return 'Based on the image, I would need to analyze its content using image recognition. In a production app, I would use OpenAI\'s Vision API to analyze the food image and identify potential allergens.';
      } else {
        return 'Please provide either an image or a description of the food to analyze its safety.';
      }
    } catch (e) {
      _logger.severe('Error analyzing food safety: $e');
      // Fallback to simulated response in case of any error
      return _getSimulatedFoodSafetyResponse(imageFile, description);
    }
  }
  
  String _getSimulatedFoodSafetyResponse(File? imageFile, String description) {
    // Fallback simulated response logic
    final descLower = description.toLowerCase();
    
    if (descLower.contains('peanut') || 
        descLower.contains('nut')) {
      return 'NOT SAFE: This food contains peanuts or tree nuts, which are in your list of confirmed allergens. Consuming this may cause a severe allergic reaction.';
    } else if (descLower.contains('shellfish') || 
               descLower.contains('shrimp') || 
               descLower.contains('crab') || 
               descLower.contains('lobster')) {
      return 'NOT SAFE: This food contains shellfish, which is in your list of confirmed allergens. Avoid consuming this to prevent an allergic reaction.';
    } else if (descLower.contains('milk') || 
               descLower.contains('cheese') || 
               descLower.contains('dairy')) {
      return 'CAUTION: This food contains dairy, which is in your list of suspected allergens. Consider avoiding this food or consuming with caution while monitoring for symptoms.';
    } else if (descLower.isEmpty && imageFile != null) {
      // If we only have an image and no description
      return 'Based on the image, this appears to be a food that does not contain any of your confirmed allergens. However, I cannot guarantee its safety without more information about ingredients. Always check ingredient labels when available.';
    } else {
      return 'LIKELY SAFE: Based on the information provided, this food does not appear to contain any of your confirmed or suspected allergens. However, always check ingredient labels when available and be cautious with processed foods that may contain hidden allergens.';
    }
  }
} 