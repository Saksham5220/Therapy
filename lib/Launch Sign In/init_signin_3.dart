import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InitSignIn3 extends StatefulWidget {
  final Map<String, dynamic>? signIn1Data;
  final Map<String, dynamic>? signIn2Data;
  final VoidCallback? onComplete;
  final Map<String, dynamic>? initialData;

  const InitSignIn3({
    super.key,
    this.signIn1Data,
    this.signIn2Data,
    this.onComplete,
    this.initialData,
  });

  @override
  State<InitSignIn3> createState() => _InitSignIn3State();
}

class _InitSignIn3State extends State<InitSignIn3> {
  final List<String> _selectedHobbies = [];
  final List<String> _selectedActivities = [];
  bool _isSubmitting = false;

  final List<String> _hobbiesOptions = [
    'Reading', 'Writing', 'Drawing', 'Painting', 'Photography', 'Cooking',
    'Gardening', 'Gaming', 'Music', 'Dancing', 'Singing', 'Crafting',
    'Knitting', 'Collecting', 'Puzzles', 'Board Games',
  ];

  final List<String> _activitiesOptions = [
    'Running', 'Swimming', 'Cycling', 'Hiking', 'Yoga', 'Gym',
    'Football', 'Basketball', 'Tennis', 'Volleyball', 'Traveling',
    'Movies', 'Shopping', 'Socializing', 'Meditation', 'Volunteering',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      final hobbies = widget.initialData!['hobbies'];
      final activities = widget.initialData!['activities'];
      if (hobbies is List) _selectedHobbies.addAll(hobbies.cast<String>());
      if (activities is List) _selectedActivities.addAll(activities.cast<String>());
    }
  }

  void _toggleSelection(String item, List<String> selectedList, int maxSelections) {
    setState(() {
      if (selectedList.contains(item)) {
        selectedList.remove(item);
      } else {
        if (selectedList.length < maxSelections) {
          selectedList.add(item);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('You can select maximum $maxSelections options'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    });
  }

  Widget _buildFloatingOptions({
    required String title,
    required List<String> options,
    required List<String> selectedItems,
    required int maxSelections,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title (Select up to $maxSelections)',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Selected: ${selectedItems.length}/$maxSelections',
          style: TextStyle(
            fontSize: 14,
            color: selectedItems.length == maxSelections ? Colors.red : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selectedItems.contains(option);
            return GestureDetector(
              onTap: () => _toggleSelection(option, selectedItems, maxSelections),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue : Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? Colors.blue : Colors.grey[400]!),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _submitAllData() async {
    if (_selectedHobbies.isEmpty || _selectedActivities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one hobby and one activity'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceId = prefs.getString('device_id');
      if (deviceId == null) throw Exception('Device ID not found');

      final completeUserData = {
        'device_id': deviceId,
        'timestamp': DateTime.now().toIso8601String(),
        'sign_in_1': widget.signIn1Data ?? {},
        'sign_in_2': widget.signIn2Data ?? {},
        'sign_in_3': {
          'hobbies': _selectedHobbies,
          'activities': _selectedActivities,
        },
        'onboarding_completed': true,
      };

      final dbRef = FirebaseDatabase.instance.ref();
      await dbRef.child('Users Information').child(deviceId).set(completeUserData);

      await prefs.setBool('onboarding_complete', true);
      await prefs.setBool('user_signed_in', true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sign up completed successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      if (widget.onComplete != null) {
        widget.onComplete!();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => _isSubmitting = false);
  }

  bool _canSubmit() {
    return _selectedHobbies.isNotEmpty &&
        _selectedActivities.isNotEmpty &&
        !_isSubmitting;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up - Step 3'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Tell us about your interests:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            _buildFloatingOptions(
              title: 'Hobbies',
              options: _hobbiesOptions,
              selectedItems: _selectedHobbies,
              maxSelections: 5,
            ),
            const SizedBox(height: 40),
            _buildFloatingOptions(
              title: 'Activities You Love',
              options: _activitiesOptions,
              selectedItems: _selectedActivities,
              maxSelections: 5,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canSubmit() ? _submitAllData : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _canSubmit() ? Colors.blue : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSubmitting
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Completing Sign Up...'),
                        ],
                      )
                    : const Text(
                        'Complete Sign Up',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
