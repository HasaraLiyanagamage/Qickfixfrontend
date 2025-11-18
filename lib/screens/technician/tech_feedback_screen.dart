import 'package:flutter/material.dart';
import '../../services/api.dart';
import '../../widgets/gradient_header.dart';
import '../../widgets/empty_state.dart';

class TechFeedbackScreen extends StatefulWidget {
  const TechFeedbackScreen({super.key});

  @override
  State<TechFeedbackScreen> createState() => _TechFeedbackScreenState();
}

class _TechFeedbackScreenState extends State<TechFeedbackScreen> {
  List<Map<String, dynamic>> _feedbacks = [];
  bool _isLoading = true;
  double _averageRating = 0.0;
  int _totalRatings = 0;
  Map<int, int> _ratingDistribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

  @override
  void initState() {
    super.initState();
    _loadFeedbacks();
  }

  Future<void> _loadFeedbacks() async {
    setState(() => _isLoading = true);
    try {
      final data = await Api.getTechnicianFeedbacks();
      print('DEBUG: Feedbacks data received: $data');
      if (mounted && data != null) {
        setState(() {
          _feedbacks = List<Map<String, dynamic>>.from(data);
          print('DEBUG: Parsed feedbacks: $_feedbacks');
          _calculateStats();
          _isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      print('DEBUG: Error loading feedbacks: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading feedbacks: $e')),
        );
      }
    }
  }

  void _calculateStats() {
    if (_feedbacks.isEmpty) {
      _averageRating = 0.0;
      _totalRatings = 0;
      _ratingDistribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
      return;
    }

    _totalRatings = _feedbacks.length;
    double sum = 0;
    _ratingDistribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

    for (var feedback in _feedbacks) {
      final ratingValue = feedback['rating'];
      // Handle both formats: direct number or object with 'score' field
      final rating = (ratingValue is num) 
          ? ratingValue.toDouble() 
          : (ratingValue is Map && ratingValue['score'] != null)
              ? (ratingValue['score'] as num).toDouble()
              : 0.0;
      sum += rating;
      final ratingInt = rating.toInt();
      if (ratingInt >= 1 && ratingInt <= 5) {
        _ratingDistribution[ratingInt] = (_ratingDistribution[ratingInt] ?? 0) + 1;
      }
    }

    _averageRating = sum / _totalRatings;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _loadFeedbacks,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: GradientHeader(
                title: 'Ratings & Feedback',
                subtitle: 'See what customers think about your work',
                icon: Icons.star,
                gradientColors: const [Colors.orangeAccent, Colors.deepOrange],
              ),
            ),
            SliverToBoxAdapter(
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _feedbacks.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(16),
                          child: EmptyState(
                            icon: Icons.star_border,
                            title: 'No feedback yet',
                            subtitle: 'Complete jobs to receive ratings and feedback from customers',
                          ),
                        )
                      : Column(
                          children: [
                            _buildStatsSection(),
                            const SizedBox(height: 16),
                            _buildRatingDistribution(),
                            const SizedBox(height: 24),
                            _buildFeedbackList(),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.orangeAccent, Colors.deepOrange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                const Icon(Icons.star, color: Colors.white, size: 48),
                const SizedBox(height: 8),
                Text(
                  _averageRating.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Average Rating',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 80,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          Expanded(
            child: Column(
              children: [
                const Icon(Icons.reviews, color: Colors.white, size: 48),
                const SizedBox(height: 8),
                Text(
                  _totalRatings.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Total Reviews',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingDistribution() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rating Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(5, (index) {
            final rating = 5 - index;
            final count = _ratingDistribution[rating] ?? 0;
            final percentage = _totalRatings > 0 ? (count / _totalRatings) : 0.0;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 30,
                    child: Text(
                      '$rating',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          rating >= 4 ? Colors.green : rating >= 3 ? Colors.orange : Colors.red,
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 40,
                    child: Text(
                      count.toString(),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFeedbackList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Customer Reviews',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ..._feedbacks.map((feedback) => _buildFeedbackCard(feedback)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard(Map<String, dynamic> feedback) {
    final ratingValue = feedback['rating'];
    // Handle both formats: direct number or object with 'score' field
    final rating = (ratingValue is num) 
        ? ratingValue.toDouble() 
        : (ratingValue is Map && ratingValue['score'] != null)
            ? (ratingValue['score'] as num).toDouble()
            : 0.0;
    
    // Get review text from rating object or comment field
    final reviewText = (ratingValue is Map && ratingValue['review'] != null)
        ? ratingValue['review'] as String
        : feedback['comment'] ?? '';
    final comment = reviewText;
    final userName = feedback['userName'] ?? 'Anonymous';
    final serviceType = feedback['serviceType'] ?? 'Service';
    final createdAt = feedback['createdAt'] ?? '';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.orangeAccent.withValues(alpha: 0.2),
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'A',
                  style: const TextStyle(
                    color: Colors.deepOrange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      serviceType,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(createdAt),
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                comment,
                style: TextStyle(
                  color: Colors.grey[800],
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStarRating(rating.toInt()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStarRating(int rating) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 20,
        );
      }),
    );
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          if (difference.inMinutes == 0) {
            return 'Just now';
          }
          return '${difference.inMinutes}m ago';
        }
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        return '${months[date.month - 1]} ${date.day}, ${date.year}';
      }
    } catch (e) {
      return '';
    }
  }
}
