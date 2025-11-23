import 'package:flutter/material.dart';
import '../../services/api.dart';
import '../../utils/app_theme.dart';
import '../../widgets/gradient_header.dart';
import '../../widgets/modern_card.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  Map<String, dynamic>? _metrics;
  bool _isLoading = true;
  String _timeRange = 'today';

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    setState(() => _isLoading = true);
    try {
      print('=== Loading Analytics Metrics ===');
      print('Time Range: $_timeRange');
      
      final data = await Api.getDashboardMetrics(timeRange: _timeRange);
      print('Dashboard Metrics Response: $data');
      
      if (mounted) {
        setState(() {
          if (data != null && data['metrics'] != null) {
            final metrics = data['metrics'];
            print('Metrics Data: $metrics');
            
            // Transform backend response to frontend format
            final totalBookings = metrics['bookings']?['total'] ?? 0;
            final completedBookings = metrics['bookings']?['completed'] ?? 0;
            final activeBookings = metrics['bookings']?['active'] ?? 0;
            final cancelledBookings = metrics['bookings']?['cancelled'] ?? 0;
            final pendingBookings = totalBookings - completedBookings - activeBookings - cancelledBookings;
            
            print('Total Bookings: $totalBookings');
            print('Completed: $completedBookings, Active: $activeBookings, Cancelled: $cancelledBookings');
            print('Total Users: ${metrics['users']?['total']}');
            print('Total Revenue: ${metrics['revenue']?['total']}');
            
            _metrics = {
              'totalBookings': totalBookings,
              'activeUsers': metrics['users']?['total'] ?? 0,
              'totalRevenue': (metrics['revenue']?['total'] ?? 0).toDouble(),
              'averageRating': double.tryParse(metrics['performance']?['averageRating']?.toString() ?? '0') ?? 0.0,
              'pendingBookings': pendingBookings > 0 ? pendingBookings : 0,
              'inProgressBookings': activeBookings,
              'completedBookings': completedBookings,
              'cancelledBookings': cancelledBookings,
              'topServices': [],
              'topTechnicians': [],
            };
            print('Metrics Object Created: $_metrics');
            _loadAdditionalData();
          } else {
            print('ERROR: No metrics data in response');
            _metrics = null;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      print('ERROR loading metrics: $e');
    }
  }

  Future<void> _loadAdditionalData() async {
    try {
      print('=== Loading Additional Data ===');
      
      // Load service analytics for top services
      print('Fetching service analytics...');
      final serviceData = await Api.getServiceTypeAnalytics(timeRange: _timeRange);
      print('Service Data Response: $serviceData');
      
      if (serviceData != null && serviceData['analytics'] != null) {
        final services = serviceData['analytics']['services'] as List? ?? [];
        print('Services List: $services');
        
        if (mounted) {
          setState(() {
            _metrics!['topServices'] = services.take(5).map((s) => {
              'service': s['serviceType'] ?? 'Unknown',
              'count': s['bookings'] ?? 0,
            }).toList();
            print('Top Services Updated: ${_metrics!['topServices']}');
          });
        }
      } else {
        print('No service analytics data');
      }

      // Load performance analytics for top technicians
      print('Fetching performance analytics...');
      final perfData = await Api.getPerformanceAnalytics(timeRange: _timeRange);
      print('Performance Data Response: $perfData');
      
      if (perfData != null && perfData['analytics'] != null) {
        final techPerf = perfData['analytics']['technicianPerformance'] as List? ?? [];
        print('Technician Performance List: $techPerf');
        
        if (mounted) {
          setState(() {
            _metrics!['topTechnicians'] = techPerf.take(5).map((t) {
              final techId = t['_id']?.toString() ?? '';
              final displayId = techId.length > 8 ? techId.substring(0, 8) : techId;
              return {
                'name': 'Technician $displayId',
                'completedJobs': t['totalBookings'] ?? 0,
                'rating': t['avgRating'] ?? 0.0,
              };
            }).toList();
            print('Top Technicians Updated: ${_metrics!['topTechnicians']}');
          });
        }
      } else {
        print('No performance analytics data');
      }
    } catch (e) {
      print('ERROR loading additional data: $e');
    }
  }

  void _changeTimeRange(String range) {
    setState(() => _timeRange = range);
    _loadMetrics();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            title: 'Analytics Dashboard',
            subtitle: 'System performance metrics',
            icon: Icons.analytics,
            gradientColors: [AppTheme.accentPurple, AppTheme.accentPurple.withOpacity(0.7)],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildTimeRangeButton('Today', 'today'),
                const SizedBox(width: 8),
                _buildTimeRangeButton('Week', 'week'),
                const SizedBox(width: 8),
                _buildTimeRangeButton('Month', 'month'),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _metrics == null
                    ? const Center(child: Text('No data available'))
                    : RefreshIndicator(
                        onRefresh: _loadMetrics,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Overview Metrics
                              const Text(
                                'Overview',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildMetricCard(
                                      'Total Bookings',
                                      (_metrics!['totalBookings'] ?? 0).toString(),
                                      Icons.work,
                                      Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildMetricCard(
                                      'Active Users',
                                      (_metrics!['activeUsers'] ?? 0).toString(),
                                      Icons.people,
                                      Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildMetricCard(
                                      'Revenue',
                                      'Rs ${(_metrics!['totalRevenue'] ?? 0).toStringAsFixed(0)}',
                                      Icons.attach_money,
                                      Colors.orange,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildMetricCard(
                                      'Avg Rating',
                                      (_metrics!['averageRating'] ?? 0.0).toStringAsFixed(1),
                                      Icons.star,
                                      Colors.amber,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Booking Status
                              const Text(
                                'Booking Status',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ModernCard(
                                child: Column(
                                  children: [
                                    _buildStatusRow('Pending', (_metrics!['pendingBookings'] ?? 0) as int, Colors.orange),
                                    const Divider(),
                                    _buildStatusRow('In Progress', (_metrics!['inProgressBookings'] ?? 0) as int, Colors.blue),
                                    const Divider(),
                                    _buildStatusRow('Completed', (_metrics!['completedBookings'] ?? 0) as int, Colors.green),
                                    const Divider(),
                                    _buildStatusRow('Cancelled', (_metrics!['cancelledBookings'] ?? 0) as int, Colors.red),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Top Services
                              const Text(
                                'Top Services',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ModernCard(
                                child: (_metrics!['topServices'] as List? ?? []).isEmpty
                                    ? const Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Center(
                                          child: Text(
                                            'No service data available',
                                            style: TextStyle(color: Colors.grey),
                                          ),
                                        ),
                                      )
                                    : Column(
                                        children: (_metrics!['topServices'] as List)
                                            .map((service) => Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text(
                                                        service['service'] ?? 'Unknown',
                                                        style: const TextStyle(fontSize: 16),
                                                      ),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                          vertical: 4,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: AppTheme.accentPurple.withOpacity(0.1),
                                                          borderRadius: BorderRadius.circular(12),
                                                        ),
                                                        child: Text(
                                                          '${service['count']} bookings',
                                                          style: TextStyle(
                                                            color: AppTheme.accentPurple,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ))
                                            .toList(),
                                      ),
                              ),
                              const SizedBox(height: 24),

                              // Technician Performance
                              const Text(
                                'Top Technicians',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ModernCard(
                                child: (_metrics!['topTechnicians'] as List? ?? []).isEmpty
                                    ? const Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Center(
                                          child: Text(
                                            'No technician data available',
                                            style: TextStyle(color: Colors.grey),
                                          ),
                                        ),
                                      )
                                    : Column(
                                        children: (_metrics!['topTechnicians'] as List)
                                            .map((tech) => Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                                  child: Row(
                                                    children: [
                                                      CircleAvatar(
                                                        backgroundColor: AppTheme.accentPurple,
                                                        child: Text(
                                                          tech['name']?[0] ?? '?',
                                                          style: const TextStyle(color: Colors.white),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(
                                                              tech['name'] ?? 'Unknown',
                                                              style: const TextStyle(
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            ),
                                                            Text(
                                                              '${tech['completedJobs']} jobs • ${tech['rating']?.toStringAsFixed(1) ?? '0.0'} ⭐',
                                                              style: const TextStyle(
                                                                fontSize: 12,
                                                                color: Colors.grey,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ))
                                            .toList(),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRangeButton(String label, String value) {
    final isSelected = _timeRange == value;
    return Expanded(
      child: ElevatedButton(
        onPressed: () => _changeTimeRange(value),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? AppTheme.accentPurple : Colors.grey[200],
          foregroundColor: isSelected ? Colors.white : Colors.black,
          elevation: isSelected ? 2 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(label),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          Text(
            count.toString(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
