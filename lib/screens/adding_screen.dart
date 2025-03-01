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
  final _phoneController = TextEditingController();
  final _joinDateController = TextEditingController();
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
    _phoneController.dispose();
    _joinDateController.dispose();
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
    final phone = _phoneController.text.trim();
    final joinDate = _joinDateController.text.trim();
    final currentUserPayments = <String, dynamic>{};

    final items =
        code.split(RegExp(r'\s+')).map((item) => item.toUpperCase()).toList();

    try {
      await _firestore.collection('places').add({
        'code': code,
        'items': items,
        'itemsString': items.first.toString(),
        'place': _selectedPlace,
        'year': DateTime.now().year,
        'currentUser': {
          'name': customerName,
          'phone': phone,
          'amount':
              amount.isNotEmpty ? int.parse(amount).toString() : 0.toString(),
          // 'aqarat' : 'baxi shaqlawa',
          'joinedDate': joinDate,
          'payments': currentUserPayments,
          'dateLeft': ''
        },
        'previousUsers': [], // You can add logic for previous users if needed
      });
      print(currentUserPayments);

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
      _phoneController.clear();
      _joinDateController.clear();
      setState(() {
        _selectedPlace = null; // Reset to null to reset the dropdown
      });
      for (var controller in _monthlyControllers) {
        controller.clear();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('سەرکەوتوو نەبوو $e'),
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
                label: 'کۆد',
              ),
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
                label: 'بڕی پارە',
              ),
              const SizedBox(height: 10),
              Addingfields(
                controller: _phoneController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'ژمارەی موبایل داواکراوە';
                  }
                  return null;
                },
                label: 'موبایل',
              ),
              const SizedBox(height: 10),
              Addingfields(
                controller: _joinDateController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'تاریخی تێچووی داواکراوە';
                  }
                  return null;
                },
                label: 'تاریخی تێچووی',
                isDateField:
                    true, // Specify that this field is for date selection
              ),
              const SizedBox(height: 20),
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
