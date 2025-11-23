import 'package:flutter/material.dart';
import '../../services/api.dart';
import '../../utils/logger.dart';
import '../../utils/app_theme.dart';
import '../../widgets/modern_card.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/empty_state.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic>? _users;
  List<dynamic>? _technicians;
  bool _isLoadingUsers = true;
  bool _isLoadingTechnicians = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUsers();
    _loadTechnicians();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoadingUsers = true);
    try {
      final usersData = await Api.getAllUsers();
      if (mounted) {
        setState(() {
          _users = usersData?.where((user) => user['role'] == 'user').toList();
          _isLoadingUsers = false;
        });
      }
    } catch (e) {
      AppLogger.error('Error loading users', error: e);
      if (mounted) {
        setState(() => _isLoadingUsers = false);
      }
    }
  }

  Future<void> _loadTechnicians() async {
    setState(() => _isLoadingTechnicians = true);
    try {
      final usersData = await Api.getAllUsers();
      if (mounted) {
        setState(() {
          _technicians = usersData?.where((user) => user['role'] == 'technician').toList();
          _isLoadingTechnicians = false;
        });
      }
    } catch (e) {
      AppLogger.error('Error loading technicians', error: e);
      if (mounted) {
        setState(() => _isLoadingTechnicians = false);
      }
    }
  }

  Future<void> _updateUserStatus(String userId, String status) async {
    try {
      final result = await Api.updateUserStatus(userId, status);
      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User status updated to $status'),
            backgroundColor: Colors.green,
          ),
        );
        _loadUsers();
        _loadTechnicians();
      }
    } catch (e) {
      AppLogger.error('Error updating user status', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteUser(String userId, String userName) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete $userName? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final result = await Api.deleteUser(userId);
      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User $userName deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadUsers();
        _loadTechnicians();
      }
    } catch (e) {
      AppLogger.error('Error deleting user', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'User Management',
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
          tabs: const [
            Tab(
              icon: Icon(Icons.people),
              text: 'Users',
            ),
            Tab(
              icon: Icon(Icons.engineering),
              text: 'Technicians',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUsersList(),
          _buildTechniciansList(),
        ],
      ),
    );
  }

  Widget _buildUsersList() {
    if (_isLoadingUsers) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_users == null || _users!.isEmpty) {
      return EmptyState(
        icon: Icons.people_outline,
        title: 'No users found',
        subtitle: 'Users will appear here once they register',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _users!.length,
        itemBuilder: (context, index) {
          final user = _users![index];
          return _buildUserCard(user);
        },
      ),
    );
  }

  Widget _buildTechniciansList() {
    if (_isLoadingTechnicians) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_technicians == null || _technicians!.isEmpty) {
      return EmptyState(
        icon: Icons.engineering_outlined,
        title: 'No technicians found',
        subtitle: 'Technicians will appear here once they register',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTechnicians,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _technicians!.length,
        itemBuilder: (context, index) {
          final technician = _technicians![index];
          return _buildTechnicianCard(technician);
        },
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final status = user['status'] ?? 'active';
    final isActive = status == 'active';

    return ModernCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
                child: Text(
                  user['name']?[0]?.toUpperCase() ?? 'U',
                  style: const TextStyle(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['name'] ?? 'Unknown',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user['email'] ?? '',
                      style: TextStyle(
                        color: AppTheme.getSecondaryTextColor(context),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              isActive
                  ? StatusBadge.success('ACTIVE')
                  : StatusBadge.error('SUSPENDED'),
            ],
          ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'User ID: ${user['_id'] != null && user['_id'].length > 8 ? user['_id'].substring(0, 8) + '...' : user['_id'] ?? 'N/A'}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: () => _showUserDetails(user),
                      icon: const Icon(Icons.info_outline, size: 16),
                      label: const Text('Details'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _updateUserStatus(
                        user['_id'],
                        isActive ? 'suspended' : 'active',
                      ),
                      icon: Icon(
                        isActive ? Icons.block : Icons.check_circle,
                        size: 16,
                      ),
                      label: Text(isActive ? 'Suspend' : 'Activate'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isActive ? Colors.orange : Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _deleteUser(user['_id'], user['name'] ?? 'User'),
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: Colors.red,
                      tooltip: 'Delete User',
                    ),
                  ],
                ),
              ],
            ),
          ],
      ),
    );
  }

  Widget _buildTechnicianCard(Map<String, dynamic> technician) {
    final status = technician['status'] ?? 'active';
    final isActive = status == 'active';
    final rating = technician['rating']?.toDouble() ?? 0.0;

    return ModernCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.accentOrange.withValues(alpha: 0.1),
                child: Text(
                  technician['name']?[0]?.toUpperCase() ?? 'T',
                  style: const TextStyle(
                    color: AppTheme.accentOrange,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      technician['name'] ?? 'Unknown',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      technician['email'] ?? '',
                      style: TextStyle(
                        color: AppTheme.getSecondaryTextColor(context),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              isActive
                  ? StatusBadge.success('ACTIVE')
                  : StatusBadge.error('SUSPENDED'),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tech ID: ${technician['_id'] != null && technician['_id'].length > 8 ? technician['_id'].substring(0, 8) + '...' : technician['_id'] ?? 'N/A'}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: () => _showUserDetails(technician),
                      icon: const Icon(Icons.info_outline, size: 16),
                      label: const Text('Details'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _updateUserStatus(
                        technician['_id'],
                        isActive ? 'suspended' : 'active',
                      ),
                      icon: Icon(
                        isActive ? Icons.block : Icons.check_circle,
                        size: 16,
                      ),
                      label: Text(isActive ? 'Suspend' : 'Activate'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isActive ? Colors.orange : Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _deleteUser(technician['_id'], technician['name'] ?? 'Technician'),
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: Colors.red,
                      tooltip: 'Delete Technician',
                    ),
                  ],
                ),
              ],
            ),
          ],
      ),
    );
  }

  void _showUserDetails(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user['name'] ?? 'User Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Email', user['email'] ?? 'N/A'),
              _buildDetailRow('Role', user['role'] ?? 'N/A'),
              _buildDetailRow('Status', user['status'] ?? 'N/A'),
              _buildDetailRow('User ID', user['_id'] ?? 'N/A'),
              if (user['phone'] != null)
                _buildDetailRow('Phone', user['phone']),
              if (user['rating'] != null)
                _buildDetailRow('Rating', user['rating'].toString()),
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
}
