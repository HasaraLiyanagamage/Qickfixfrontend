import 'package:flutter/material.dart';
import '../../models/app_models.dart';
import '../../services/api.dart';
import '../tracking_screen.dart';

class UserBookingsScreen extends StatefulWidget {
  const UserBookingsScreen({super.key});

  @override
  State<UserBookingsScreen> createState() => _UserBookingsScreenState();
}

class _UserBookingsScreenState extends State<UserBookingsScreen> {
  List<Booking>? _bookings;
  bool _isLoading = true;
  String _filter = 'all'; // all, active, completed

  @override
  void initState() {
    super.initState();
    _loadBookings();
    _setupSocketListeners();
  }

  void _setupSocketListeners() async {
    // Initialize socket connection
    Api.initSocket();
    
    // Get user profile to join their room
    try {
      final profileData = await Api.getUserProfile();
      if (profileData != null && profileData['_id'] != null) {
        final userId = profileData['_id'];
        Api.socket?.emit('user:join', {'userId': userId});
        print('User joined room: user_$userId');
      }
    } catch (e) {
      print('Error joining user room: $e');
    }
    
    // Listen for booking updates (status changes, assignments, etc.)
    Api.socket?.on('booking:updated', (data) {
      print('Booking updated via socket: $data');
      if (mounted) {
        _loadBookings(); // Reload all bookings when any update occurs
      }
    });

    // Listen for booking status changes
    Api.socket?.on('booking:status', (data) {
      print('Booking status changed via socket: $data');
      if (mounted) {
        _loadBookings();
      }
    });

    // Listen for technician acceptance
    Api.socket?.on('booking:accepted', (data) {
      print('Booking accepted via socket: $data');
      if (mounted) {
        _loadBookings();
      }
    });

    // Listen for booking completion
    Api.socket?.on('booking:completed', (data) {
      print('Booking completed via socket: $data');
      if (mounted) {
        _loadBookings();
      }
    });
  }

  @override
  void dispose() {
    // Clean up socket listeners
    Api.socket?.off('booking:updated');
    Api.socket?.off('booking:status');
    Api.socket?.off('booking:accepted');
    Api.socket?.off('booking:completed');
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    try {
      final bookingsData = await Api.getUserBookings();
      print('Bookings data received: $bookingsData');
      
      if (mounted) {
        setState(() {
          if (bookingsData != null) {
            _bookings = [];
            for (var i = 0; i < bookingsData.length; i++) {
              try {
                final booking = Booking.fromJson(bookingsData[i]);
                _bookings!.add(booking);
              } catch (e) {
                print('Error parsing booking $i: $e');
                print('Booking data: ${bookingsData[i]}');
              }
            }
          }
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('Error loading bookings: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading bookings: $e')),
        );
      }
    }
  }

  List<Booking> get _filteredBookings {
    if (_bookings == null) return [];
    switch (_filter) {
      case 'active':
        return _bookings!.where((b) =>
          b.status == 'requested' ||
          b.status == 'matched' ||
          b.status == 'accepted' ||
          b.status == 'in_progress'
        ).toList();
      case 'completed':
        return _bookings!.where((b) =>
          b.status == 'completed' || b.status == 'cancelled'
        ).toList();
      default:
        return _bookings!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('My Bookings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => setState(() => _filter = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Bookings')),
              const PopupMenuItem(value: 'active', child: Text('Active')),
              const PopupMenuItem(value: 'completed', child: Text('Completed')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredBookings.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadBookings,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredBookings.length,
                    itemBuilder: (context, index) {
                      final booking = _filteredBookings[index];
                      return _buildBookingCard(booking);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/request-service'),
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.work_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No ${_filter == 'all' ? '' : _filter} bookings',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your service requests will appear here',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/request-service'),
            icon: const Icon(Icons.add),
            label: const Text('Request Service'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.serviceType.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        booking.location?['address'] ?? 'No address provided',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
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
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: booking.getStatusColor().withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    booking.getStatusDisplay(),
                    style: TextStyle(
                      color: booking.getStatusColor(),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  '${booking.createdAt.day}/${booking.createdAt.month}/${booking.createdAt.year}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
                if (booking.etaMinutes != null) ...[
                  const SizedBox(width: 16),
                  Icon(Icons.timer, size: 16, color: Colors.orange[500]),
                  const SizedBox(width: 4),
                  Text(
                    '${booking.etaMinutes} min ETA',
                    style: TextStyle(color: Colors.orange[500], fontSize: 12),
                  ),
                ],
              ],
            ),
            if (booking.technician != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.blueAccent,
                      child: Text(
                        booking.technician!.user!.name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.technician!.user!.name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          if (booking.technician!.skills.isNotEmpty)
                            Text(
                              booking.technician!.skills.join(', '),
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.phone, size: 20),
                      color: Colors.green,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (booking.status == 'completed') ...[
                  OutlinedButton.icon(
                    onPressed: () => _showRatingDialog(booking),
                    icon: const Icon(Icons.star_outline, size: 16),
                    label: const Text('Rate Service'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.orange[500]!),
                      foregroundColor: Colors.orange[500],
                    ),
                  ),
                ] else if (booking.status == 'in_progress') ...[
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.message, size: 16),
                    label: const Text('Chat'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.blueAccent),
                      foregroundColor: Colors.blueAccent,
                    ),
                  ),
                ] else if (booking.status == 'accepted' || booking.status == 'matched') ...[
                  ElevatedButton.icon(
                    onPressed: () => _openTracking(booking),
                    icon: const Icon(Icons.navigation, size: 16),
                    label: const Text('Track'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
                Text(
                  '\$${booking.totalCost?.toStringAsFixed(2) ?? 'TBD'}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openTracking(Booking booking) {
    if (booking.technician == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No technician assigned yet')),
      );
      return;
    }

    // Handle both coordinate formats: [lng, lat] array or lat/lng fields
    double userLat = 0;
    double userLng = 0;
    
    if (booking.location != null) {
      if (booking.location!.containsKey('coordinates') && booking.location!['coordinates'] is List) {
        userLng = booking.location!['coordinates'][0].toDouble();
        userLat = booking.location!['coordinates'][1].toDouble();
      } else {
        userLat = (booking.location!['lat'] ?? 0).toDouble();
        userLng = (booking.location!['lng'] ?? 0).toDouble();
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingTrackingScreen(
          bookingId: booking.id,
          technicianName: booking.technician!.user!.name,
          serviceType: booking.serviceType,
          userLat: userLat,
          userLng: userLng,
          userAddress: booking.location?['address'] ?? 'Your location',
        ),
      ),
    );
  }

  void _showRatingDialog(Booking booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rate Service'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('How was your experience with ${booking.technician?.user?.name}?'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: () {},
                  icon: Icon(
                    index < 4 ? Icons.star : Icons.star_border,
                    color: Colors.orange,
                  ),
                );
              }),
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
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Thank you for your rating!')),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
