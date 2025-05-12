import 'package:flutter/material.dart';
import '../models/user_profile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Mock user profile - create a mutable instance
  late UserProfile _userProfile;
  
  final TextEditingController _allergenController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    // Initialize with mock data
    _userProfile = UserProfile(
      name: 'John Doe',
      email: 'john@example.com',
      confirmedAllergens: ['Dairy', 'Nuts', 'Shellfish'],
      suspectedAllergens: ['Wheat'],
      emergencyContacts: [
        {'name': 'Jane Doe', 'phone': '555-1234'},
      ],
    );
  }
  
  @override
  void dispose() {
    _allergenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              _showEditProfileDialog();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile header
            _buildProfileHeader(),
                        
            const SizedBox(height: 32),
            
            // Allergen sections
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildAllergenSection(
                title: 'Confirmed Allergens',
                allergens: _userProfile.confirmedAllergens,
                color: Colors.red,
                onEdit: () => _showEditAllergensDialog(true),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildAllergenSection(
                title: 'Suspected Allergens',
                allergens: _userProfile.suspectedAllergens,
                color: Colors.orange,
                onEdit: () => _showEditAllergensDialog(false),
              ),
            ),
            const SizedBox(height: 24),
            
            // Emergency contacts
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildEmergencyContacts(),
            ),
            
            const SizedBox(height: 32),
            
            // Navigation options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'App Navigation',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 16),
            _buildNavigationTile(
              icon: Icons.home,
              title: 'Home Dashboard',
              onTap: () {
                Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
              },
            ),
            _buildNavigationTile(
              icon: Icons.medical_services,
              title: 'Check Symptoms',
              onTap: () {
                Navigator.pushNamed(context, '/symptom-checker');
              },
            ),
            _buildNavigationTile(
              icon: Icons.camera_alt,
              title: 'Scan Food',
              onTap: () {
                Navigator.pushNamed(context, '/food-scanner');
              },
            ),
            _buildNavigationTile(
              icon: Icons.history,
              title: 'View History',
              onTap: () {
                Navigator.pushNamed(context, '/history');
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProfileHeader() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Theme.of(context).colorScheme.secondary,
                child: Text(
                  _userProfile.name.substring(0, 1),
                  style: const TextStyle(
                    fontSize: 48,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _userProfile.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _userProfile.email,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _showEditProfileDialog,
              icon: const Icon(Icons.edit),
              label: const Text('Edit Profile'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNavigationTile({
    required IconData icon, 
    required String title, 
    required VoidCallback onTap
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
  
  Widget _buildAllergenSection({
    required String title,
    required List<String> allergens,
    required Color color,
    required VoidCallback onEdit,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: onEdit,
                  iconSize: 20,
                  tooltip: 'Add $title',
                  style: IconButton.styleFrom(
                    backgroundColor: color.withOpacity(0.1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            allergens.isEmpty
                ? Text(
                    'No $title added yet',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: allergens.map((allergen) => Chip(
                      label: Text(allergen),
                      backgroundColor: color.withOpacity(0.1),
                      side: BorderSide(color: color),
                      labelStyle: TextStyle(color: color.withOpacity(0.8), fontWeight: FontWeight.w500),
                      deleteIcon: const Icon(Icons.clear, size: 16),
                      onDeleted: () {
                        setState(() {
                          if (title == 'Confirmed Allergens') {
                            _userProfile.confirmedAllergens.remove(allergen);
                          } else {
                            _userProfile.suspectedAllergens.remove(allergen);
                          }
                        });
                      },
                    )).toList(),
                  ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmergencyContacts() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Emergency Contacts',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _showAddContactDialog,
                  iconSize: 20,
                  tooltip: 'Add Contact',
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error.withOpacity(0.1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _userProfile.emergencyContacts.isEmpty
                ? Text(
                    'No emergency contacts added yet',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _userProfile.emergencyContacts.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final contact = _userProfile.emergencyContacts[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.phone,
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    contact['name'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    contact['phone'] ?? '',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              color: Theme.of(context).colorScheme.error,
                              onPressed: () {
                                setState(() {
                                  _userProfile.emergencyContacts.remove(contact);
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
  
  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _userProfile.name);
    final emailController = TextEditingController(text: _userProfile.email);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              // Create a new UserProfile instance with updated values
              final updatedProfile = UserProfile(
                name: nameController.text,
                email: emailController.text,
                confirmedAllergens: _userProfile.confirmedAllergens,
                suspectedAllergens: _userProfile.suspectedAllergens,
                emergencyContacts: _userProfile.emergencyContacts,
              );
              
              setState(() {
                _userProfile = updatedProfile;
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  
  void _showEditAllergensDialog(bool isConfirmed) {
    final allergenController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add ${isConfirmed ? 'Confirmed' : 'Suspected'} Allergen'),
        content: TextField(
          controller: allergenController,
          decoration: InputDecoration(
            labelText: 'Allergen Name',
            hintText: 'E.g., Peanuts, Milk, Eggs',
            prefixIcon: Icon(
              Icons.warning_amber,
              color: isConfirmed ? Colors.red : Colors.orange,
            ),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (allergenController.text.isNotEmpty) {
                setState(() {
                  if (isConfirmed) {
                    _userProfile.confirmedAllergens.add(allergenController.text);
                  } else {
                    _userProfile.suspectedAllergens.add(allergenController.text);
                  }
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
  
  void _showAddContactDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Emergency Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.person),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && phoneController.text.isNotEmpty) {
                setState(() {
                  _userProfile.emergencyContacts.add({
                    'name': nameController.text,
                    'phone': phoneController.text,
                  });
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
