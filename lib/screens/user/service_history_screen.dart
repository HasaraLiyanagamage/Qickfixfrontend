import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../services/api.dart';
import '../../utils/app_theme.dart';
import '../../widgets/gradient_header.dart';
import '../../widgets/modern_card.dart';
import '../../widgets/empty_state.dart';

class ServiceHistoryScreen extends StatefulWidget {
  const ServiceHistoryScreen({super.key});

  @override
  State<ServiceHistoryScreen> createState() => _ServiceHistoryScreenState();
}

class _ServiceHistoryScreenState extends State<ServiceHistoryScreen> {
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final data = await Api.getServiceHistory(
        startDate: _startDate,
        endDate: _endDate,
      );
      if (mounted && data != null) {
        setState(() {
          _history = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadHistory();
    }
  }

  Future<void> _generatePDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Service History Report',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 20),
          if (_startDate != null && _endDate != null)
            pw.Text(
              'Period: ${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}',
              style: const pw.TextStyle(fontSize: 12),
            ),
          pw.Text(
            'Generated: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headers: ['Date', 'Service', 'Technician', 'Status', 'Amount'],
            data: _history.map((booking) {
              final createdAt = booking['createdAt'];
              final date = createdAt != null 
                  ? DateTime.parse(createdAt) 
                  : DateTime.now();
              return [
                DateFormat('dd/MM/yyyy').format(date),
                booking['serviceType'] ?? 'N/A',
                booking['technician']?['user']?['name'] ?? 'N/A',
                booking['status'] ?? 'N/A',
                'LKR ${_getBookingCost(booking).toStringAsFixed(2)}',
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
          ),
          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text(
                'Total: LKR ${_calculateTotal()}',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  double _calculateTotal() {
    return _history.fold(0.0, (sum, booking) {
      // Try quotation.totalEstimate first (for on-site quotes), then pricing.totalFare
      final quotationTotal = booking['quotation']?['totalEstimate'];
      final pricingTotal = booking['pricing']?['totalFare'];
      
      final cost = quotationTotal ?? pricingTotal ?? 0;
      if (cost is num) return sum + cost.toDouble();
      return sum;
    });
  }
  
  double _getBookingCost(Map<String, dynamic> booking) {
    // Try quotation.totalEstimate first (for on-site quotes), then pricing.totalFare
    final quotationTotal = booking['quotation']?['totalEstimate'];
    final pricingTotal = booking['pricing']?['totalFare'];
    
    final cost = quotationTotal ?? pricingTotal ?? 0;
    return cost is num ? cost.toDouble() : 0.0;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppTheme.success;
      case 'cancelled':
        return AppTheme.error;
      case 'in_progress':
        return AppTheme.info;
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
            title: 'Service History',
            subtitle: 'View and export your service records',
            icon: Icons.history,
            gradientColors: [AppTheme.accentPurple, AppTheme.accentPurple.withOpacity(0.7)],
            action: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.date_range, color: Colors.white),
                  onPressed: _selectDateRange,
                  tooltip: 'Filter by Date',
                ),
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                  onPressed: _history.isEmpty ? null : _generatePDF,
                  tooltip: 'Export PDF',
                ),
              ],
            ),
          ),
          if (_startDate != null && _endDate != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.info.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.filter_list, size: 20, color: AppTheme.info),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Showing: ${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      setState(() {
                        _startDate = null;
                        _endDate = null;
                      });
                      _loadHistory();
                    },
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _history.isEmpty
                    ? EmptyState(
                        icon: Icons.history,
                        title: 'No Service History',
                        subtitle: 'Your completed services will appear here',
                      )
                    : Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${_history.length} service(s)',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Total: LKR ${_calculateTotal().toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryBlue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: RefreshIndicator(
                              onRefresh: _loadHistory,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _history.length,
                                itemBuilder: (context, index) {
                                  final booking = _history[index];
                                  final status = booking['status'] ?? 'unknown';
                                  final createdAt = booking['createdAt'];
                                  final date = createdAt != null 
                                      ? DateTime.parse(createdAt) 
                                      : DateTime.now();
                                  
                                  return ModernCard(
                                    margin: const EdgeInsets.only(bottom: 12),
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
                                                    booking['serviceType'] ?? 'Service',
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    DateFormat('dd MMM yyyy, hh:mm a').format(date),
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _getStatusColor(status),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                status.toUpperCase(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            const Icon(Icons.person, size: 16, color: Colors.grey),
                                            const SizedBox(width: 8),
                                            Text(
                                              booking['technician']?['user']?['name'] ?? 'Technician',
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                                const SizedBox(width: 8),
                                                Text(
                                                  booking['location']?['address'] ?? 'N/A',
                                                  style: const TextStyle(fontSize: 14),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              'LKR ${_getBookingCost(booking).toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.primaryBlue,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}
