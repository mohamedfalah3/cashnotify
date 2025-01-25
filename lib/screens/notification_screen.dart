import 'package:cashnotify/helper/helper_class.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UnpaidRemindersScreen extends StatefulWidget {
  const UnpaidRemindersScreen({super.key});

  @override
  _UnpaidRemindersScreenState createState() => _UnpaidRemindersScreenState();
}

class _UnpaidRemindersScreenState extends State<UnpaidRemindersScreen> {
  final int itemsPerPage = 10;
  int currentPage = 1;
  bool isLoading = false;
  List<Map<String, dynamic>> unpaidReminders = [];

  @override
  void initState() {
    super.initState();
    fetchUnpaidPlaces();
  }

  Future<void> fetchUnpaidPlaces() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      final provider = Provider.of<PaymentProvider>(context, listen: false);
      final allUnpaidPlaces = await provider.getUnpaidPlaces();

      // Implement pagination logic here to show limited results per page.
      final startIndex = (currentPage - 1) * itemsPerPage;
      final endIndex = startIndex + itemsPerPage;
      final newReminders = allUnpaidPlaces.sublist(
          startIndex,
          endIndex > allUnpaidPlaces.length
              ? allUnpaidPlaces.length
              : endIndex);

      setState(() {
        unpaidReminders = newReminders;
      });
    } catch (e) {
      print('Error fetching unpaid reminders: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _goToNextPage() {
    setState(() {
      currentPage++;
    });
    fetchUnpaidPlaces();
  }

  void _goToPreviousPage() {
    if (currentPage > 1) {
      setState(() {
        currentPage--;
      });
      fetchUnpaidPlaces();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Unpaid Reminders - ${DateTime.now().year}'),
        backgroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: Container(
            color: Colors.deepPurple,
            height: 4.0,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: unpaidReminders.isEmpty
                ? Center(
                    child: isLoading
                        ? const CircularProgressIndicator()
                        : Text(
                            'No unpaid reminders found.',
                            style: TextStyle(color: Colors.deepPurple.shade700),
                          ),
                  )
                : ListView.builder(
                    itemCount: unpaidReminders.length,
                    itemBuilder: (context, index) {
                      final reminder = unpaidReminders[index];

                      return Card(
                        color: Colors.white,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.deepPurple,
                            child: Text(
                              (reminder['name']?.isNotEmpty ?? false)
                                  ? (reminder['name'][0].toUpperCase())
                                  : 'U',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            reminder['name'] ?? 'Unknown',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple.shade700,
                            ),
                          ),
                          subtitle: const Text(
                            'Has not paid until today',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (unpaidReminders.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: currentPage > 1 ? _goToPreviousPage : null,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple),
                    child: const Text('Previous'),
                  ),
                  Text(
                    'Page $currentPage',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton(
                    onPressed: unpaidReminders.length == itemsPerPage
                        ? _goToNextPage
                        : null,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple),
                    child: const Text('Next'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
