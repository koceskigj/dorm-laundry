class LaundryPartner {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final String street;
  final String workingHours;
  final String phone;
  final String discount;
  final String description;

  LaundryPartner({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.street,
    required this.workingHours,
    required this.phone,
    required this.discount,
    required this.description,
  });

  factory LaundryPartner.fromDoc(String id, Map<String, dynamic> data) {
    return LaundryPartner(
      id: id,
      name: data['name'] ?? '',
      lat: (data['lat'] as num).toDouble(),
      lng: (data['lng'] as num).toDouble(),
      street: data['street'] ?? '',
      workingHours: data['workingHours'] ?? '',
      phone: data['phone'] ?? '',
      discount: data['discount'] ?? '',
      description: data['description'] ?? '',
    );
  }
}