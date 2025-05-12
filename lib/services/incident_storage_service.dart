import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/allergy_incident.dart';

class IncidentStorageService {
  static const String _storageKey = 'allergy_incidents';
  
  // Save a new allergy incident
  static Future<void> saveIncident(AllergyIncident incident) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> incidents = prefs.getStringList(_storageKey) ?? [];
    
    // Convert incident to JSON string
    final String incidentJson = jsonEncode(incident.toJson());
    
    // Add to list and save
    incidents.add(incidentJson);
    await prefs.setStringList(_storageKey, incidents);
  }
  
  // Get all saved incidents
  static Future<List<AllergyIncident>> getAllIncidents() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> incidents = prefs.getStringList(_storageKey) ?? [];
    
    // Convert JSON strings back to AllergyIncident objects
    return incidents.map((incidentJson) {
      final Map<String, dynamic> json = jsonDecode(incidentJson);
      return AllergyIncident.fromJson(json);
    }).toList();
  }
  
  // Get incidents sorted by date (most recent first)
  static Future<List<AllergyIncident>> getRecentIncidents() async {
    final incidents = await getAllIncidents();
    incidents.sort((a, b) => b.date.compareTo(a.date));
    return incidents;
  }
  
  // Get incidents filtered by allergen
  static Future<List<AllergyIncident>> getIncidentsByAllergen(String allergen) async {
    final incidents = await getAllIncidents();
    return incidents
        .where((incident) => incident.detectedAllergens
            .map((a) => a.toLowerCase())
            .contains(allergen.toLowerCase()))
        .toList();
  }
  
  // Delete an incident by ID
  static Future<void> deleteIncident(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> incidents = prefs.getStringList(_storageKey) ?? [];
    
    // Filter out the incident with matching ID
    final updatedIncidents = incidents.where((incidentJson) {
      final Map<String, dynamic> json = jsonDecode(incidentJson);
      return json['id'] != id;
    }).toList();
    
    await prefs.setStringList(_storageKey, updatedIncidents);
  }
  
  // Get statistics about allergen frequencies
  static Future<Map<String, int>> getAllergenFrequencyStats() async {
    final incidents = await getAllIncidents();
    final Map<String, int> allergenCounts = {};
    
    for (final incident in incidents) {
      for (final allergen in incident.detectedAllergens) {
        final lowerAllergen = allergen.toLowerCase();
        allergenCounts[lowerAllergen] = (allergenCounts[lowerAllergen] ?? 0) + 1;
      }
    }
    
    return allergenCounts;
  }
  
  // Determine the most problematic allergen
  static Future<String?> getMostFrequentAllergen() async {
    final allergenCounts = await getAllergenFrequencyStats();
    
    if (allergenCounts.isEmpty) return null;
    
    String? mostFrequent;
    int highestCount = 0;
    
    allergenCounts.forEach((allergen, count) {
      if (count > highestCount) {
        mostFrequent = allergen;
        highestCount = count;
      }
    });
    
    return mostFrequent;
  }
} 