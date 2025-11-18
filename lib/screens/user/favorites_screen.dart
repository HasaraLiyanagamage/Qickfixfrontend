import 'package:flutter/material.dart';
import '../../services/api.dart';
import '../../utils/app_theme.dart';
import '../../widgets/gradient_header.dart';
import '../../widgets/modern_card.dart';
import '../../widgets/empty_state.dart';
import '../request_service_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Map<String, dynamic>> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    try {
      final data = await Api.getFavorites();
      if (mounted && data != null) {
        setState(() {
          _favorites = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _removeFavorite(String technicianId) async {
    try {
      await Api.removeFavorite(technicianId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from favorites')),
        );
        _loadFavorites();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showTechnicianProfile(Map<String, dynamic> technician) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                      child: Text(
                        (technician['user']?['name'] ?? 'T')[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            technician['user']?['name'] ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            technician['serviceType'] ?? 'General Service',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Rating
                ModernCard(
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 32),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${technician['rating'] ?? 0.0}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${technician['totalReviews'] ?? 0} reviews',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Contact Info
                if (technician['user']?['phone'] != null) ...[
                  const Text(
                    'Contact',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ModernCard(
                    child: Row(
                      children: [
                        const Icon(Icons.phone, color: AppTheme.primaryBlue),
                        const SizedBox(width: 12),
                        Text(
                          technician['user']?['phone'] ?? 'N/A',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Skills
                if (technician['skills'] != null && (technician['skills'] as List).isNotEmpty) ...[
                  const Text(
                    'Skills',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (technician['skills'] as List).map((skill) {
                      return Chip(
                        label: Text(skill.toString()),
                        backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                        labelStyle: const TextStyle(color: AppTheme.primaryBlue),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _bookTechnician(technician);
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: const Text('Book Now'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _bookTechnician(Map<String, dynamic> technician) {
    // Show dialog to select service type and book this specific technician
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Book ${technician['user']?['name'] ?? 'Technician'}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Would you like to request a service from this technician?'),
            const SizedBox(height: 16),
            Text(
              'Service Type: ${technician['serviceType'] ?? 'General Service'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.star, size: 16, color: Colors.amber),
                const SizedBox(width: 4),
                Text('${technician['rating'] ?? 0.0} rating'),
              ],
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
              Navigator.pop(context); // Close dialog
              // Navigate to request service with pre-selected service type
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RequestServiceScreen(
                    initialServiceType: technician['serviceType']?.toString().toLowerCase(),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Request Service'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            title: 'Favorite Technicians',
            subtitle: 'Your trusted service providers',
            icon: Icons.favorite,
            gradientColors: [AppTheme.accentRed, AppTheme.accentRed.withOpacity(0.7)],
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _favorites.isEmpty
                    ? EmptyState(
                        icon: Icons.favorite_border,
                        title: 'No Favorites Yet',
                        subtitle: 'Add technicians to favorites for quick access',
                      )
                    : RefreshIndicator(
                        onRefresh: _loadFavorites,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _favorites.length,
                          itemBuilder: (context, index) {
                            final favorite = _favorites[index];
                            final technician = favorite['technician'] as Map<String, dynamic>?;
                            if (technician == null) return const SizedBox.shrink();
                            
                            return ModernCard(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 30,
                                        backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                                        child: Text(
                                          (technician['user']?['name'] ?? 'T')[0].toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primaryBlue,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              technician['user']?['name'] ?? 'Unknown',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              technician['serviceType'] ?? 'General Service',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(Icons.star, size: 16, color: Colors.amber),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${technician['rating'] ?? 0.0} (${technician['totalReviews'] ?? 0} reviews)',
                                                  style: const TextStyle(fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.favorite, color: AppTheme.accentRed),
                                        onPressed: () => _removeFavorite(technician['_id']),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () => _bookTechnician(technician),
                                          icon: const Icon(Icons.calendar_today, size: 18),
                                          label: const Text('Book Now'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.primaryBlue,
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => _showTechnicianProfile(technician),
                                          icon: const Icon(Icons.person, size: 18),
                                          label: const Text('View Profile'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppTheme.primaryBlue,
                                          ),
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
    );
  }
}
