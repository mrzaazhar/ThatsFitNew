import 'package:flutter/material.dart';
import 'admin_auth.dart';
import 'admin_service.dart';
import 'admin_user_management.dart';
import '../main.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  int _totalUsers = 0;
  int _activeUsers = 0;
  List<Map<String, dynamic>> _recentUsers = [];
  String _serverStatus = 'Unknown';
  String _lastRefreshTime = 'Never';
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _loadDashboardData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      print('🔄 Loading dashboard data...');

      // Load data from Firebase
      await Future.wait([
        _loadAnalyticsFromFirebase(),
        _loadRecentUsersFromFirebase(),
        _loadServerStatus(),
      ]);

      _fadeController.forward();
      _slideController.forward();
      print('✅ Dashboard data loaded successfully');
    } catch (e) {
      print('❌ Error loading dashboard data: $e');
      _showSnackBar('Error loading dashboard data', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAnalyticsFromFirebase() async {
    try {
      print('📊 Loading analytics from Firebase...');
      final total = await AdminService.getTotalUsersFromStoredResponse();
      final active = await AdminService.getActiveUsersFromStoredResponse();

      print('✅ Analytics loaded - Total: $total, Active: $active');

      setState(() {
        _totalUsers = total;
        _activeUsers = active;
      });
    } catch (e) {
      print('❌ Error loading analytics from Firebase: $e');
      _showSnackBar('Error loading analytics data', Colors.red);
    }
  }

  Future<void> _loadRecentUsersFromFirebase() async {
    try {
      print('📊 Loading recent users from Firebase...');
      final users = await AdminService.getRecentUsersFromStoredResponse();

      print('✅ Recent users loaded: ${users.length} users');

      setState(() {
        _recentUsers = users.take(5).toList();
      });
    } catch (e) {
      print('❌ Error loading recent users from Firebase: $e');
      _showSnackBar('Error loading recent users', Colors.red);
    }
  }

  Future<void> _loadServerStatus() async {
    try {
      print('📊 Loading server status from Firebase...');
      final status = await AdminService.getServerHealthStatus();
      final lastRefresh = await AdminService.getLastRefreshTime();

      print(
          '✅ Server Status loaded - Status: $status, Last Refresh: $lastRefresh');

      setState(() {
        _serverStatus = status;
        _lastRefreshTime = lastRefresh;
      });
    } catch (e) {
      print('❌ Error loading server status from Firebase: $e');
      _showSnackBar('Error loading server status', Colors.red);
    }
  }

  Future<void> _loadAnalytics() async {
    try {
      print('🔄 Loading analytics data...');
      print('📊 Calling getTotalUserCount()...');
      final total = await AdminService.getTotalUserCount();
      print('✅ Total users received: $total');

      print('📊 Calling getActiveUsersCount()...');
      final active = await AdminService.getActiveUsersCount();
      print('✅ Active users received: $active');

      setState(() {
        _totalUsers = total;
        _activeUsers = active;
      });
      print('✅ Analytics data loaded successfully');
    } catch (e) {
      print('❌ Error loading analytics data: $e');
      _showSnackBar('Error loading analytics data', Colors.red);
    }
  }

  Future<void> _loadRecentUsers() async {
    try {
      print('🔄 Loading recent users...');
      print('📊 Calling getAllUsersFromBackend()...');
      final users = await AdminService.getAllUsersFromBackend();
      print('✅ Recent users received: ${users.length} users');

      setState(() {
        _recentUsers = users.take(5).toList();
      });
      print('✅ Recent users loaded successfully');
    } catch (e) {
      print('❌ Error loading recent users: $e');
      _showSnackBar('Error loading recent users', Colors.red);
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400;
    final isMediumScreen = screenSize.width >= 400 && screenSize.width < 600;

    return Scaffold(
      backgroundColor: Color(0xFF1a1a1a),
      appBar: AppBar(
        backgroundColor: Color(0xFF33443c),
        elevation: 0,
        title: Text(
          'Admin Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: isSmallScreen ? 18 : 20,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout,
                color: Colors.white, size: isSmallScreen ? 20 : 24),
            onPressed: () async {
              await AdminAuth.logoutAdmin();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF33443c)),
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading dashboard...',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 12 : 16,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWelcomeSection(isSmallScreen),
                        SizedBox(height: isSmallScreen ? 20 : 24),
                        _buildAnalyticsSection(isSmallScreen, isMediumScreen),
                        SizedBox(height: isSmallScreen ? 20 : 24),
                        _buildQuickActionsSection(isSmallScreen),
                        SizedBox(height: 20),
                        _buildRecentUsersSection(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildWelcomeSection(bool isSmallScreen) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF33443c),
            Color(0xFF2a3630),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.admin_panel_settings,
                color: Colors.white,
                size: isSmallScreen ? 28 : 32,
              ),
              SizedBox(width: isSmallScreen ? 10 : 12),
              Expanded(
                child: Text(
                  'Welcome, Admin!',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 20 : 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Manage your ThatsFit application and monitor user activity',
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              color: Colors.white.withOpacity(0.9),
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsSection(bool isSmallScreen, bool isMediumScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Analytics Overview',
                style: TextStyle(
                  fontSize: isSmallScreen ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.refresh, color: Color(0xFF33443c), size: 20),
              onPressed: _loadAnalytics,
              tooltip: 'Refresh',
            ),
          ],
        ),
        SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisCount: isSmallScreen ? 1 : 2,
          crossAxisSpacing: isSmallScreen ? 0 : 16,
          mainAxisSpacing: isSmallScreen ? 12 : 16,
          childAspectRatio: isSmallScreen ? 2.5 : (isMediumScreen ? 1.4 : 1.3),
          children: [
            _buildAnalyticsCard(
              'Total Users',
              _totalUsers.toString(),
              Icons.people,
              Color(0xFF33443c),
              isSmallScreen,
            ),
            _buildAnalyticsCard(
              'ThatsFit Active Users',
              _activeUsers.toString(),
              Icons.person_add,
              Colors.blue,
              isSmallScreen,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnalyticsCard(String title, String value, IconData icon,
      Color color, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: Color(0xFF2d2d2d),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: isSmallScreen
          ? Row(
              children: [
                Icon(icon, color: color, size: isSmallScreen ? 20 : 24),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmallScreen ? 12 : 14,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        value,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmallScreen ? 18 : 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      if (title == 'Total Users' && value == '0' && !_isLoading)
                        Text(
                          'No users registered yet',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 8,
                            fontFamily: 'Poppins',
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 24),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontFamily: 'Poppins',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                if (title == 'Total Users' && value == '0' && !_isLoading)
                  Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'No users registered yet',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 10,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildQuickActionsSection(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: isSmallScreen ? 18 : 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
        ),
        SizedBox(height: 16),
        _buildActionCard(
          'User Management',
          Icons.people,
          Colors.blue,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdminUserManagement(),
              ),
            );
          },
          isSmallScreen,
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color,
      VoidCallback onTap, bool isSmallScreen) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
          decoration: BoxDecoration(
            color: Color(0xFF2d2d2d),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: isSmallScreen ? 28 : 32,
              ),
              SizedBox(height: isSmallScreen ? 6 : 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentUsersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Users',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
        ),
        SizedBox(height: 12),
        _recentUsers.isEmpty
            ? Text(
                'No recent users found.',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                  fontFamily: 'Poppins',
                ),
              )
            : ListView.separated(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _recentUsers.length,
                separatorBuilder: (context, index) => Divider(
                  color: Colors.grey[700],
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final user = _recentUsers[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Color(0xFF33443c),
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(
                      user['name'] ?? 'Unknown',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      user['email'] ?? '',
                      style: TextStyle(
                        color: Colors.white70,
                        fontFamily: 'Poppins',
                        fontSize: 12,
                      ),
                    ),
                    trailing: Text(
                      user['createdAt'] != null
                          ? user['createdAt'].toString().substring(0, 10)
                          : '',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  );
                },
              ),
      ],
    );
  }
}
