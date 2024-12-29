class Place {
  String id;
  String? name; // Nullable name
  String? amount; // Nullable amount
  Map<String, String>? comments; // Nullable comments
  List<String>? items; // Nullable items
  Map<String, String?>? payments; // Nullable payments
  int year;
  String? itemsString; // Nullable itemsString
  String? place; // Nullable place

  // Constructor
  Place({
    required this.id,
    this.name,
    this.amount,
    this.comments,
    this.items,
    this.payments,
    required this.year,
    this.itemsString,
    this.place,
  });
}
