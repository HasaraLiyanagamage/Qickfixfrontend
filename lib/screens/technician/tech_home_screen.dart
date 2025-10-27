import 'package:flutter/material.dart';
import '../../models/app_models.dart';
import '../../services/api.dart';
import 'tech_jobs_screen.dart';
import 'tech_profile_screen.dart';

class TechnicianHomeScreen extends StatefulWidget {
  const TechnicianHomeScreen({super.key});

  @override
  State<TechnicianHomeScreen> createState() => _TechnicianHomeScreenState();
}

class _TechnicianHomeScreenState extends State<TechnicianHomeScreen> {
  int _currentIndex = 0;
  Technician? _technician;
  List<Booking>? _assignedJobs;
  bool _isLoading = true;
  bool _isAvailable = true;
  double _todayEarnings = 0.0;
  int _completedJobs = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Load technician profile
      final profile = await Api.getTechnicianProfile();
      if (profile != null) {
        setState(() {
          _technician = Technician.fromJson(profile['technician']);
          _isAvailable = _technician?.isAvailable ?? true;
        });
      }

      // Load assigned jobs
      final jobs = await Api.getUserBookings(); // This would need a separate endpoint
      if (jobs != null) {
        setState(() {
          _assignedJobs = jobs.map((b) => Booking.fromJson(b)).where((b) =>
            b.technicianId == _technician?.id &&
            (b.status == 'matched' || b.status == 'accepted' || b.status == 'in_progress')
          ).toList();
        });
      }

      // Calculate earnings and completed jobs (mock data for now)
      _calculateStats();

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _calculateStats() {
    // This would come from API in real implementation
    _todayEarnings = 150.0;
    _completedJobs = 3;
  }

  Future<void> _toggleAvailability() async {
    setState(() => _isLoading = true);
    try {
      final result = await Api.updateTechnicianLocation(
        0.0, // current lat
        0.0, // current lng
        isAvailable: !_isAvailable,
      );

      if (result != null) {
        setState(() {
          _isAvailable = !_isAvailable;
          if (_technician != null) {
            _technician = _technician!.copyWith(isAvailable: _isAvailable);
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isAvailable ? 'You are now available for jobs' : 'You are now unavailable'),
              backgroundColor: _isAvailable ? Colors.green : Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating availability: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Technician Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          Switch(
            value: _isAvailable,
            onChanged: (_) => _toggleAvailability(),
            activeThumbColor: Colors.green,
          ),
          const SizedBox(width: 8),
          Text(
            _isAvailable ? 'Available' : 'Busy',
            style: TextStyle(
              color: _isAvailable ? Colors.green : Colors.orange,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsCards(),
                  const SizedBox(height: 24),
                  _buildAvailabilityStatus(),
                  const SizedBox(height: 24),
                  _buildActiveJobs(),
                  const SizedBox(height: 24),
                  _buildQuickActions(),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          switch (index) {
            case 0: // Jobs
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TechJobsScreen()),
              );
              break;
            case 1: // Chat
              // Navigate to chat screen
              break;
            case 2: // Profile
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TechProfileScreen()),
              );
              break;
          }
        },
        selectedItemColor: Colors.orangeAccent,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.work_outline), label: 'Jobs'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
      floatingActionButton: _isAvailable ? FloatingActionButton(
        onPressed: () => _showLocationUpdateDialog(),
        backgroundColor: Colors.orangeAccent,
        child: const Icon(Icons.my_location),
      ) : null,
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Today\'s Earnings',
            '\$${_todayEarnings.toStringAsFixed(0)}',
            Icons.attach_money,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Completed Jobs',
            '$_completedJobs',
            Icons.check_circle,
            Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
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
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isAvailable ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isAvailable ? Colors.green[200]! : Colors.orange[200]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isAvailable ? Icons.check_circle : Icons.schedule,
            color: _isAvailable ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isAvailable ? 'You are Available' : 'You are Busy',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _isAvailable ? Colors.green[800] : Colors.orange[800],
                  ),
                ),
                Text(
                  _isAvailable
                      ? 'You will receive new job requests'
                      : 'You won\'t receive new job requests',
                  style: TextStyle(
                    fontSize: 12,
                    color: _isAvailable ? Colors.green[600] : Colors.orange[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isAvailable,
            onChanged: (_) => _toggleAvailability(),
            activeThumbColor: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveJobs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Active Jobs',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TechJobsScreen()),
              ),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_assignedJobs == null || _assignedJobs!.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: const Center(
              child: Text(
                'No active jobs',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _assignedJobs!.length > 2 ? 2 : _assignedJobs!.length,
            itemBuilder: (context, index) {
              final job = _assignedJobs![index];
              return _buildJobCard(job);
            },
          ),
      ],
    );
  }

  Widget _buildJobCard(Booking job) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: job.getStatusColor().withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.work_outline,
              color: job.getStatusColor(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.serviceType.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  job.location['address'] ?? 'No address',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  job.getStatusDisplay(),
                  style: TextStyle(
                    color: job.getStatusColor(),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${job.totalCost?.toStringAsFixed(0) ?? 'TBD'}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              if (job.etaMinutes != null)
                Text(
                  '${job.etaMinutes}min',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Update Location',
                Icons.my_location,
                Colors.blue,
                () => _showLocationUpdateDialog(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'View Profile',
                Icons.person,
                Colors.purple,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TechProfileScreen()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Job History',
                Icons.history,
                Colors.orange,
                () {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'Settings',
                Icons.settings,
                Colors.grey,
                () {},
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showLocationUpdateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Location'),
        content: const Text(
          'This will update your current location for better job matching. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Here you would get current location and update
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Location updated successfully!')),
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
