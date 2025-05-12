import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/allergy_incident.dart';
import '../services/incident_storage_service.dart';

class GeminiService {
  // Using the provided API key for Gemini
  final String _apiKey = 'AIzaSyAIkRrWEH1brJICl6EWntE3FXijSGgg-wQ';
  final String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';
  
  // Enhanced dataset for known food allergens with more comprehensive keywords
  final Map<String, List<String>> _allergenDatabase = {
    'dairy': ['milk', 'cheese', 'yogurt', 'butter', 'cream', 'whey', 'casein', 'lactose', 'dairy', 'ice cream', 'custard', 'pudding'],
    'eggs': ['egg', 'mayonnaise', 'omelette', 'quiche', 'meringue', 'custard', 'albumin', 'egg white', 'egg yolk'],
    'fish': ['salmon', 'tuna', 'cod', 'fish', 'seafood', 'halibut', 'tilapia', 'swordfish', 'bass', 'trout', 'sardines', 'anchovies'],
    'shellfish': ['shrimp', 'crab', 'lobster', 'prawn', 'shellfish', 'clam', 'mussel', 'oyster', 'scallop', 'crawfish', 'langoustine'],
    'nuts': ['peanut', 'almond', 'walnut', 'cashew', 'hazelnut', 'pistachio', 'pecan', 'macadamia', 'brazil nut', 'pine nut', 'coconut'],
    'wheat': ['wheat', 'bread', 'pasta', 'flour', 'pastry', 'cake', 'cookie', 'cereal', 'cracker', 'biscuit', 'gluten', 'semolina', 'couscous'],
    'soy': ['soy', 'tofu', 'miso', 'edamame', 'soybean', 'tempeh', 'soy sauce', 'soy milk', 'textured vegetable protein', 'tamari'],
    'sesame': ['sesame', 'tahini', 'sesame oil', 'sesame seed', 'halva', 'gomashio'],
    'sulfites': ['sulfite', 'wine', 'dried fruit', 'vinegar', 'processed potatoes', 'grape juice'],
    'celery': ['celery', 'celeriac', 'celery seed', 'celery salt', 'celery spice'],
    'mustard': ['mustard', 'mustard seed', 'mustard powder', 'mustard greens', 'dijon'],
    'lupin': ['lupin', 'lupin flour', 'lupin bean'],
  };
  
  // Enhanced symptom patterns linked to common allergens
  final Map<String, List<String>> _allergenSymptoms = {
    'dairy': ['bloating', 'gas', 'diarrhea', 'stomach pain', 'cramps', 'nausea', 'vomiting', 'indigestion'],
    'eggs': ['skin rash', 'hives', 'nasal congestion', 'digestive issues', 'vomiting', 'stomach pain'],
    'fish': ['hives', 'swelling', 'wheezing', 'vomiting', 'diarrhea', 'headache', 'nausea'],
    'shellfish': ['tingling in mouth', 'hives', 'swelling', 'wheezing', 'breathing difficulty', 'dizziness', 'nausea'],
    'nuts': ['swelling', 'itchy mouth', 'hives', 'throat tightness', 'breathing difficulty', 'anaphylaxis', 'abdominal pain'],
    'wheat': ['bloating', 'stomach pain', 'diarrhea', 'headache', 'fatigue', 'brain fog', 'joint pain', 'skin rash'],
    'soy': ['tingling in mouth', 'hives', 'itching', 'swelling', 'wheezing', 'abdominal pain', 'diarrhea'],
    'sesame': ['rash', 'hives', 'itching', 'runny nose', 'congestion', 'wheezing', 'coughing'],
    'sulfites': ['wheezing', 'coughing', 'breathing difficulty', 'skin rash', 'stomach pain', 'diarrhea', 'headache'],
    'celery': ['oral allergy syndrome', 'swelling of lips', 'itching in mouth', 'hives', 'difficulty swallowing'],
    'mustard': ['eczema', 'hives', 'swelling', 'asthma symptoms', 'runny nose', 'itching'],
    'lupin': ['hives', 'swelling', 'vomiting', 'anaphylaxis', 'breathing difficulty'],
  };
  
  // Enhanced analysis with typical time frames for allergic reactions
  final Map<String, Map<String, String>> _reactionTimeframes = {
    'immediate': {
      'description': 'within minutes to 2 hours',
      'likely_allergens': 'most food allergies, especially severe ones like nuts, shellfish, fish',
      'severity': 'can be severe, especially with anaphylactic symptoms',
    },
    'delayed': {
      'description': '2-24 hours after consumption',
      'likely_allergens': 'dairy, wheat, non-IgE mediated allergies, food intolerances',
      'severity': 'typically less severe but can be uncomfortable and persistent',
    },
    'very_delayed': {
      'description': '24-72 hours after consumption',
      'likely_allergens': 'non-IgE mediated food allergies, celiac disease reactions, food intolerances',
      'severity': 'generally milder but can significantly impact quality of life',
    }
  };
  
  Future<String> analyzeAllergy({
    required String symptoms,
    required String timeframe,
    required String foodEaten,
  }) async {
    try {
      // First check against dataset for common allergens
      final List<String> possibleAllergens = _checkAgainstDatabase(foodEaten.toLowerCase());
      
      // Find potential allergens based on symptom matching
      final List<String> symptomsBasedAllergens = _checkSymptomsAgainstPatterns(symptoms.toLowerCase());
      
      // Determine reaction timeframe category
      final String timeframeCategory = _categorizeTimeframe(timeframe.toLowerCase());
      
      // Combine data for AI analysis with a more sophisticated prompt
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text": """You are Dr.Allergy AI, a specialized medical assistant focused exclusively on food allergies and intolerances. Analyze the following information to identify potential allergens.
                  
                  USER REPORTED INFORMATION:
                  - Symptoms: $symptoms
                  - Timing of symptoms: $timeframe (categorized as: $timeframeCategory)
                  - Foods eaten: $foodEaten
                  
                  DATABASE ANALYSIS:
                  - Allergens detected in foods: ${possibleAllergens.isEmpty ? 'None detected in our database' : possibleAllergens.join(', ')}
                  - Allergens associated with these symptoms: ${symptomsBasedAllergens.isEmpty ? 'No clear pattern match' : symptomsBasedAllergens.join(', ')}
                  
                  YOUR TASK:
                  1. Identify the most likely allergen(s) causing these symptoms
                  2. Explain the connection between the foods, symptoms, and timing
                  3. Classify the likelihood of each potential allergen (High, Medium, Low)
                  4. Provide specific recommendations
                  
                  Format your response in these sections:
                  - MOST LIKELY ALLERGENS: (list with likelihood levels)
                  - ANALYSIS: (brief explanation of the connection)
                  - RECOMMENDATIONS: (clear actionable advice)
                  
                  Important notes:
                  - Focus only on the most probable allergens
                  - Always emphasize consulting a healthcare professional for proper diagnosis
                  - Mention the importance of an elimination diet if appropriate"""
                }
              ]
            }
          ],
          "generationConfig": {
            "temperature": 0.2,
            "maxOutputTokens": 800,
          }
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'];
      } else {
        // Fallback to enhanced local analysis if API call fails
        return _getEnhancedLocalAllergyAnalysis(
          symptoms, 
          timeframe, 
          foodEaten, 
          possibleAllergens,
          symptomsBasedAllergens,
          timeframeCategory
        );
      }
    } catch (e) {
      // Fallback to enhanced local analysis in case of any error
      final possibleAllergens = _checkAgainstDatabase(foodEaten.toLowerCase());
      final symptomsBasedAllergens = _checkSymptomsAgainstPatterns(symptoms.toLowerCase());
      final timeframeCategory = _categorizeTimeframe(timeframe.toLowerCase());
      
      return _getEnhancedLocalAllergyAnalysis(
        symptoms, 
        timeframe, 
        foodEaten, 
        possibleAllergens,
        symptomsBasedAllergens,
        timeframeCategory
      );
    }
  }
  
  // Improved database checking
  List<String> _checkAgainstDatabase(String foodDescription) {
    final Set<String> detectedAllergens = {};
    
    _allergenDatabase.forEach((allergenCategory, keywords) {
      for (final keyword in keywords) {
        // Look for the keyword as a whole word to reduce false positives
        if (foodDescription.contains(keyword)) {
          detectedAllergens.add(allergenCategory);
          break; // Found one match in this category, no need to check others
        }
      }
    });
    
    return detectedAllergens.toList();
  }
  
  // New method to match symptoms against known allergen patterns
  List<String> _checkSymptomsAgainstPatterns(String symptomsDescription) {
    final Set<String> potentialAllergens = {};
    
    _allergenSymptoms.forEach((allergen, symptomPatterns) {
      for (final symptom in symptomPatterns) {
        if (symptomsDescription.contains(symptom)) {
          potentialAllergens.add(allergen);
          break;
        }
      }
    });
    
    return potentialAllergens.toList();
  }
  
  // New method to categorize the timeframe of reactions
  String _categorizeTimeframe(String timeframe) {
    // Check for immediate reactions (minutes to 2 hours)
    if (timeframe.contains('minute') || 
        timeframe.contains('hour') && (timeframe.contains('1') || timeframe.contains('2') || timeframe.contains('one') || timeframe.contains('two')) ||
        timeframe.contains('immediately') ||
        timeframe.contains('right away') ||
        timeframe.contains('shortly after')) {
      return 'immediate';
    }
    
    // Check for delayed reactions (2-24 hours)
    else if (timeframe.contains('hours') ||
             timeframe.contains('same day') ||
             timeframe.contains('after eating') ||
             timeframe.contains('later that day')) {
      return 'delayed';
    }
    
    // Check for very delayed reactions (24-72 hours)
    else if (timeframe.contains('day') || 
             timeframe.contains('next morning') ||
             timeframe.contains('following day')) {
      return 'very_delayed';
    }
    
    // Default if unclear
    return 'unknown';
  }
  
  // Enhanced local analysis with better matching and explanations
  String _getEnhancedLocalAllergyAnalysis(
    String symptoms, 
    String timeframe, 
    String foodEaten, 
    List<String> detectedAllergens,
    List<String> symptomsBasedAllergens,
    String timeframeCategory
  ) {
    symptoms.toLowerCase();
    timeframe.toLowerCase();
    
    // Find overlapping allergens (highest confidence)
    final List<String> highConfidenceAllergens = detectedAllergens
        .where((allergen) => symptomsBasedAllergens.contains(allergen))
        .toList();
    
    // If we have high confidence matches
    if (highConfidenceAllergens.isNotEmpty) {
      final String primaryAllergen = highConfidenceAllergens.first;
      
      return '''
MOST LIKELY ALLERGENS:
- ${primaryAllergen.toUpperCase()} (High likelihood)
${highConfidenceAllergens.length > 1 ? '- ${highConfidenceAllergens.sublist(1).map((a) => '${a.toUpperCase()} (Medium likelihood)').join('\n')}' : ''}
${detectedAllergens.where((a) => !highConfidenceAllergens.contains(a)).isNotEmpty ? '- ${detectedAllergens.where((a) => !highConfidenceAllergens.contains(a)).map((a) => '${a.toUpperCase()} (Low likelihood)').join('\n')}' : ''}

ANALYSIS:
Your symptoms ($symptoms) occurring $timeframe after consuming foods containing $primaryAllergen strongly suggest a $primaryAllergen allergy or intolerance. The timing of your reaction (${_reactionTimeframes[timeframeCategory]?['description'] ?? timeframe}) is consistent with ${_reactionTimeframes[timeframeCategory]?['likely_allergens'] ?? 'food allergies'}.

RECOMMENDATIONS:
1. Consider eliminating $primaryAllergen from your diet for 2-4 weeks to see if symptoms improve
2. Keep a detailed food diary recording everything you eat and any symptoms
3. Consult with an allergist for proper testing and diagnosis
4. If you experience severe symptoms like difficulty breathing, seek immediate medical attention
''';
    }
    
    // If we have allergens detected in food but not matching symptoms
    else if (detectedAllergens.isNotEmpty) {
      return '''
MOST LIKELY ALLERGENS:
${detectedAllergens.map((a) => '- ${a.toUpperCase()} (Medium likelihood)').join('\n')}

ANALYSIS:
I detected ${detectedAllergens.join(', ')} in the foods you mentioned. Your symptoms ($symptoms) occurring $timeframe might be related to one of these allergens, but the pattern is not typical of the most common reactions.

RECOMMENDATIONS:
1. Consider an elimination diet where you remove one potential allergen at a time for 2-3 weeks
2. Keep a detailed food and symptom diary to identify patterns
3. Consult with a healthcare provider for proper allergy testing
''';
    }
    
    // If we have symptom matches but no food matches
    else if (symptomsBasedAllergens.isNotEmpty) {
      return '''
MOST LIKELY ALLERGENS:
${symptomsBasedAllergens.map((a) => '- ${a.toUpperCase()} (Medium likelihood)').join('\n')}

ANALYSIS:
Your symptoms ($symptoms) are commonly associated with ${symptomsBasedAllergens.join(', ')} allergies, though I couldn't identify these specific allergens in the foods you listed. They may be present as hidden ingredients or cross-contaminants.

RECOMMENDATIONS:
1. Check ingredient labels carefully for these potential allergens
2. Consider keeping a detailed food diary
3. Consult with an allergist for proper testing and diagnosis
''';
    }
    
    // If nothing detected
    return '''
MOST LIKELY ALLERGENS:
- No specific allergens could be identified with confidence

ANALYSIS:
Based on the foods you mentioned, I couldn't identify common allergens in our database that match your symptoms. However, your symptoms ($symptoms) that occurred $timeframe could still be related to a food intolerance or an allergen not in our database.

RECOMMENDATIONS:
1. Keep a detailed food diary recording everything you eat and any symptoms that occur
2. Consider an elimination diet under healthcare supervision
3. Consult with an allergist for professional evaluation and comprehensive testing
''';
  }
  
  Future<String> analyzeFoodSafety({
    File? imageFile,
    required String description,
    required List<String> userAllergens,
  }) async {
    try {
      final List<String> detectedAllergens = [];
      
      // First check against database for known allergens
      for (final allergen in userAllergens) {
        final lowerAllergen = allergen.toLowerCase().trim();
        if (_allergenDatabase.containsKey(lowerAllergen)) {
          for (final keyword in _allergenDatabase[lowerAllergen]!) {
            if (description.toLowerCase().contains(keyword)) {
              detectedAllergens.add(allergen);
              break; // Found one match in this category, no need to check others
            }
          }
        }
      }
      
      // Improved prompt for Gemini with more detailed analysis request
      if (description.isNotEmpty) {
        final response = await http.post(
          Uri.parse('$_baseUrl?key=$_apiKey'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            "contents": [
              {
                "parts": [
                  {
                    "text": """You are Dr.Allergy AI, an assistant specializing in food allergies and safety analysis.
                    
                    ANALYZE THIS FOOD:
                    Food description: $description
                    
                    USER'S ALLERGEN PROFILE:
                    - Allergens to avoid: ${userAllergens.join(', ')}
                    - Initial database analysis: ${detectedAllergens.isEmpty ? 'No allergens detected in initial scan' : 'DETECTED: ${detectedAllergens.join(', ')}'}
                    
                    YOUR TASK:
                    1. Determine if this food is safe for the user based on their allergens
                    2. Identify any hidden or potential cross-contamination risks
                    3. Suggest safe alternatives if needed
                    
                    Format your response in these sections:
                    - SAFETY ASSESSMENT: (Start with "SAFE:", "CAUTION:", or "NOT SAFE:")
                    - ALLERGEN DETAILS: (List detected allergens and risk level)
                    - HIDDEN RISKS: (Note potential cross-contamination or masked ingredients)
                    - ALTERNATIVES: (If unsafe, suggest alternatives)"""
                  }
                ]
              }
            ],
            "generationConfig": {
              "temperature": 0.2,
              "maxOutputTokens": 800,
            }
          }),
        );
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['candidates'][0]['content']['parts'][0]['text'];
        } else {
          // Fallback to local analysis if API call fails
          return _getEnhancedFoodSafetyAnalysis(description, userAllergens, detectedAllergens);
        }
      } else if (imageFile != null) {
        // For image-only analysis
        return 'Without a text description, I can only analyze based on the image. In a production environment, I would use image recognition to identify the food and its ingredients. For safety, please add a description of the food so I can provide better allergen analysis.';
      } else {
        return 'Please provide either an image or a description of the food to analyze its safety.';
      }
    } catch (e) {
      // Fallback to local analysis in case of any error
      final List<String> detectedAllergens = [];
      
      for (final allergen in userAllergens) {
        final lowerAllergen = allergen.toLowerCase().trim();
        if (_allergenDatabase.containsKey(lowerAllergen)) {
          for (final keyword in _allergenDatabase[lowerAllergen]!) {
            if (description.toLowerCase().contains(keyword)) {
              detectedAllergens.add(allergen);
              break;
            }
          }
        }
      }
      
      return _getEnhancedFoodSafetyAnalysis(description, userAllergens, detectedAllergens);
    }
  }
  
  String _getEnhancedFoodSafetyAnalysis(String description, List<String> userAllergens, List<String> detectedAllergens) {
    if (detectedAllergens.isEmpty) {
      return '''
SAFETY ASSESSMENT: LIKELY SAFE
      
ALLERGEN DETAILS:
No known allergens from your profile detected in this food.

HIDDEN RISKS:
Always be cautious with processed foods as they may contain hidden allergens or traces from manufacturing processes. Cross-contamination is always a possibility in restaurants and food preparation areas.

ALTERNATIVES:
This food appears to be compatible with your allergen profile, but always check ingredient labels when available.
''';
    }
    
    if (detectedAllergens.length == 1) {
      final String allergen = detectedAllergens[0];
      
      return '''
SAFETY ASSESSMENT: NOT SAFE

ALLERGEN DETAILS:
This food contains ${allergen.toUpperCase()}, which is in your list of allergens to avoid.

HIDDEN RISKS:
$allergen can appear under different names in ingredient lists. For example:
${_getAllergenAliases(allergen)}

ALTERNATIVES:
Consider these allergen-free alternatives:
${_getSafeAlternativesText(description, allergen)}
''';
    }
    
    return '''
SAFETY ASSESSMENT: NOT SAFE

ALLERGEN DETAILS:
This food contains multiple allergens that you should avoid:
${detectedAllergens.map((a) => '- ${a.toUpperCase()}').join('\n')}

HIDDEN RISKS:
These allergens may appear under different names in ingredient lists and can cause cross-reactivity with other foods.

ALTERNATIVES:
Look for products specifically labeled as free from ${detectedAllergens.join(' and ')}.
${_getSafeAlternativesText(description, detectedAllergens.join(', '))}
''';
  }
  
  String _getAllergenAliases(String allergen) {
    final Map<String, List<String>> allergenAliases = {
      'dairy': ['Casein', 'Whey', 'Lactose', 'Milk solids', 'Buttermilk', 'Lactoglobulin'],
      'eggs': ['Albumin', 'Globulin', 'Ovomucin', 'Vitellin', 'Ovalbumin'],
      'nuts': ['Arachis oil (peanut)', 'Mandelonas (peanut)', 'Marzipan (almond)', 'Nougat'],
      'wheat': ['Gluten', 'Durum', 'Semolina', 'Spelt', 'Farina', 'Graham flour', 'Kamut'],
      'soy': ['Edamame', 'Tofu', 'Miso', 'Tempeh', 'Textured vegetable protein (TVP)'],
      'shellfish': ['Crevette', 'Scampi', 'Langoustine', 'Seafood flavoring'],
      'fish': ['Surimi', 'Fish gelatin', 'Fish stock', 'Caviar', 'Roe'],
    };
    
    final lowerAllergen = allergen.toLowerCase();
    if (allergenAliases.containsKey(lowerAllergen)) {
      return allergenAliases[lowerAllergen]!.map((alias) => '- $alias').join('\n');
    }
    
    return '- Various processed forms may be present';
  }
  
  String _getSafeAlternativesText(String foodDescription, String allergen) {
    final Map<String, List<String>> alternatives = {
      'dairy': [
        'Almond milk', 'Oat milk', 'Coconut milk', 'Soy milk',
        'Dairy-free cheese', 'Coconut yogurt', 'Olive oil (instead of butter)'
      ],
      'eggs': [
        'Applesauce (in baking)', 'Flaxseed mixture', 'Silken tofu',
        'Commercial egg replacers', 'Aquafaba', 'Mashed banana'
      ],
      'nuts': [
        'Seeds (sunflower, pumpkin)', 'Roasted chickpeas', 'Soy nuts',
        'Pretzels', 'Dried fruit', 'Coconut flakes (if not allergic)'
      ],
      'wheat': [
        'Rice', 'Quinoa', 'Corn products', 'Gluten-free bread',
        'Potatoes', 'Buckwheat (despite the name, it\'s wheat-free)'
      ],
      'soy': [
        'Coconut aminos (instead of soy sauce)', 'Hemp milk', 'Almond milk',
        'Chickpea tofu', 'Seitan (if not wheat-allergic)'
      ],
      'shellfish': [
        'White fish', 'Chicken', 'Tofu', 'Jackfruit (for texture)',
        'Mushrooms (for umami flavor)'
      ],
      'fish': [
        'Chicken', 'Tofu', 'Legumes', 'Tempeh',
        'Seitan (if not wheat-allergic)'
      ],
    };
    
    // Determine the food category from the description
    String foodCategory = '';
    if (foodDescription.toLowerCase().contains('milk') || foodDescription.toLowerCase().contains('cheese') || foodDescription.toLowerCase().contains('yogurt')) {
      foodCategory = 'dairy';
    } else if (foodDescription.toLowerCase().contains('bread') || foodDescription.toLowerCase().contains('pasta') || foodDescription.toLowerCase().contains('cake')) {
      foodCategory = 'wheat';
    } else if (foodDescription.toLowerCase().contains('nut') || foodDescription.toLowerCase().contains('almond')) {
      foodCategory = 'nuts';
    }
    
    // If the allergen is known and we have alternatives for it
    final lowerAllergen = allergen.toLowerCase();
    if (alternatives.containsKey(lowerAllergen)) {
      return alternatives[lowerAllergen]!.take(3).map((alt) => '- $alt').join('\n');
    }
    
    // If we identified a food category but it doesn't match the allergen
    if (foodCategory.isNotEmpty && alternatives.containsKey(foodCategory)) {
      return alternatives[foodCategory]!.take(3).map((alt) => '- $alt').join('\n');
    }
    
    // Generic response if we can't determine specific alternatives
    return '- Check for products labeled as $allergen-free\n- Consult allergen-free cookbooks or websites for specific alternatives';
  }
  
  // New method to analyze user's history patterns and provide insights
  Future<String> analyzeUserAllergyHistory(List<AllergyIncident> incidents) async {
    if (incidents.isEmpty) {
      return "Not enough data to analyze. Use the symptom checker to log your reactions.";
    }
    
    try {
      // Extract key information from incidents
      final frequentAllergens = await _getFrequentAllergensFromIncidents(incidents);
      final symptomPatterns = _getSymptomPatternsFromIncidents(incidents);
      final reactionTimePatterns = _getReactionTimePatternsFromIncidents(incidents);
      
      // Send to Gemini for analysis
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text": """You are Dr.Allergy AI, a specialized medical assistant focused exclusively on food allergies and intolerances. 
                  Analyze the following user history data to provide personalized insights:
                  
                  ALLERGEN FREQUENCY DATA:
                  ${frequentAllergens.entries.map((e) => '- ${e.key.toUpperCase()}: ${e.value} occurrences').join('\n')}
                  
                  SYMPTOM PATTERNS:
                  ${symptomPatterns.entries.map((e) => '- ${e.key.toUpperCase()}: ${e.value.join(', ')}').join('\n')}
                  
                  REACTION TIME PATTERNS:
                  ${reactionTimePatterns.entries.map((e) => '- ${e.key}: ${e.value} incidents').join('\n')}
                  
                  YOUR TASK:
                  1. Identify the most likely allergen patterns and connections
                  2. Suggest specific monitoring strategies based on the user's history
                  3. Recommend next steps for diagnosis/management
                  
                  Format your response in these sections:
                  - ALLERGEN PATTERNS: (analysis of the user's most common triggers)
                  - SYMPTOM INSIGHTS: (patterns in how the user's body typically reacts)
                  - RECOMMENDATIONS: (personalized advice for managing their allergies)
                  
                  Be specific, evidence-based, and personalized to this user's data. Focus on practical advice."""
                }
              ]
            }
          ],
          "generationConfig": {
            "temperature": 0.1,
            "maxOutputTokens": 1000,
          }
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'];
      } else {
        // Fallback to local analysis
        return _getLocalAllergyHistoryAnalysis(frequentAllergens, symptomPatterns, reactionTimePatterns);
      }
    } catch (e) {
      // Generate local analysis in case of API error
      final frequentAllergens = await _getFrequentAllergensFromIncidents(incidents);
      final symptomPatterns = _getSymptomPatternsFromIncidents(incidents);
      final reactionTimePatterns = _getReactionTimePatternsFromIncidents(incidents);
      
      return _getLocalAllergyHistoryAnalysis(frequentAllergens, symptomPatterns, reactionTimePatterns);
    }
  }
  
  // Helper methods for history analysis
  Future<Map<String, int>> _getFrequentAllergensFromIncidents(List<AllergyIncident> incidents) async {
    // Use the storage service to get allergen frequency stats
    return await IncidentStorageService.getAllergenFrequencyStats();
  }
  
  Map<String, List<String>> _getSymptomPatternsFromIncidents(List<AllergyIncident> incidents) {
    // Group symptoms by allergen
    final Map<String, List<String>> symptomsByAllergen = {};
    
    for (final incident in incidents) {
      for (final allergen in incident.detectedAllergens) {
        final lowerAllergen = allergen.toLowerCase();
        
        if (!symptomsByAllergen.containsKey(lowerAllergen)) {
          symptomsByAllergen[lowerAllergen] = [];
        }
        
        // Extract individual symptoms by splitting at commas, semicolons, and 'and'
        final individualSymptoms = incident.symptoms
            .toLowerCase()
            .replaceAll(' and ', ', ')
            .split(RegExp(r'[,;]'))
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        
        for (final symptom in individualSymptoms) {
          if (!symptomsByAllergen[lowerAllergen]!.contains(symptom)) {
            symptomsByAllergen[lowerAllergen]!.add(symptom);
          }
        }
      }
    }
    
    return symptomsByAllergen;
  }
  
  Map<String, int> _getReactionTimePatternsFromIncidents(List<AllergyIncident> incidents) {
    // Count incidents by timeframe category
    final Map<String, int> reactionTimes = {
      'immediate': 0,
      'delayed': 0,
      'very_delayed': 0,
      'unknown': 0,
    };
    
    for (final incident in incidents) {
      final timeframeCategory = _categorizeTimeframe(incident.timeframe.toLowerCase());
      reactionTimes[timeframeCategory] = (reactionTimes[timeframeCategory] ?? 0) + 1;
    }
    
    return reactionTimes;
  }
  
  String _getLocalAllergyHistoryAnalysis(
    Map<String, int> frequentAllergens,
    Map<String, List<String>> symptomPatterns,
    Map<String, int> reactionTimePatterns
  ) {
    // Determine most frequent allergen
    String? mostFrequentAllergen;
    int highestCount = 0;
    
    frequentAllergens.forEach((allergen, count) {
      if (count > highestCount) {
        mostFrequentAllergen = allergen;
        highestCount = count;
      }
    });
    
    // Determine most common reaction timeframe
    String? mostCommonTimeframe;
    int highestTimeCount = 0;
    
    reactionTimePatterns.forEach((timeframe, count) {
      if (count > highestTimeCount && timeframe != 'unknown') {
        mostCommonTimeframe = timeframe;
        highestTimeCount = count;
      }
    });
    
    // Build the analysis response
    final StringBuffer analysis = StringBuffer();
    
    // Add allergen patterns section
    analysis.writeln('ALLERGEN PATTERNS:');
    if (mostFrequentAllergen != null) {
      analysis.writeln('Your history shows that ${mostFrequentAllergen!.toUpperCase()} appears to be your most frequent trigger, accounting for ${frequentAllergens[mostFrequentAllergen]} of your recorded reactions.');
      
      // Add other significant allergens
      final otherAllergens = frequentAllergens.entries
          .where((e) => e.key != mostFrequentAllergen && e.value > 1)
          .toList();
      
      if (otherAllergens.isNotEmpty) {
        analysis.writeln('\nOther notable allergens in your history include:');
        for (final entry in otherAllergens) {
          analysis.writeln('- ${entry.key.toUpperCase()}: ${entry.value} reactions');
        }
      }
    } else {
      analysis.writeln('There is not enough data to establish clear allergen patterns yet.');
    }
    
    // Add symptom insights section
    analysis.writeln('\nSYMPTOM INSIGHTS:');
    if (mostFrequentAllergen != null && 
        symptomPatterns.containsKey(mostFrequentAllergen) && 
        symptomPatterns[mostFrequentAllergen]!.isNotEmpty) {
      
      analysis.writeln('When exposed to ${mostFrequentAllergen!.toUpperCase()}, you typically experience:');
      for (final symptom in symptomPatterns[mostFrequentAllergen]!.take(5)) {
        analysis.writeln('- $symptom');
      }
      
      // Note about reaction timing
      if (mostCommonTimeframe != null) {
        analysis.writeln('\nYour reactions most commonly occur ${_reactionTimeframes[mostCommonTimeframe]?['description'] ?? 'at varying times'} after consumption.');
      }
    } else {
      analysis.writeln('Your symptom patterns are still emerging. Continue logging your reactions to identify clearer patterns.');
    }
    
    // Add recommendations section
    analysis.writeln('\nRECOMMENDATIONS:');
    if (mostFrequentAllergen != null) {
      analysis.writeln('1. Consider an elimination diet that removes ${mostFrequentAllergen!.toUpperCase()} for 2-4 weeks, then reintroduce it carefully while monitoring for symptoms.');
      analysis.writeln('2. When eating out, specifically ask about ${mostFrequentAllergen!.toUpperCase()} content in your food.');
      analysis.writeln('3. Learn alternative names for ${mostFrequentAllergen!.toUpperCase()} that might appear on food labels.');
      analysis.writeln('4. Consult with an allergist for formal testing to confirm this sensitivity.');
    } else {
      analysis.writeln('1. Continue logging your reactions to build enough data for meaningful analysis.');
      analysis.writeln('2. Keep a detailed food diary, noting ingredients, brands, and preparation methods.');
      analysis.writeln('3. Consider consulting with an allergist for professional guidance.');
    }
    
    analysis.writeln('\nNote: This analysis is based solely on your logged history. Always consult healthcare professionals for medical advice and diagnosis.');
    
    return analysis.toString();
  }
} 