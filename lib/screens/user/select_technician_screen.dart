import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/api.dart';
import '../tracking_screen.dart';

class SelectTechnicianScreen extends StatefulWidget {
  final String serviceType;
  final String address;
  final double lat;
  final double lng;
  final Map<String, dynamic>? package;
  final bool isPackage;

  const SelectTechnicianScreen({
    super.key,
    required this.serviceType,
    required this.address,
    required this.lat,
    required this.lng,
    this.package,
    this.isPackage = false,
  });

  @override
  State<SelectTechnicianScreen> createState() => _SelectTechnicianScreenState();
}

class _SelectTechnicianScreenState extends State<SelectTechnicianScreen> {
  List<Map<String, dynamic>> _technicians = [];
  bool _isLoading = true;
  bool _isBooking = false;

  @override
  void initState() {
    super.initState();
    _loadTechnicians();
  }

  Future<void> _loadTechnicians() async {
    setState(() => _isLoading = true);
    try {
      print('Loading technicians for ${widget.serviceType} at (${widget.lat}, ${widget.lng})');
      
      final techniciansData = await Api.getAvailableTechnicians(
        serviceType: widget.serviceType,
        lat: widget.lat,
        lng: widget.lng,
        radiusKm: 50,
      );

      if (mounted) {
        if (techniciansData != null && techniciansData.isNotEmpty) {
          // Calculate distance for each technician (backend already calculates, but recalculate for accuracy)
          List<Map<String, dynamic>> techList = [];
          for (var tech in techniciansData) {
            final techData = Map<String, dynamic>.from(tech);
            
            // Use backend-calculated distance if available, otherwise calculate
            if (techData['distance'] != null) {
              // Backend already calculated distance
              print('Technician ${techData['user']?['name']}: ${techData['distance']}km (from backend)');
            } else if (techData['location'] != null && 
                techData['location']['coordinates'] != null) {
              final coords = techData['location']['coordinates'];
              if (coords.length >= 2) {
                final distance = Geolocator.distanceBetween(
                  widget.lat,
                  widget.lng,
                  coords[1], // lat
                  coords[0], // lng
                ) / 1000; // convert to km
                techData['distance'] = distance;
                print('Technician ${techData['user']?['name']}: ${distance.toStringAsFixed(2)}km (calculated)');
              }
            }
            techList.add(techData);
          }

          // Sort by distance (ascending) - closest first
          techList.sort((a, b) {
            final distA = a['distance'] ?? 999999;
            final distB = b['distance'] ?? 999999;
            return distA.compareTo(distB);
          });

          print('Loaded ${techList.length} technicians within 50km');
          
          setState(() {
            _technicians = techList;
            _isLoading = false;
          });
        } else {
          print('No technicians found for ${widget.serviceType} within 50km of (${widget.lat}, ${widget.lng})');
          setState(() {
            _technicians = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading technicians: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Error loading technicians: $e');
      }
    }
  }

  Future<void> _bookTechnician(String technicianId, String technicianName) async {
    setState(() => _isBooking = true);
    try {
      dynamic result;
      
      // Check if this is a package booking
      if (widget.isPackage && widget.package != null) {
        // Book package with location and technician
        result = await Api.bookServicePackage(
          widget.package!['_id'],
          location: {
            'latitude': widget.lat,
            'longitude': widget.lng,
            'address': widget.address,
          },
          technicianId: technicianId,
        );
      } else {
        // Regular service booking
        result = await Api.createBooking(
          serviceType: widget.serviceType,
          lat: widget.lat,
          lng: widget.lng,
          address: widget.address,
          technicianId: technicianId,
        );
      }

      if (mounted) {
        setState(() => _isBooking = false);
        if (result != null && result['booking'] != null) {
          // Backend returns 'id', not '_id'
          final bookingId = (result['booking']['id'] as String?) ?? '';
          
          if (bookingId.isEmpty) {
            _showSnackBar('Failed to create booking: Invalid booking ID');
            return;
          }
          
          final message = widget.isPackage 
              ? 'Package booked successfully with $technicianName!'
              : 'Booking created successfully with $technicianName!';
          _showSnackBar(message);
          
          // Navigate to tracking screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => BookingTrackingScreen(
                bookingId: bookingId,
                technicianName: technicianName,
                serviceType: widget.serviceType,
                userLat: widget.lat,
                userLng: widget.lng,
                userAddress: widget.address,
              ),
            ),
          );
        } else {
          _showSnackBar('Failed to create booking. Please try again.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isBooking = false);
        _showSnackBar('Error: $e');
      }
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Select Technician - ${widget.serviceType}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _technicians.isEmpty
              ? _buildEmptyState()
              : _buildTechnicianList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person_search, size: 60, color: Colors.orange[400]),
            ),
            const SizedBox(height: 24),
            Text(
              'No ${_capitalizeServiceType(widget.serviceType)} Technicians Found',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'We couldn\'t find any technicians with "${widget.serviceType}" skills in your area.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tips:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Try increasing the search radius\n'
                    '• Check if the address is correct\n'
                    '• Try again later when more technicians are available',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue[800],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _loadTechnicians,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _capitalizeServiceType(String service) {
    return service.split(' ').map((word) => 
      word.isEmpty ? word : word[0].toUpperCase() + word.substring(1).toLowerCase()
    ).join(' ');
  }

  IconData _getServiceIcon(String serviceType) {
    final service = serviceType.toLowerCase();
    switch (service) {
      case 'plumbing':
        return Icons.plumbing;
      case 'electrical':
        return Icons.electrical_services;
      case 'carpentry':
        return Icons.carpenter;
      case 'painting':
        return Icons.format_paint;
      case 'cleaning':
        return Icons.cleaning_services;
      case 'hvac':
        return Icons.ac_unit;
      case 'handyman':
        return Icons.handyman;
      case 'emergency':
        return Icons.emergency;
      default:
        return Icons.build;
    }
  }

  Widget _buildTechnicianList() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[400]!, Colors.blue[600]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_getServiceIcon(widget.serviceType), size: 16, color: Colors.blue[700]),
                        const SizedBox(width: 6),
                        Text(
                          _capitalizeServiceType(widget.serviceType),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_technicians.length} Available',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.address,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadTechnicians,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _technicians.length,
              itemBuilder: (context, index) {
                final tech = _technicians[index];
                return _buildTechnicianCard(tech);
              },
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildTechnicianCard(Map<String, dynamic> tech) {
    final user = tech['user'] as Map<String, dynamic>?;
    final name = (user?['name'] as String?) ?? 'Unknown';
    final phone = (user?['phone'] as String?) ?? '';
    final distance = tech['distance'] as double?;
    final rating = (tech['rating'] as num?)?.toDouble() ?? 4.5;
    final skills = (tech['skills'] as List<dynamic>?) ?? [];
    final techId = (tech['_id'] as String?) ?? '';
    
    // Skip rendering if techId is empty
    if (techId.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blueAccent,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'T',
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
                        name,
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
                          Text(
                            rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (distance != null) ...[
                            const SizedBox(width: 12),
                            Icon(Icons.location_on, color: Colors.grey[600], size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${distance.toStringAsFixed(1)} km',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (phone.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.phone, color: Colors.grey[600], size: 14),
                            const SizedBox(width: 4),
                            Text(
                              phone,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (skills.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Skills:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: skills.map((skill) {
                      final isRequestedService = skill.toString().toLowerCase() == widget.serviceType.toLowerCase();
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isRequestedService ? Colors.green[500] : Colors.blue[50],
                          borderRadius: BorderRadius.circular(16),
                          border: isRequestedService 
                              ? Border.all(color: Colors.green[700]!, width: 1.5)
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isRequestedService)
                              const Icon(Icons.check_circle, size: 14, color: Colors.white),
                            if (isRequestedService)
                              const SizedBox(width: 4),
                            Text(
                              skill.toString(),
                              style: TextStyle(
                                fontSize: 12,
                                color: isRequestedService ? Colors.white : Colors.blue[700],
                                fontWeight: isRequestedService ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isBooking ? null : () => _bookTechnician(techId, name),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isBooking
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Book This Technician',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
