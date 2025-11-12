import 'package:flutter/material.dart';
import '../../services/api.dart';
import '../../models/app_models.dart';
import '../../utils/app_theme.dart';
import '../../widgets/gradient_header.dart';
import '../login_screen.dart';

class TechProfileScreen extends StatefulWidget {
  const TechProfileScreen({super.key});

  @override
  State<TechProfileScreen> createState() => _TechProfileScreenState();
}

class _TechProfileScreenState extends State<TechProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _skillsController = TextEditingController();

  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  Map<String, dynamic>? _profile;
  User? _user;
  bool _isAvailable = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final profileData = await Api.getTechnicianProfile();
      if (mounted && profileData != null) {
        final userData = profileData['user'];
        setState(() {
          _profile = Map<String, dynamic>.from(profileData);
          _user = userData != null ? User.fromJson(userData) : null;
          _nameController.text = _user?.name ?? '';
          _emailController.text = _user?.email ?? '';
          _phoneController.text = _user?.phone ?? '';
          _skillsController.text = (profileData['skills'] as List?)?.join(', ') ?? '';
          _isAvailable = profileData['isAvailable'] ?? true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final result = await Api.updateTechnicianProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        skills: _skillsController.text.trim().isEmpty ? null : _skillsController.text.trim(),
      );

      if (mounted) {
        setState(() => _isSaving = false);
        if (result != null) {
          setState(() => _isEditing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          _loadProfile();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update profile')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
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

  void _toggleEdit() {
    setState(() {
      if (_isEditing) {
        // Cancel editing - restore original values
        _nameController.text = _user?.name ?? '';
        _phoneController.text = _user?.phone ?? '';
        _skillsController.text = (_profile?['skills'] as List?)?.join(', ') ?? '';
      }
      _isEditing = !_isEditing;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            title: 'My Profile',
            subtitle: 'Technician account',
            icon: Icons.engineering,
            gradientColors: [AppTheme.accentOrange, AppTheme.accentOrange.withValues(alpha: 0.7)],
            action: !_isLoading && _user != null
                ? IconButton(
                    icon: Icon(_isEditing ? Icons.close : Icons.edit, color: Colors.white),
                    onPressed: _toggleEdit,
                    tooltip: _isEditing ? 'Cancel' : 'Edit Profile',
                  )
                : null,
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _user == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'Unable to load profile',
                              style: TextStyle(color: Colors.grey[600], fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadProfile,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildProfileHeader(),
                            const SizedBox(height: 16),
                            _buildAvailabilityCard(),
                            const SizedBox(height: 16),
                            _buildStatsCards(),
                            const SizedBox(height: 16),
                            _buildProfileForm(),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
          ),
        ],
      ),
      bottomNavigationBar: _isEditing
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orangeAccent, Colors.orange.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            child: Text(
              _user!.name.isNotEmpty ? _user!.name[0].toUpperCase() : 'T',
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.orangeAccent,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _user!.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _user!.email,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Technician',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
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
                color: (_isAvailable ? Colors.green : Colors.orange).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _isAvailable ? Icons.check_circle : Icons.cancel,
                color: _isAvailable ? Colors.green : Colors.orange,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Availability Status',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isAvailable ? 'Available' : 'Offline',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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
      ),
    );
  }

  Widget _buildStatsCards() {
    final totalJobs = _profile?['totalJobs'] ?? 0;
    final rating = _profile?['rating'] ?? 0;

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
              value: rating > 0 ? rating.toString() : 'N/A',
              color: Colors.amber,
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

  Widget _buildProfileForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personal Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _nameController,
              label: 'Full Name',
              icon: Icons.person,
              enabled: _isEditing,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _emailController,
              label: 'Email',
              icon: Icons.email,
              enabled: false,
              helperText: 'Email cannot be changed',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _phoneController,
              label: 'Phone Number',
              icon: Icons.phone,
              enabled: _isEditing,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _skillsController,
              label: 'Skills',
              icon: Icons.build,
              enabled: _isEditing,
              helperText: 'Separate skills with commas (e.g., Plumbing, Electrical)',
              maxLines: 2,
            ),
            const SizedBox(height: 32),
            // Account Management Section
            const Text(
              'Account Management',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildActionButton(
              label: 'Change Password',
              icon: Icons.lock_outline,
              color: Colors.orangeAccent,
              onPressed: _showChangePasswordDialog,
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              label: 'Delete Account',
              icon: Icons.delete_outline,
              color: Colors.red,
              onPressed: _showDeleteAccountDialog,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: color),
        onTap: onPressed,
      ),
    );
  }

  Future<void> _showChangePasswordDialog() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter current password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter new password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (value) {
                  if (value != newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
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
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);
                await _changePassword(
                  currentPasswordController.text,
                  newPasswordController.text,
                );
              }
            },
            child: const Text('Change Password'),
          ),
        ],
      ),
    );
  }

  Future<void> _changePassword(String currentPassword, String newPassword) async {
    try {
      await Api.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password changed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showDeleteAccountDialog() async {
    final passwordController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to delete your account? This action cannot be undone.',
              style: TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Enter your password to confirm',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (passwordController.text.isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );

    if (confirmed == true && passwordController.text.isNotEmpty) {
      await _deleteAccount(passwordController.text);
    }
  }

  Future<void> _deleteAccount(String password) async {
    try {
      await Api.deleteAccount(password);
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    String? helperText,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enabled ? Colors.grey[300]! : Colors.grey[200]!,
        ),
      ),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          prefixIcon: Icon(icon, color: enabled ? Colors.orangeAccent : Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          labelStyle: TextStyle(
            color: enabled ? Colors.black87 : Colors.grey,
          ),
        ),
        style: TextStyle(
          color: enabled ? Colors.black : Colors.grey[600],
        ),
      ),
    );
  }
}
