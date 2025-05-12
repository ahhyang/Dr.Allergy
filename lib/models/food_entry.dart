class FoodEntry {
  final String id;
  final String name;
  final DateTime date;
  final bool isSafe;
  final List<String> allergens;
  final String? imageUrl;
  final String? notes;
  
  FoodEntry({
    required this.id,
    required this.name,
    required this.date,
    required this.isSafe,
    required this.allergens,
    this.imageUrl,
    this.notes,
  });
}
