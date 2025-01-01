import 'package:cashnotify/widgets/addingFields.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  _AddCustomerScreenState createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _codeController = TextEditingController();
  final _amountController = TextEditingController();
  final _placeController = TextEditingController();
  String? _selectedPlace;
  final List<TextEditingController> _monthlyControllers = List.generate(
    12,
    (index) => TextEditingController(),
  );

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _customerNameController.dispose();
    _codeController.dispose();
    _amountController.dispose();
    _placeController.dispose();
    for (var controller in _monthlyControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  String monthName(int month) {
    const monthNames = [
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
    return monthNames[month - 1];
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final customerName = _customerNameController.text.trim();
    final code = _codeController.text.trim();
    final amount = _amountController.text.trim();
    final Map<String, dynamic> payments = {};

    for (int i = 0; i < 12; i++) {
      final month = monthName(i + 1);
      final value = _monthlyControllers[i].text.trim();
      if (value.isNotEmpty) {
        payments[month] = int.parse(value).toString();
      }
    }

    final items =
        code.split(RegExp(r'\s+')).map((item) => item.toUpperCase()).toList();

    try {
      await _firestore.collection('places').add({
        'name': customerName,
        'items': items,
        'amount':
            amount.isNotEmpty ? int.parse(amount).toString() : 0.toString(),
        'payments': payments,
        'itemsString': items.first.toString(),
        'place': _selectedPlace,
        'year': DateTime.now().year,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('بە سەرکەوتویی تۆمارکرا'),
          backgroundColor: Colors.green,
        ),
      );

      // Clear all fields after saving
      _customerNameController.clear();
      _codeController.clear();
      _amountController.clear();
      _placeController.clear();
      setState(() {
        _selectedPlace = null; // Reset to null to reset the dropdown
      });
      for (var controller in _monthlyControllers) {
        controller.clear();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('سەرکەوتوو نەبوو$e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('زیادکردنی شوێن'),
        backgroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(4.0), // Line height
          child: Container(
            color: Colors.deepPurple, // Line color
            height: 4.0, // Line height
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'زانیاری کەسی',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Addingfields(
                controller: _customerNameController,
                validator: (value) {
                  return null;
                },
                label: 'ناو',
              ),
              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                style: const TextStyle(color: Colors.black),
                dropdownColor: Colors.deepPurpleAccent,
                value: _selectedPlace,
                // A variable to hold the selected value (Ganjan City or Ainkawa)
                decoration: InputDecoration(
                  labelText: 'شوێن',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedPlace = newValue;
                  });
                },
                items: ['Ganjan City', 'Ainkawa', 'Shuqa'].map((place) {
                  return DropdownMenuItem<String>(
                    value: place,
                    child: Text(place),
                  );
                }).toList(),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'شوێن داواکراوە';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              Addingfields(
                  controller: _codeController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'کۆد داواکراوە';
                    }
                    return null;
                  },
                  label: 'کۆد'),
              const SizedBox(height: 10),
              Addingfields(
                  controller: _amountController,
                  validator: (value) {
                    if (value != null &&
                        value.isNotEmpty &&
                        (int.tryParse(value) == null || int.parse(value) < 0)) {
                      return 'ژمارەی گونجاو تۆمار بکە';
                    }
                    return null;
                  },
                  label: 'بڕی پارە'),
              const SizedBox(height: 20),

              // Monthly Payments Section
              const Text(
                'پارەی مانگانە',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    final month = monthName(index + 1);
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              month,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextFormField(
                              controller: _monthlyControllers[index],
                              decoration: InputDecoration(
                                labelText: 'بڕی پارە',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                suffixText: 'USD',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value != null &&
                                    value.isNotEmpty &&
                                    int.tryParse(value) == null) {
                                  return 'ژمارەی گونجاو تۆمار بکە';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      for (var controller in _monthlyControllers) {
                        controller.text = _amountController.text;
                      }
                    },
                    child: const Text('هەموو دراوە'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      for (var controller in _monthlyControllers) {
                        controller.clear();
                      }
                    },
                    child: const Text('سڕینەوەی هەموو'),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              // Save Button
              Center(
                child: ElevatedButton(
                  onPressed: _saveCustomer,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 15),
                  ),
                  child: const Text('داخل کردن بۆ سیستەم'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
