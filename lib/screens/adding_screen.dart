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
  final _aqaratController = TextEditingController();
  final _phoneController = TextEditingController();
  final _taminat = TextEditingController();
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
    _aqaratController.dispose();
    _phoneController.dispose();
    _taminat.dispose();
    _joinDateController.dispose();
    for (var controller in _monthlyControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final customerName = _customerNameController.text.trim();
    final code = _codeController.text.trim();
    final amount = _amountController.text.trim();
    final phone = _phoneController.text.trim();
    final aqarat = _aqaratController.text.trim();
    final taminat = _taminat.text.trim();
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
          'aqarat': aqarat,
          'taminat': taminat,
          'joinedDate': joinDate,
          'payments': currentUserPayments,
          'information': {},
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
      _aqaratController.clear();
      _taminat.clear();
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
          preferredSize: const Size.fromHeight(4.0), // Line height
          child: Container(
            color: const Color.fromARGB(255, 0, 122, 255),
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
                value: _selectedPlace,
                style: const TextStyle(
                  color: Colors.black, // Ensure selected text is visible
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  // Background color so text is always visible
                  labelText: 'شوێن',
                  labelStyle: const TextStyle(
                    color: Color.fromARGB(255, 0, 122, 255),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(
                      color: Color.fromARGB(255, 0, 122, 255),
                      width: 2,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(
                      color: Color.fromARGB(255, 0, 122, 255),
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(
                      color: Colors.blueAccent,
                      width: 2,
                    ),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                dropdownColor: const Color.fromARGB(255, 0, 122, 255),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedPlace = newValue; // Ensure state updates correctly
                  });
                },
                items:
                    ['گەنجان سیتی', 'عەینکاوە', 'کورانی عەینکاوە'].map((place) {
                  return DropdownMenuItem<String>(
                    value: place,
                    child: Text(
                      place,
                      style: const TextStyle(
                          color: Colors.black), // Ensure text is visible
                    ),
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
                controller: _aqaratController,
                validator: (value) {
                  return null;
                },
                label: 'عقارات',
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
                controller: _taminat,
                validator: (value) {
                  if (value != null &&
                      value.isNotEmpty &&
                      (int.tryParse(value) == null || int.parse(value) < 0)) {
                    return 'ژمارەی گونجاو تۆمار بکە';
                  }
                  return null;
                },
                label: 'بڕی تامینات',
              ),
              const SizedBox(height: 10),
              Addingfields(
                controller: _phoneController,
                validator: (value) {
                  // Iraqi phone number regex: starts with 07 and has 9 more digits
                  final RegExp iraqPhoneRegex = RegExp(r'^07[0-9]{9}$');
                  if (!iraqPhoneRegex.hasMatch(value!)) {
                    return 'تکایە ژمارەی دروست بنوسە (11 ژمارە بەپێی 07)';
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
                    return null;
                  }
                  return null;
                },
                label: 'بەرواری هاتن',
                isDateField:
                    true, // Specify that this field is for date selection
              ),
              const SizedBox(height: 20),

              // Save Button
              Center(
                child: ElevatedButton(
                  onPressed: _saveCustomer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 0, 122, 255),
                    // Button color
                    foregroundColor: Colors.white,
                    // Text color
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(25), // Rounded corners
                    ),
                    elevation: 5,
                    // Adds a shadow effect
                    shadowColor: Colors.blueAccent, // Shadow color
                  ),
                  child: const Text(
                    'داخل کردن بۆ سیستەم',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2, // Slight text spacing for elegance
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
