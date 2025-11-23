import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../services/api.dart';
import '../../providers/theme_provider.dart';
import '../../providers/language_provider.dart';
import '../../widgets/gradient_header.dart';
import '../login_screen.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool _autoBackup = true;
  bool _twoFactorEnabled = false;
  String _defaultLocation = 'Not set';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoBackup = prefs.getBool('autoBackup') ?? true;
      _twoFactorEnabled = prefs.getBool('twoFactorEnabled') ?? false;
      _defaultLocation = prefs.getString('defaultLocation') ?? 'Not set';
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }


  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await Api.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
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
      body: Column(
        children: [
          GradientHeader(
            title: 'Settings',
            subtitle: 'Customize your experience',
            icon: Icons.settings,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
          // Appearance Section
          _buildSectionHeader('Appearance'),
          const SizedBox(height: 8),
          
          _buildThemeTile(),
          const SizedBox(height: 8),
          
          _buildLanguageTile(),
          const SizedBox(height: 16),
          
          // Security Section
          _buildSectionHeader('Security'),
          const SizedBox(height: 8),
          
          // Two-Factor Authentication
          _buildActionTile(
            'Two-Factor Authentication',
            _twoFactorEnabled ? 'Enabled' : 'Add extra security',
            Icons.chevron_right,
            () => _showTwoFactorDialog(),
            leadingIcon: Icons.shield_outlined,
          ),
          const SizedBox(height: 8),
          
          // Privacy Policy
          _buildActionTile(
            'Privacy Policy',
            'View our privacy policy',
            Icons.chevron_right,
            () => _showPrivacyPolicy(),
            leadingIcon: Icons.privacy_tip_outlined,
          ),
          const SizedBox(height: 16),
          
          // Preferences Section
          _buildSectionHeader('Preferences'),
          const SizedBox(height: 8),
          
          _buildActionTile(
            'Default Location',
            _defaultLocation,
            Icons.chevron_right,
            () => _showDefaultLocationDialog(),
            leadingIcon: Icons.location_on_outlined,
          ),
          const SizedBox(height: 8),
          
          _buildActionTile(
            'Service Preferences',
            'Customize service options',
            Icons.chevron_right,
            () => _showServicePreferences(),
            leadingIcon: Icons.settings_outlined,
          ),
          const SizedBox(height: 8),
          
          _buildActionTile(
            'Payment Methods',
            'Manage payment options',
            Icons.chevron_right,
            () => _showPaymentMethods(),
            leadingIcon: Icons.credit_card_outlined,
          ),
          const SizedBox(height: 16),
          
          // Data & Storage Section
          _buildSectionHeader('Data & Storage'),
          const SizedBox(height: 8),
          
          _buildSwitchTile(
            'Auto Backup',
            'Backup data automatically',
            _autoBackup,
            (value) {
              setState(() => _autoBackup = value);
              _saveSetting('autoBackup', value);
            },
            leadingIcon: Icons.backup_outlined,
          ),
          const SizedBox(height: 8),
          
          _buildActionTile(
            'Clear Cache',
            'Free up storage space',
            Icons.chevron_right,
            () => _showClearCacheDialog(),
            leadingIcon: Icons.cleaning_services_outlined,
          ),
          const SizedBox(height: 8),
          
          _buildActionTile(
            'Data Usage',
            'View data consumption',
            Icons.chevron_right,
            () => _showDataUsage(),
            leadingIcon: Icons.data_usage_outlined,
          ),
          const SizedBox(height: 8),
          
          _buildActionTile(
            'Export Data',
            'Download your data',
            Icons.chevron_right,
            () => _exportData(),
            leadingIcon: Icons.download_outlined,
          ),
          const SizedBox(height: 16),
          
          // Support Section
          _buildSectionHeader('Support'),
          const SizedBox(height: 8),
          
          _buildActionTile(
            'Rate App',
            'Rate us on the app store',
            Icons.chevron_right,
            () => _rateApp(),
            leadingIcon: Icons.star_outline,
          ),
          const SizedBox(height: 8),
          
          _buildActionTile(
            'Share App',
            'Share with friends',
            Icons.chevron_right,
            () => _shareApp(),
            leadingIcon: Icons.share_outlined,
          ),
          const SizedBox(height: 8),
          
          _buildActionTile(
            'App Version',
            'Version 1.0.0',
            Icons.chevron_right,
            () => _showSnackBar('App Version 1.0.0'),
            leadingIcon: Icons.info_outline,
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: _logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Version 1.0.0',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ),
          const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.menu, size: 20, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    {IconData? leadingIcon}
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        leading: leadingIcon != null
            ? Icon(leadingIcon, size: 24, color: Colors.grey[700])
            : null,
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.teal,
        ),
      ),
    );
  }


  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData trailingIcon,
    VoidCallback onTap,
    {IconData? leadingIcon}
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        leading: leadingIcon != null
            ? Icon(leadingIcon, size: 24, color: Colors.grey[700])
            : null,
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        subtitle: subtitle.isNotEmpty
            ? Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600]))
            : null,
        trailing: Icon(trailingIcon, size: 20, color: Colors.grey[600]),
        onTap: onTap,
      ),
    );
  }

  Future<void> _showTwoFactorDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Two-Factor Authentication'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _twoFactorEnabled ? 'Two-factor authentication is currently enabled.' : 'Enable two-factor authentication for extra security.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable 2FA'),
              value: _twoFactorEnabled,
              onChanged: (value) {
                setState(() => _twoFactorEnabled = value);
                _saveSetting('twoFactorEnabled', value);
                Navigator.pop(context);
                _showSnackBar(value ? '2FA enabled' : '2FA disabled');
              },
            ),
          ],
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

  Future<void> _showPrivacyPolicy() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'QuickFix Privacy Policy',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                'Last updated: October 2024\n\n'
                '1. Information We Collect\n'
                'We collect information you provide directly to us, including name, email, phone number, and location data.\n\n'
                '2. How We Use Your Information\n'
                'We use your information to provide, maintain, and improve our services, process bookings, and communicate with you.\n\n'
                '3. Data Security\n'
                'We implement appropriate security measures to protect your personal information.\n\n'
                '4. Your Rights\n'
                'You have the right to access, update, or delete your personal information at any time.',
                style: TextStyle(fontSize: 14),
              ),
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

  Future<void> _showDefaultLocationDialog() async {
    final TextEditingController locationController = TextEditingController(text: _defaultLocation == 'Not set' ? '' : _defaultLocation);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Default Location'),
        content: TextField(
          controller: locationController,
          decoration: const InputDecoration(
            labelText: 'Enter your default address',
            border: OutlineInputBorder(),
            hintText: 'e.g., 123 Main St, City',
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (locationController.text.isNotEmpty) {
                setState(() => _defaultLocation = locationController.text);
                _saveSetting('defaultLocation', locationController.text);
                Navigator.pop(context);
                _showSnackBar('Default location saved');
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showServicePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    bool notifyNewServices = prefs.getBool('notifyNewServices') ?? true;
    bool autoAcceptBookings = prefs.getBool('autoAcceptBookings') ?? false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Service Preferences'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Notify about new services'),
                subtitle: const Text('Get notified when new services are available'),
                value: notifyNewServices,
                onChanged: (value) {
                  setDialogState(() => notifyNewServices = value);
                  _saveSetting('notifyNewServices', value);
                },
              ),
              SwitchListTile(
                title: const Text('Auto-accept bookings'),
                subtitle: const Text('Automatically accept booking requests'),
                value: autoAcceptBookings,
                onChanged: (value) {
                  setDialogState(() => autoAcceptBookings = value);
                  _saveSetting('autoAcceptBookings', value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPaymentMethods() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Methods'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.credit_card),
              title: const Text('Credit/Debit Card'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar('Card payment setup');
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: const Text('Digital Wallet'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar('Wallet payment setup');
              },
            ),
            ListTile(
              leading: const Icon(Icons.money),
              title: const Text('Cash on Service'),
              trailing: const Icon(Icons.check_circle, color: Colors.green),
              onTap: () {},
            ),
          ],
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

  Future<void> _showClearCacheDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('Are you sure you want to clear the cache? This will free up storage space.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Simulate cache clearing
      await Future.delayed(const Duration(milliseconds: 500));
      _showSnackBar('Cache cleared successfully (12.5 MB freed)');
    }
  }

  Future<void> _showDataUsage() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Data Usage'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Month',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            _buildDataUsageRow('Images', '45.2 MB'),
            _buildDataUsageRow('Videos', '12.8 MB'),
            _buildDataUsageRow('Documents', '8.5 MB'),
            _buildDataUsageRow('Cache', '25.3 MB'),
            const Divider(height: 24),
            _buildDataUsageRow('Total', '91.8 MB', isBold: true),
          ],
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

  Widget _buildDataUsageRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: const Text(
          'Your data will be exported as a JSON file and saved to your device. This includes your profile information, bookings, and preferences.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Export'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Simulate data export
      await Future.delayed(const Duration(seconds: 1));
      _showSnackBar('Data exported successfully to Downloads folder');
    }
  }

  Future<void> _rateApp() async {
    final Uri appStoreUrl = Platform.isIOS
        ? Uri.parse('https://apps.apple.com/app/quickfix')
        : Uri.parse('https://play.google.com/store/apps/details?id=com.quickfix.app');

    try {
      if (await canLaunchUrl(appStoreUrl)) {
        await launchUrl(appStoreUrl, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar('Could not open app store');
      }
    } catch (e) {
      _showSnackBar('Error opening app store');
    }
  }

  Future<void> _shareApp() async {
    try {
      await Share.share(
        'Check out QuickFix - Your one-stop solution for home services! Download now: https://quickfix.app',
        subject: 'QuickFix App',
      );
    } catch (e) {
      _showSnackBar('Error sharing app');
    }
  }

  Widget _buildThemeTile() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        leading: Icon(
          isDark ? Icons.dark_mode : Icons.light_mode,
          size: 24,
          color: Colors.grey[700],
        ),
        title: const Text(
          'Dark Mode',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          isDark ? 'Dark theme enabled' : 'Light theme enabled',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: Switch(
          value: isDark,
          onChanged: (value) {
            themeProvider.toggleTheme();
          },
          activeThumbColor: Colors.blueAccent,
        ),
      ),
    );
  }

  Widget _buildLanguageTile() {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final currentLanguage = LanguageProvider.supportedLanguages.firstWhere(
      (lang) => lang['code'] == languageProvider.languageCode,
      orElse: () => LanguageProvider.supportedLanguages[0],
    );
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        leading: Icon(Icons.language, size: 24, color: Colors.grey[700]),
        title: const Text(
          'Language',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          currentLanguage['nativeName'] ?? 'English',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: Icon(Icons.chevron_right, size: 20, color: Colors.grey[600]),
        onTap: () => _showLanguageDialog(),
      ),
    );
  }

  Future<void> _showLanguageDialog() async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: LanguageProvider.supportedLanguages.map((lang) {
            final isSelected = lang['code'] == languageProvider.languageCode;
            return ListTile(
              leading: Radio<String>(
                value: lang['code']!,
                groupValue: languageProvider.languageCode,
                onChanged: (value) {
                  if (value != null) {
                    languageProvider.setLanguage(value);
                    Navigator.pop(context);
                    _showSnackBar('Language changed to ${lang['name']}');
                  }
                },
              ),
              title: Text(lang['nativeName']!),
              subtitle: Text(lang['name']!),
              trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
              onTap: () {
                languageProvider.setLanguage(lang['code']!);
                Navigator.pop(context);
                _showSnackBar('Language changed to ${lang['name']}');
              },
            );
          }).toList(),
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

}
