import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/food_entry.dart';
import '../utils/app_theme.dart';
import 'allergen_chip.dart';

class FoodEntryCard extends StatelessWidget {
  final FoodEntry entry;
  final VoidCallback onTap;
  
  const FoodEntryCard({
    super.key,
    required this.entry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('MMM d, yyyy');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(
          color: kBrandColor,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusIndicator(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: kTextPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                          color: kBrandColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateFormatter.format(entry.date),
                          style: const TextStyle(
                            fontSize: 13,
                            color: kTextSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                    if (entry.allergens.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: entry.allergens.map((allergen) {
                          return _buildAllergenChip(allergen);
                        }).toList(),
                      ),
                    ],
                    if (entry.notes != null && entry.notes!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: kBrandColor, width: 1),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.notes,
                              size: 16,
                              color: kBrandColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                entry.notes!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: kTextPrimaryColor,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: kBrandColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatusIndicator() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: entry.isSafe ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Center(
        child: Icon(
          entry.isSafe 
              ? Icons.check_circle_outline_rounded
              : Icons.error_outline_rounded,
          color: entry.isSafe ? Colors.green : Colors.red,
          size: 24,
        ),
      ),
    );
  }
  
  Widget _buildAllergenChip(String allergen) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 12,
            color: Colors.red,
          ),
          const SizedBox(width: 4),
          Text(
            allergen,
            style: const TextStyle(
              fontSize: 12,
              color: kTextPrimaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
