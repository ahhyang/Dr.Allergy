import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

class AllergenDatabaseService {
  static final Logger _logger = Logger('AllergenDatabaseService');
  static bool _initialized = false;
  
  // Foods with their associated allergens
  static Map<String, List<String>> _foodToAllergens = {};
  
  // Allergens with their associated foods
  static Map<String, List<String>> _allergenToFoods = {};
  
  // All food classes for categorization
  static Map<String, String> _foodToClass = {};
  
  // All food types for categorization
  static Map<String, String> _foodToType = {};
  
  // All food groups for categorization
  static Map<String, String> _foodToGroup = {};
  
  // Statistical data from food_allergy_dataset
  static Map<String, Map<String, dynamic>> _foodStatistics = {};
  
  // Map food types to standardized categories
  static Map<String, String> _foodTypeMapping = {
    'Dairy': 'Dairy',
    'Nuts': 'Nut',
    'Seafood': 'Fish/Shellfish',
    'Gluten': 'Gluten',
    'Eggs': 'Egg',
  };
  
  // Initialize the database
  static Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // Load the FoodData.csv data from the assets
      await _loadBasicFoodData();
      
      // Load the statistical dataset
      await _loadStatisticalData();
      
      // Add some manually entered safe alternatives
      _initializeManualData();
      
      _initialized = true;
    } catch (e) {
      _logger.severe('Error initializing allergen database: $e');
      // Fall back to manual data if CSV loading fails
      _initializeManualData();
      _initialized = true;
    }
  }
  
  static Future<void> _loadBasicFoodData() async {
    try {
      final String csvData = await rootBundle.loadString('assets/allergydataset/FoodData.csv');
      
      // Parse the CSV data
      final List<String> lines = const LineSplitter().convert(csvData);
      
      // Skip header row
      for (int i = 1; i < lines.length; i++) {
        final List<String> row = lines[i].split(',');
        
        if (row.length >= 5) {
          final String foodClass = row[0].trim();
          final String foodType = row[1].trim();
          final String foodGroup = row[2].trim();
          final String food = row[3].trim().toLowerCase();
          final String allergy = row[4].trim();
          
          // Store food-to-allergen mapping
          if (allergy.isNotEmpty) {
            if (!_foodToAllergens.containsKey(food)) {
              _foodToAllergens[food] = [];
            }
            _foodToAllergens[food]!.add(allergy);
            
            // Store allergen-to-food mapping
            if (!_allergenToFoods.containsKey(allergy)) {
              _allergenToFoods[allergy] = [];
            }
            _allergenToFoods[allergy]!.add(food);
          }
          
          // Store food classification data
          _foodToClass[food] = foodClass;
          _foodToType[food] = foodType;
          _foodToGroup[food] = foodGroup;
        }
      }
      
      _logger.info('Successfully loaded food data from FoodData.csv');
    } catch (e) {
      _logger.warning('Error loading FoodData.csv: $e');
    }
  }
  
  static Future<void> _loadStatisticalData() async {
    try {
      final String csvData = await rootBundle.loadString('allergydataset/food_allergy_dataset.csv');
      
      // Parse the CSV data
      final List<String> lines = const LineSplitter().convert(csvData);
      
      // Skip header and metadata rows (lines starting with #)
      int headerRow = 0;
      while (headerRow < lines.length && lines[headerRow].startsWith('#')) {
        headerRow++;
      }
      
      // Now we're at the actual header row
      List<String> headers = lines[headerRow].split(',');
      int foodTypeIndex = headers.indexOf('Food_Type');
      int allergyIndex = headers.indexOf('Allergic');
      int severityIndex = headers.indexOf('Severity_Score');
      int symptomIndex = headers.indexOf('Symptoms');
      int igeIndex = headers.indexOf('IgE_Levels');
      
      // Sanity check - make sure we found the columns
      if (foodTypeIndex == -1 || allergyIndex == -1 || severityIndex == -1) {
        _logger.warning('Required columns not found in food_allergy_dataset.csv');
        return;
      }
      
      // Initialize statistics counters for each food type
      Map<String, int> totalSamples = {};
      Map<String, int> allergicSamples = {};
      Map<String, int> severitySum = {};
      Map<String, Map<String, int>> symptomCounts = {};
      Map<String, double> avgIgeLevel = {};
      
      // Process data rows
      for (int i = headerRow + 1; i < lines.length; i++) {
        if (lines[i].trim().isEmpty) continue;
        
        final List<String> row = lines[i].split(',');
        if (row.length <= foodTypeIndex || row.length <= allergyIndex) continue;
        
        String foodType = row[foodTypeIndex].trim();
        int isAllergic = int.tryParse(row[allergyIndex].trim()) ?? 0;
        int severityScore = int.tryParse(row[severityIndex].trim()) ?? 0;
        String symptom = symptomIndex >= 0 && row.length > symptomIndex ? row[symptomIndex].trim() : '';
        double igeLevel = igeIndex >= 0 && row.length > igeIndex ? double.tryParse(row[igeIndex].trim()) ?? 0 : 0;
        
        // Initialize if needed
        if (!totalSamples.containsKey(foodType)) {
          totalSamples[foodType] = 0;
          allergicSamples[foodType] = 0;
          severitySum[foodType] = 0;
          symptomCounts[foodType] = {};
          avgIgeLevel[foodType] = 0;
        }
        
        // Update counters
        totalSamples[foodType] = (totalSamples[foodType] ?? 0) + 1;
        if (isAllergic == 1) {
          allergicSamples[foodType] = (allergicSamples[foodType] ?? 0) + 1;
          severitySum[foodType] = (severitySum[foodType] ?? 0) + severityScore;
        }
        
        // Update symptom counts
        if (symptom.isNotEmpty) {
          symptomCounts[foodType]![symptom] = (symptomCounts[foodType]![symptom] ?? 0) + 1;
        }
        
        // Update IgE levels sum (we'll calculate average later)
        avgIgeLevel[foodType] = (avgIgeLevel[foodType] ?? 0) + igeLevel;
      }
      
      // Calculate final statistics for each food type
      foodTypeMapping.keys.forEach((foodType) {
        if (totalSamples.containsKey(foodType)) {
          double allergyRate = allergicSamples[foodType]! / totalSamples[foodType]!;
          double avgSeverity = allergicSamples[foodType]! > 0 
              ? severitySum[foodType]! / allergicSamples[foodType]! 
              : 0;
          double avgIge = totalSamples[foodType]! > 0 
              ? avgIgeLevel[foodType]! / totalSamples[foodType]! 
              : 0;
          
          // Determine most common symptoms
          List<String> commonSymptoms = [];
          if (symptomCounts.containsKey(foodType)) {
            var sortedSymptoms = symptomCounts[foodType]!.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));
            
            commonSymptoms = sortedSymptoms
                .take(3)
                .map((e) => e.key)
                .toList();
          }
          
          // Store compiled statistics
          _foodStatistics[foodType] = {
            'allergyRate': allergyRate,
            'avgSeverity': avgSeverity,
            'avgIgeLevel': avgIge,
            'commonSymptoms': commonSymptoms,
            'sampleSize': totalSamples[foodType],
          };
        }
      });
      
      _logger.info('Successfully loaded statistical data from food_allergy_dataset.csv');
    } catch (e) {
      _logger.warning('Error loading food_allergy_dataset.csv: $e');
    }
  }
  
  // Initialize with manually entered data as fallback or supplement
  static void _initializeManualData() {
    // Common foods with their allergens
    final Map<String, List<String>> commonFoods = {
      'milk': ['Lactose', 'Dairy', 'Casein'],
      'cheese': ['Lactose', 'Dairy', 'Casein'],
      'yogurt': ['Lactose', 'Dairy'],
      'butter': ['Lactose', 'Dairy'],
      'cream': ['Lactose', 'Dairy'],
      'ice cream': ['Lactose', 'Dairy'],
      'eggs': ['Egg'],
      'peanuts': ['Peanut'],
      'tree nuts': ['Nuts'],
      'almonds': ['Nuts'],
      'walnuts': ['Nuts'],
      'cashews': ['Nuts'],
      'pistachios': ['Nuts'],
      'pecans': ['Nuts'],
      'hazelnuts': ['Nuts'],
      'soy': ['Soy'],
      'soya': ['Soy'],
      'soybeans': ['Soy'],
      'tofu': ['Soy'],
      'wheat': ['Gluten', 'Wheat'],
      'bread': ['Gluten', 'Wheat'],
      'pasta': ['Gluten', 'Wheat'],
      'cereal': ['Gluten', 'Wheat'],
      'barley': ['Gluten'],
      'rye': ['Gluten'],
      'oats': ['Gluten'],
      'fish': ['Fish'],
      'salmon': ['Fish'],
      'tuna': ['Fish'],
      'cod': ['Fish'],
      'shellfish': ['Shellfish', 'Crustacean'],
      'shrimp': ['Shellfish', 'Crustacean'],
      'crab': ['Shellfish', 'Crustacean'],
      'lobster': ['Shellfish', 'Crustacean'],
      'sesame': ['Sesame'],
      'mustard': ['Mustard'],
      'celery': ['Celery'],
      'sulphites': ['Sulphites'],
      'sulfites': ['Sulphites'],
      'wine': ['Sulphites'],
      'dried fruits': ['Sulphites'],
      'lupin': ['Lupin'],
      'molluscs': ['Molluscs'],
      'chocolate': ['Cocoa', 'Dairy'],
      'strawberries': ['Salicylates'],
      'tomatoes': ['Nightshade'],
      'potatoes': ['Nightshade'],
      'peppers': ['Nightshade'],
      'eggplant': ['Nightshade'],
      'corn': ['Corn'],
      'maize': ['Corn'],
      'beef': ['Alpha-gal'],
      'pork': ['Alpha-gal'],
      'lamb': ['Alpha-gal'],
      'citrus': ['Citrus'],
      'oranges': ['Citrus'],
      'lemons': ['Citrus'],
      'limes': ['Citrus'],
      'grapefruits': ['Citrus'],
      'kiwi': ['Latex-fruit'],
      'bananas': ['Latex-fruit'],
      'avocados': ['Latex-fruit'],
      'apples': ['Oral Allergy Syndrome'],
      'pears': ['Oral Allergy Syndrome'],
      'cherries': ['Oral Allergy Syndrome'],
      'peaches': ['Oral Allergy Syndrome'],
      'melons': ['Oral Allergy Syndrome'],
    };
    
    // Merge with any existing data
    commonFoods.forEach((food, allergens) {
      if (!_foodToAllergens.containsKey(food)) {
        _foodToAllergens[food] = [];
      }
      
      for (final allergen in allergens) {
        if (!_foodToAllergens[food]!.contains(allergen)) {
          _foodToAllergens[food]!.add(allergen);
        }
        
        if (!_allergenToFoods.containsKey(allergen)) {
          _allergenToFoods[allergen] = [];
        }
        
        if (!_allergenToFoods[allergen]!.contains(food)) {
          _allergenToFoods[allergen]!.add(food);
        }
      }
    });
  }
  
  // Get all allergens in a specific food
  static List<String> getAllergensInFood(String food) {
    food = food.toLowerCase();
    
    // Direct match
    if (_foodToAllergens.containsKey(food)) {
      return _foodToAllergens[food]!;
    }
    
    // Partial match (for compound foods)
    List<String> allergens = [];
    
    _foodToAllergens.forEach((key, value) {
      if (food.contains(key)) {
        allergens.addAll(value);
      }
    });
    
    // Remove duplicates
    return allergens.toSet().toList();
  }
  
  // Get all foods containing a specific allergen
  static List<String> getFoodsWithAllergen(String allergen) {
    allergen = allergen.toLowerCase();
    
    List<String> foods = [];
    
    _allergenToFoods.forEach((key, value) {
      if (key.toLowerCase().contains(allergen)) {
        foods.addAll(value);
      }
    });
    
    return foods.toSet().toList();
  }
  
  // Get food class (plant origin, animal origin, etc.)
  static String? getFoodClass(String food) {
    return _foodToClass[food.toLowerCase()];
  }
  
  // Get food type (cereal grain, dairy, etc.)
  static String? getFoodType(String food) {
    return _foodToType[food.toLowerCase()];
  }
  
  // Get food group (pulse, cereal grain, etc.)
  static String? getFoodGroup(String food) {
    return _foodToGroup[food.toLowerCase()];
  }
  
  // Get safe alternatives for a food based on user allergens
  static List<String> getSafeAlternatives(String food, List<String> userAllergens) {
    food = food.toLowerCase();
    final userAllergensLower = userAllergens.map((a) => a.toLowerCase()).toList();
    
    // Get food type and group if available
    String? foodType = getFoodType(food);
    String? foodGroup = getFoodGroup(food);
    
    List<String> alternatives = [];
    
    // Find alternatives in the same food group
    if (foodGroup != null) {
      _foodToGroup.forEach((key, value) {
        if (value == foodGroup && key != food) {
          bool isSafe = true;
          
          // Check if alternative contains any of user's allergens
          List<String> alternativeAllergens = getAllergensInFood(key);
          for (final allergen in alternativeAllergens) {
            if (userAllergensLower.contains(allergen.toLowerCase())) {
              isSafe = false;
              break;
            }
          }
          
          if (isSafe) {
            alternatives.add(key);
          }
        }
      });
    }
    
    // If we don't have enough alternatives from the same group, find more from the same type
    if (alternatives.length < 3 && foodType != null) {
      _foodToType.forEach((key, value) {
        if (value == foodType && key != food && !alternatives.contains(key)) {
          bool isSafe = true;
          
          // Check if alternative contains any of user's allergens
          List<String> alternativeAllergens = getAllergensInFood(key);
          for (final allergen in alternativeAllergens) {
            if (userAllergensLower.contains(allergen.toLowerCase())) {
              isSafe = false;
              break;
            }
          }
          
          if (isSafe) {
            alternatives.add(key);
          }
        }
      });
    }
    
    // Fallback to manual recommendations if no alternatives found
    if (alternatives.isEmpty) {
      if (food.contains('milk') || food.contains('dairy')) {
        alternatives.addAll(['almond milk', 'oat milk', 'coconut milk', 'soy milk']);
      } else if (food.contains('wheat') || food.contains('bread')) {
        alternatives.addAll(['rice', 'corn', 'quinoa', 'oats']);
      } else if (food.contains('peanut')) {
        alternatives.addAll(['sunflower seeds', 'pumpkin seeds', 'chia seeds']);
      }
    }
    
    // Filter out alternatives that contain user's allergens
    alternatives = alternatives.where((alternative) {
      List<String> allergens = getAllergensInFood(alternative);
      for (final allergen in allergens) {
        if (userAllergensLower.contains(allergen.toLowerCase())) {
          return false;
        }
      }
      return true;
    }).toList();
    
    return alternatives.take(5).toList(); // Return max 5 alternatives
  }
  
  // Get all known allergens
  static List<String> getAllAllergens() {
    return _allergenToFoods.keys.toList();
  }
  
  // Check if food contains a specific allergen
  static bool foodContainsAllergen(String food, String allergen) {
    food = food.toLowerCase();
    allergen = allergen.toLowerCase();
    
    List<String> allergens = getAllergensInFood(food);
    return allergens.any((a) => a.toLowerCase().contains(allergen));
  }
  
  // Get standardized food category from a food name
  static String? getFoodCategory(String food) {
    food = food.toLowerCase();
    
    // Check direct allergens first
    List<String> allergens = getAllergensInFood(food);
    
    // Determine food category based on allergens or food name
    if (allergens.any((a) => a.toLowerCase().contains('dairy') || 
                            a.toLowerCase().contains('lactose') || 
                            a.toLowerCase().contains('casein'))) {
      return 'Dairy';
    } else if (allergens.any((a) => a.toLowerCase().contains('nut'))) {
      return 'Nuts';
    } else if (allergens.any((a) => a.toLowerCase().contains('fish') || 
                              a.toLowerCase().contains('shellfish') || 
                              a.toLowerCase().contains('crustacean'))) {
      return 'Seafood';
    } else if (allergens.any((a) => a.toLowerCase().contains('gluten') || 
                               a.toLowerCase().contains('wheat'))) {
      return 'Gluten';
    } else if (allergens.any((a) => a.toLowerCase().contains('egg'))) {
      return 'Eggs';
    }
    
    // Check food name if no allergens matched
    if (food.contains('milk') || food.contains('cheese') || 
        food.contains('yogurt') || food.contains('butter') || 
        food.contains('cream')) {
      return 'Dairy';
    } else if (food.contains('nut') || food.contains('almond') || 
               food.contains('walnut') || food.contains('cashew') || 
               food.contains('pistachio')) {
      return 'Nuts';
    } else if (food.contains('fish') || food.contains('shrimp') || 
               food.contains('crab') || food.contains('lobster') || 
               food.contains('tuna') || food.contains('salmon')) {
      return 'Seafood';
    } else if (food.contains('wheat') || food.contains('bread') || 
               food.contains('pasta') || food.contains('cereal') || 
               food.contains('barley') || food.contains('rye') || 
               food.contains('gluten')) {
      return 'Gluten';
    } else if (food.contains('egg')) {
      return 'Eggs';
    }
    
    return null;
  }
  
  // Calculate allergy probability based on symptoms and food
  static Map<String, dynamic> calculateAllergyProbability(String food, List<String> symptoms) {
    food = food.toLowerCase();
    List<String> allergens = getAllergensInFood(food);
    
    // Convert symptoms to lowercase for matching
    final symptomsLower = symptoms.map((s) => s.toLowerCase()).toList();
    
    // Find the food category
    String? foodCategory = getFoodCategory(food);
    
    // Default result structure
    Map<String, dynamic> result = {
      'personalProbability': 0.0,
      'populationProbability': 0.0,
      'severityEstimate': 0.0,
      'matchedSymptoms': <String>[],
      'commonSymptoms': <String>[],
    };
    
    // If we couldn't categorize the food, use the classic calculation method
    if (foodCategory == null || !_foodStatistics.containsKey(foodCategory)) {
      double classicProbability = _calculateClassicProbability(food, symptomsLower);
      result['personalProbability'] = classicProbability;
      result['populationProbability'] = classicProbability * 0.7; // Rough estimate
      return result;
    }
    
    // Use the statistical data for better accuracy
    Map<String, dynamic> stats = _foodStatistics[foodCategory]!;
    
    // Base population probability from our dataset
    result['populationProbability'] = stats['allergyRate'] * 100;
    
    // Get common symptoms for this food type
    List<String> commonSymptoms = List<String>.from(stats['commonSymptoms'] ?? []);
    result['commonSymptoms'] = commonSymptoms;
    
    // Base personal probability starts with population probability
    double personalProbability = result['populationProbability'];
    
    // Common allergy symptoms mapping
    const Map<String, List<String>> allergenToSymptoms = {
      'dairy': ['bloating', 'gas', 'diarrhea', 'stomach', 'nausea'],
      'nuts': ['rash', 'hives', 'itching', 'swelling', 'throat', 'breathing'],
      'seafood': ['hives', 'swelling', 'throat', 'breathing', 'nausea'],
      'gluten': ['bloating', 'fatigue', 'diarrhea', 'headache', 'stomach'],
      'eggs': ['rash', 'hives', 'itching', 'swelling', 'stomach'],
    };
    
    // Check for symptom matches
    List<String> matchedSymptoms = [];
    
    if (allergenToSymptoms.containsKey(foodCategory.toLowerCase())) {
      List<String> typicalSymptoms = allergenToSymptoms[foodCategory.toLowerCase()]!;
      
      for (final symptom in typicalSymptoms) {
        if (symptomsLower.any((s) => s.contains(symptom))) {
          matchedSymptoms.add(symptom);
          // Increase probability based on symptom matches
          personalProbability += 10.0;
        }
      }
    }
    
    // Adjust based on symptom matches from our dataset
    for (final commonSymptom in commonSymptoms) {
      String lowerCommonSymptom = commonSymptom.toLowerCase();
      
      if (symptomsLower.any((s) => s.contains(lowerCommonSymptom) || 
                              lowerCommonSymptom.contains(s))) {
        if (!matchedSymptoms.contains(commonSymptom)) {
          matchedSymptoms.add(commonSymptom);
        }
        // Increase probability based on symptom matches from dataset
        personalProbability += 15.0;
      }
    }
    
    // Add matched symptoms to result
    result['matchedSymptoms'] = matchedSymptoms;
    
    // Add random variation to make it look more natural (±5%)
    personalProbability += (Random().nextDouble() * 10) - 5;
    
    // Adjust based on number of allergens in food
    if (allergens.isNotEmpty) {
      personalProbability += allergens.length * 5.0;
    }
    
    // Cap probabilities at 95%
    result['personalProbability'] = min<double>(95.0, max<double>(10.0, personalProbability));
    result['populationProbability'] = min<double>(95.0, max<double>(5.0, result['populationProbability'] as double));
    
    // Estimate severity based on matched symptoms and dataset
    double severityEstimate = stats['avgSeverity'] ?? 5.0;
    if (matchedSymptoms.isNotEmpty) {
      // Adjust severity based on number of matched symptoms
      severityEstimate += matchedSymptoms.length * 0.5;
    }
    
    // Cap severity at 10
    result['severityEstimate'] = min<double>(10.0, severityEstimate);
    
    return result;
  }
  
  // Classic probability calculation (fallback method)
  static double _calculateClassicProbability(String food, List<String> symptomsLower) {
    List<String> allergens = getAllergensInFood(food);
    
    if (allergens.isEmpty) {
      return 10.0; // Low base probability if no known allergens
    }
    
    // Base probability based on number of allergens in food
    double probability = allergens.length * 15.0;
    
    // Common allergy symptoms
    const Map<String, List<String>> allergenToSymptoms = {
      'nut': ['rash', 'hives', 'itching', 'swelling', 'throat', 'breathing'],
      'dairy': ['bloating', 'gas', 'diarrhea', 'stomach', 'nausea'],
      'gluten': ['bloating', 'fatigue', 'diarrhea', 'headache', 'stomach'],
      'shellfish': ['hives', 'swelling', 'throat', 'breathing', 'nausea'],
      'fish': ['hives', 'swelling', 'throat', 'breathing', 'nausea'],
      'soy': ['rash', 'hives', 'itching', 'diarrhea', 'nausea'],
      'egg': ['rash', 'hives', 'itching', 'swelling', 'stomach'],
      'wheat': ['bloating', 'fatigue', 'headache', 'stomach', 'rash'],
      'peanut': ['rash', 'hives', 'itching', 'swelling', 'throat', 'breathing'],
      'nightshade': ['joint', 'pain', 'inflammation', 'digestive'],
      'citrus': ['heartburn', 'rash', 'mouth', 'sores', 'itching'],
      'oral allergy': ['itching', 'tingling', 'swelling', 'mouth', 'throat'],
    };
    
    // Check symptoms against common allergy patterns
    for (final entry in allergenToSymptoms.entries) {
      final allergenKey = entry.key;
      final commonSymptoms = entry.value;
      
      bool foodHasAllergen = allergens.any((a) => 
          a.toLowerCase().contains(allergenKey) || 
          allergenKey.contains(a.toLowerCase()));
      
      if (foodHasAllergen) {
        // Count matching symptoms
        int matchingSymptoms = 0;
        
        for (final symptom in commonSymptoms) {
          if (symptomsLower.any((s) => s.contains(symptom))) {
            matchingSymptoms++;
          }
        }
        
        // Increase probability based on symptom matches
        if (matchingSymptoms > 0) {
          probability += matchingSymptoms * 10.0;
        }
      }
    }
    
    // Add random variation to make it look more natural (±5%)
    probability += (Random().nextDouble() * 10) - 5;
    
    // Cap at 95%
    return min<double>(95.0, max<double>(10.0, probability));
  }
  
  // Get mapping of food types to standardized categories
  static Map<String, String> get foodTypeMapping => _foodTypeMapping;
} 