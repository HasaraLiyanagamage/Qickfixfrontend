import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/app_theme.dart';
import '../widgets/modern_card.dart';
import '../widgets/gradient_header.dart';
import 'user/select_technician_screen.dart';

class RequestServiceScreen extends StatefulWidget {
  final String? initialServiceType;
  final Map<String, dynamic>? package;
  final bool isPackage;
  
  const RequestServiceScreen({
    super.key, 
    this.initialServiceType,
    this.package,
    this.isPackage = false,
  });

  @override
  State<RequestServiceScreen> createState() => _RequestServiceScreenState();
}

class _RequestServiceScreenState extends State<RequestServiceScreen> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String? _selectedService;
  bool _isLoadingLocation = false;
  bool _isGeocodingAddress = false;
  String _searchQuery = '';

  final List<Map<String, dynamic>> _services = [
    {'name': 'Plumbing', 'icon': Icons.plumbing, 'color': Colors.blue},
    {'name': 'Electrical', 'icon': Icons.electrical_services, 'color': Colors.orange},
    {'name': 'Carpentry', 'icon': Icons.carpenter, 'color': Colors.brown},
    {'name': 'Painting', 'icon': Icons.format_paint, 'color': Colors.purple},
    {'name': 'Cleaning', 'icon': Icons.cleaning_services, 'color': Colors.green},
    {'name': 'HVAC', 'icon': Icons.ac_unit, 'color': Colors.cyan},
    {'name': 'Handyman', 'icon': Icons.handyman, 'color': Colors.grey},
    {'name': 'Emergency', 'icon': Icons.emergency, 'color': Colors.red},
  ];

  @override
  void initState() {
    super.initState();
    _selectedService = widget.initialServiceType ?? widget.package?['name'];
  }

  @override
  void dispose() {
    _addressController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredServices {
    if (_searchQuery.isEmpty) {
      return _services;
    }
    return _services.where((service) {
      return service['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnackBar('Location services are disabled');
        setState(() => _isLoadingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar('Location permission denied');
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition();
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final address = '${place.street}, ${place.locality}, ${place.administrativeArea}';
        setState(() {
          _addressController.text = address;
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      _showSnackBar('Failed to get location: $e');
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _proceedToTechnicians() async {
    if (_selectedService == null) {
      _showSnackBar('Please select a service');
      return;
    }

    if (_addressController.text.trim().isEmpty) {
      _showSnackBar('Please enter your address');
      return;
    }

    setState(() => _isGeocodingAddress = true);

    try {
      // Geocode the address
      List<Location> locations = [];
      final address = _addressController.text.trim();
      
      try {
        locations = await locationFromAddress(address);
      } catch (e) {
        // Try with Sri Lanka appended
        if (!address.toLowerCase().contains('sri lanka')) {
          locations = await locationFromAddress('$address, Sri Lanka');
        }
      }

      double lat;
      double lng;

      if (locations.isNotEmpty) {
        lat = locations.first.latitude;
        lng = locations.first.longitude;
      } else {
        // Use Sri Lanka center if geocoding fails
        lat = 7.8731;
        lng = 80.7718;
      }

      setState(() => _isGeocodingAddress = false);

      // Navigate to technician selection screen
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SelectTechnicianScreen(
            serviceType: _selectedService!.toLowerCase(),
            address: _addressController.text.trim(),
            lat: lat,
            package: widget.package,
            isPackage: widget.isPackage,
            lng: lng,
          ),
        ),
      );
    } catch (e) {
      setState(() => _isGeocodingAddress = false);
      _showSnackBar('Could not process address. Please try again.');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            title: 'Request Service',
            subtitle: 'Choose a service and enter your location',
            icon: Icons.build_circle,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'What service do you need?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Search Bar
                  TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search services (e.g., plumbing, electrical)...',
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                      prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    ),
                  ),
                  const SizedBox(height: 16),

              // Service Selection Grid
              _filteredServices.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No services found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try searching for "plumbing", "electrical", or "emergency"',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.3,
                ),
                itemCount: _filteredServices.length,
                itemBuilder: (context, index) {
                  final service = _filteredServices[index];
                  final isSelected = _selectedService == service['name'];
                  
                  return ModernCard(
                    onTap: () {
                      setState(() {
                        _selectedService = service['name'];
                      });
                    },
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [
                              service['color'] as Color,
                              (service['color'] as Color).withValues(alpha: 0.8),
                            ],
                          )
                        : null,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: (service['color'] as Color).withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ]
                        : null,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          service['icon'],
                          size: 40,
                          color: isSelected ? Colors.white : service['color'],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          service['name'],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              // Address Section
              const Text(
                'Where do you need the service?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Address Input
              TextField(
                controller: _addressController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Enter your complete address\ne.g., 23 Siyane St, Gampaha, Sri Lanka',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  prefixIcon: const Icon(Icons.location_on, color: Colors.blueAccent),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),

              // Use Current Location Button
              OutlinedButton.icon(
                onPressed: _isLoadingLocation ? null : _useCurrentLocation,
                icon: _isLoadingLocation
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
                label: Text(_isLoadingLocation ? 'Getting location...' : 'Use Current Location'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  side: const BorderSide(color: Colors.blueAccent),
                  foregroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Continue Button
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isGeocodingAddress ? null : _proceedToTechnicians,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isGeocodingAddress
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Find Technicians',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Info Card
              ModernCard(
                color: AppTheme.info.withValues(alpha: 0.1),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.info, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'We\'ll show you available technicians near your location',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.info,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
