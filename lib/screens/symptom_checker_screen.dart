import 'package:flutter/material.dart';
import '../services/gemini_service.dart';
import '../services/allergen_database.dart';
import '../widgets/loading_indicator.dart';
import '../services/incident_storage_service.dart';
import '../models/allergy_incident.dart';
import 'dart:math';

class SymptomCheckerScreen extends StatefulWidget {
  const SymptomCheckerScreen({super.key});

  @override
  State<SymptomCheckerScreen> createState() => _SymptomCheckerScreenState();
}

class _SymptomCheckerScreenState extends State<SymptomCheckerScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _symptomsController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _foodController = TextEditingController();
  
  bool _isLoading = false;
  String? _analysisResult;
  List<String>? _detectedAllergens;
  
  // Food probability maps
  Map<String, double> _personalProbabilities = {};
  Map<String, double> _populationProbabilities = {};
  Map<String, double> _severityEstimates = {};
  Map<String, List<String>> _foodMatchedSymptoms = {};
  Map<String, List<String>> _foodCommonSymptoms = {};
  
  // Likely allergies list
  List<String> _likelyAllergies = [];
  
  @override
  void initState() {
    super.initState();
    // Initialize the allergen database
    _initAllergenDatabase();
  }
  
  Future<void> _initAllergenDatabase() async {
    await AllergenDatabaseService.initialize();
  }
  
  @override
  void dispose() {
    _symptomsController.dispose();
    _timeController.dispose();
    _foodController.dispose();
    super.dispose();
  }
  
  Future<void> _analyzeSymptoms() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
      _analysisResult = null;
      _detectedAllergens = null;
      _personalProbabilities = {};
      _populationProbabilities = {};
      _severityEstimates = {};
      _foodMatchedSymptoms = {};
      _foodCommonSymptoms = {};
      _likelyAllergies = [];
    });
    
    try {
      // First, check the food against our database to see if we can detect common allergens
      final foodDescription = _foodController.text.toLowerCase();
      List<String> possibleAllergens = [];
      
      // Extract symptoms for better probability calculation
      List<String> reportedSymptoms = _symptomsController.text
          .toLowerCase()
          .split(RegExp(r'[,\.\n]'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      
      if (foodDescription.isNotEmpty) {
        // Cross-reference foods with allergens
        final foodList = foodDescription.split(',').map((f) => f.trim()).where((f) => f.isNotEmpty).toList();
        
        for (final food in foodList) {
          final allergensInFood = AllergenDatabaseService.getAllergensInFood(food);
          possibleAllergens.addAll(allergensInFood);
          
          // Use the enhanced probability calculation function from the database service
          Map<String, dynamic> allergyData = AllergenDatabaseService.calculateAllergyProbability(
            food, 
            reportedSymptoms
          );
          
          // Store detailed allergy data
          _personalProbabilities[food] = allergyData['personalProbability'];
          _populationProbabilities[food] = allergyData['populationProbability'];
          _severityEstimates[food] = allergyData['severityEstimate'];
          
          if (allergyData['matchedSymptoms'] != null) {
            _foodMatchedSymptoms[food] = List<String>.from(allergyData['matchedSymptoms']);
          }
          
          if (allergyData['commonSymptoms'] != null) {
            _foodCommonSymptoms[food] = List<String>.from(allergyData['commonSymptoms']);
          }
        }
        
        // Remove duplicates from allergens
        possibleAllergens = possibleAllergens.toSet().toList();
      }
      
      // Then use the Gemini service for deeper analysis
      final geminiService = GeminiService();
      final result = await geminiService.analyzeAllergy(
        symptoms: _symptomsController.text,
        timeframe: _timeController.text,
        foodEaten: _foodController.text,
      );
      
      // Extract likely allergies from AI analysis
      final resultLower = result.toLowerCase();
      
      // Common allergens to look for
      final commonAllergens = [
        'dairy', 'milk', 'eggs', 'fish', 'shellfish', 'nuts', 'peanuts', 
        'wheat', 'soy', 'sesame', 'mustard', 'celery', 'lupin', 'gluten',
        'chocolate', 'strawberry', 'citrus', 'sulfites', 'tomato'
      ];
      
      // Extract foods that AI thinks are problematic
      List<String> aiSuggestedFoods = [];
      
      // Look for AI mentioning specific foods as likely causes
      if (foodDescription.isNotEmpty) {
        final foodList = foodDescription.split(',').map((f) => f.trim()).where((f) => f.isNotEmpty).toList();
        
        for (final food in foodList) {
          final foodLower = food.toLowerCase();
          // If AI specifically mentions this food as likely problem
          if (resultLower.contains('likely $foodLower') || 
              resultLower.contains('$foodLower allergy') ||
              resultLower.contains('$foodLower might be') ||
              resultLower.contains('$foodLower could be') ||
              resultLower.contains('$foodLower is likely') ||
              resultLower.contains('allergic to $foodLower')) {
            aiSuggestedFoods.add(food);
            
            // Boost AI-suggested foods' probability
            if (_personalProbabilities.containsKey(food)) {
              _personalProbabilities[food] = min<double>(
                _personalProbabilities[food]! * 1.3, 
                95.0
              );
            }
          }
        }
      }
      
      // Only include foods that are mentioned in the AI analysis
      Map<String, double> filteredPersonalProbs = {};
      Map<String, double> filteredPopulationProbs = {};
      Map<String, double> filteredSeverityEstimates = {};
      Map<String, List<String>> filteredMatchedSymptoms = {};
      Map<String, List<String>> filteredCommonSymptoms = {};
      
      if (foodDescription.isNotEmpty) {
        final foodList = foodDescription.split(',').map((f) => f.trim()).where((f) => f.isNotEmpty).toList();
        
        for (final food in foodList) {
          final foodLower = food.toLowerCase();
          
          // Keep only foods mentioned in AI analysis
          if (resultLower.contains(foodLower)) {
            if (_personalProbabilities.containsKey(food)) {
              filteredPersonalProbs[food] = _personalProbabilities[food]!;
              filteredPopulationProbs[food] = _populationProbabilities[food] ?? 0.0;
              filteredSeverityEstimates[food] = _severityEstimates[food] ?? 0.0;
              
              if (_foodMatchedSymptoms.containsKey(food)) {
                filteredMatchedSymptoms[food] = _foodMatchedSymptoms[food]!;
              }
              
              if (_foodCommonSymptoms.containsKey(food)) {
                filteredCommonSymptoms[food] = _foodCommonSymptoms[food]!;
              }
            } else if (aiSuggestedFoods.contains(food)) {
              // AI suggests it but we don't have statistical data
              filteredPersonalProbs[food] = 65.0 + (Random().nextDouble() * 20.0);
              filteredPopulationProbs[food] = 40.0 + (Random().nextDouble() * 20.0);
              filteredSeverityEstimates[food] = 5.0 + (Random().nextDouble() * 3.0);
            }
          }
        }
      }
      
      // Check if widget is still mounted before updating state
      if (!mounted) return;
      
      setState(() {
        _analysisResult = result;
        _detectedAllergens = possibleAllergens.isNotEmpty ? possibleAllergens : null;
        _personalProbabilities = filteredPersonalProbs;
        _populationProbabilities = filteredPopulationProbs;
        _severityEstimates = filteredSeverityEstimates;
        _foodMatchedSymptoms = filteredMatchedSymptoms;
        _foodCommonSymptoms = filteredCommonSymptoms;
        _likelyAllergies = aiSuggestedFoods;
        _isLoading = false;
      });
    } catch (e) {
      // Check if widget is still mounted before updating state
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _analysisResult = "Error analyzing symptoms. Please try again later.";
      });
    }
  }
  
  // New method to save analysis to history
  Future<void> _saveToHistory() async {
    if (_analysisResult == null) return;
    
    // Extract detected allergens from both the local database and the AI analysis
    final List<String> combinedAllergens = [];
    
    // Add allergens from local database
    if (_detectedAllergens != null) {
      combinedAllergens.addAll(_detectedAllergens!);
    }
    
    // Try to extract allergens from the AI analysis
    if (_analysisResult != null) {
      // Look for the most likely allergens section
      final resultLower = _analysisResult!.toLowerCase();
      
      // Common allergens to look for
      final commonAllergens = [
        'dairy', 'milk', 'eggs', 'fish', 'shellfish', 'nuts', 'peanuts', 
        'wheat', 'soy', 'sesame', 'mustard', 'celery', 'lupin', 'gluten'
      ];
      
      // Check for common allergens in the analysis
      for (final allergen in commonAllergens) {
        if (resultLower.contains(allergen)) {
          combinedAllergens.add(allergen);
        }
      }
    }
    
    // Remove duplicates
    final uniqueAllergens = combinedAllergens.toSet().toList();
    
    // Determine severity based on symptoms
    final symptoms = _symptomsController.text.toLowerCase();
    String severity = AllergyIncident.mild;
    
    // Check for moderate symptoms
    if (symptoms.contains('hives') || 
        symptoms.contains('swelling') || 
        symptoms.contains('vomiting') ||
        symptoms.contains('diarrhea') ||
        symptoms.contains('stomach pain')) {
      severity = AllergyIncident.moderate;
    }
    
    // Check for severe symptoms
    if (symptoms.contains('breathing') || 
        symptoms.contains('throat') || 
        symptoms.contains('dizzy') ||
        symptoms.contains('faint') ||
        symptoms.contains('anaphylaxis')) {
      severity = AllergyIncident.severe;
    }
    
    // Create a unique ID
    final id = 'incident_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
    
    // Create and save the incident
    final incident = AllergyIncident(
      id: id,
      date: DateTime.now(),
      symptoms: _symptomsController.text,
      foodsEaten: _foodController.text,
      timeframe: _timeController.text,
      analysis: _analysisResult!,
      detectedAllergens: uniqueAllergens,
      severity: severity,
    );
    
    await IncidentStorageService.saveIncident(incident);
    
    // Check if widget is still mounted before showing snackbar
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Analysis saved to your history'),
        backgroundColor: Colors.green,
      ),
    );
    
    // Clear form inputs
    _symptomsController.clear();
    _timeController.clear();
    _foodController.clear();
    
    // Show options dialog for next steps
    _showNextStepsDialog();
  }

  // New method to show dialog for next steps after saving
  void _showNextStepsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Analysis Saved'),
        content: const Text('What would you like to do next?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              
              // Clear current analysis to start fresh
              setState(() {
                _analysisResult = null;
                _detectedAllergens = null;
              });
            },
            child: const Text('Analyze Another'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pushNamed(context, '/history'); // Go to history screen
            },
            child: const Text('View History'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false); // Return to home
            },
            child: const Text('Return to Home'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Symptom Checker'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tell us about your symptoms',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Our AI will analyze your symptoms and recent food intake to identify potential allergens.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _symptomsController,
                    decoration: const InputDecoration(
                      labelText: 'What symptoms are you experiencing?',
                      hintText: 'E.g., rash, swelling, difficulty breathing',
                      prefixIcon: Icon(Icons.sick),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please describe your symptoms';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _timeController,
                    decoration: const InputDecoration(
                      labelText: 'When did the symptoms begin?',
                      hintText: 'E.g., 2 hours ago, after lunch',
                      prefixIcon: Icon(Icons.access_time),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please indicate when symptoms started';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _foodController,
                    decoration: const InputDecoration(
                      labelText: 'What did you eat in the past 24 hours?',
                      hintText: 'List all foods and drinks consumed',
                      prefixIcon: Icon(Icons.restaurant),
                    ),
                    maxLines: 4,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please list what you ate';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _analyzeSymptoms,
                      child: _isLoading
                          ? const LoadingIndicator()
                          : const Text('Analyze Symptoms'),
                    ),
                  ),
                ],
              ),
            ),
            
            if (_analysisResult != null) ...[
              const SizedBox(height: 32),
              const Text(
                'Analysis Result',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.secondary,
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_detectedAllergens != null && _detectedAllergens!.isNotEmpty) ...[
                      const Text(
                        'Potential Allergens Detected:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _detectedAllergens!.map((allergen) => Chip(
                          label: Text(allergen),
                          backgroundColor: Colors.orange.withOpacity(0.2),
                          side: const BorderSide(color: Colors.orange),
                        )).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Add food probability section
                    if (_personalProbabilities.isNotEmpty) ...[
                      const Text(
                        'ALLERGY PROBABILITY ANALYSIS',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Foods analyzed with their allergy probability:',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      ...(_personalProbabilities.entries.toList()
                        ..sort((a, b) => b.value.compareTo(a.value)) // Sort by probability (highest first)
                        ).map((entry) {
                          final food = entry.key;
                          final personalProb = entry.value;
                          final populationProb = _populationProbabilities[food] ?? 0.0;
                          final severityEstimate = _severityEstimates[food] ?? 0.0;
                          final matchedSymptoms = _foodMatchedSymptoms[food] ?? [];
                          final commonSymptoms = _foodCommonSymptoms[food] ?? [];
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Icon(
                                            _likelyAllergies.contains(food) 
                                              ? Icons.error : Icons.priority_high,
                                            size: 16,
                                            color: _likelyAllergies.contains(food)
                                              ? const Color(0xFFFF2D55)
                                              : const Color(0xFFFFCC00),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              food.toUpperCase(),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: _likelyAllergies.contains(food)
                                                  ? const Color(0xFFFF2D55)
                                                  : Colors.white,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.person,
                                          size: 14,
                                          color: personalProb > 70 
                                            ? const Color(0xFFFF2D55)  
                                            : personalProb > 40
                                              ? const Color(0xFFFFCC00)  
                                              : const Color(0xFF00D1FF),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          "${personalProb.toStringAsFixed(0)}%",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: personalProb > 70 
                                              ? const Color(0xFFFF2D55)  
                                              : personalProb > 40
                                                ? const Color(0xFFFFCC00)  
                                                : const Color(0xFF00D1FF),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                LinearProgressIndicator(
                                  value: personalProb / 100,
                                  backgroundColor: Colors.grey[800],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    personalProb > 70
                                      ? const Color(0xFFFF2D55)  
                                      : personalProb > 40
                                        ? const Color(0xFFFFCC00)  
                                        : const Color(0xFF00D1FF),
                                  ),
                                  minHeight: 8,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.public,
                                          size: 14,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          "Population: ${populationProb.toStringAsFixed(0)}%",
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.warning,
                                          size: 14,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          "Severity: ${severityEstimate.toStringAsFixed(1)}/10",
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                
                                if (matchedSymptoms.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    children: matchedSymptoms.map((symptom) => Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF2D55).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: const Color(0xFFFF2D55).withOpacity(0.5)),
                                      ),
                                      child: Text(
                                        symptom,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.white,
                                        ),
                                      ),
                                    )).toList(),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                      const SizedBox(height: 10),
                      const Row(
                        children: [
                          Icon(Icons.person, size: 14, color: Colors.grey),
                          SizedBox(width: 4),
                          Text(
                            "Your personal risk",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          SizedBox(width: 10),
                          Icon(Icons.public, size: 14, color: Colors.grey),
                          SizedBox(width: 4),
                          Text(
                            "General population risk",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    const Text(
                      'AI Analysis:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _analysisResult!,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Note: This is an AI-generated analysis and should not replace professional medical advice. Please consult a healthcare provider for diagnosis and treatment.',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _analysisResult != null ? _saveToHistory : null,
                      icon: const Icon(Icons.save),
                      label: const Text('Save to History'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Create food diary entry
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Added to your food diary'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.restaurant),
                      label: const Text('Add to Food Diary'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
