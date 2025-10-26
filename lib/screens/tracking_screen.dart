import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/api.dart';
import 'dart:async';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  late GoogleMapController mapController;
  final Completer<GoogleMapController> _controller = Completer();
  final LatLng initial = LatLng(6.9271,79.8612);
  Marker? techMarker;

  @override
  void initState(){
    super.initState();
    // listen to socket
    Api.initSocket();
    Api.socket?.on('tech:location', (data) {
      if (data == null) return;
      final lat = data['lat'];
      final lng = data['lng'];
      final techMarkerNew = Marker(markerId: MarkerId('tech'), position: LatLng(lat, lng), infoWindow: InfoWindow(title: 'Technician'));
      setState(()=> techMarker = techMarkerNew);
      _controller.future.then((c) {
        c.animateCamera(CameraUpdate.newLatLng(LatLng(lat, lng)));
      });
    });
  }

  @override Widget build(BuildContext ctx) {
    return Scaffold(
      appBar: AppBar(title: Text('Tracking')),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(target: initial, zoom: 14),
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
        markers: techMarker != null ? {techMarker!} : {},
      )
    );
  }
}
