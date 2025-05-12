class UserProfile {
  final String name;
  final String email;
  final List<String> confirmedAllergens;
  final List<String> suspectedAllergens;
  final List<Map<String, String>> emergencyContacts;
  
  UserProfile({
    required this.name,
    required this.email,
    required this.confirmedAllergens,
    required this.suspectedAllergens,
    required this.emergencyContacts,
  });
}
