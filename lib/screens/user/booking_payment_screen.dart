import 'package:flutter/material.dart';
import '../../services/api.dart';
import '../../utils/app_theme.dart';
import '../../widgets/gradient_header.dart';
import '../../widgets/modern_card.dart';

class BookingPaymentScreen extends StatefulWidget {
  final String bookingId;

  const BookingPaymentScreen({
    super.key,
    required this.bookingId,
  });

  @override
  State<BookingPaymentScreen> createState() => _BookingPaymentScreenState();
}

class _BookingPaymentScreenState extends State<BookingPaymentScreen> {
  Map<String, dynamic>? _booking;
  bool _isLoading = true;
  bool _isProcessing = false;
  String _selectedPaymentMethod = 'cash';

  @override
  void initState() {
    super.initState();
    _loadBookingDetails();
  }

  Future<void> _loadBookingDetails() async {
    setState(() => _isLoading = true);
    try {
      final booking = await Api.getBookingById(widget.bookingId);
      if (mounted) {
        setState(() {
          _booking = booking;
          _isLoading = false;
        });
        
        if (booking == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Booking not found')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading booking: $e')),
        );
      }
    }
  }

  bool get _hasQuotation => _booking?['quotation'] != null && 
      _booking!['quotation']['totalEstimate'] != null &&
      _booking!['quotation']['totalEstimate'] > 0;

  bool get _isQuotationApproved => _booking?['quotation']?['status'] == 'approved';

  bool get _isCompleted => _booking?['status'] == 'completed';
  
  bool get _isPaymentPending => _booking?['status'] == 'payment_pending' || 
      _booking?['payment']?['status'] == 'pending';

  double get _totalAmount {
    if (_hasQuotation) {
      return (_booking!['quotation']['totalEstimate'] as num).toDouble();
    }
    // Try pricing.totalFare first, then fall back to a reasonable default
    final pricingTotal = (_booking?['pricing']?['totalFare'] as num?)?.toDouble();
    if (pricingTotal != null && pricingTotal > 0) {
      return pricingTotal;
    }
    // If no pricing, return a default amount (this should be set by backend)
    return 1000.0; // Default amount in LKR
  }

  Future<void> _approveQuotation() async {
    setState(() => _isProcessing = true);
    try {
      await Api.approveQuotation(widget.bookingId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quotation approved! Technician will start work.'),
            backgroundColor: AppTheme.success,
          ),
        );
        _loadBookingDetails();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _rejectQuotation() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => _RejectQuotationDialog(),
    );

    if (reason != null && reason.isNotEmpty) {
      setState(() => _isProcessing = true);
      try {
        await Api.rejectQuotation(widget.bookingId, reason);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Quotation rejected. Technician will revise.'),
              backgroundColor: AppTheme.warning,
            ),
          );
          _loadBookingDetails();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isProcessing = false);
        }
      }
    }
  }

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);
    try {
      if (_selectedPaymentMethod == 'cash') {
        await Api.confirmCashPayment(bookingId: widget.bookingId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cash payment confirmed!'),
              backgroundColor: AppTheme.success,
            ),
          );
          Navigator.pop(context, true);
        }
      } else if (_selectedPaymentMethod == 'card') {
        // Process card payment directly
        final confirmed = await _showCardPaymentDialog();
        if (confirmed == true) {
          await Api.confirmCardPayment(bookingId: widget.bookingId);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Card payment successful!'),
                backgroundColor: AppTheme.success,
              ),
            );
            Navigator.pop(context, true);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<bool?> _showCardPaymentDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Card Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Amount: LKR ${_totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'In a production app, this would integrate with a payment gateway like Stripe, PayPal, or a local payment provider.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'For demo purposes, this will simulate a successful card payment.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
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
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm Payment'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.accentGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Payment'),
      ),
      body: Column(
        children: [
          GradientHeader(
            title: 'Payment',
            subtitle: _hasQuotation ? 'Review quotation & pay' : 'Awaiting quotation',
            icon: Icons.receipt_long,
            gradientColors: [AppTheme.accentGreen, AppTheme.accentGreen.withOpacity(0.7)],
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _booking == null
                    ? const Center(child: Text('Booking not found'))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Service Info Card
                            ModernCard(
                              gradient: LinearGradient(
                                colors: [AppTheme.primaryBlue.withOpacity(0.1), Colors.white],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.build_circle,
                                        color: AppTheme.primaryBlue,
                                        size: 32,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _booking!['serviceType'] ?? 'Service',
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              'Booking #${widget.bookingId.substring(0, 8)}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      _buildStatusBadge(),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Quotation Section
                            if (_hasQuotation) ...[
                              const Text(
                                'Quotation Details',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ModernCard(
                                child: Column(
                                  children: [
                                    _buildCostRow(
                                      'Labor Cost',
                                      _booking!['quotation']['laborCost'] ?? 0,
                                    ),
                                    const SizedBox(height: 8),
                                    _buildCostRow(
                                      'Materials Cost',
                                      _booking!['quotation']['materialsCost'] ?? 0,
                                    ),
                                    if (_booking!['quotation']['additionalCosts'] != null &&
                                        (_booking!['quotation']['additionalCosts'] as List).isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      const Divider(),
                                      const SizedBox(height: 8),
                                      ...(_booking!['quotation']['additionalCosts'] as List).map(
                                        (cost) => Padding(
                                          padding: const EdgeInsets.only(bottom: 8),
                                          child: _buildCostRow(
                                            cost['description'] ?? 'Additional',
                                            cost['amount'] ?? 0,
                                          ),
                                        ),
                                      ),
                                    ],
                                    const Divider(height: 24),
                                    _buildCostRow(
                                      'Total Estimate',
                                      _booking!['quotation']['totalEstimate'] ?? 0,
                                      isTotal: true,
                                    ),
                                    if (_booking!['quotation']['notes'] != null &&
                                        _booking!['quotation']['notes'].toString().isNotEmpty) ...[
                                      const SizedBox(height: 16),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.blue[50],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Icon(
                                              Icons.info_outline,
                                              color: AppTheme.info,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                _booking!['quotation']['notes'],
                                                style: const TextStyle(fontSize: 13),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Quotation Actions
                              if (!_isQuotationApproved && _booking!['status'] == 'quoted') ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _isProcessing ? null : _rejectQuotation,
                                        icon: const Icon(Icons.close),
                                        label: const Text('Reject'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppTheme.error,
                                          side: const BorderSide(color: AppTheme.error),
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: 2,
                                      child: ElevatedButton.icon(
                                        onPressed: _isProcessing ? null : _approveQuotation,
                                        icon: const Icon(Icons.check_circle),
                                        label: const Text('Approve & Start Work'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.success,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                              ],
                            ] else ...[
                              // Waiting for Quotation
                              ModernCard(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.hourglass_empty,
                                      size: 48,
                                      color: Colors.orange[400],
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Awaiting Quotation',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'The technician will inspect the issue and provide a detailed quotation before starting work.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Payment Section (if quotation approved OR work completed without quotation)
                            if ((_isQuotationApproved || !_hasQuotation) && (_isCompleted || _isPaymentPending)) ...[
                              if (_isPaymentPending) ...[
                                // Show payment pending message
                                ModernCard(
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.hourglass_empty,
                                        size: 48,
                                        color: Colors.orange[400],
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Payment Pending',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Your payment has been initiated. Waiting for technician to confirm receipt.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.orange[50],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Payment Method: ${_booking?['payment']?['method']?.toString().toUpperCase() ?? 'N/A'}',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.orange[700],
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                const Text(
                                  'Payment Method',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ModernCard(
                                onTap: () => setState(() => _selectedPaymentMethod = 'cash'),
                                child: Row(
                                  children: [
                                    Radio<String>(
                                      value: 'cash',
                                      groupValue: _selectedPaymentMethod,
                                      onChanged: (value) => setState(() => _selectedPaymentMethod = value!),
                                    ),
                                    const Icon(Icons.money, color: AppTheme.accentGreen),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Cash Payment',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            'Pay cash to technician',
                                            style: TextStyle(fontSize: 12, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              ModernCard(
                                onTap: () => setState(() => _selectedPaymentMethod = 'card'),
                                child: Row(
                                  children: [
                                    Radio<String>(
                                      value: 'card',
                                      groupValue: _selectedPaymentMethod,
                                      onChanged: (value) => setState(() => _selectedPaymentMethod = value!),
                                    ),
                                    const Icon(Icons.credit_card, color: AppTheme.primaryBlue),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Card Payment',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            'Pay securely with card',
                                            style: TextStyle(fontSize: 12, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isProcessing ? null : _processPayment,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.accentGreen,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                  child: _isProcessing
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : Text(
                                          'Pay LKR ${_totalAmount.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                              ],
                            ],

                            // Info Box
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue[200]!),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: AppTheme.info,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'How it works',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '1. Technician arrives and inspects the issue\n'
                                          '2. You receive a detailed quotation\n'
                                          '3. Approve the quote to start work\n'
                                          '4. Pay after work is completed',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[700],
                                            height: 1.5,
                                          ),
                                        ),
                                      ],
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

  Widget _buildStatusBadge() {
    final status = _booking!['status'] as String?;
    Color color;
    String label;

    switch (status) {
      case 'inspecting':
        color = Colors.orange;
        label = 'Inspecting';
        break;
      case 'quoted':
        color = Colors.blue;
        label = 'Quoted';
        break;
      case 'quote_approved':
        color = Colors.green;
        label = 'Approved';
        break;
      case 'in_progress':
        color = Colors.purple;
        label = 'In Progress';
        break;
      case 'payment_pending':
        color = Colors.orange;
        label = 'Payment Pending';
        break;
      case 'completed':
        color = AppTheme.success;
        label = 'Completed';
        break;
      default:
        color = Colors.grey;
        label = status ?? 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCostRow(String label, dynamic amount, {bool isTotal = false}) {
    final cost = (amount as num?)?.toDouble() ?? 0.0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          'LKR ${cost.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: isTotal ? AppTheme.primaryBlue : null,
          ),
        ),
      ],
    );
  }
}

class _RejectQuotationDialog extends StatefulWidget {
  @override
  State<_RejectQuotationDialog> createState() => _RejectQuotationDialogState();
}

class _RejectQuotationDialogState extends State<_RejectQuotationDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reject Quotation'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Please provide a reason for rejecting this quotation:'),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'E.g., Price too high, need more details...',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_controller.text.trim().isNotEmpty) {
              Navigator.pop(context, _controller.text.trim());
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.error,
            foregroundColor: Colors.white,
          ),
          child: const Text('Reject'),
        ),
      ],
    );
  }
}
