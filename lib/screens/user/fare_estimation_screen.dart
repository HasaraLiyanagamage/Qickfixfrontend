import 'package:flutter/material.dart';
import '../../services/api.dart';

class FareEstimationScreen extends StatefulWidget {
  final String serviceType;
  final double lat;
  final double lng;
  final String address;

  const FareEstimationScreen({
    super.key,
    required this.serviceType,
    required this.lat,
    required this.lng,
    required this.address,
  });

  @override
  State<FareEstimationScreen> createState() => _FareEstimationScreenState();
}

class _FareEstimationScreenState extends State<FareEstimationScreen> {
  Map<String, dynamic>? _fareDetails;
  bool _isLoading = true;
  String _urgency = 'normal';
  final TextEditingController _promoController = TextEditingController();
  String? _appliedPromoCode;
  bool _promoApplied = false;

  @override
  void initState() {
    super.initState();
    _estimateFare();
  }

  Future<void> _estimateFare() async {
    setState(() => _isLoading = true);

    try {
      final response = await Api.estimateFare(
        serviceType: widget.serviceType,
        lat: widget.lat,
        lng: widget.lng,
        urgency: _urgency,
        promoCode: _appliedPromoCode,
      );

      if (response != null && mounted) {
        setState(() {
          _fareDetails = Map<String, dynamic>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _applyPromoCode() async {
    final code = _promoController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _appliedPromoCode = code;
      _promoApplied = true;
    });

    await _estimateFare();
  }

  void _removePromoCode() {
    setState(() {
      _appliedPromoCode = null;
      _promoApplied = false;
      _promoController.clear();
    });
    _estimateFare();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fare Estimate'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service Info Card
                  _buildServiceInfoCard(isDark),
                  const SizedBox(height: 16),

                  // Urgency Selector
                  _buildUrgencySelector(isDark),
                  const SizedBox(height: 16),

                  // Promo Code Input
                  _buildPromoCodeInput(isDark),
                  const SizedBox(height: 24),

                  // Fare Breakdown
                  if (_fareDetails != null) _buildFareBreakdown(isDark),
                  const SizedBox(height: 24),

                  // Confirm Button
                  _buildConfirmButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildServiceInfoCard(bool isDark) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getServiceIcon(widget.serviceType),
                  size: 32,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.serviceType.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.address,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_fareDetails != null) ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Distance',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  Text(
                    '${_fareDetails!['estimatedDistance']} km',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Available Technicians',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  Text(
                    '${_fareDetails!['availableTechnicians']}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUrgencySelector(bool isDark) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Service Urgency',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'normal',
                  label: Text('Normal'),
                  icon: Icon(Icons.schedule),
                ),
                ButtonSegment(
                  value: 'urgent',
                  label: Text('Urgent'),
                  icon: Icon(Icons.flash_on),
                ),
                ButtonSegment(
                  value: 'emergency',
                  label: Text('Emergency'),
                  icon: Icon(Icons.warning),
                ),
              ],
              selected: {_urgency},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _urgency = newSelection.first;
                });
                _estimateFare();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoCodeInput(bool isDark) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Have a Promo Code?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (!_promoApplied)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _promoController,
                      decoration: const InputDecoration(
                        hintText: 'Enter promo code',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.local_offer),
                      ),
                      textCapitalization: TextCapitalization.characters,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _applyPromoCode,
                    child: const Text('Apply'),
                  ),
                ],
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Promo code "$_appliedPromoCode" applied!',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: _removePromoCode,
                      color: Colors.green,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFareBreakdown(bool isDark) {
    final fare = _fareDetails!['fare'];
    final surgeActive = _fareDetails!['surgeActive'] ?? false;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fare Breakdown',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            _buildFareRow('Base Fare', fare['baseFare']),
            _buildFareRow('Distance Charge', fare['distanceFare']),
            if (fare['serviceFare'] > 0)
              _buildFareRow(
                'Service Charge',
                fare['serviceFare'],
                color: Colors.orange,
              ),
            if (fare['surgeFare'] > 0)
              _buildFareRow(
                'Surge Pricing',
                fare['surgeFare'],
                color: Colors.red,
                icon: Icons.trending_up,
              ),
            if (fare['discount'] > 0)
              _buildFareRow(
                'Discount',
                -fare['discount'],
                color: Colors.green,
                icon: Icons.local_offer,
              ),
            const Divider(height: 24),
            _buildFareRow(
              'Total Fare',
              fare['totalFare'],
              isTotal: true,
            ),
            if (surgeActive) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 16, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Surge pricing active (${_fareDetails!['surgeMultiplier']}x)',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFareRow(
    String label,
    dynamic amount, {
    bool isTotal = false,
    Color? color,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: isTotal ? 16 : 14,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
          Text(
            'LKR ${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () {
          // Return fare details to previous screen
          Navigator.pop(context, {
            'fareDetails': _fareDetails,
            'urgency': _urgency,
            'promoCode': _appliedPromoCode,
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
        child: const Text(
          'Confirm Booking',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  IconData _getServiceIcon(String serviceType) {
    switch (serviceType.toLowerCase()) {
      case 'plumbing':
        return Icons.plumbing;
      case 'electrical':
        return Icons.electrical_services;
      case 'carpentry':
        return Icons.carpenter;
      case 'painting':
        return Icons.format_paint;
      case 'cleaning':
        return Icons.cleaning_services;
      case 'appliance_repair':
        return Icons.build;
      default:
        return Icons.home_repair_service;
    }
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }
}
