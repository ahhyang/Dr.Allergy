import 'package:flutter/material.dart';

class AllergyIncident {
  final String id;
  final DateTime date;
  final String symptoms;
  final String foodsEaten;
  final String timeframe;
  final String analysis;
  final List<String> detectedAllergens;
  final String severity;
  
  // Severity levels for allergic reactions
  static const String mild = 'mild';
  static const String moderate = 'moderate';
  static const String severe = 'severe';
  
  AllergyIncident({
    required this.id,
    required this.date,
    required this.symptoms,
    required this.foodsEaten,
    required this.timeframe,
    required this.analysis,
    required this.detectedAllergens,
    required this.severity,
  });
  
  // Convert to and from JSON for storage
  factory AllergyIncident.fromJson(Map<String, dynamic> json) {
    return AllergyIncident(
      id: json['id'],
      date: DateTime.parse(json['date']),
      symptoms: json['symptoms'],
      foodsEaten: json['foodsEaten'],
      timeframe: json['timeframe'],
      analysis: json['analysis'],
      detectedAllergens: List<String>.from(json['detectedAllergens']),
      severity: json['severity'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'symptoms': symptoms,
      'foodsEaten': foodsEaten,
      'timeframe': timeframe,
      'analysis': analysis,
      'detectedAllergens': detectedAllergens,
      'severity': severity,
    };
  }
  
  // Helper method to determine color based on severity
  Color getSeverityColor() {
    switch (severity) {
      case mild:
        return Colors.yellow;
      case moderate:
        return Colors.orange;
      case severe:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  // Helper method to determine icon based on severity
  IconData getSeverityIcon() {
    switch (severity) {
      case mild:
        return Icons.info_outline;
      case moderate:
        return Icons.warning;
      case severe:
        return Icons.dangerous;
      default:
        return Icons.help_outline;
    }
  }
} 