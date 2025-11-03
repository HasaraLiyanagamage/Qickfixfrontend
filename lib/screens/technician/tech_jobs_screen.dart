import 'package:flutter/material.dart';
import '../../models/app_models.dart';
import '../../services/api.dart';

class TechJobsScreen extends StatefulWidget {
  const TechJobsScreen({super.key});

  @override
  State<TechJobsScreen> createState() => _TechJobsScreenState();
}

class _TechJobsScreenState extends State<TechJobsScreen> {
  List<Booking>? _allJobs;
  bool _isLoading = true;
  String _filter = 'all'; // all, available, active, completed

  @override
  void initState() {
    super.initState();
    _loadJobs();
    _setupSocketListeners();
  }

  void _setupSocketListeners() async {
    // Initialize socket connection
    Api.initSocket();
    
    // Get technician profile to join their room
    try {
      final profileData = await Api.getTechnicianProfile();
      if (profileData != null && profileData['_id'] != null) {
        final techId = profileData['_id'];
        Api.socket?.emit('technician:join', {'technicianId': techId});
        print('Technician joined room: tech_$techId');
      }
    } catch (e) {
      print('Error joining technician room: $e');
    }
    
    // Listen for booking updates
    Api.socket?.on('booking:updated', (data) {
      print('Booking updated via socket: $data');
      if (mounted) {
        _loadJobs();
      }
    });

    // Listen for booking status changes
    Api.socket?.on('booking:status', (data) {
      print('Booking status changed via socket: $data');
      if (mounted) {
        _loadJobs();
      }
    });

    // Listen for booking assignments
    Api.socket?.on('booking:assigned', (data) {
      print('New booking assigned via socket: $data');
      if (mounted) {
        _loadJobs();
      }
    });
  }

  @override
  void dispose() {
    // Clean up socket listeners
    Api.socket?.off('booking:updated');
    Api.socket?.off('booking:status');
    Api.socket?.off('booking:assigned');
    super.dispose();
  }

  Future<void> _loadJobs() async {
    setState(() => _isLoading = true);
    try {
      final jobsData = await Api.getTechnicianJobs();
      print('Jobs data received: ${jobsData?.length ?? 0} jobs');
      
      if (mounted) {
        setState(() {
          if (jobsData != null) {
            _allJobs = [];
            for (var i = 0; i < jobsData.length; i++) {
              try {
                final job = Booking.fromJson(jobsData[i]);
                print('Job ${i + 1}: ${job.serviceType} - Status: ${job.status}');
                _allJobs!.add(job);
              } catch (e) {
                print('Error parsing job $i: $e');
                print('Job data: ${jobsData[i]}');
              }
            }
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading jobs: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading jobs: $e')),
        );
      }
    }
  }

  List<Booking> get _filteredJobs {
    if (_allJobs == null) return [];
    switch (_filter) {
      case 'available':
        return _allJobs!.where((b) =>
          b.status == 'matched' && b.technicianId != null
        ).toList();
      case 'active':
        return _allJobs!.where((b) =>
          b.status == 'accepted' || b.status == 'in_progress'
        ).toList();
      case 'completed':
        return _allJobs!.where((b) =>
          b.status == 'completed' || b.status == 'cancelled'
        ).toList();
      default:
        return _allJobs!;
    }
  }

  Future<void> _acceptJob(Booking job) async {
    try {
      final result = await Api.acceptBooking(job.id);
      if (result != null && mounted) {
        setState(() {
          job = job.copyWith(status: 'accepted', technician: null); // Update would come from refresh
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job accepted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadJobs(); // Refresh the list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error accepting job: $e')),
        );
      }
    }
  }

  Future<void> _updateJobStatus(Booking job, String newStatus) async {
    try {
      final result = await Api.updateBookingStatus(job.id, newStatus);
      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Job status updated to $newStatus')),
        );
        // Reload the entire list to get fresh data from server
        _loadJobs();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update job status')),
          );
        }
      }
    } catch (e) {
      print('Error updating job status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating job status: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('My Jobs', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => setState(() => _filter = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Jobs')),
              const PopupMenuItem(value: 'available', child: Text('Available')),
              const PopupMenuItem(value: 'active', child: Text('Active')),
              const PopupMenuItem(value: 'completed', child: Text('Completed')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredJobs.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadJobs,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredJobs.length,
                    itemBuilder: (context, index) {
                      final job = _filteredJobs[index];
                      return _buildJobCard(job);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadJobs,
        backgroundColor: Colors.orangeAccent,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.work_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No ${_filter == 'all' ? '' : _filter} jobs',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _filter == 'available'
                ? 'New job requests will appear here'
                : 'Your jobs will appear here when assigned',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadJobs,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard(Booking job) {
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
                        job.serviceType.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        job.location?['address'] ?? 'No address provided',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: job.getStatusColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: job.getStatusColor().withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    job.getStatusDisplay(),
                    style: TextStyle(
                      color: job.getStatusColor(),
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
                  '${job.createdAt.day}/${job.createdAt.month}/${job.createdAt.year}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
                if (job.etaMinutes != null) ...[
                  const SizedBox(width: 16),
                  Icon(Icons.timer, size: 16, color: Colors.orange[500]),
                  const SizedBox(width: 4),
                  Text(
                    '${job.etaMinutes} min ETA',
                    style: TextStyle(color: Colors.orange[500], fontSize: 12),
                  ),
                ],
              ],
            ),
            if (job.user != null) ...[
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
                        job.user!.name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.user!.name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          if (job.user!.phone != null)
                            Text(
                              job.user!.phone!,
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
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildActionButtons(job),
                Text(
                  '\$${job.totalCost?.toStringAsFixed(2) ?? 'TBD'}',
                  style: const TextStyle(
                    fontSize: 18,
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

  Widget _buildActionButtons(Booking job) {
    switch (job.status) {
      case 'matched':
        return Row(
          children: [
            OutlinedButton(
              onPressed: () => _updateJobStatus(job, 'cancelled'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                foregroundColor: Colors.red,
              ),
              child: const Text('Decline'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _acceptJob(job),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Accept'),
            ),
          ],
        );
      case 'accepted':
        return Row(
          children: [
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.navigation, size: 16),
              label: const Text('Navigate'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.blueAccent),
                foregroundColor: Colors.blueAccent,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _updateJobStatus(job, 'in_progress'),
              icon: const Icon(Icons.play_arrow, size: 16),
              label: const Text('Start'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      case 'in_progress':
        return Row(
          children: [
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.message, size: 16),
              label: const Text('Chat'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.blueAccent),
                foregroundColor: Colors.blueAccent,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _updateJobStatus(job, 'completed'),
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Complete'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      case 'completed':
        return OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.star_outline, size: 16),
          label: const Text('Rate Customer'),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.orange[500]!),
            foregroundColor: Colors.orange[500],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
