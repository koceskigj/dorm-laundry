import 'package:dorm_laundry_app/core/widgets/branded_app_bar.dart';
import 'package:flutter/material.dart';

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BrandedAppBar(),
      body: const Center(child: Text('Points & achievements coming next')),
    );
  }
}