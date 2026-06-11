import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import '../dummy_data/dummy_data.dart';
import '../themes/app_theme.dart';
import '../widgets/stats_card.dart';
import '../config/api_config.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List<Map<String, dynamic>> _backendUsers = [];
  List<Map<String, dynamic>> _backendBookings = [];
  bool _isLoadingUsers = false;
  bool _isLoadingBookings = false;

  @override
  void initState() {
    super.initState();
    _fetchBackendUsers();
    _fetchBackendBookings();
  }

  Future<void> _fetchBackendUsers() async {
    setState(() {
      _isLoadingUsers = true;
    });

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.adminUsersUrl),
      ).timeout(
        const Duration(seconds: 3),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          setState(() {
            _backendUsers = List<Map<String, dynamic>>.from(data['users']);
          });
        }
      }
    } catch (error) {
      print('Error fetching users: $error');
    } finally {
      setState(() {
        _isLoadingUsers = false;
      });
    }
  }

  Future<void> _fetchBackendBookings() async {
    setState(() {
      _isLoadingBookings = true;
    });

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.adminBookingsUrl),
      ).timeout(
        const Duration(seconds: 3),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          setState(() {
            _backendBookings = List<Map<String, dynamic>>.from(data['bookings']);
          });
        }
      }
    } catch (error) {
      print('Error fetching bookings: $error');
    } finally {
      setState(() {
        _isLoadingBookings = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/backend-admin');
            },
            tooltip: 'Backend Server Admin',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats cards
            Row(
              children: [
                Expanded(
                  child: StatsCard(
                    title: 'Total Users',
                    value: _backendUsers.isNotEmpty ? _backendUsers.length.toString() : '2,847',
                    icon: Icons.people,
                    iconColor: AppTheme.accentBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatsCard(
                    title: 'Total Rentals',
                    value: _backendBookings.isNotEmpty ? _backendBookings.length.toString() : '1,234',
                    icon: Icons.build,
                    iconColor: AppTheme.primaryYellow,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatsCard(
                    title: 'Total Revenue',
                    value: _backendBookings.isNotEmpty 
                        ? '₹${_backendBookings.fold<double>(0, (sum, item) => sum + (item['totalPrice'] ?? 0)).toStringAsFixed(0)}'
                        : '₹3,791,274',
                    icon: Icons.attach_money,
                    iconColor: AppTheme.accentGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatsCard(
                    title: 'Active Vendors',
                    value: DummyData.vendors.length.toString(),
                    icon: Icons.store,
                    iconColor: AppTheme.accentOrange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Backend Users Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Backend Users',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _fetchBackendUsers,
                  tooltip: 'Refresh Users',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _isLoadingUsers
                ? const Center(child: CircularProgressIndicator())
                : _backendUsers.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(24),
                        decoration: AppTheme.cardDecoration(),
                        child: Center(
                          child: Text(
                            'No users found in backend',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.mediumGray,
                                ),
                          ),
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.all(16),
                        decoration: AppTheme.cardDecoration(),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _backendUsers.length,
                          itemBuilder: (context, index) {
                            final user = _backendUsers[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.primaryYellow,
                                child: Text(
                                  (user['name']?.isNotEmpty ?? false) ? user['name'][0].toUpperCase() : 'U',
                                  style: const TextStyle(
                                    color: AppTheme.primaryBlack,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                user['name'],
                                style: const TextStyle(
                                  color: AppTheme.primaryBlack,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                user['email'],
                                style: TextStyle(
                                  color: AppTheme.mediumGray,
                                ),
                              ),
                              trailing: Text(
                                'ID: ${user['id']}',
                                style: TextStyle(
                                  color: AppTheme.mediumGray,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
            const SizedBox(height: 24),
            // Revenue chart
            Text(
              'Revenue Analytics',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.cardDecoration(),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Monthly Revenue',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '+23%',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.accentGreen,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        gridData: FlGridData(show: false),
                        titlesData: FlTitlesData(
                          show: true,
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                                if (value.toInt() >= 0 && value.toInt() < months.length) {
                                  return Text(
                                    months[value.toInt()],
                                    style: Theme.of(context).textTheme.bodySmall,
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 10000,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '₹${(value / 1000).toInt()}k',
                                  style: Theme.of(context).textTheme.bodySmall,
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: [
                          BarChartGroupData(
                            x: 0,
                            barRods: [
                              BarChartRodData(
                                toY: 25000,
                                color: AppTheme.primaryYellow,
                                width: 20,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ],
                          ),
                          BarChartGroupData(
                            x: 1,
                            barRods: [
                              BarChartRodData(
                                toY: 32000,
                                color: AppTheme.primaryYellow,
                                width: 20,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ],
                          ),
                          BarChartGroupData(
                            x: 2,
                            barRods: [
                              BarChartRodData(
                                toY: 28000,
                                color: AppTheme.primaryYellow,
                                width: 20,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ],
                          ),
                          BarChartGroupData(
                            x: 3,
                            barRods: [
                              BarChartRodData(
                                toY: 40000,
                                color: AppTheme.primaryYellow,
                                width: 20,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ],
                          ),
                          BarChartGroupData(
                            x: 4,
                            barRods: [
                              BarChartRodData(
                                toY: 35000,
                                color: AppTheme.primaryYellow,
                                width: 20,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ],
                          ),
                          BarChartGroupData(
                            x: 5,
                            barRods: [
                              BarChartRodData(
                                toY: 45000,
                                color: AppTheme.primaryYellow,
                                width: 20,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Vendor approvals
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pending Vendor Approvals',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.accentOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '12 Pending',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.accentOrange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...DummyData.vendors.take(3).map((vendor) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.cardDecoration(),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(vendor.imageUrl),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vendor.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            vendor.location,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.mediumGray,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check_circle, color: AppTheme.accentGreen),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel, color: AppTheme.accentRed),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 24),
            // Backend Bookings
            Text(
              'Recent Bookings',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _isLoadingBookings
                ? const Center(child: CircularProgressIndicator())
                : _backendBookings.isEmpty
                    ? const Center(child: Text('No bookings yet'))
                    : Column(
                        children: _backendBookings.take(5).map((booking) {
                          final tool = booking['tool'];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: AppTheme.cardDecoration(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      tool['name'] ?? 'Unknown Tool',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(booking['status']).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        (booking['status'] ?? 'pending').toUpperCase(),
                                        style: TextStyle(
                                          color: _getStatusColor(booking['status']),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('Customer: ${booking['userName'] ?? 'N/A'}'),
                                Text('Phone: ${booking['userPhone'] ?? 'N/A'}'),
                                Text('Price: ₹${booking['totalPrice']?.toStringAsFixed(0) ?? '0'}'),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.payment, size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Payment: ${(booking['paymentMethod'] ?? 'cash').toUpperCase()}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                    if (booking['paymentDetails'] != null && booking['paymentDetails'].isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        '(${booking['paymentDetails']})',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Colors.grey,
                                            ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
            const SizedBox(height: 24),
            // Recent activity
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.cardDecoration(),
              child: Column(
                children: [
                  _buildActivityItem(
                    'New user registration',
                    'John Doe joined the platform',
                    Icons.person_add,
                    AppTheme.accentBlue,
                  ),
                  const Divider(height: 32),
                  _buildActivityItem(
                    'New booking',
                    'Bosch Drill rented for 3 days',
                    Icons.build,
                    AppTheme.primaryYellow,
                  ),
                  const Divider(height: 32),
                  _buildActivityItem(
                    'Payment received',
                    '₹7,055.00 payment from Sarah',
                    Icons.payment,
                    AppTheme.accentGreen,
                  ),
                  const Divider(height: 32),
                  _buildActivityItem(
                    'Vendor request',
                    'BuildRight Rentals requested approval',
                    Icons.store,
                    AppTheme.accentOrange,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Reports section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Reports & Analytics',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'View All',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.primaryYellow,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildReportCard('User Growth', '+15%', Icons.trending_up, AppTheme.accentGreen),
                _buildReportCard('Revenue', '+23%', Icons.attach_money, AppTheme.primaryYellow),
                _buildReportCard('Bookings', '+8%', Icons.build, AppTheme.accentBlue),
                _buildReportCard('Vendors', '+12%', Icons.store, AppTheme.accentOrange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(String title, String subtitle, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.mediumGray,
                    ),
              ),
            ],
          ),
        ),
        Text(
          '2h ago',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.mediumGray,
              ),
        ),
      ],
    );
  }

  Widget _buildReportCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.mediumGray,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }
}
