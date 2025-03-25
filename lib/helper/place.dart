class Place {
  final String id;
  final String? name;
  final double? amount;
  final List<String>? items;
  final String? itemsString;
  final String? place;
  final String? phone;
  final String? joinedDate;
  Map<String, dynamic>? currentUser;
  final int? year;
  List<Map<String, dynamic>>? previousUsers;

  Place({
    required this.id,
    this.name,
    this.amount,
    this.items,
    this.itemsString,
    this.place,
    this.phone,
    this.joinedDate,
    this.currentUser,
    this.year,
    this.previousUsers,
  });

  // Add a method to handle parsing from Firestore
  factory Place.fromFirestore(String id, Map<String, dynamic> data) {
    return Place(
      id: id,
      name: data['currentUser']?['name'],
      phone: data['currentUser']?['phone'],
      joinedDate: data['currentUser']?['joinedDate'],
      amount: data['amount'] != null
          ? double.tryParse(data['amount'].toString())
          : null,
      items: List<String>.from(data['items'] ?? []),
      itemsString: data['itemsString'],
      place: data['place'],
      currentUser: data['currentUser'],
      year: data['year'],
      previousUsers: (data['previousUsers'] as List<dynamic>?)
          ?.map((e) => Map<String, dynamic>.from(e))
          .toList(),
    );
  }
}
