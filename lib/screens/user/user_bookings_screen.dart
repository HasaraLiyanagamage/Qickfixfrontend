import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/app_models.dart';
import '../../services/api.dart';
import '../../utils/logger.dart';
import '../../utils/app_theme.dart';
import '../../widgets/modern_card.dart';
import '../../widgets/gradient_header.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/empty_state.dart';
import '../tracking_screen.dart';
import '../chat_screen.dart';
import 'booking_payment_screen.dart';

class UserBookingsScreen extends StatefulWidget {
  const UserBookingsScreen({super.key});

  @override
  State<UserBookingsScreen> createState() => _UserBookingsScreenState();
}

class _UserBookingsScreenState extends State<UserBookingsScreen> {
  List<Booking>? _bookings;
  bool _isLoading = true;
  String _filter = 'all'; // all, active, completed
  Set<String> _favoriteTechnicianIds = {}; // Track favorite technicians

  @override
  void initState() {
    super.initState();
    _loadBookings();
    _loadFavorites();
    _setupSocketListeners();
  }

  Future<void> _loadFavorites() async {
    try {
      final favorites = await Api.getFavorites();
      if (favorites != null && mounted) {
        setState(() {
          _favoriteTechnicianIds = favorites
              .map((fav) => fav['technician']?['_id'] as String?)
              .where((id) => id != null)
              .cast<String>()
              .toSet();
        });
      }
    } catch (e) {
      AppLogger.error('Error loading favorites', error: e);
    }
  }

  Future<void> _toggleFavorite(Booking booking) async {
    if (booking.technician == null) return;
    
    final technicianId = booking.technician!.id;
    final isFavorite = _favoriteTechnicianIds.contains(technicianId);
    
    try {
      bool success;
      if (isFavorite) {
        success = await Api.removeFavorite(technicianId);
        if (success && mounted) {
          setState(() {
            _favoriteTechnicianIds.remove(technicianId);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Removed ${booking.technician!.user!.name} from favorites'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        success = await Api.addFavorite(technicianId);
        if (success && mounted) {
          setState(() {
            _favoriteTechnicianIds.add(technicianId);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added ${booking.technician!.user!.name} to favorites'),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: 'VIEW',
                textColor: Colors.white,
                onPressed: () {
                  Navigator.pushNamed(context, '/favorites');
                },
              ),
            ),
          );
        }
      }
      
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update favorites. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Error toggling favorite', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
        AppLogger.info('User joined room: user_$userId');
      }
    } catch (e) {
      AppLogger.error('Error joining user room', error: e);
    }

    // Listen for booking updates (status changes, assignments, etc.)
    Api.socket?.on('booking:updated', (data) {
      AppLogger.debug('Booking updated via socket: $data');
      if (mounted) {
        _loadBookings(); // Reload all bookings when any update occurs
      }
    });

    // Listen for booking status changes
    Api.socket?.on('booking:status', (data) {
      AppLogger.debug('Booking status changed via socket: $data');
      if (mounted) {
        _loadBookings();
      }
    });

    // Listen for technician acceptance
    Api.socket?.on('booking:accepted', (data) {
      AppLogger.debug('Booking accepted via socket: $data');
      if (mounted) {
        _loadBookings();
      }
    });

    // Listen for booking completion
    Api.socket?.on('booking:completed', (data) {
      AppLogger.debug('Booking completed via socket: $data');
      if (mounted) {
        _loadBookings();
      }
    });

    // Listen for payment confirmation by technician
    Api.socket?.on('payment:confirmed', (data) {
      AppLogger.debug('Payment confirmed via socket: $data');
      if (mounted) {
        _loadBookings();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment confirmed by technician!'),
            backgroundColor: AppTheme.success,
            duration: const Duration(seconds: 3),
          ),
        );
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
    Api.socket?.off('payment:confirmed');
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    try {
      final bookingsData = await Api.getUserBookings();
      AppLogger.info(
          'Bookings data received: ${bookingsData?.length ?? 0} bookings');

      if (mounted) {
        setState(() {
          if (bookingsData != null) {
            _bookings = [];
            for (var i = 0; i < bookingsData.length; i++) {
              try {
                final booking = Booking.fromJson(bookingsData[i]);
                AppLogger.debug(
                    'Booking ${i + 1}: ${booking.serviceType} - Status: ${booking.status}');
                _bookings!.add(booking);
              } catch (e) {
                AppLogger.error('Error parsing booking $i', error: e);
                AppLogger.debug('Booking data: ${bookingsData[i]}');
              }
            }
          }
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error loading bookings',
          error: e, stackTrace: stackTrace);
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
        return _bookings!
            .where((b) =>
                b.status == 'requested' ||
                b.status == 'matched' ||
                b.status == 'accepted' ||
                b.status == 'in_progress')
            .toList();
      case 'completed':
        return _bookings!
            .where((b) => b.status == 'completed' || b.status == 'cancelled')
            .toList();
      default:
        return _bookings!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            title: 'My Bookings',
            subtitle: 'Track your service requests',
            icon: Icons.work,
            action: PopupMenuButton<String>(
              onSelected: (value) => setState(() => _filter = value),
              icon: const Icon(Icons.filter_list, color: Colors.white),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'all', child: Text('All Bookings')),
                const PopupMenuItem(value: 'active', child: Text('Active')),
                const PopupMenuItem(
                    value: 'completed', child: Text('Completed')),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/request-service'),
        backgroundColor: AppTheme.primaryBlue,
        icon: const Icon(Icons.add),
        label: const Text('New Request'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return EmptyState(
      icon: Icons.work_outline,
      title: 'No ${_filter == 'all' ? '' : _filter} bookings',
      subtitle: 'Your service requests will appear here',
      actionText: 'Request Service',
      onAction: () => Navigator.pushNamed(context, '/request-service'),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    return ModernCard(
      margin: const EdgeInsets.only(bottom: 12),
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _getServiceColor(booking.serviceType)
                                    .withValues(alpha: 0.2),
                                _getServiceColor(booking.serviceType)
                                    .withValues(alpha: 0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getServiceIcon(booking.serviceType),
                            color: _getServiceColor(booking.serviceType),
                            size: 20,
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
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                booking.location?['address'] ?? 'No address',
                                style: TextStyle(
                                  color:
                                      AppTheme.getSecondaryTextColor(context),
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(booking.status),
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
                      booking.technician!.user!.name.isNotEmpty
                          ? booking.technician!.user!.name.substring(0, 1).toUpperCase()
                          : '?',
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
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _toggleFavorite(booking),
                    icon: Icon(
                      Icons.favorite,
                      size: 20,
                      color: _favoriteTechnicianIds.contains(booking.technician!.id) 
                          ? Colors.red 
                          : Colors.grey[400],
                    ),
                    tooltip: _favoriteTechnicianIds.contains(booking.technician!.id)
                        ? 'Remove from favorites' 
                        : 'Add to favorites',
                  ),
                  IconButton(
                    onPressed: () => _callTechnician(booking),
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
              // Payment/Quotation button for specific statuses
              if (booking.status == 'quoted' || 
                  booking.status == 'quote_approved' ||
                  booking.status == 'inspecting' ||
                  booking.status == 'completed' ||
                  booking.status == 'payment_pending') ...[
                // Show appropriate button based on status and payment
                if (booking.status == 'quoted') ...[
                  ElevatedButton.icon(
                    onPressed: () => _openPaymentScreen(booking),
                    icon: const Icon(Icons.receipt_long, size: 16),
                    label: const Text('View Quote'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                ] else if (booking.isPaymentPending) ...[
                  // Show awaiting confirmation when payment is pending
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.hourglass_empty, size: 16, color: Colors.orange[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Awaiting confirmation',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ] else if (booking.needsPayment) ...[
                  // Only show Pay Now if work is completed but not paid and not pending
                  ElevatedButton.icon(
                    onPressed: () => _openPaymentScreen(booking),
                    icon: const Icon(Icons.payment, size: 16),
                    label: const Text('Pay Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentGreen,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                ] else if (booking.isPaid) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 16, color: Colors.green[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Paid',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
              
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (booking.status == 'completed') ...[
                      if (booking.hasRating) ...[
                        // Show rating if already rated
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ...List.generate(5, (index) {
                                return Icon(
                                  index < (booking.ratingScore ?? 0)
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 20,
                                );
                              }),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'You rated ${booking.ratingScore} star${(booking.ratingScore ?? 0) > 1 ? 's' : ''}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // Show rate button if not yet rated
                        OutlinedButton.icon(
                          onPressed: () => _showRatingDialog(booking),
                          icon: const Icon(Icons.star_outline, size: 16),
                          label: const Text('Rate'),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.orange[500]!),
                            foregroundColor: Colors.orange[500],
                          ),
                        ),
                      ],
                    ] else if (booking.status == 'in_progress') ...[
                      OutlinedButton.icon(
                        onPressed: () => _openChat(booking),
                        icon: const Icon(Icons.message, size: 16),
                        label: const Text('Chat'),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.blueAccent),
                          foregroundColor: Colors.blueAccent,
                        ),
                      ),
                    ] else if (booking.status == 'accepted' ||
                        booking.status == 'matched') ...[
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
                  ],
                ),
              ),
            ],
          ),
          if (booking.totalCost != null) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Cost:',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  '\$${booking.totalCost?.toStringAsFixed(2) ?? 'TBD'}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ],
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
      if (booking.location!.containsKey('coordinates') &&
          booking.location!['coordinates'] is List) {
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

  void _openPaymentScreen(Booking booking) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingPaymentScreen(
          bookingId: booking.id,
        ),
      ),
    ).then((result) {
      // Reload bookings if payment was completed
      if (result == true) {
        _loadBookings();
      }
    });
  }

  void _callTechnician(Booking booking) async {
    if (booking.technician?.user?.phone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number not available')),
      );
      return;
    }

    final phoneNumber = booking.technician!.user!.phone!;
    final uri = Uri.parse('tel:$phoneNumber');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch phone dialer')),
        );
      }
    }
  }

  void _openChat(Booking booking) {
    if (booking.technician == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No technician assigned yet')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          bookingId: booking.id,
          otherPartyName: booking.technician!.user!.name,
          serviceType: booking.serviceType,
        ),
      ),
    );
  }

  void _showRatingDialog(Booking booking) {
    int selectedRating = 0;
    final reviewController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Rate Service'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                    'How was your experience with ${booking.technician?.user?.name}?'),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      onPressed: () {
                        setState(() {
                          selectedRating = index + 1;
                        });
                      },
                      icon: Icon(
                        index < selectedRating ? Icons.star : Icons.star_border,
                        color: Colors.orange,
                        size: 32,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reviewController,
                  decoration: const InputDecoration(
                    hintText: 'Write a review (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedRating > 0
                  ? () async {
                      final navigator = Navigator.of(context);
                      final messenger = ScaffoldMessenger.of(context);
                      navigator.pop();
                      final result = await Api.rateBooking(
                        bookingId: booking.id,
                        score: selectedRating,
                        review: reviewController.text.trim(),
                      );
                      if (mounted) {
                        if (result != null) {
                          messenger.showSnackBar(
                            const SnackBar(
                                content: Text('Thank you for your rating!')),
                          );
                          _loadBookings();
                        } else {
                          messenger.showSnackBar(
                            const SnackBar(
                                content: Text('Failed to submit rating')),
                          );
                        }
                      }
                    }
                  : null,
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return StatusBadge.success('COMPLETED');
      case 'payment_pending':
        return StatusBadge.warning('PAYMENT PENDING');
      case 'in_progress':
        return StatusBadge.info('IN PROGRESS');
      case 'quote_approved':
        return StatusBadge.success('QUOTE APPROVED');
      case 'quoted':
        return StatusBadge.warning('QUOTED');
      case 'inspecting':
        return StatusBadge.warning('INSPECTING');
      case 'arrived':
        return StatusBadge.info('ARRIVED');
      case 'accepted':
        return StatusBadge.info('ACCEPTED');
      case 'matched':
        return StatusBadge.warning('MATCHED');
      case 'requested':
        return StatusBadge.warning('REQUESTED');
      case 'cancelled':
        return StatusBadge.error('CANCELLED');
      default:
        return StatusBadge.info(status.toUpperCase());
    }
  }

  Color _getServiceColor(String serviceType) {
    switch (serviceType.toLowerCase()) {
      case 'plumbing':
        return Colors.blue;
      case 'electrical':
        return Colors.orange;
      case 'carpentry':
        return Colors.brown;
      case 'painting':
        return Colors.purple;
      case 'cleaning':
        return Colors.green;
      case 'hvac':
        return Colors.cyan;
      case 'handyman':
        return Colors.grey;
      case 'emergency':
        return Colors.red;
      default:
        return AppTheme.primaryBlue;
    }
  }

  IconData _getServiceIcon(String serviceType) {
    switch (serviceType.toLowerCase()) {
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
}
