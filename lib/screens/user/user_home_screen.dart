import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../services/api.dart';
import '../../models/app_models.dart';
import '../login_screen.dart';
import '../request_service_screen.dart';
import 'user_chatbot_screen.dart';
import 'user_bookings_screen.dart';
import 'user_profile_screen.dart';
import 'select_technician_screen.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  List<Booking>? _recentBookings;
  bool _isLoading = true;
  Map<String, dynamic>? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadRecentBookings();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await Api.getUserProfile();
      if (mounted && profile != null) {
        setState(() {
          _userProfile = Map<String, dynamic>.from(profile);
        });
      }
    } catch (e) {
      // Silently fail, user can still enter address manually
    }
  }

  Future<void> _loadRecentBookings() async {
    setState(() => _isLoading = true);
    try {
      final bookingsData = await Api.getUserBookings();
      if (mounted) {
        setState(() {
          _recentBookings = bookingsData
              ?.map((b) => Booking.fromJson(b))
              .take(3)
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    await Api.logout();
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _openChatbot(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UserChatbotScreen()),
    );
  }

  void _requestService(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RequestServiceScreen()),
    );
  }

  void _viewAllBookings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UserBookingsScreen()),
    );
  }

  Future<void> _selectService(String serviceType) async {
    // Navigate to the new request service screen with pre-selected service
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RequestServiceScreen(
          initialServiceType: serviceType,
        ),
      ),
    );
  }

  // Keep the old flow for backward compatibility
  Future<void> _selectServiceOld(String serviceType) async {
    String? choice;
    
    // Check if user has registered address
    if (_userProfile != null && 
        _userProfile!['address'] != null && 
        _userProfile!['lat'] != null && 
        _userProfile!['lng'] != null) {
      // Show dialog to use registered address or choose different location
      if (!mounted) return;
      choice = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Location'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Use your registered address or choose a different location?'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.home, color: Colors.blueAccent, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _userProfile!['address'],
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.home),
              label: const Text('Use Registered Address'),
              onPressed: () => Navigator.pop(context, 'registered'),
            ),
            TextButton.icon(
              icon: const Icon(Icons.my_location),
              label: const Text('Current Location'),
              onPressed: () => Navigator.pop(context, 'auto'),
            ),
            TextButton.icon(
              icon: const Icon(Icons.edit_location),
              label: const Text('Enter Manually'),
              onPressed: () => Navigator.pop(context, 'manual'),
            ),
          ],
        ),
      );

      if (choice == null) return;
      
      if (choice == 'registered') {
        // Use registered address
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SelectTechnicianScreen(
              serviceType: serviceType,
              address: _userProfile!['address'],
              lat: _userProfile!['lat'].toDouble(),
              lng: _userProfile!['lng'].toDouble(),
            ),
          ),
        );
        return;
      }
    } else {
      // Show dialog to choose location method
      if (!mounted) return;
      choice = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Location'),
          content: const Text('How would you like to provide your location?'),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.my_location),
              label: const Text('Use Current Location'),
              onPressed: () => Navigator.pop(context, 'auto'),
            ),
            TextButton.icon(
              icon: const Icon(Icons.edit_location),
              label: const Text('Enter Manually'),
              onPressed: () => Navigator.pop(context, 'manual'),
            ),
          ],
        ),
      );

      if (choice == null) return;
    }

    if (choice == 'manual') {
      _selectServiceWithManualLocation(serviceType);
      return;
    }

    // Auto location flow
    try {
      // Get user's current location
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationErrorDialog(
          'Location Services Disabled',
          'Please enable location services or enter your address manually.',
          serviceType,
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showLocationErrorDialog(
            'Location Permission Denied',
            'Please grant location permission or enter your address manually.',
            serviceType,
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showLocationErrorDialog(
          'Location Permission Denied',
          'Please enable location permission in settings or enter your address manually.',
          serviceType,
        );
        return;
      }

      // Show loading
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () async {
          // Fallback to last known position
          Position? lastPosition = await Geolocator.getLastKnownPosition();
          if (lastPosition != null) {
            return lastPosition;
          }
          throw Exception('Unable to get location. Please check your location settings.');
        },
      );

      // Get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      String address = 'Current Location';
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        address = '${place.street ?? ''}, ${place.locality ?? ''}, ${place.country ?? ''}'.trim();
        if (address.startsWith(',')) address = address.substring(1).trim();
      }

      // Close loading dialog
      if (!mounted) return;
      Navigator.pop(context);

      // Navigate to technician selection screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SelectTechnicianScreen(
            serviceType: serviceType,
            address: address,
            lat: position.latitude,
            lng: position.longitude,
          ),
        ),
      );
    } catch (e) {
      // Close loading dialog if open
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      String errorTitle = 'Location Error';
      String errorMessage = 'Unable to get your location. Would you like to enter your address manually?';
      
      if (e.toString().contains('location settings')) {
        errorMessage = kIsWeb 
            ? 'Please enable location in your browser or enter your address manually.'
            : 'Please enable location services or enter your address manually.';
      } else if (e.toString().contains('timeout') || e.toString().contains('Unable to get location')) {
        errorMessage = 'Location request timed out. Please check your internet connection or enter your address manually.';
      }
      
      _showLocationErrorDialog(errorTitle, errorMessage, serviceType);
    }
  }

  void _showLocationErrorDialog(String title, String message, String serviceType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _selectServiceWithManualLocation(serviceType);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Enter Address'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectServiceWithManualLocation(String serviceType) async {
    final TextEditingController addressController = TextEditingController();
    
    final address = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Your Address'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Please enter your full address including street, city, and country.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                hintText: 'e.g., 123 Main St, New York, USA',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final addr = addressController.text.trim();
              if (addr.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter an address')),
                );
                return;
              }
              Navigator.pop(context, addr);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (address == null || address.isEmpty) return;

    // Show loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Convert address to coordinates using geocoding
      List<Location> locations;
      
      try {
        locations = await locationFromAddress(address).timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw Exception('Request timed out'),
        );
      } catch (geocodeError) {
        if (mounted) {
          Navigator.pop(context);
          _showSnackBar(
            'Could not find the address. Please check:\n'
            '• Address is complete (street, city, country)\n'
            '• Spelling is correct\n'
            '• Internet connection is active'
          );
        }
        return;
      }
      
      if (locations.isEmpty) {
        if (mounted) {
          Navigator.pop(context);
          _showSnackBar('Could not find the address. Please enter a more specific address.');
        }
        return;
      }

      final location = locations.first;
      
      // Validate coordinates
      if (location.latitude == 0.0 && location.longitude == 0.0) {
        if (mounted) {
          Navigator.pop(context);
          _showSnackBar('Invalid location coordinates. Please try a different address.');
        }
        return;
      }
      
      // Close loading dialog
      if (!mounted) return;
      Navigator.pop(context);

      // Navigate to technician selection screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SelectTechnicianScreen(
            serviceType: serviceType,
            address: address,
            lat: location.latitude,
            lng: location.longitude,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showSnackBar('Unable to process address. Please try again or use current location.');
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "QuickFix",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserProfileScreen()),
              );
            },
            tooltip: 'My Profile',
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () => _openChatbot(context),
            tooltip: 'Chat with QuickFix Assistant',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadRecentBookings,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeSection(),
              const SizedBox(height: 24),
              _buildQuickActions(),
              const SizedBox(height: 24),
              _buildServicesSection(),
              const SizedBox(height: 24),
              _buildRecentBookingsSection(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _requestService(context),
        backgroundColor: Colors.blueAccent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Request Service',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueAccent, Colors.blue.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome Back!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'How can we help you today?',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  icon: Icons.build,
                  label: 'Request Service',
                  color: Colors.blueAccent,
                  onTap: () => _requestService(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.history,
                  label: 'My Bookings',
                  color: Colors.orange,
                  onTap: () => _viewAllBookings(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesSection() {
    final services = [
      {'icon': Icons.plumbing, 'name': 'Plumbing', 'color': Colors.blue},
      {'icon': Icons.electrical_services, 'name': 'Electrical', 'color': Colors.amber},
      {'icon': Icons.carpenter, 'name': 'Carpentry', 'color': Colors.brown},
      {'icon': Icons.format_paint, 'name': 'Painting', 'color': Colors.purple},
      {'icon': Icons.ac_unit, 'name': 'AC Repair', 'color': Colors.cyan},
      {'icon': Icons.cleaning_services, 'name': 'Cleaning', 'color': Colors.green},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Our Services',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              return InkWell(
                onTap: () => _selectService(service['name'] as String),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        service['icon'] as IconData,
                        color: service['color'] as Color,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        service['name'] as String,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentBookingsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Bookings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => _viewAllBookings(context),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_recentBookings == null || _recentBookings!.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.work_outline, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      'No bookings yet',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => _requestService(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Request Your First Service'),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: _recentBookings!
                  .map((booking) => _buildBookingCard(booking))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: booking.getStatusColor().withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.build,
              color: booking.getStatusColor(),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.serviceType.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  booking.location['address'] ?? 'No address',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: booking.getStatusColor().withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              booking.getStatusDisplay(),
              style: TextStyle(
                color: booking.getStatusColor(),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
