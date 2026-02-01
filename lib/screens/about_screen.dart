import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';

class AboutScreen extends StatelessWidget {
  final Map<String, List<dynamic>> entries;
  final DateTime focusedMonth;

  const AboutScreen({
    super.key,
    this.entries = const {},
    DateTime? focusedMonth,
  }) : focusedMonth = focusedMonth ?? const _DefaultDateTime();

  @override
  Widget build(BuildContext context) {
    final month = focusedMonth is _DefaultDateTime ? DateTime.now() : focusedMonth;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'About',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: AppDrawer(
        entries: entries,
        focusedMonth: month,
        currentPage: 'about',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // App Logo & Title
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF66BB6A), Color(0xFF4CAF50)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4CAF50).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.savings,
                        size: 56,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Savings & Tip',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Note Calendar',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Version 1.0.0',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // About Section
              _buildSection(
                'About This App',
                Icons.info_outline,
                'Savings & Tip Note Calendar is a simple yet powerful app designed to help you track your daily savings and tips. Whether you\'re saving for a goal or tracking your tip income, this app makes it easy to stay organized and motivated.',
              ),
              const SizedBox(height: 12),

              // Features Section
              _buildSection(
                'Key Features',
                Icons.star_outline,
                null,
                features: [
                  '📅 Visual calendar with entry indicators',
                  '💰 Track both savings and tips separately',
                  '📊 Dashboard with interactive line graphs',
                  '📋 Detailed history for all entries',
                  '📝 Add descriptions to your entries',
                  '🔄 Navigate through months and years easily',
                ],
              ),
              const SizedBox(height: 12),

              // How to Use Section
              _buildSection(
                'How to Use',
                Icons.help_outline,
                null,
                steps: [
                  {'step': '1', 'title': 'Select a Date', 'desc': 'Tap any date on the calendar to select it for entry.'},
                  {'step': '2', 'title': 'Enter Amount', 'desc': 'Type the amount you want to save or the tip you received.'},
                  {'step': '3', 'title': 'Add Description', 'desc': 'Optionally add a note to remember what the entry is for.'},
                  {'step': '4', 'title': 'Save or Tip', 'desc': 'Tap "Savings" or "Tip" button to record your entry.'},
                  {'step': '5', 'title': 'View Details', 'desc': 'Double-tap any date to see all entries for that day.'},
                ],
              ),
              const SizedBox(height: 12),

              // Benefits Section
              _buildSection(
                'Benefits',
                Icons.thumb_up_outlined,
                null,
                features: [
                  '✅ Build better saving habits',
                  '✅ Track your tip income accurately',
                  '✅ Visualize your progress over time',
                  '✅ Stay motivated with visual feedback',
                  '✅ Easy to use, no complicated setup',
                  '✅ Works offline - your data stays private',
                ],
              ),
              const SizedBox(height: 12),

              // Tips Section
              _buildSection(
                'Pro Tips',
                Icons.lightbulb_outline,
                null,
                features: [
                  '💡 Set a daily or weekly savings goal',
                  '💡 Check the dashboard for monthly trends',
                  '💡 Use descriptions to categorize entries',
                  '💡 Review your history to find patterns',
                  '💡 Celebrate milestones to stay motivated!',
                ],
              ),
              const SizedBox(height: 20),

              // Footer
              Center(
                child: Column(
                  children: [
                    Text(
                      'Made with ❤️ for savers everywhere',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '© 2026 Savings & Tip Note Calendar',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, String? description, {List<String>? features, List<Map<String, String>>? steps}) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: const Color(0xFF4CAF50), size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (description != null)
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            if (features != null)
              ...features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  feature,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
              )),
            if (steps != null)
              ...steps.map((step) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          step['step']!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step['title']!,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                          Text(
                            step['desc']!,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }
}

// Helper class for default DateTime value
class _DefaultDateTime implements DateTime {
  const _DefaultDateTime();
  
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
