import 'package:flutter/material.dart';
import '../../services/api.dart';
import '../../utils/app_theme.dart';
import '../../widgets/gradient_header.dart';
import '../../widgets/modern_card.dart';
import '../../widgets/empty_state.dart';

class ServicePackagesScreen extends StatefulWidget {
  const ServicePackagesScreen({super.key});

  @override
  State<ServicePackagesScreen> createState() => _ServicePackagesScreenState();
}

class _ServicePackagesScreenState extends State<ServicePackagesScreen> {
  List<Map<String, dynamic>> _packages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    setState(() => _isLoading = true);
    try {
      final data = await Api.getServicePackages();
      if (mounted && data != null) {
        setState(() {
          _packages = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _bookPackage(Map<String, dynamic> package) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Book ${package['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Price: LKR ${package['price']}'),
            const SizedBox(height: 8),
            Text('Duration: ${package['duration']} minutes'),
            const SizedBox(height: 8),
            const Text('Services included:'),
            const SizedBox(height: 4),
            ...((package['services'] as List?) ?? []).map((service) => 
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, size: 16, color: AppTheme.success),
                    const SizedBox(width: 8),
                    Expanded(child: Text(service.toString())),
                  ],
                ),
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
              Navigator.pop(context);
              _confirmBooking(package);
            },
            child: const Text('Confirm Booking'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmBooking(Map<String, dynamic> package) async {
    try {
      await Api.bookServicePackage(package['_id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Package booked successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Color _getPackageColor(String type) {
    switch (type.toLowerCase()) {
      case 'basic':
        return AppTheme.info;
      case 'standard':
        return AppTheme.accentOrange;
      case 'premium':
        return AppTheme.accentPurple;
      case 'emergency':
        return Colors.red;
      case 'subscription':
        return Colors.green;
      default:
        return AppTheme.primaryBlue;
    }
  }
  
  IconData _getPackageIcon(String type) {
    switch (type.toLowerCase()) {
      case 'basic':
        return Icons.home_repair_service;
      case 'standard':
        return Icons.build;
      case 'premium':
        return Icons.star;
      case 'emergency':
        return Icons.emergency;
      case 'subscription':
        return Icons.calendar_month;
      default:
        return Icons.card_giftcard;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            title: 'Service Packages',
            subtitle: 'Choose the best package for you',
            icon: Icons.card_giftcard,
            gradientColors: [AppTheme.accentPurple, AppTheme.accentPurple.withOpacity(0.7)],
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _packages.isEmpty
                    ? EmptyState(
                        icon: Icons.card_giftcard,
                        title: 'No Packages Available',
                        subtitle: 'Check back later for service packages',
                      )
                    : RefreshIndicator(
                        onRefresh: _loadPackages,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _packages.length,
                          itemBuilder: (context, index) {
                            final package = _packages[index];
                            final packageType = package['type'] ?? 'basic';
                            final color = _getPackageColor(packageType);
                            
                            return ModernCard(
                              margin: const EdgeInsets.only(bottom: 16),
                              gradient: LinearGradient(
                                colors: [color.withOpacity(0.1), Colors.white],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: color.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          _getPackageIcon(packageType),
                                          color: color,
                                          size: 32,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: color,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                packageType.toUpperCase(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              package['name'] ?? 'Package',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              package['description'] ?? '',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[600],
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          if (package['discount'] != null && package['discount'] > 0)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppTheme.success,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                '${package['discount']}% OFF',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          if (package['discount'] != null && package['discount'] > 0)
                                            const SizedBox(height: 4),
                                          Text(
                                            'LKR ${package['price']}',
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: color,
                                            ),
                                          ),
                                          Text(
                                            '${package['duration']} min',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Includes:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...((package['services'] as List?) ?? []).map((service) => 
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Row(
                                        children: [
                                          Icon(Icons.check_circle, size: 16, color: color),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              service.toString(),
                                              style: const TextStyle(fontSize: 13),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () => _bookPackage(package),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: color,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Book This Package'),
                                    ),
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
    );
  }
}
