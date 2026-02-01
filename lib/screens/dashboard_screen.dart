import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/app_drawer.dart';
import '../services/storage_service.dart';
import 'home_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Map<String, List<dynamic>> entries;
  final DateTime focusedMonth;

  const DashboardScreen({
    super.key,
    this.entries = const {},
    required this.focusedMonth,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late DateTime _focusedMonth;
  Map<String, List<dynamic>> _entries = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _focusedMonth = widget.focusedMonth;
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final savedEntries = await StorageService.loadEntries();
    
    // Convert to the correct format with Entry objects
    final Map<String, List<dynamic>> convertedEntries = {};
    savedEntries.forEach((key, entryList) {
      convertedEntries[key] = entryList.map((e) => Entry(
        amount: (e['amount'] as num).toDouble(),
        description: e['description'] as String,
        isSavings: e['isSavings'] as bool,
        timestamp: DateTime.parse(e['timestamp'] as String),
      )).toList();
    });
    
    if (mounted) {
      setState(() {
        _entries = convertedEntries;
        _isLoading = false;
      });
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + delta);
    });
  }

  void _changeYear(int delta) {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year + delta, _focusedMonth.month);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dashboard')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Calculate daily totals for the current month
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    
    List<double> savingsByDay = List.filled(daysInMonth, 0.0);
    List<double> tipsByDay = List.filled(daysInMonth, 0.0);
    
    double totalSavings = 0;
    double totalTips = 0;

    // Process entries for this month
    _entries.forEach((key, entryList) {
      final parts = key.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);
      
      if (year == _focusedMonth.year && month == _focusedMonth.month) {
        for (var entry in entryList) {
          final isSavings = entry.isSavings as bool;
          final amount = entry.amount as double;
          if (isSavings) {
            savingsByDay[day - 1] += amount;
            totalSavings += amount;
          } else {
            tipsByDay[day - 1] += amount;
            totalTips += amount;
          }
        }
      }
    });

    // Find max value for Y axis
    double maxValue = 0;
    for (int i = 0; i < daysInMonth; i++) {
      if (savingsByDay[i] > maxValue) maxValue = savingsByDay[i];
      if (tipsByDay[i] > maxValue) maxValue = tipsByDay[i];
    }
    maxValue = maxValue == 0 ? 1000 : (maxValue * 1.2).ceilToDouble();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HomeScreen(),
                ),
              );
            },
            tooltip: 'Go to Calendar',
          ),
        ],
      ),
      drawer: AppDrawer(
        entries: _entries,
        focusedMonth: _focusedMonth,
        isFromDashboard: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Month/Year Navigation
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Column(
                    children: [
                      // Year navigation
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.keyboard_double_arrow_left, color: Color(0xFF4CAF50), size: 20),
                            onPressed: () => _changeYear(-1),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            tooltip: 'Previous Year',
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '${_focusedMonth.year}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.keyboard_double_arrow_right, color: Color(0xFF4CAF50), size: 20),
                            onPressed: () => _changeYear(1),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            tooltip: 'Next Year',
                          ),
                        ],
                      ),
                      // Month navigation
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left, color: Color(0xFF4CAF50), size: 28),
                            onPressed: () => _changeMonth(-1),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                            tooltip: 'Previous Month',
                          ),
                          Container(
                            width: 120,
                            alignment: Alignment.center,
                            child: Text(
                              _getMonthName(_focusedMonth.month),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right, color: Color(0xFF4CAF50), size: 28),
                            onPressed: () => _changeMonth(1),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                            tooltip: 'Next Month',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              
              // Summary Cards
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Savings',
                      totalSavings,
                      const Color(0xFF4CAF50),
                      Icons.savings,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSummaryCard(
                      'Tips',
                      totalTips,
                      const Color(0xFFFF8F00),
                      Icons.paid,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Grand Total Card
              _buildSummaryCard(
                'Total for ${_getMonthName(_focusedMonth.month)}',
                totalSavings + totalTips,
                const Color(0xFF2E7D32),
                Icons.account_balance_wallet,
              ),
              const SizedBox(height: 12),
              
              // Line Chart
              Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      // Legend
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLegendItem('Savings', const Color(0xFF4CAF50)),
                          const SizedBox(width: 20),
                          _buildLegendItem('Tips', const Color(0xFFFF8F00)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Chart
                      SizedBox(
                        height: 250,
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: maxValue / 5,
                              getDrawingHorizontalLine: (value) {
                                return FlLine(
                                  color: const Color(0xFFE0E0E0),
                                  strokeWidth: 1,
                                );
                              },
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 28,
                                  interval: (daysInMonth / 7).ceilToDouble(),
                                  getTitlesWidget: (value, meta) {
                                    final day = value.toInt() + 1;
                                    if (day <= daysInMonth && day > 0) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 5),
                                        child: Text(
                                          '$day',
                                          style: const TextStyle(
                                            color: Color(0xFF666666),
                                            fontSize: 10,
                                          ),
                                        ),
                                      );
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 42,
                                  interval: maxValue / 5,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      '₱${value.toInt()}',
                                      style: const TextStyle(
                                        color: Color(0xFF666666),
                                        fontSize: 9,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(
                              show: true,
                              border: const Border(
                                left: BorderSide(color: Color(0xFFE0E0E0)),
                                bottom: BorderSide(color: Color(0xFFE0E0E0)),
                              ),
                            ),
                            minX: 0,
                            maxX: (daysInMonth - 1).toDouble(),
                            minY: 0,
                            maxY: maxValue,
                            lineBarsData: [
                              // Savings line (green)
                              LineChartBarData(
                                spots: List.generate(
                                  daysInMonth,
                                  (i) => FlSpot(i.toDouble(), savingsByDay[i]),
                                ),
                                isCurved: true,
                                color: const Color(0xFF4CAF50),
                                barWidth: 3,
                                isStrokeCapRound: true,
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter: (spot, percent, barData, index) {
                                    return FlDotCirclePainter(
                                      radius: savingsByDay[index] > 0 ? 4 : 0,
                                      color: const Color(0xFF4CAF50),
                                      strokeWidth: 2,
                                      strokeColor: Colors.white,
                                    );
                                  },
                                ),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                                ),
                              ),
                              // Tips line (orange)
                              LineChartBarData(
                                spots: List.generate(
                                  daysInMonth,
                                  (i) => FlSpot(i.toDouble(), tipsByDay[i]),
                                ),
                                isCurved: true,
                                color: const Color(0xFFFF8F00),
                                barWidth: 3,
                                isStrokeCapRound: true,
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter: (spot, percent, barData, index) {
                                    return FlDotCirclePainter(
                                      radius: tipsByDay[index] > 0 ? 4 : 0,
                                      color: const Color(0xFFFF8F00),
                                      strokeWidth: 2,
                                      strokeColor: Colors.white,
                                    );
                                  },
                                ),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: const Color(0xFFFF8F00).withOpacity(0.1),
                                ),
                              ),
                            ],
                            lineTouchData: LineTouchData(
                              touchTooltipData: LineTouchTooltipData(
                                getTooltipItems: (touchedSpots) {
                                  return touchedSpots.map((spot) {
                                    final isSavings = spot.barIndex == 0;
                                    final day = spot.x.toInt() + 1;
                                    return LineTooltipItem(
                                      'Day $day\n${isSavings ? "Savings" : "Tips"}: ₱${spot.y.toStringAsFixed(0)}',
                                      TextStyle(
                                        color: isSavings 
                                            ? const Color(0xFF4CAF50)
                                            : const Color(0xFFFF8F00),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    );
                                  }).toList();
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Day of Month',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Entry Report Box
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.receipt_long, color: Color(0xFF4CAF50), size: 18),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Entry Report - ${_getMonthName(_focusedMonth.month)} ${_focusedMonth.year}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      _buildEntryReportList(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEntryReportList() {
    // Collect all entries for this month
    List<Map<String, dynamic>> monthEntries = [];
    
    widget.entries.forEach((key, entryList) {
      final parts = key.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);
      
      if (year == _focusedMonth.year && month == _focusedMonth.month) {
        for (var entry in entryList) {
          monthEntries.add({
            'day': day,
            'amount': entry.amount as double,
            'description': entry.description as String,
            'isSavings': entry.isSavings as bool,
          });
        }
      }
    });
    
    // Sort by day
    monthEntries.sort((a, b) => (a['day'] as int).compareTo(b['day'] as int));
    
    if (monthEntries.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.inbox_outlined, size: 40, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                'No entries for this month',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }
    
    return Column(
      children: monthEntries.map((entry) {
        final isSavings = entry['isSavings'] as bool;
        final day = entry['day'] as int;
        final amount = entry['amount'] as double;
        final description = entry['description'] as String;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isSavings 
                ? const Color(0xFFF1F8E9) 
                : const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSavings 
                  ? const Color(0xFF4CAF50).withOpacity(0.3) 
                  : const Color(0xFFFF8F00).withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSavings ? const Color(0xFF4CAF50) : const Color(0xFFFF8F00),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isSavings ? Icons.savings : Icons.paid,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You put a ${isSavings ? "Savings" : "Tip"} entry on ${_getMonthName(_focusedMonth.month)} $day',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                    if (description.isNotEmpty)
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Text(
                '₱${amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isSavings ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSummaryCard(String title, double amount, Color color, IconData icon) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '₱${amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}
