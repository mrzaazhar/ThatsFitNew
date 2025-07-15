import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_auth.dart';
import 'admin_service.dart';
import 'admin_user_management.dart';
import '../main.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool _isLoading = true;
  Map<String, dynamic> _analytics = {};
  List<Map<String, dynamic>> _dailyActivity = [];
  List<Map<String, dynamic>> _recentUsers = [];

  @override
  void initState() {
    super.initState();
    print('AdminDashboard initState called');
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    print('Loading dashboard data...');
    setState(() {
      _isLoading = true;
    });

    try {
      await Future.wait([
        _loadAnalytics(),
        _loadDailyActivity(),
        _loadRecentUsers(),
      ]);
      print('Dashboard data loaded successfully');
    } catch (e) {
      print('Error loading dashboard data: $e');
      _showSnackBar('Error loading dashboard data', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAnalytics() async {
    try {
      print('Loading user analytics...');

      // Get analytics using the stored count from admin document
      final analytics = await AdminService.getUserAnalytics();
      print('Analytics loaded - Total Users: ${analytics['totalUsers']}');
      setState(() {
        _analytics = analytics;
      });
    } catch (e) {
      print('Error loading analytics: $e');
      _showSnackBar('Error loading analytics data', Colors.red);
    }
  }

  Future<void> _loadDailyActivity() async {
    try {
      final activity = await AdminService.getDailyActivity();
      setState(() {
        _dailyActivity = activity;
      });
    } catch (e) {
      print('Error loading daily activity: $e');
    }
  }

  Future<void> _loadRecentUsers() async {
    try {
      final users = await AdminService.getAllUsers();
      setState(() {
        _recentUsers = users.take(5).toList();
      });
    } catch (e) {
      print('Error loading recent users: $e');
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1a1a1a),
      appBar: AppBar(
        backgroundColor: Color(0xFF33443c),
        title: Text(
          'Admin Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadDashboardData,
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await AdminAuth.logoutAdmin();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF33443c)),
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Section
                  _buildWelcomeSection(),
                  SizedBox(height: 24),

                  // Analytics Cards
                  _buildAnalyticsSection(),
                  SizedBox(height: 24),

                  // Quick Actions
                  _buildQuickActionsSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: EdgeInsets.all(20),
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
              Icon(Icons.admin_panel_settings, color: Colors.white, size: 32),
              SizedBox(width: 12),
              Text(
                'Welcome, Admin!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Manage your ThatsFit application and monitor user activity',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Analytics Overview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Poppins',
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.bug_report, color: Colors.orange),
                  onPressed: () async {
                    print('=== MANUAL DEBUG CHECK ===');
                    await AdminService.testFirestoreAccess();
                    final count =
                        await AdminService.getTotalUserCountFromAuth();
                    _showSnackBar('Debug: Found $count users in Firestore',
                        Colors.orange);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.add_circle, color: Colors.green),
                  onPressed: () async {
                    print('=== SETTING INITIAL USER COUNT ===');
                    await AdminService.setInitialUserCount(
                        1); // Set to 1 for testing
                    await _loadAnalytics(); // Refresh the display
                    _showSnackBar('Set initial user count to 1', Colors.green);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.settings, color: Colors.purple),
                  onPressed: () async {
                    print('=== MANUAL USER COUNT SET ===');
                    // Set a manual count for testing
                    await AdminService.updateTotalUserCount(1);
                    await _loadAnalytics(); // Refresh the display
                    _showSnackBar('Manual count set to 1', Colors.purple);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.refresh, color: Color(0xFF33443c)),
                  onPressed: () {
                    _loadAnalytics();
                    _showSnackBar('Refreshing analytics...', Color(0xFF33443c));
                  },
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.3,
          children: [
            _buildAnalyticsCard(
              'Total Users',
              _analytics['totalUsers']?.toString() ?? '0',
              Icons.people,
              Color(0xFF33443c),
            ),
            _buildAnalyticsCard(
              'Active Users',
              _analytics['activeUsers']?.toString() ?? '0',
              Icons.person_add,
              Colors.blue,
            ),
            _buildAnalyticsCard(
              'Completed Profiles',
              _analytics['completedProfiles']?.toString() ?? '0',
              Icons.check_circle,
              Colors.green,
            ),
            _buildAnalyticsCard(
              'Users with Workouts',
              _analytics['usersWithWorkouts']?.toString() ?? '0',
              Icons.fitness_center,
              Colors.orange,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnalyticsCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'Poppins',
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

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Add User',
                Icons.person_add,
                Color(0xFF33443c),
                () => _showAddUserDialog(),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
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
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Color(0xFF2d2d2d),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddUserDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminUserManagement(),
      ),
    );
  }
}
