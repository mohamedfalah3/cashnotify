import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddPlaceScreen extends StatefulWidget {
  @override
  _AddPlaceScreenState createState() => _AddPlaceScreenState();
}

class _AddPlaceScreenState extends State<AddPlaceScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final Map<String, TextEditingController> _monthControllers = {};

  @override
  void initState() {
    super.initState();
    // Initialize text controllers for each month
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    for (var month in months) {
      _monthControllers[month] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _monthControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _addPlace() async {
    if (_formKey.currentState!.validate()) {
      final String name = _nameController.text.trim();
      final Map<String, int?> payments = {};

      // Collect payments data
      _monthControllers.forEach((month, controller) {
        final value = controller.text.trim();
        payments[month] = value.isEmpty ? null : int.parse(value);
      });

      // Add to Firestore
      await FirebaseFirestore.instance.collection('places').add({
        'name': name,
        'payments': payments,
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Place added successfully!')),
      );

      // Clear the form
      _nameController.clear();
      _monthControllers.values.forEach((controller) => controller.clear());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Add New Place'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Place Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              // Place name input
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Place Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.place),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Place name is required';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              Text(
                'Payments',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              // Month-by-month input fields
              Column(
                children: _monthControllers.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: TextFormField(
                      controller: entry.value,
                      decoration: InputDecoration(
                        labelText: entry.key,
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          try {
                            int.parse(value);
                          } catch (_) {
                            return 'Enter a valid number';
                          }
                        }
                        return null;
                      },
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 20),
              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _addPlace,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.all(16),
                    textStyle: TextStyle(fontSize: 16),
                  ),
                  child: Text('Add Place'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
