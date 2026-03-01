import 'package:flutter/material.dart';
import '../../../core/widgets/branded_app_bar.dart';

class AdminStatsScreen extends StatelessWidget {
  const AdminStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: BrandedAppBar(),
      body: Center(
        child: Text(
          'Stats screen (next)\nWill show totals + charts once bookings/history exist.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}