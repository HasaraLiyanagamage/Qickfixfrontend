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
  bool _mapError = false;

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
      body: _mapError
          ? _buildMapErrorWidget()
          : GoogleMap(
              initialCameraPosition: CameraPosition(target: initial, zoom: 14),
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
              markers: techMarker != null ? {techMarker!} : {},
            ),
      // Fallback UI in case Google Maps fails to load
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(content: Text('Map tracking feature - Technician location: ${techMarker?.position ?? 'Unknown'}'))
          );
        },
        child: Icon(Icons.location_on),
      ),
    );
  }

  Widget _buildMapErrorWidget() {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Map unavailable',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            SizedBox(height: 8),
            Text(
              'Unable to load Google Maps',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() => _mapError = false);
              },
              child: Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
