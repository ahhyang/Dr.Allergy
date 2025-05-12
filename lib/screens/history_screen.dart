import 'package:flutter/material.dart';
import '../models/allergy_incident.dart';
import '../services/incident_storage_service.dart';
import '../widgets/loading_indicator.dart';
import 'package:intl/intl.dart';
import '../services/gemini_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _isAnalyzing = false;
  List<AllergyIncident> _incidents = [];
  Map<String, int> _allergenStats = {};
  late TabController _tabController;
  String? _selectedFilter;
  String? _deepAnalysisResult;
  final GeminiService _geminiService = GeminiService();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadIncidents();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadIncidents() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Load all incidents
      final incidents = await IncidentStorageService.getRecentIncidents();
      
      // Calculate allergen statistics
      final stats = await IncidentStorageService.getAllergenFrequencyStats();
      
      setState(() {
        _incidents = incidents;
        _allergenStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading history: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  List<AllergyIncident> _getFilteredIncidents() {
    if (_selectedFilter == null) {
      return _incidents;
    }
    
    return _incidents.where((incident) => 
      incident.detectedAllergens
          .map((a) => a.toLowerCase())
          .contains(_selectedFilter!.toLowerCase())
    ).toList();
  }
  
  Future<void> _deleteIncident(String id) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await IncidentStorageService.deleteIncident(id);
      await _loadIncidents(); // Reload data
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Incident deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting incident: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // New method to perform deep analysis
  Future<void> _performDeepAnalysis() async {
    if (_incidents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not enough data for analysis. Record some allergy incidents first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() {
      _isAnalyzing = true;
    });
    
    try {
      final analysis = await _geminiService.analyzeUserAllergyHistory(_incidents);
      
      setState(() {
        _deepAnalysisResult = analysis;
        _isAnalyzing = false;
      });
      
      _showDeepAnalysisResults();
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error performing analysis: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _showDeepAnalysisResults() {
    if (_deepAnalysisResult == null) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.analytics,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Pattern Analysis',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _deepAnalysisResult!,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'IMPORTANT: This analysis is based solely on your recorded history. The findings should be discussed with a healthcare provider and are not a substitute for professional medical diagnosis.',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // Share functionality would go here
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Share feature coming soon'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.share),
                        label: const Text('Share with Healthcare Provider'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Allergy History'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Timeline'),
            Tab(text: 'Insights'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _isAnalyzing ? null : _performDeepAnalysis,
          ),
        ],
      ),
      body: Stack(
        children: [
          _isLoading 
              ? const Center(child: LoadingIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTimelineTab(),
                    _buildInsightsTab(),
                  ],
                ),
          if (_isAnalyzing)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LoadingIndicator(size: 48),
                    SizedBox(height: 16),
                    Text(
                      'Analyzing your allergy patterns...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/symptom-checker');
        },
        icon: const Icon(Icons.add),
        label: const Text('Log Reaction'),
        tooltip: 'Log New Reaction',
      ),
    );
  }
  
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Allergen'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: const Text('Show All'),
                selected: _selectedFilter == null,
                onTap: () {
                  setState(() {
                    _selectedFilter = null;
                  });
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              ..._allergenStats.keys.map((allergen) => ListTile(
                title: Text(allergen.toUpperCase()),
                subtitle: Text('${_allergenStats[allergen]} incidents'),
                selected: _selectedFilter == allergen,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.label,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
                onTap: () {
                  setState(() {
                    _selectedFilter = allergen;
                  });
                  Navigator.pop(context);
                },
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTimelineTab() {
    final filteredIncidents = _getFilteredIncidents();
    
    if (filteredIncidents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history,
                size: 64,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _selectedFilter != null
                  ? 'No incidents found with ${_selectedFilter!.toUpperCase()}'
                  : 'No allergy incidents recorded yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Record your reactions to build a comprehensive history',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Record New Incident'),
              onPressed: () {
                // Navigate directly to symptom checker screen with a clear navigation path
                Navigator.pushNamed(context, '/symptom-checker');
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadIncidents,
      child: ListView.builder(
        itemCount: filteredIncidents.length + 1, // +1 for header
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          // Header
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16, left: 8),
              child: Text(
                _selectedFilter != null 
                  ? 'Showing reactions to ${_selectedFilter!.toUpperCase()}'
                  : 'Your Reaction History',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            );
          }
          
          final incident = filteredIncidents[index - 1]; // Adjust for header
          
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: incident.getSeverityColor().withOpacity(0.3),
                width: 1,
              ),
            ),
            child: InkWell(
              onTap: () => _showIncidentDetails(incident),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: incident.getSeverityColor().withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            incident.getSeverityIcon(),
                            color: incident.getSeverityColor(),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('MMMM d, yyyy').format(incident.date),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                DateFormat('h:mm a').format(incident.date),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _confirmDelete(incident.id),
                          color: Colors.red[400],
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    const Text(
                      'Symptoms:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      incident.symptoms,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Detected Allergens:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    incident.detectedAllergens.isNotEmpty
                        ? Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: incident.detectedAllergens.map((allergen) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: incident.getSeverityColor().withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: incident.getSeverityColor().withOpacity(0.5),
                                ),
                              ),
                              child: Text(
                                allergen,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: incident.getSeverityColor(),
                                ),
                              ),
                            )).toList(),
                          )
                        : const Text(
                            'No specific allergens identified',
                            style: TextStyle(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildInsightsTab() {
    if (_incidents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.insert_chart,
                size: 64,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Data Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Record your reactions to generate insights',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Record First Reaction'),
              onPressed: () {
                Navigator.pushNamed(context, '/symptom-checker');
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }
    
    // Get most recent incident date
    final latestIncident = _incidents.first;
    
    // Calculate frequency by month
    final Map<String, int> monthlyFrequency = {};
    for (final incident in _incidents) {
      final month = DateFormat('MMM yyyy').format(incident.date);
      monthlyFrequency[month] = (monthlyFrequency[month] ?? 0) + 1;
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary card
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.summarize,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Summary',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInsightStat(
                        title: 'Total',
                        value: _incidents.length.toString(),
                        color: Theme.of(context).colorScheme.primary,
                        icon: Icons.history,
                      ),
                      _buildInsightStat(
                        title: 'severe',
                        value: _incidents
                            .where((i) => i.severity == AllergyIncident.severe)
                            .length
                            .toString(),
                        color: Colors.red,
                        icon: Icons.warning,
                      ),
                      _buildInsightStat(
                        title: 'Last',
                        value: DateFormat('MMM d').format(latestIncident.date),
                        color: Theme.of(context).colorScheme.tertiary,
                        icon: Icons.event,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Allergen frequency
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.bubble_chart,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Common Triggers',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _allergenStats.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('No allergen data available'),
                          ),
                        )
                      : Column(
                          children: _allergenStats.entries
                              .toList()
                              .sublist(0, _allergenStats.length > 5 ? 5 : _allergenStats.length)
                              .map((entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          entry.key.toUpperCase(),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '${(entry.value / _incidents.length * 100).toStringAsFixed(0)}%',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context).colorScheme.secondary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        value: entry.value / _incidents.length,
                                        backgroundColor: Colors.grey.withOpacity(0.2),
                                        color: Theme.of(context).colorScheme.secondary,
                                        minHeight: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                              .toList(),
                        ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Monthly frequency
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.tertiary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.calendar_month,
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Monthly Frequency',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  monthlyFrequency.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('No time data available'),
                          ),
                        )
                      : Column(
                          children: monthlyFrequency.entries
                              .toList()
                              .sublist(0, monthlyFrequency.length > 6 ? 6 : monthlyFrequency.length)
                              .map((entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 100,
                                      child: Text(
                                        entry.key,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        height: 30,
                                        alignment: Alignment.centerLeft,
                                        child: Row(
                                          children: [
                                            Container(
                                              width: entry.value * 20.0, // Scale factor
                                              height: 24,
                                              decoration: BoxDecoration(
                                                color: Theme.of(context).colorScheme.tertiary,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context).colorScheme.tertiary.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                entry.value.toString(),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context).colorScheme.tertiary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                              .toList(),
                        ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Tips based on data
          _buildDataDrivenTips(),
        ],
      ),
    );
  }
  
  Widget _buildDataDrivenTips() {
    // Only show tips if we have enough data
    if (_incidents.length < 3 || _allergenStats.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Get most common allergen
    String? mostCommonAllergen;
    int highestCount = 0;
    
    _allergenStats.forEach((allergen, count) {
      if (count > highestCount) {
        mostCommonAllergen = allergen;
        highestCount = count;
      }
    });
    
    if (mostCommonAllergen == null) {
      return const SizedBox.shrink();
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.lightbulb,
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Personalized Tips',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.amber.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Based on your history, ${mostCommonAllergen!.toUpperCase()} appears to be your most common trigger.',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _getTipForAllergen(mostCommonAllergen!),
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // In a real app, this could navigate to educational content
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Feature coming soon!'),
                    ),
                  );
                },
                icon: const Icon(Icons.school),
                label: const Text('Learn more about managing this allergy'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInsightStat({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  
  void _showIncidentDetails(AllergyIncident incident) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: incident.getSeverityColor().withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          incident.getSeverityIcon(),
                          color: incident.getSeverityColor(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Incident Details',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),
              
              Text(
                'Date: ${DateFormat('MMMM d, yyyy').format(incident.date)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                'Time: ${DateFormat('h:mm a').format(incident.date)}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              
              _buildDetailSection(
                title: 'Symptoms',
                content: incident.symptoms,
              ),
              
              _buildDetailSection(
                title: 'Foods Eaten',
                content: incident.foodsEaten,
              ),
              
              _buildDetailSection(
                title: 'Timeframe',
                content: incident.timeframe,
              ),
              
              const SizedBox(height: 16),
              const Text(
                'Detected Allergens:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              
              incident.detectedAllergens.isNotEmpty
                  ? Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: incident.detectedAllergens.map((allergen) => Chip(
                        label: Text(allergen),
                        backgroundColor: incident.getSeverityColor().withOpacity(0.1),
                        side: BorderSide(
                          color: incident.getSeverityColor().withOpacity(0.5),
                        ),
                      )).toList(),
                    )
                  : const Text('No specific allergens identified'),
              
              const SizedBox(height: 24),
              const Text(
                'AI Analysis',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(incident.analysis),
              ),
              
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Share functionality would go here
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Share feature coming soon'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('Share with Doctor'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _confirmDelete(incident.id);
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildDetailSection({
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title + ':',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(content),
        ],
      ),
    );
  }
  
  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Incident'),
        content: const Text('Are you sure you want to delete this incident? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteIncident(id);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  String _getTipForAllergen(String allergen) {
    // Tips based on common allergens
    final Map<String, String> allergenTips = {
      'dairy': 'Look for dairy-free alternatives like almond milk, coconut yogurt, or oat-based products. Check labels for hidden dairy ingredients like casein, whey, or lactose.',
      'nuts': 'Always check food labels for nut warnings. Be cautious at buffets and bakeries due to cross-contamination risks. Consider carrying an epinephrine auto-injector.',
      'shellfish': 'Be careful at seafood restaurants as cross-contamination is common. Inform servers about your allergy when dining out.',
      'wheat': 'Look for gluten-free certifications on products. Many grains like quinoa, rice, and corn are safe alternatives to wheat.',
      'soy': 'Check labels carefully as soy is found in many processed foods. Look for alternatives like coconut aminos instead of soy sauce.',
      'eggs': 'Aquafaba (chickpea water) and commercial egg replacers can substitute eggs in many recipes. Be careful with baked goods and mayonnaise.',
      'fish': 'Be cautious with Asian cuisines that may use fish sauce as a flavoring. Watch for cross-contamination at seafood counters.',
      'peanut': 'Be careful with Asian cuisines and bakery items. Sunflower seed butter and almond butter can be good alternatives.',
    };
    
    // Convert to lowercase for case-insensitive matching
    final lowerAllergen = allergen.toLowerCase();
    
    // Return specific tip if available, otherwise a general tip
    if (allergenTips.containsKey(lowerAllergen)) {
      return allergenTips[lowerAllergen]!;
    }
    
    // Check for partial matches
    for (final entry in allergenTips.entries) {
      if (lowerAllergen.contains(entry.key) || entry.key.contains(lowerAllergen)) {
        return entry.value;
      }
    }
    
    // Default general tip
    return 'Keep a food diary to track and avoid your trigger foods. When dining out, always inform staff about your allergies.';
  }
}
