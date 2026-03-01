import 'package:flutter/material.dart';
import '../../../core/widgets/branded_app_bar.dart';

class AdminStudentsScreen extends StatelessWidget {
  const AdminStudentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: BrandedAppBar(),
      body: Center(
        child: Text(
          'Students screen (next)\nSearch by studentId/email + details page.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}