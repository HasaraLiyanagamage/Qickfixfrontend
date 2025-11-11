import 'package:flutter/material.dart';
import '../../services/api.dart';
import '../../models/app_models.dart';
import '../../utils/logger.dart';
import '../../utils/app_theme.dart';
import 'package:intl/intl.dart';

class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Booking>? _allBookings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    try {
      final bookingsData = await Api.getAllBookings();
      if (mounted) {
        setState(() {
          if (bookingsData != null) {
            _allBookings = [];
            for (var i = 0; i < bookingsData.length; i++) {
              try {
                final booking = Booking.fromJson(bookingsData[i]);
                _allBookings!.add(booking);
              } catch (e) {
                AppLogger.error('Error parsing booking $i', error: e);
              }
            }
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.error('Error loading bookings', error: e);
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Booking> _getFilteredBookings(String filter) {
    if (_allBookings == null) return [];
    
    switch (filter) {
      case 'pending':
        return _allBookings!.where((b) => b.status == 'pending' || b.status == 'matched').toList();
      case 'active':
        return _allBookings!.where((b) => b.status == 'accepted' || b.status == 'in_progress').toList();
      case 'completed':
        return _allBookings!.where((b) => b.status == 'completed').toList();
      case 'all':
      default:
        return _allBookings!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Booking Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.accentPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          isScrollable: true,
          tabs: [
            Tab(
              icon: const Icon(Icons.list),
              text: 'All (${_allBookings?.length ?? 0})',
            ),
            Tab(
              icon: const Icon(Icons.pending_actions),
              text: 'Pending (${_getFilteredBookings('pending').length})',
            ),
            Tab(
              icon: const Icon(Icons.work),
              text: 'Active (${_getFilteredBookings('active').length})',
            ),
            Tab(
              icon: const Icon(Icons.check_circle),
              text: 'Completed (${_getFilteredBookings('completed').length})',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBookingsList('all'),
                _buildBookingsList('pending'),
                _buildBookingsList('active'),
                _buildBookingsList('completed'),
              ],
            ),
    );
  }

  Widget _buildBookingsList(String filter) {
    final bookings = _getFilteredBookings(filter);

    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No ${filter == 'all' ? '' : filter} bookings found',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return _buildBookingCard(booking);
        },
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    final statusColor = _getStatusColor(booking.status);
    final statusIcon = _getStatusIcon(booking.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showBookingDetails(booking),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with service type and status
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getServiceColor(booking.serviceType).withValues(alpha: 0.2),
                          _getServiceColor(booking.serviceType).withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getServiceIcon(booking.serviceType),
                      color: _getServiceColor(booking.serviceType),
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
                          booking.location?['address'] ?? _getLocationText(booking.location),
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          _formatStatus(booking.status),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              
              // User and Technician Info
              if (booking.user != null || booking.technician != null) ...[
                Row(
                  children: [
                    // User info
                    if (booking.user != null) ...[
                      Expanded(
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.blue.shade100,
                              child: Icon(Icons.person, size: 16, color: Colors.blue.shade700),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    booking.user!.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    booking.user!.email,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.person, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              'User: ${booking.userId.substring(0, 8)}...',
                              style: TextStyle(color: Colors.grey[700], fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    const SizedBox(width: 12),
                    
                    // Technician info
                    if (booking.technician != null) ...[
                      Expanded(
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.orange.shade100,
                              child: Icon(Icons.engineering, size: 16, color: Colors.orange.shade700),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    booking.technician!.user!.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (booking.technician!.skills.isNotEmpty)
                                    Text(
                                      booking.technician!.skills.take(2).join(', '),
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 11,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (booking.technicianId != null) ...[
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.engineering, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              'Tech: ${booking.technicianId!.substring(0, 8)}...',
                              style: TextStyle(color: Colors.grey[700], fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.engineering_outlined, size: 16, color: Colors.grey[400]),
                            const SizedBox(width: 4),
                            Text(
                              'No technician',
                              style: TextStyle(color: Colors.grey[500], fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
              ],
              
              // Time and Cost Info
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM d, yyyy HH:mm').format(booking.createdAt),
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  ),
                  if (booking.etaMinutes != null) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.timer, size: 16, color: Colors.orange[500]),
                    const SizedBox(width: 4),
                    Text(
                      '${booking.etaMinutes} min ETA',
                      style: TextStyle(color: Colors.orange[500], fontSize: 13),
                    ),
                  ],
                  const Spacer(),
                  if (booking.totalCost != null) ...[
                    Text(
                      '\$${booking.totalCost!.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ],
              ),
              
              // Notes if available
              if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.note, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          booking.notes!,
                          style: TextStyle(color: Colors.grey[700], fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Rating if available
              if (booking.ratingScore != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    ...List.generate(5, (index) {
                      return Icon(
                        index < booking.ratingScore! ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 16,
                      );
                    }),
                    const SizedBox(width: 8),
                    Text(
                      '${booking.ratingScore}/5',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showBookingDetails(Booking booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(_getServiceIcon(booking.serviceType), color: _getServiceColor(booking.serviceType)),
            const SizedBox(width: 8),
            Expanded(child: Text(booking.serviceType)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Booking ID', booking.id),
              _buildDetailRow('Status', _formatStatus(booking.status)),
              const Divider(),
              _buildDetailRow('Service Type', booking.serviceType),
              if (booking.totalCost != null)
                _buildDetailRow('Total Cost', '\$${booking.totalCost!.toStringAsFixed(2)}'),
              if (booking.etaMinutes != null)
                _buildDetailRow('ETA', '${booking.etaMinutes} minutes'),
              const Divider(),
              if (booking.user != null) ...[
                _buildDetailRow('User Name', booking.user!.name),
                _buildDetailRow('User Email', booking.user!.email),
                if (booking.user!.phone != null)
                  _buildDetailRow('User Phone', booking.user!.phone!),
              ] else
                _buildDetailRow('User ID', booking.userId),
              const Divider(),
              if (booking.technician != null) ...[
                _buildDetailRow('Technician Name', booking.technician!.user!.name),
                _buildDetailRow('Technician Email', booking.technician!.user!.email),
                if (booking.technician!.user!.phone != null)
                  _buildDetailRow('Technician Phone', booking.technician!.user!.phone!),
                if (booking.technician!.skills.isNotEmpty)
                  _buildDetailRow('Skills', booking.technician!.skills.join(', ')),
                if (booking.technician!.rating != null)
                  _buildDetailRow('Tech Rating', '${booking.technician!.rating!.toStringAsFixed(1)}/5'),
              ] else if (booking.technicianId != null)
                _buildDetailRow('Technician ID', booking.technicianId!)
              else
                _buildDetailRow('Technician', 'Not assigned'),
              const Divider(),
              _buildDetailRow('Location', booking.location?['address'] ?? _getLocationText(booking.location)),
              _buildDetailRow('Created', DateFormat('MMM d, yyyy HH:mm').format(booking.createdAt)),
              if (booking.updatedAt != null)
                _buildDetailRow('Updated', DateFormat('MMM d, yyyy HH:mm').format(booking.updatedAt!)),
              if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                const Divider(),
                _buildDetailRow('Notes', booking.notes!),
              ],
              if (booking.ratingScore != null) ...[
                const Divider(),
                _buildDetailRow('Rating', '${booking.ratingScore}/5 stars'),
                if (booking.ratingReview != null && booking.ratingReview!.isNotEmpty)
                  _buildDetailRow('Review', booking.ratingReview!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'matched':
        return Colors.blue;
      case 'accepted':
        return Colors.purple;
      case 'in_progress':
        return Colors.indigo;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'matched':
        return Icons.person_search;
      case 'accepted':
        return Icons.check_circle_outline;
      case 'in_progress':
        return Icons.build;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  String _formatStatus(String status) {
    return status.split('_').map((word) => 
      word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }

  IconData _getServiceIcon(String serviceType) {
    final type = serviceType.toLowerCase();
    if (type.contains('plumb')) return Icons.plumbing;
    if (type.contains('electr')) return Icons.electrical_services;
    if (type.contains('paint')) return Icons.format_paint;
    if (type.contains('carpen')) return Icons.carpenter;
    if (type.contains('clean')) return Icons.cleaning_services;
    if (type.contains('ac') || type.contains('air')) return Icons.ac_unit;
    return Icons.build;
  }

  Color _getServiceColor(String serviceType) {
    final type = serviceType.toLowerCase();
    if (type.contains('plumb')) return Colors.blue;
    if (type.contains('electr')) return Colors.amber;
    if (type.contains('paint')) return Colors.purple;
    if (type.contains('carpen')) return Colors.brown;
    if (type.contains('clean')) return Colors.teal;
    if (type.contains('ac') || type.contains('air')) return Colors.cyan;
    return Colors.grey;
  }

  String _getLocationText(Map<String, dynamic>? location) {
    if (location == null) return 'N/A';
    if (location['address'] != null) return location['address'];
    final lat = location['coordinates']?[1] ?? location['lat'];
    final lng = location['coordinates']?[0] ?? location['lng'];
    if (lat != null && lng != null) {
      return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
    }
    return 'N/A';
  }
}
