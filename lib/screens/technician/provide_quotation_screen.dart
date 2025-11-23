import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api.dart';
import '../../utils/app_theme.dart';
import '../../widgets/gradient_header.dart';
import '../../widgets/modern_card.dart';

class ProvideQuotationScreen extends StatefulWidget {
  final String bookingId;
  final String serviceType;
  final String customerName;

  const ProvideQuotationScreen({
    super.key,
    required this.bookingId,
    required this.serviceType,
    required this.customerName,
  });

  @override
  State<ProvideQuotationScreen> createState() => _ProvideQuotationScreenState();
}

class _ProvideQuotationScreenState extends State<ProvideQuotationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _laborCostController = TextEditingController();
  final _materialsCostController = TextEditingController();
  final _notesController = TextEditingController();
  
  final List<AdditionalCost> _additionalCosts = [];
  bool _isSubmitting = false;

  double get _totalEstimate {
    double labor = double.tryParse(_laborCostController.text) ?? 0;
    double materials = double.tryParse(_materialsCostController.text) ?? 0;
    double additional = _additionalCosts.fold(0, (sum, cost) => sum + cost.amount);
    return labor + materials + additional;
  }

  @override
  void dispose() {
    _laborCostController.dispose();
    _materialsCostController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addAdditionalCost() {
    showDialog(
      context: context,
      builder: (context) => _AddCostDialog(
        onAdd: (description, amount) {
          setState(() {
            _additionalCosts.add(AdditionalCost(description, amount));
          });
        },
      ),
    );
  }

  void _removeAdditionalCost(int index) {
    setState(() {
      _additionalCosts.removeAt(index);
    });
  }

  Future<void> _submitQuotation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_totalEstimate <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Total estimate must be greater than zero'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final success = await Api.provideQuotation(
        bookingId: widget.bookingId,
        laborCost: double.tryParse(_laborCostController.text) ?? 0,
        materialsCost: double.tryParse(_materialsCostController.text) ?? 0,
        additionalCosts: _additionalCosts.map((c) => {
          'description': c.description,
          'amount': c.amount,
        }).toList(),
        notes: _notesController.text.trim(),
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Quotation sent successfully!'),
              backgroundColor: AppTheme.success,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to send quotation. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Provide Quotation'),
      ),
      body: Column(
        children: [
          GradientHeader(
            title: 'Provide Quotation',
            subtitle: 'For ${widget.customerName}',
            icon: Icons.receipt_long,
            gradientColors: [AppTheme.primaryBlue, AppTheme.primaryBlue.withOpacity(0.7)],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Service Info
                    ModernCard(
                      gradient: LinearGradient(
                        colors: [Colors.blue[50]!, Colors.white],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      child: Row(
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
                                  widget.serviceType,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Booking #${widget.bookingId.length > 8 ? widget.bookingId.substring(0, 8) : widget.bookingId}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Labor Cost
                    const Text(
                      'Labor Cost',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _laborCostController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      decoration: InputDecoration(
                        hintText: 'Enter labor cost',
                        prefixText: 'LKR ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter labor cost';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),

                    // Materials Cost
                    const Text(
                      'Materials Cost',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _materialsCostController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      decoration: InputDecoration(
                        hintText: 'Enter materials cost',
                        prefixText: 'LKR ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter materials cost';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 24),

                    // Additional Costs
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Additional Costs',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _addAdditionalCost,
                          icon: const Icon(Icons.add_circle_outline, size: 20),
                          label: const Text('Add'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_additionalCosts.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'No additional costs. Tap "Add" to include extra charges.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...List.generate(_additionalCosts.length, (index) {
                        final cost = _additionalCosts[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ModernCard(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cost.description,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'LKR ${cost.amount.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _removeAdditionalCost(index),
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    const SizedBox(height: 24),

                    // Notes
                    const Text(
                      'Notes / Explanation',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Explain the work needed, parts required, etc.',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please provide notes explaining the quotation';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Total Estimate
                    ModernCard(
                      gradient: LinearGradient(
                        colors: [AppTheme.primaryBlue.withOpacity(0.1), Colors.white],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Labor Cost:'),
                              Text(
                                'LKR ${(double.tryParse(_laborCostController.text) ?? 0).toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Materials Cost:'),
                              Text(
                                'LKR ${(double.tryParse(_materialsCostController.text) ?? 0).toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          if (_additionalCosts.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Additional Costs:'),
                                Text(
                                  'LKR ${_additionalCosts.fold(0.0, (sum, cost) => sum + cost.amount).toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Estimate:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'LKR ${_totalEstimate.toStringAsFixed(2)}',
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

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitQuotation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          disabledBackgroundColor: Colors.grey,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Send Quotation to Customer',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AdditionalCost {
  final String description;
  final double amount;

  AdditionalCost(this.description, this.amount);
}

class _AddCostDialog extends StatefulWidget {
  final Function(String description, double amount) onAdd;

  const _AddCostDialog({required this.onAdd});

  @override
  State<_AddCostDialog> createState() => _AddCostDialogState();
}

class _AddCostDialogState extends State<_AddCostDialog> {
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Additional Cost'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'e.g., Emergency callout fee',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            decoration: const InputDecoration(
              labelText: 'Amount',
              hintText: 'Enter amount',
              prefixText: 'LKR ',
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
            final description = _descriptionController.text.trim();
            final amount = double.tryParse(_amountController.text);
            
            if (description.isNotEmpty && amount != null && amount > 0) {
              widget.onAdd(description, amount);
              Navigator.pop(context);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enter valid description and amount'),
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryBlue,
            foregroundColor: Colors.white,
          ),
          child: const Text('Add'),
        ),
      ],
    );
  }
}
