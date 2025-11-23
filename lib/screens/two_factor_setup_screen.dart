import 'package:flutter/material.dart';
import '../services/api.dart';
import '../utils/app_theme.dart';

class TwoFactorSetupScreen extends StatefulWidget {
  final bool isEnabled;

  const TwoFactorSetupScreen({
    super.key,
    required this.isEnabled,
  });

  @override
  State<TwoFactorSetupScreen> createState() => _TwoFactorSetupScreenState();
}

class _TwoFactorSetupScreenState extends State<TwoFactorSetupScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  bool _codeSent = false;
  String _selectedMethod = 'sms'; // 'sms' or 'email'
  String? _devCode; // For development mode

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    setState(() => _isLoading = true);

    final result = await Api.send2FACode(_selectedMethod);

    setState(() => _isLoading = false);

    if (result != null && result['success'] == true) {
      setState(() {
        _codeSent = true;
        _devCode = result['dev_code']; // For development
      });
      
      String message = result['message'] ?? 'Code sent';
      if (_devCode != null) {
        message += '\n\nDEV MODE: Code is $_devCode';
      }
      
      _showSnackBar(message);
    } else {
      _showErrorDialog(result?['error'] ?? 'Failed to send code');
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();

    if (code.isEmpty || code.length != 6) {
      _showSnackBar('Please enter the 6-digit code');
      return;
    }

    setState(() => _isLoading = true);

    final result = await Api.verify2FACode(code);

    setState(() => _isLoading = false);

    if (result != null && result['success'] == true) {
      // Now enable 2FA
      await _enable2FA();
    } else {
      _showErrorDialog(result?['error'] ?? 'Invalid code');
    }
  }

  Future<void> _enable2FA() async {
    setState(() => _isLoading = true);

    final result = await Api.enable2FA();

    setState(() => _isLoading = false);

    if (result != null && result['success'] == true) {
      _showSuccessDialog();
    } else {
      _showErrorDialog(result?['error'] ?? 'Failed to enable 2FA');
    }
  }

  Future<void> _disable2FA() async {
    setState(() => _isLoading = true);

    final result = await Api.disable2FA();

    setState(() => _isLoading = false);

    if (result != null && result['success'] == true) {
      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate change
      }
      _showSnackBar('2FA disabled successfully');
    } else {
      _showErrorDialog(result?['error'] ?? 'Failed to disable 2FA');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 10),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 10),
            Text('Success'),
          ],
        ),
        content: const Text('Two-factor authentication has been enabled!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, true); // Go back with success
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showDisableConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disable 2FA?'),
        content: const Text(
          'Are you sure you want to disable two-factor authentication? '
          'This will make your account less secure.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _disable2FA();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Disable'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEnabled) {
      // Show disable screen
      return Scaffold(
        appBar: AppBar(
          title: const Text('Two-Factor Authentication'),
          backgroundColor: AppTheme.primaryBlue,
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.verified_user,
                size: 80,
                color: Colors.green,
              ),
              const SizedBox(height: 24),
              const Text(
                '2FA is Enabled',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Your account is protected with two-factor authentication.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _showDisableConfirmation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Disable 2FA',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show enable screen
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enable 2FA'),
        backgroundColor: AppTheme.primaryBlue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.security,
              size: 80,
              color: AppTheme.primaryBlue,
            ),
            const SizedBox(height: 24),
            const Text(
              'Secure Your Account',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Add an extra layer of security to your account.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            if (!_codeSent) ...[
              const Text(
                'Choose verification method:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              RadioListTile<String>(
                title: const Text('SMS (Text Message)'),
                subtitle: const Text('Receive code via SMS'),
                value: 'sms',
                groupValue: _selectedMethod,
                onChanged: (value) {
                  setState(() => _selectedMethod = value!);
                },
              ),
              RadioListTile<String>(
                title: const Text('Email'),
                subtitle: const Text('Receive code via email'),
                value: 'email',
                groupValue: _selectedMethod,
                onChanged: (value) {
                  setState(() => _selectedMethod = value!);
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _sendCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Send Verification Code',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ] else ...[
              const Text(
                'Enter the 6-digit code:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Verification Code',
                  hintText: '123456',
                  prefixIcon: Icon(Icons.sms),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _verifyCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Verify & Enable 2FA',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _codeSent = false;
                    _codeController.clear();
                  });
                },
                child: const Text('Resend Code'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
