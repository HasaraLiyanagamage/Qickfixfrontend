import 'package:flutter/material.dart';
import '../../services/api.dart';
import '../../utils/app_theme.dart';
import '../../widgets/gradient_header.dart';
import '../../widgets/modern_card.dart';

class TechVerificationScreen extends StatefulWidget {
  const TechVerificationScreen({super.key});

  @override
  State<TechVerificationScreen> createState() => _TechVerificationScreenState();
}

class _TechVerificationScreenState extends State<TechVerificationScreen> {
  Map<String, dynamic>? _verification;
  bool _isLoading = true;
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _loadVerification();
    _initControllers();
  }

  void _initControllers() {
    _controllers['idProofNumber'] = TextEditingController();
    _controllers['tradeLicenseNumber'] = TextEditingController();
    _controllers['qualificationType'] = TextEditingController();
    _controllers['qualificationNumber'] = TextEditingController();
    _controllers['policeClearanceNumber'] = TextEditingController();
  }

  Future<void> _loadVerification() async {
    setState(() => _isLoading = true);
    try {
      final data = await Api.getVerificationStatus();
      if (mounted) {
        setState(() {
          _verification = data != null ? Map<String, dynamic>.from(data) : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitVerification() async {
    // Validate required fields
    if (_controllers['idProofNumber']!.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID Proof Number is required')),
      );
      return;
    }
    
    if (_controllers['tradeLicenseNumber']!.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trade License Number is required')),
      );
      return;
    }

    final Map<String, dynamic> documents = {
      'idProof': {
        'type': 'national_id',
        'number': _controllers['idProofNumber']!.text,
        'verified': false,
      },
      'tradeLicense': {
        'licenseNumber': _controllers['tradeLicenseNumber']!.text,
        'verified': false,
      },
    };

    // Add qualifications if provided
    if (_controllers['qualificationType']!.text.isNotEmpty && 
        _controllers['qualificationNumber']!.text.isNotEmpty) {
      documents['qualifications'] = [
        {
          'type': _controllers['qualificationType']!.text,
          'certificateNumber': _controllers['qualificationNumber']!.text,
          'verified': false,
        }
      ];
    }

    // Add police clearance if provided
    if (_controllers['policeClearanceNumber']!.text.isNotEmpty) {
      documents['policeClearance'] = {
        'certificateNumber': _controllers['policeClearanceNumber']!.text,
        'verified': false,
      };
    }

    try {
      final result = await Api.submitVerification(documents);
      if (mounted && result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification submitted successfully!')),
        );
        _loadVerification();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'pending':
      case 'under_review':
        return Colors.orange;
      case 'rejected':
      case 'resubmission_required':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getVerificationLevel(int score) {
    if (score >= 90) return 'Gold';
    if (score >= 70) return 'Silver';
    if (score >= 50) return 'Bronze';
    return 'Basic';
  }

  @override
  void dispose() {
    for (var c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            title: 'Verification',
            subtitle: 'Complete your profile verification',
            icon: Icons.verified_user,
            gradientColors: [Colors.blue, Colors.blue.shade700],
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_verification != null && _verification!['verification'] != null) ...[
                          ModernCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Verification Status',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(_verification!['verification']['status']),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _verification!['verification']['status']?.toString().toUpperCase() ?? 'UNKNOWN',
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
                                _buildInfoRow('Score', '${_verification!['verification']['verificationScore'] ?? 0}/100'),
                                _buildInfoRow('Level', _verification!['verification']['verificationLevel']?.toString().toUpperCase() ?? 'NONE'),
                                if (_verification!['verification']['completedAt'] != null)
                                  _buildInfoRow('Verified On', _verification!['verification']['completedAt'].toString().split('T')[0]),
                                const SizedBox(height: 16),
                                const Text(
                                  'Document Status:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildDocumentStatus('ID Proof', _verification!['verification']['documents']?['idProof']),
                                _buildDocumentStatus('Trade License', _verification!['verification']['documents']?['tradeLicense']),
                                _buildDocumentStatus('Qualifications', _verification!['verification']['documents']?['qualifications']),
                                _buildDocumentStatus('Police Clearance', _verification!['verification']['documents']?['policeClearance']),
                                _buildDocumentStatus('Address Proof', _verification!['verification']['documents']?['addressProof']),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        const Text(
                          'Submit Documents',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ModernCard(
                          child: Column(
                            children: [
                              const Text(
                                'Required Documents',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildDocumentField(
                                'ID Proof Number (NIC/Passport) *',
                                _controllers['idProofNumber']!,
                                Icons.credit_card,
                              ),
                              const SizedBox(height: 16),
                              _buildDocumentField(
                                'Trade License Number *',
                                _controllers['tradeLicenseNumber']!,
                                Icons.card_membership,
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'Optional Documents',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildDocumentField(
                                'Qualification Type (e.g., Electrician License)',
                                _controllers['qualificationType']!,
                                Icons.school,
                              ),
                              const SizedBox(height: 16),
                              _buildDocumentField(
                                'Qualification Certificate Number',
                                _controllers['qualificationNumber']!,
                                Icons.numbers,
                              ),
                              const SizedBox(height: 16),
                              _buildDocumentField(
                                'Police Clearance Certificate Number',
                                _controllers['policeClearanceNumber']!,
                                Icons.security,
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _submitVerification,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.accentPurple,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Submit for Verification',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentField(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildDocumentStatus(String label, dynamic status) {
    bool isVerified = false;
    String displayText = 'Not Submitted';
    Color statusColor = Colors.grey;

    if (status != null) {
      if (status is bool) {
        isVerified = status;
        displayText = isVerified ? 'Verified' : 'Pending';
        statusColor = isVerified ? Colors.green : Colors.orange;
      } else if (status is int) {
        // For qualifications, it shows count
        displayText = '$status verified';
        statusColor = status > 0 ? Colors.green : Colors.orange;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13),
          ),
          Row(
            children: [
              Icon(
                isVerified || (status is int && status > 0) 
                    ? Icons.check_circle 
                    : Icons.pending,
                size: 16,
                color: statusColor,
              ),
              const SizedBox(width: 4),
              Text(
                displayText,
                style: TextStyle(
                  fontSize: 13,
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
