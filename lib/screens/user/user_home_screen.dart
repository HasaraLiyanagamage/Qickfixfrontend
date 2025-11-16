import 'package:flutter/material.dart';
import '../../services/api.dart';
import '../../models/app_models.dart';
import '../../l10n/app_localizations.dart';
import '../login_screen.dart';
import '../request_service_screen.dart';
import 'user_chatbot_screen.dart';
import 'user_bookings_screen.dart';
import 'user_profile_screen.dart';
import 'user_settings_screen.dart';
import 'user_notifications_screen.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  List<Booking>? _recentBookings;
  bool _isLoading = true;
  int _selectedIndex = 0;
  int _unreadNotificationCount = 0;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadRecentBookings();
    _loadUnreadNotificationCount();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await Api.getUserProfile();
      if (mounted && profile != null) {
        setState(() {
          _userName = profile['name'] ?? '';
        });
      }
    } catch (e) {
      // Handle error silently - endpoint may not exist yet
      // Greeting will show "Welcome!" instead of personalized name
      if (mounted) {
        setState(() {
          _userName = ''; // Will fallback to "Welcome!"
        });
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  Future<void> _loadUnreadNotificationCount() async {
    try {
      final count = await Api.getUnreadNotificationCount();
      if (mounted) {
        setState(() {
          _unreadNotificationCount = count;
        });
      }
    } catch (e) {
      // Handle error silently - endpoint may not exist yet
      // Badge will show 0 notifications
      if (mounted) {
        setState(() {
          _unreadNotificationCount = 0;
        });
      }
    }
  }

  Future<void> _loadRecentBookings() async {
    setState(() => _isLoading = true);
    try {
      final bookingsData = await Api.getUserBookings();
      if (mounted) {
        setState(() {
          _recentBookings = bookingsData
              ?.map((b) => Booking.fromJson(b))
              .take(3)
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    await Api.logout();
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _openChatbot(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UserChatbotScreen()),
    );
  }

  void _requestService(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RequestServiceScreen()),
    );
  }

  void _viewAllBookings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UserBookingsScreen()),
    );
  }

  Future<void> _selectService(String serviceType) async {
    // Navigate to the new request service screen with pre-selected service
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RequestServiceScreen(
          initialServiceType: serviceType,
        ),
      ),
    );
  }

  void _onNavItemTapped(int index) {
    if (_selectedIndex == index) return; // Don't navigate if already on the page
    
    setState(() => _selectedIndex = index);
    
    switch (index) {
      case 0:
        // Already on home, do nothing
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UserBookingsScreen()),
        ).then((_) {
          // Reset selection when returning
          if (mounted) setState(() => _selectedIndex = 0);
        });
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UserChatbotScreen()),
        ).then((_) {
          if (mounted) setState(() => _selectedIndex = 0);
        });
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UserSettingsScreen()),
        ).then((_) {
          if (mounted) setState(() => _selectedIndex = 0);
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).appName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: theme.primaryColor,
        elevation: 0,
        actions: [
          // Notifications icon with badge
          IconButton(
            icon: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.notifications, size: 20),
                ),
                if (_unreadNotificationCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        _unreadNotificationCount > 9 ? '9+' : _unreadNotificationCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserNotificationsScreen()),
              );
              // Reload notification count after returning
              _loadUnreadNotificationCount();
            },
            tooltip: 'Notifications',
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.person, size: 20),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserProfileScreen()),
              );
            },
            tooltip: AppLocalizations.of(context).profile,
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.chat_bubble_outline, size: 20),
            ),
            onPressed: () => _openChatbot(context),
            tooltip: AppLocalizations.of(context).chat,
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: _buildDrawer(theme, isDark),
      body: RefreshIndicator(
        onRefresh: _loadRecentBookings,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeSection(),
              const SizedBox(height: 24),
              _buildQuickActions(),
              const SizedBox(height: 24),
              _buildServicesSection(),
              const SizedBox(height: 24),
              _buildRecentBookingsSection(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _requestService(context),
        backgroundColor: theme.primaryColor,
        elevation: 6,
        icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 24),
        label: Text(
          AppLocalizations.of(context).translate('request_service'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 0.5,
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onNavItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          selectedItemColor: theme.primaryColor,
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home),
              label: AppLocalizations.of(context).home,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.history),
              label: AppLocalizations.of(context).bookings,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.chat_bubble_outline),
              label: AppLocalizations.of(context).chat,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.settings),
              label: AppLocalizations.of(context).settings,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.waving_hand,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userName.isNotEmpty ? '${_getGreeting()}, $_userName!' : '${AppLocalizations.of(context).welcome}!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context).translate('how_can_help'),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: 16,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.flash_on,
                color: theme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).translate('quick_actions'),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  icon: Icons.build_circle,
                  label: AppLocalizations.of(context).translate('request_service'),
                  color: theme.primaryColor,
                  onTap: () => _requestService(context),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.history_rounded,
                  label: AppLocalizations.of(context).translate('my_bookings'),
                  color: Colors.orange,
                  onTap: () => _viewAllBookings(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.2),
                      color.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServicesSection() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final services = [
      {'icon': Icons.plumbing, 'name': 'Plumbing', 'color': const Color(0xFF2196F3)},
      {'icon': Icons.electrical_services, 'name': 'Electrical', 'color': const Color(0xFFFFC107)},
      {'icon': Icons.carpenter, 'name': 'Carpentry', 'color': const Color(0xFF795548)},
      {'icon': Icons.format_paint, 'name': 'Painting', 'color': const Color(0xFF9C27B0)},
      {'icon': Icons.ac_unit, 'name': 'AC Repair', 'color': const Color(0xFF00BCD4)},
      {'icon': Icons.cleaning_services, 'name': 'Cleaning', 'color': const Color(0xFF4CAF50)},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.home_repair_service,
                color: theme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).translate('our_services'),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.95,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              final color = service['color'] as Color;
              
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _selectService(service['name'] as String),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                color.withValues(alpha: 0.2),
                                color.withValues(alpha: 0.1),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            service['icon'] as IconData,
                            color: color,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            service['name'] as String,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentBookingsSection() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.history_rounded,
                    color: theme.primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context).translate('recent_bookings'),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => _viewAllBookings(context),
                style: TextButton.styleFrom(
                  foregroundColor: theme.primaryColor,
                ),
                child: Row(
                  children: [
                    Text(
                      AppLocalizations.of(context).translate('view_all'),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_ios, size: 14),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: CircularProgressIndicator(
                  color: theme.primaryColor,
                ),
              ),
            )
          else if (_recentBookings == null || _recentBookings!.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.work_outline,
                        size: 48,
                        color: theme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context).translate('no_bookings'),
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context).translate('start_first_service'),
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => _requestService(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.add_circle_outline),
                      label: Text(
                        AppLocalizations.of(context).translate('request_first_service'),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: _recentBookings!
                  .map((booking) => _buildBookingCard(booking))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final statusColor = booking.getStatusColor();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Navigate to bookings screen to see full details
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const UserBookingsScreen(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        statusColor.withValues(alpha: 0.2),
                        statusColor.withValues(alpha: 0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.build_circle,
                    color: statusColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.serviceType.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              booking.location?['address'] ?? 'No address',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        statusColor.withValues(alpha: 0.2),
                        statusColor.withValues(alpha: 0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    booking.getStatusDisplay(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(ThemeData theme, bool isDark) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.primaryColor,
                  theme.primaryColor.withValues(alpha: 0.8),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 35, color: Colors.blue),
                ),
                const SizedBox(height: 12),
                Text(
                  _userName.isNotEmpty ? _userName : 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('My Bookings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserBookingsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            trailing: _unreadNotificationCount > 0
                ? Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _unreadNotificationCount > 9
                          ? '9+'
                          : _unreadNotificationCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : null,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserNotificationsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserProfileScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.chat_bubble_outline),
            title: const Text('Chat Support'),
            onTap: () {
              Navigator.pop(context);
              _openChatbot(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserSettingsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _logout(context);
            },
          ),
        ],
      ),
    );
  }
}
