import 'package:flutter/material.dart';
import '../screens/dashboard_screen.dart';
import '../screens/savings_history_screen.dart';
import '../screens/tip_history_screen.dart';
import '../screens/about_screen.dart';

class AppDrawer extends StatelessWidget {
  final Map<String, List<dynamic>> entries;
  final DateTime? focusedMonth;
  final bool isFromDashboard;
  final String? currentPage;

  const AppDrawer({
    super.key,
    this.entries = const {},
    this.focusedMonth,
    this.isFromDashboard = false,
    this.currentPage,
  });

  @override
  Widget build(BuildContext context) {
    final month = focusedMonth ?? DateTime.now();
    
    return Drawer(
      child: Container(
        color: const Color(0xFFF5F9F5),
        child: Column(
          children: [
            // Drawer Header
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF66BB6A), Color(0xFF4CAF50)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Icon(
                      Icons.savings,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Savings & Tip',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Note Calendar',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            // Menu Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    context,
                    icon: Icons.dashboard,
                    title: 'Dashboard',
                    onTap: () {
                      Navigator.pop(context);
                      if (currentPage != 'dashboard') {
                        if (currentPage != null && currentPage != 'calendar') {
                          Navigator.pop(context);
                        }
                        if (!isFromDashboard) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DashboardScreen(
                                entries: entries,
                                focusedMonth: month,
                              ),
                            ),
                          );
                        }
                      }
                    },
                    isSelected: currentPage == 'dashboard' || isFromDashboard,
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.calendar_month,
                    title: 'Calendar',
                    onTap: () {
                      Navigator.pop(context);
                      if (currentPage != null && currentPage != 'calendar') {
                        Navigator.pop(context);
                      }
                      if (isFromDashboard) {
                        Navigator.pop(context);
                      }
                    },
                    isSelected: currentPage == 'calendar' || (currentPage == null && !isFromDashboard),
                  ),
                  const Divider(color: Color(0xFFE8F5E9), thickness: 1),
                  _buildDrawerItem(
                    context,
                    icon: Icons.savings,
                    title: 'Savings History',
                    onTap: () {
                      Navigator.pop(context);
                      if (currentPage != 'savings_history') {
                        if (currentPage != null && currentPage != 'calendar') {
                          Navigator.pop(context);
                        }
                        if (isFromDashboard) {
                          Navigator.pop(context);
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SavingsHistoryScreen(
                              entries: entries,
                              focusedMonth: month,
                            ),
                          ),
                        );
                      }
                    },
                    isSelected: currentPage == 'savings_history',
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.attach_money,
                    title: 'Tip History',
                    onTap: () {
                      Navigator.pop(context);
                      if (currentPage != 'tip_history') {
                        if (currentPage != null && currentPage != 'calendar') {
                          Navigator.pop(context);
                        }
                        if (isFromDashboard) {
                          Navigator.pop(context);
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TipHistoryScreen(
                              entries: entries,
                              focusedMonth: month,
                            ),
                          ),
                        );
                      }
                    },
                    isSelected: currentPage == 'tip_history',
                  ),
                  const Divider(color: Color(0xFFE8F5E9), thickness: 1),
                  _buildDrawerItem(
                    context,
                    icon: Icons.info_outline,
                    title: 'About',
                    onTap: () {
                      Navigator.pop(context);
                      if (currentPage != 'about') {
                        if (currentPage != null && currentPage != 'calendar') {
                          Navigator.pop(context);
                        }
                        if (isFromDashboard) {
                          Navigator.pop(context);
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AboutScreen(
                              entries: entries,
                              focusedMonth: month,
                            ),
                          ),
                        );
                      }
                    },
                    isSelected: currentPage == 'about',
                  ),
                ],
              ),
            ),
            
            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              child: const Text(
                'Version 1.0.0',
                style: TextStyle(
                  color: Color(0xFF81C784),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFE8F5E9) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? const Color(0xFF4CAF50) : const Color(0xFF558B2F),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? const Color(0xFF4CAF50) : const Color(0xFF2E7D32),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
