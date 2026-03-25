import 'package:flutter/material.dart';
import '../models/laundry_partner.dart';

class PartnerDetailsSheet extends StatelessWidget {
  final LaundryPartner partner;

  const PartnerDetailsSheet({super.key, required this.partner});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            partner.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),

          _row(Icons.location_on, partner.street),
          _row(Icons.access_time, partner.workingHours),
          _row(Icons.phone, partner.phone),
          _row(Icons.discount, partner.discount),

          const SizedBox(height: 10),

          Text(
            partner.description,
            style: TextStyle(color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}