import 'package:flutter/material.dart';
import '../../services/api.dart';
import '../../utils/app_theme.dart';
import '../../widgets/gradient_header.dart';
import '../../widgets/modern_card.dart';

class AdminVerificationsScreen extends StatefulWidget {
  const AdminVerificationsScreen({super.key});

  @override
  State<AdminVerificationsScreen> createState() => _AdminVerificationsScreenState();
}

class _AdminVerificationsScreenState extends State<AdminVerificationsScreen> {
  List<Map<String, dynamic>> _verifications = [];
  bool _isLoading = true;
  String _filter = 'all'; // all, pending, verified, rejected

  @override
  void initState() {
    super.initState();
    _loadVerifications();
  }

  Future<void> _loadVerifications() async {
    setState(() => _isLoading = true);
    try {
      final data = await Api.getAllVerifications();
      if (mounted && data != null) {
        setState(() {
          _verifications = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _approveVerification(String verificationId) async {
    try {
      await Api.approveVerification(verificationId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification approved!')),
        );
        _loadVerifications();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _rejectVerification(String verificationId, String reason) async {
    try {
      await Api.rejectVerification(verificationId, reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification rejected')),
        );
        _loadVerifications();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showRejectDialog(String verificationId) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Verification'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Reason for rejection',
            hintText: 'Enter reason...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _rejectVerification(verificationId, reasonController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredVerifications {
    if (_filter == 'all') return _verifications;
    return _verifications.where((v) => v['status'] == _filter).toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'verified':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            title: 'Verifications',
            subtitle: 'Review technician verifications',
            icon: Icons.verified_user,
            gradientColors: [AppTheme.accentPurple, AppTheme.accentPurple.withOpacity(0.7)],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Pending', 'pending'),
                const SizedBox(width: 8),
                _buildFilterChip('Verified', 'verified'),
                const SizedBox(width: 8),
                _buildFilterChip('Rejected', 'rejected'),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredVerifications.isEmpty
                    ? const Center(child: Text('No verifications found'))
                    : RefreshIndicator(
                        onRefresh: _loadVerifications,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredVerifications.length,
                          itemBuilder: (context, index) {
                            final verification = _filteredVerifications[index];
                            return _buildVerificationCard(verification);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return Expanded(
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _filter = value);
        },
        selectedColor: AppTheme.accentPurple.withOpacity(0.2),
        checkmarkColor: AppTheme.accentPurple,
      ),
    );
  }

  Widget _buildVerificationCard(Map<String, dynamic> verification) {
    final status = verification['status'] ?? 'unknown';
    final score = verification['verificationScore'] ?? 0;
    final technicianName = verification['technician']?['name'] ?? 'Unknown';
    final verificationId = verification['_id'] ?? '';

    return ModernCard(
      margin: const EdgeInsets.only(bottom: 16),
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
                      technicianName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Score: $score/100',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(status),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Documents:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          ...((verification['documents'] as Map<String, dynamic>?)?.entries ?? [])
              .where((entry) => entry.value != null && entry.value is Map)
              .map((entry) {
                // Handle both boolean and string values for 'verified'
                final verifiedValue = entry.value['verified'];
                final isVerified = verifiedValue == true || 
                                   verifiedValue == 'true' || 
                                   verifiedValue == 1 ||
                                   verifiedValue == '1';
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        isVerified ? Icons.check_circle : Icons.pending,
                        size: 16,
                        color: isVerified ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${entry.key}: ${entry.value['number'] ?? 'N/A'}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                );
              }),
          if (status == 'pending') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approveVerification(verificationId),
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showRejectDialog(verificationId),
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
