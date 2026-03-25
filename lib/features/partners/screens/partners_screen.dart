import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/widgets/branded_app_bar.dart';
import '../providers/partners_provider.dart';
import '../widgets/partner_details_sheet.dart';

class PartnersScreen extends ConsumerStatefulWidget {
  const PartnersScreen({super.key});

  @override
  ConsumerState<PartnersScreen> createState() => _PartnersScreenState();
}

class _PartnersScreenState extends ConsumerState<PartnersScreen> {
  final Completer<GoogleMapController> _controller = Completer();

  BitmapDescriptor? _customIcon;

  @override
  void initState() {
    super.initState();
    _loadMarker();
  }

  Future<void> _loadMarker() async {
    _customIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/images/laundry_marker.png',
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final partnersAsync = ref.watch(partnersProvider);

    return Scaffold(
      appBar: const BrandedAppBar(),
      body: partnersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (partners) {
          final markers = partners.map((p) {
            return Marker(
              markerId: MarkerId(p.id),
              position: LatLng(p.lat, p.lng),
              icon: _customIcon ?? BitmapDescriptor.defaultMarker,
              onTap: () => _openDetails(p),
            );
          }).toSet();

          return GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(partners.first.lat, partners.first.lng),
              zoom: 13,
            ),
            markers: markers,
            onMapCreated: (controller) {
              _controller.complete(controller);
            },
          );
        },
      ),
    );
  }

  void _openDetails(partner) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => PartnerDetailsSheet(partner: partner),
    );
  }
}