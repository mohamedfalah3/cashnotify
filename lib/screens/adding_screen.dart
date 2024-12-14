import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddCustomerScreen extends StatefulWidget {
  @override
  _AddCustomerScreenState createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _codeController = TextEditingController();
  final _amountController = TextEditingController();
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
        payments[month] = int.parse(value);
      }
    }

    final items =
        code.split(RegExp(r'\s+')).map((item) => item.toUpperCase()).toList();

    try {
      await _firestore.collection('places').add({
        'name': customerName,
        'items': items,
        'amount': amount.isNotEmpty ? int.parse(amount) : 0,
        'payments': payments,
        'itemsString': items.toString() ?? 'zzzNoItems'
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Customer saved successfully!')),
      );

      // Clear all fields after saving
      _customerNameController.clear();
      _codeController.clear();
      _amountController.clear();
      for (var controller in _monthlyControllers) {
        controller.clear();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save customer: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Add Customer'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Customer Information Section
              Text(
                'Customer Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _customerNameController,
                decoration: InputDecoration(
                  labelText: 'Customer Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Customer name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _codeController,
                decoration: InputDecoration(
                  labelText: 'Code',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Code is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                  suffixText: 'USD',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null &&
                      value.isNotEmpty &&
                      int.tryParse(value) == null) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Monthly Payments Section
              Text(
                'Monthly Payments',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
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
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextFormField(
                              controller: _monthlyControllers[index],
                              decoration: InputDecoration(
                                labelText: 'Amount',
                                border: OutlineInputBorder(),
                                suffixText: 'USD',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value != null &&
                                    value.isNotEmpty &&
                                    int.tryParse(value) == null) {
                                  return 'Enter a valid number';
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
                    child: Text('Mark All as Paid'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      for (var controller in _monthlyControllers) {
                        controller.clear();
                      }
                    },
                    child: Text('Clear All'),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              // Save Button
              Center(
                child: ElevatedButton(
                  onPressed: _saveCustomer,
                  child: Text('Save Customer'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
