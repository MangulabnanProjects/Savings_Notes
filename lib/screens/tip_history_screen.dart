import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import 'home_screen.dart';

class TipHistoryScreen extends StatelessWidget {
  final Map<String, List<dynamic>> entries;
  final DateTime focusedMonth;

  const TipHistoryScreen({
    super.key,
    required this.entries,
    required this.focusedMonth,
  });

  @override
  Widget build(BuildContext context) {
    // Collect all tip entries
    List<Map<String, dynamic>> tipEntries = [];
    
    entries.forEach((key, entryList) {
      final parts = key.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);
      
      for (var entry in entryList) {
        if (!(entry.isSavings as bool)) {
          tipEntries.add({
            'date': DateTime(year, month, day),
            'amount': entry.amount as double,
            'description': entry.description as String,
            'timestamp': entry.timestamp as DateTime,
          });
        }
      }
    });
    
    // Sort by timestamp (most recent first)
    tipEntries.sort((a, b) => 
      (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));
    
    // Calculate total
    final totalTips = tipEntries.fold(0.0, (sum, e) => sum + (e['amount'] as double));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tip History',
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
        focusedMonth: focusedMonth,
        currentPage: 'tip_history',
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Total Card
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFB74D), Color(0xFFFF8F00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF8F00).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.paid, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Tips',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '₱${totalTips.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${tipEntries.length} entries',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // History List
            Expanded(
              child: tipEntries.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.paid_outlined, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No tip entries yet',
                            style: TextStyle(color: Colors.grey[500], fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start adding tips from the calendar!',
                            style: TextStyle(color: Colors.grey[400], fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: tipEntries.length,
                      itemBuilder: (context, index) {
                        final entry = tipEntries[index];
                        final date = entry['date'] as DateTime;
                        final timestamp = entry['timestamp'] as DateTime;
                        final amount = entry['amount'] as double;
                        final description = entry['description'] as String;
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.paid, color: Color(0xFFFF8F00)),
                            ),
                            title: Text(
                              '₱${amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE65100),
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_getMonthName(date.month)} ${date.day}, ${date.year}',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                ),
                                Text(
                                  'Added at ${_formatTime(timestamp)}',
                                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                                ),
                                if (description.isNotEmpty)
                                  Text(
                                    description,
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${hour}:${dt.minute.toString().padLeft(2, '0')} $period';
  }
}
