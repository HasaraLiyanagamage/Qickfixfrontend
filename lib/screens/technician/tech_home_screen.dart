import 'package:flutter/material.dart';
import '../../services/api.dart';
import '../../models/app_models.dart';
import '../../widgets/modern_card.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/empty_state.dart';
import '../login_screen.dart';
import 'tech_chatbot_screen.dart';
import 'tech_jobs_screen.dart';
import 'tech_profile_screen.dart';
import 'technician_settings_screen.dart';
import 'tech_notifications_screen.dart';
import 'tech_feedback_screen.dart';
import 'tech_verification_screen.dart';

class TechnicianHomeScreen extends StatefulWidget {
  const TechnicianHomeScreen({super.key});

  @override
  State<TechnicianHomeScreen> createState() => _TechnicianHomeScreenState();
}

class _TechnicianHomeScreenState extends State<TechnicianHomeScreen> {
  List<Booking>? _recentJobs;
  bool _isLoading = true;
  bool _isAvailable = true;
  Map<String, dynamic>? _profile;
  int _selectedIndex = 0;
  int _unreadNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadUnreadNotificationCount();
  }

  Future<void> _loadUnreadNotificationCount() async {
    try {
      final count = await Api.getUnreadNotificationCount();
      if (mounted) {
        setState(() {
          _unreadNotificationCount = count;
        });
      }
    } catch (e) {
      // Handle error silently - endpoint may not exist yet
      // Badge will show 0 notifications
      if (mounted) {
        setState(() {
          _unreadNotificationCount = 0;
        });
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final profileData = await Api.getTechnicianProfile();
      final jobsData = await Api.getTechnicianJobs();
      
      if (mounted) {
        setState(() {
          _profile = profileData != null ? Map<String, dynamic>.from(profileData) : null;
          _isAvailable = profileData?['isAvailable'] ?? true;
          
          // Parse all jobs
          final allJobs = jobsData?.map((b) => Booking.fromJson(b)).toList() ?? [];
          
          // Get recent jobs (last 3)
          _recentJobs = allJobs.take(3).toList();
          
          // Update profile with calculated stats if not present
          if (_profile != null) {
            _profile!['totalJobs'] = _profile!['totalJobs'] ?? allJobs.length;
            _profile!['activeJobs'] = allJobs.where((j) => 
              j.status == 'accepted' || j.status == 'in_progress' || j.status == 'matched'
            ).length;
            _profile!['completedJobs'] = allJobs.where((j) => 
              j.status == 'completed'
            ).length;
          }
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleAvailability() async {
    final newStatus = !_isAvailable;
    setState(() => _isAvailable = newStatus);
    
    try {
      await Api.updateTechnicianProfile(isAvailable: newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus ? 'You are now available for jobs' : 'You are now offline'),
            backgroundColor: newStatus ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() => _isAvailable = !newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating availability: $e')),
        );
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
      MaterialPageRoute(builder: (_) => const TechChatbotScreen()),
    );
  }

  void _viewAllJobs(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TechJobsScreen()),
    );
  }

  void _viewProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TechProfileScreen()),
    );
  }

  void _onNavItemTapped(int index) {
    setState(() => _selectedIndex = index);
    
    switch (index) {
      case 0:
        // Already on home
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TechJobsScreen()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TechVerificationScreen()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TechFeedbackScreen()),
        );
        break;
      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TechChatbotScreen()),
        );
        break;
      case 5:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TechnicianSettingsScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "Technician Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.primaryColor,
        elevation: 0,
        actions: [
          // Notifications icon with badge
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined),
                if (_unreadNotificationCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        _unreadNotificationCount > 9 ? '9+' : _unreadNotificationCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TechNotificationsScreen()),
              );
              // Reload notification count after returning
              _loadUnreadNotificationCount();
            },
            tooltip: 'Notifications',
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
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGreetingCard(),
              const SizedBox(height: 16),
              _buildStatusCard(),
              const SizedBox(height: 16),
              _buildStatsSection(),
              const SizedBox(height: 24),
              _buildQuickActions(),
              const SizedBox(height: 24),
              _buildRecentJobsSection(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _viewAllJobs(context),
        backgroundColor: Colors.orangeAccent,
        icon: const Icon(Icons.work, color: Colors.white),
        label: const Text(
          'View Jobs',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.orangeAccent,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work),
            label: 'Jobs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.verified_user),
            label: 'Verify',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star),
            label: 'Feedback',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildGreetingCard() {
    final userName = _profile?['name'] ?? '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orangeAccent, Colors.deepOrange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.waving_hand,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName.isNotEmpty ? '${_getGreeting()}, $userName!' : 'Welcome!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ready to help customers today?',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isAvailable 
              ? [Colors.green.shade400, Colors.green.shade700]
              : [Colors.orange.shade400, Colors.orange.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Status',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isAvailable ? 'Available' : 'Offline',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Switch(
                value: _isAvailable,
                onChanged: (_) => _toggleAvailability(),
                activeThumbColor: Colors.white,
                activeTrackColor: Colors.white30,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: Colors.white30,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _isAvailable 
                ? 'You are visible to customers' 
                : 'Turn on to receive job requests',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    final totalJobs = _profile?['totalJobs'] ?? 0;
    final rating = _profile?['rating'] ?? 0.0;
    final activeJobs = _profile?['activeJobs'] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.work_outline,
              label: 'Total Jobs',
              value: totalJobs.toString(),
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.star,
              label: 'Rating',
              value: rating > 0 ? rating.toStringAsFixed(1) : '0.0',
              color: Colors.amber,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.pending_actions,
              label: 'Active',
              value: activeJobs.toString(),
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
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
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
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
                  icon: Icons.work,
                  label: 'View All Jobs',
                  color: Colors.orangeAccent,
                  onTap: () => _viewAllJobs(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.person,
                  label: 'My Profile',
                  color: Colors.purple,
                  onTap: () => _viewProfile(context),
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

  Widget _buildRecentJobsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Jobs',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => _viewAllJobs(context),
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
          else if (_recentJobs == null || _recentJobs!.isEmpty)
            EmptyState(
              icon: Icons.work_outline,
              title: 'No jobs yet',
              subtitle: _isAvailable 
                  ? 'Jobs will appear here when customers request services'
                  : 'Turn on availability to receive jobs',
            )
          else
            Column(
              children: _recentJobs!
                  .map((job) => _buildJobCard(job))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildJobCard(Booking job) {
    return ModernCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: job.getStatusColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.build,
                  color: job.getStatusColor(),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.serviceType.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      job.location?['address'] ?? 'No address',
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
              _buildStatusBadge(job.status),
            ],
          ),
          if (job.user != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.blueAccent,
                  child: Text(
                    job.user!.name.isNotEmpty ? job.user!.name.substring(0, 1).toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  job.user!.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return StatusBadge.warning('PENDING');
      case 'accepted':
      case 'matched':
        return StatusBadge.info('ACTIVE');
      case 'in_progress':
        return StatusBadge.info('IN PROGRESS');
      case 'completed':
        return StatusBadge.success('COMPLETED');
      case 'cancelled':
        return StatusBadge.error('CANCELLED');
      default:
        return StatusBadge.info(status.toUpperCase());
    }
  }
}
