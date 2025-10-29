import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api.dart';
import 'dart:async';

class BookingTrackingScreen extends StatefulWidget {
  final String bookingId;
  final String technicianName;
  final String serviceType;
  final double userLat;
  final double userLng;
  final String userAddress;

  const BookingTrackingScreen({
    super.key,
    required this.bookingId,
    required this.technicianName,
    required this.serviceType,
    required this.userLat,
    required this.userLng,
    required this.userAddress,
  });

  @override
  State<BookingTrackingScreen> createState() => _BookingTrackingScreenState();
}

class _BookingTrackingScreenState extends State<BookingTrackingScreen> {
  GoogleMapController? _mapController;
  final Completer<GoogleMapController> _controller = Completer();
  
  LatLng? _technicianLocation;
  late LatLng _userLocation;
  
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  
  double? _distanceInKm;
  int? _etaInMinutes;
  String _bookingStatus = 'pending';
  
  Timer? _locationUpdateTimer;
  bool _mapError = false;

  @override
  void initState() {
    super.initState();
    _userLocation = LatLng(widget.userLat, widget.userLng);
    _initializeTracking();
  }

  void _initializeTracking() {
    // Initialize socket connection
    Api.initSocket();
    
    // Listen for technician location updates
    Api.socket?.on('technician:location:${widget.bookingId}', (data) {
      if (data != null && mounted) {
        _updateTechnicianLocation(data);
      }
    });

    // Listen for booking status updates
    Api.socket?.on('booking:status:${widget.bookingId}', (data) {
      if (data != null && mounted) {
        setState(() {
          _bookingStatus = data['status'] ?? 'pending';
        });
      }
    });

    // Set up user marker
    _updateMarkers();
    
    // Poll for updates every 10 seconds as fallback
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _fetchBookingDetails();
    });
    
    // Initial fetch
    _fetchBookingDetails();
  }

  Future<void> _fetchBookingDetails() async {
    // This would fetch the latest booking details from the API
    // For now, we'll rely on socket updates
  }

  void _updateTechnicianLocation(Map<String, dynamic> data) {
    final lat = data['lat'];
    final lng = data['lng'];
    
    if (lat != null && lng != null) {
      setState(() {
        _technicianLocation = LatLng(lat.toDouble(), lng.toDouble());
        _updateMarkers();
        _updateRoute();
        _calculateDistanceAndETA();
      });

      // Animate camera to show both markers
      _fitMapToMarkers();
    }
  }

  void _updateMarkers() {
    _markers.clear();

    // User location marker
    _markers.add(
      Marker(
        markerId: const MarkerId('user'),
        position: _userLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(
          title: 'Your Location',
          snippet: widget.userAddress,
        ),
      ),
    );

    // Technician location marker
    if (_technicianLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('technician'),
          position: _technicianLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: widget.technicianName,
            snippet: 'Technician',
          ),
        ),
      );
    }
  }

  void _updateRoute() {
    if (_technicianLocation == null) return;

    _polylines.clear();
    
    // Create a simple straight line route (in production, use Google Directions API)
    _polylines.add(
      Polyline(
        polylineId: const PolylineId('route'),
        points: [_technicianLocation!, _userLocation],
        color: Colors.blueAccent,
        width: 4,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
      ),
    );
  }

  void _calculateDistanceAndETA() {
    if (_technicianLocation == null) return;

    // Calculate distance using Haversine formula
    final distance = Geolocator.distanceBetween(
      _technicianLocation!.latitude,
      _technicianLocation!.longitude,
      _userLocation.latitude,
      _userLocation.longitude,
    );

    setState(() {
      _distanceInKm = distance / 1000;
      // Estimate ETA assuming average speed of 30 km/h
      _etaInMinutes = (_distanceInKm! / 30 * 60).round();
    });
  }

  Future<void> _fitMapToMarkers() async {
    if (_technicianLocation == null || _mapController == null) return;

    final bounds = LatLngBounds(
      southwest: LatLng(
        _technicianLocation!.latitude < _userLocation.latitude
            ? _technicianLocation!.latitude
            : _userLocation.latitude,
        _technicianLocation!.longitude < _userLocation.longitude
            ? _technicianLocation!.longitude
            : _userLocation.longitude,
      ),
      northeast: LatLng(
        _technicianLocation!.latitude > _userLocation.latitude
            ? _technicianLocation!.latitude
            : _userLocation.latitude,
        _technicianLocation!.longitude > _userLocation.longitude
            ? _technicianLocation!.longitude
            : _userLocation.longitude,
      ),
    );

    final controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    Api.socket?.off('technician:location:${widget.bookingId}');
    Api.socket?.off('booking:status:${widget.bookingId}');
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Map
          _mapError
              ? _buildMapErrorWidget()
              : GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _userLocation,
                    zoom: 14,
                  ),
                  onMapCreated: (GoogleMapController controller) {
                    if (!_controller.isCompleted) {
                      _controller.complete(controller);
                      _mapController = controller;
                    }
                  },
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                ),
          
          // Top info card
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopInfoCard(),
          ),
          
          // Bottom details card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomDetailsCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopInfoCard() {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getStatusText(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.serviceType,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (_etaInMinutes != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$_etaInMinutes min',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomDetailsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Technician info
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blueAccent,
                    child: Text(
                      widget.technicianName.isNotEmpty
                          ? widget.technicianName[0].toUpperCase()
                          : 'T',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.technicianName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            const Text(
                              '4.8',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (_distanceInKm != null) ...[
                              const SizedBox(width: 12),
                              Icon(Icons.location_on,
                                  color: Colors.grey[600], size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '${_distanceInKm!.toStringAsFixed(1)} km away',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.phone, color: Colors.blueAccent),
                    onPressed: () {
                      // Call technician
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Calling technician...')),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.message, color: Colors.blueAccent),
                    onPressed: () {
                      // Message technician
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Opening chat...')),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Destination
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.blueAccent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Service Location',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.userAddress,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Cancel button (only if pending)
              if (_bookingStatus == 'pending' || _bookingStatus == 'accepted')
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      _showCancelDialog();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Cancel Booking',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
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
            const SizedBox(height: 16),
            Text(
              'Map unavailable',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Unable to load Google Maps',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() => _mapError = false);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText() {
    switch (_bookingStatus) {
      case 'pending':
        return 'Finding Technician...';
      case 'accepted':
        return 'Technician on the way';
      case 'in-progress':
        return 'Technician arrived';
      case 'completed':
        return 'Service completed';
      case 'cancelled':
        return 'Booking cancelled';
      default:
        return 'Tracking your booking';
    }
  }

  Color _getStatusColor() {
    switch (_bookingStatus) {
      case 'accepted':
        return Colors.green;
      case 'in-progress':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelBooking();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelBooking() async {
    // Call API to cancel booking
    final result = await Api.updateBookingStatus(widget.bookingId, 'cancelled');
    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking cancelled')),
      );
      Navigator.pop(context);
    }
  }
}
