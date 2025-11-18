import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../../services/api.dart';
import '../../utils/app_theme.dart';
import '../../widgets/gradient_header.dart';
import '../../widgets/modern_card.dart';

class PaymentScreen extends StatefulWidget {
  final String bookingId;
  final double amount;
  final String serviceType;

  const PaymentScreen({
    super.key,
    required this.bookingId,
    required this.amount,
    required this.serviceType,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedMethod = 'card';
  bool _isProcessing = false;
  CardFieldInputDetails? _cardDetails;

  Future<void> _processPayment() async {
    if (_selectedMethod == 'card' && _cardDetails?.complete != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter complete card details')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      if (_selectedMethod == 'card') {
        await _processCardPayment();
      } else if (_selectedMethod == 'cash') {
        await _processCashPayment();
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

  Future<void> _processCardPayment() async {
    try {
      // Create payment intent
      final paymentIntent = await Api.createPaymentIntent(
        bookingId: widget.bookingId,
        amount: widget.amount,
      );

      if (paymentIntent == null) {
        throw Exception('Failed to create payment intent');
      }

      // Confirm payment with Stripe
      await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: paymentIntent['clientSecret'],
        data: const PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(),
        ),
      );

      // Confirm payment on backend
      await Api.confirmPayment(
        bookingId: widget.bookingId,
        paymentIntentId: paymentIntent['id'],
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment successful!'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _processCashPayment() async {
    try {
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
    } catch (e) {
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            title: 'Payment',
            subtitle: 'Complete your payment',
            icon: Icons.payment,
            gradientColors: [AppTheme.accentGreen, AppTheme.accentGreen.withOpacity(0.7)],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ModernCard(
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryBlue.withOpacity(0.1), Colors.white],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Payment Summary',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Service:', style: TextStyle(fontSize: 14)),
                            Text(
                              widget.serviceType,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Divider(),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Amount:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'LKR ${widget.amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Select Payment Method',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ModernCard(
                    onTap: () => setState(() => _selectedMethod = 'card'),
                    child: Row(
                      children: [
                        Radio<String>(
                          value: 'card',
                          groupValue: _selectedMethod,
                          onChanged: (value) => setState(() => _selectedMethod = value!),
                        ),
                        const Icon(Icons.credit_card, color: AppTheme.primaryBlue),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Credit/Debit Card',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Pay securely with your card',
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
                    onTap: () => setState(() => _selectedMethod = 'cash'),
                    child: Row(
                      children: [
                        Radio<String>(
                          value: 'cash',
                          groupValue: _selectedMethod,
                          onChanged: (value) => setState(() => _selectedMethod = value!),
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
                  if (_selectedMethod == 'card') ...[
                    const SizedBox(height: 24),
                    ModernCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Card Details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          CardField(
                            onCardChanged: (card) {
                              setState(() {
                                _cardDetails = card;
                              });
                            },
                            style: const TextStyle(fontSize: 16),
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _processPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        disabledBackgroundColor: Colors.grey,
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
                              'Pay LKR ${widget.amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Secure payment powered by Stripe',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
