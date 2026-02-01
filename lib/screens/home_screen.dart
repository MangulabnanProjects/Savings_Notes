import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/app_drawer.dart';
import '../services/storage_service.dart';

// Entry model to store savings/tip data
class Entry {
  final double amount;
  final String description;
  final bool isSavings; // true = savings, false = tip
  final DateTime timestamp;

  Entry({
    required this.amount, 
    required this.description, 
    required this.isSavings,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  // Convert Entry to JSON-serializable map
  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'description': description,
      'isSavings': isSavings,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // Create Entry from JSON map
  factory Entry.fromJson(Map<String, dynamic> json) {
    return Entry(
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String,
      isSavings: json['isSavings'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  DateTime _inputDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  // Store entries by date (key = "yyyy-mm-dd")
  final Map<String, List<Entry>> _entries = {};
  
  // Animation
  bool _slideFromRight = true;
  
  // Track if amount has value
  bool _hasAmount = false;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onAmountChanged);
    _loadSavedEntries();
  }

  Future<void> _loadSavedEntries() async {
    final savedEntries = await StorageService.loadEntries();
    setState(() {
      savedEntries.forEach((key, entryList) {
        _entries[key] = entryList.map((e) => Entry.fromJson(e)).toList();
      });
    });
  }

  Future<void> _saveEntries() async {
    await StorageService.saveEntries(
      _entries.map((k, v) => MapEntry(k, v.cast<dynamic>())),
    );
  }

  void _onAmountChanged() {
    final hasValue = _amountController.text.trim().isNotEmpty;
    if (hasValue != _hasAmount) {
      setState(() {
        _hasAmount = hasValue;
      });
    }
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  bool _hasSavings(DateTime date) {
    final key = _dateKey(date);
    return _entries[key]?.any((e) => e.isSavings) ?? false;
  }

  bool _hasTip(DateTime date) {
    final key = _dateKey(date);
    return _entries[key]?.any((e) => !e.isSavings) ?? false;
  }

  void _changeMonth(int delta) {
    setState(() {
      _slideFromRight = delta > 0;
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + delta);
    });
  }

  void _changeYear(int delta) {
    setState(() {
      _slideFromRight = delta > 0;
      _focusedMonth = DateTime(_focusedMonth.year + delta, _focusedMonth.month);
    });
  }

  void _showDateDetails(DateTime date) {
    final key = _dateKey(date);
    
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Recalculate entries each time
          final entries = _entries[key] ?? [];
          final savingsEntries = entries.where((e) => e.isSavings).toList();
          final tipEntries = entries.where((e) => !e.isSavings).toList();
          final totalSavings = savingsEntries.fold(0.0, (sum, e) => sum + e.amount);
          final totalTips = tipEntries.fold(0.0, (sum, e) => sum + e.amount);
          final grandTotal = totalSavings + totalTips;
          
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            title: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.calendar_today, color: Color(0xFF4CAF50), size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${_getMonthName(date.month)} ${date.day}',
                        style: const TextStyle(color: Color(0xFF2E7D32), fontSize: 15),
                      ),
                    ),
                    // Total amount display
                    if (entries.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '₱${grandTotal.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            content: entries.isEmpty
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      const Text(
                        'No entries for this date.',
                        style: TextStyle(color: Color(0xFF558B2F)),
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Savings summary
                      if (savingsEntries.isNotEmpty)
                        _buildEntrySummaryTileWithRefresh(
                          context: context,
                          date: date,
                          isSavings: true,
                          entries: savingsEntries,
                          total: totalSavings,
                          onRefresh: () {
                            setDialogState(() {});
                            setState(() {});
                          },
                        ),
                      if (savingsEntries.isNotEmpty && tipEntries.isNotEmpty)
                        const SizedBox(height: 8),
                      // Tips summary
                      if (tipEntries.isNotEmpty)
                        _buildEntrySummaryTileWithRefresh(
                          context: context,
                          date: date,
                          isSavings: false,
                          entries: tipEntries,
                          total: totalTips,
                          onRefresh: () {
                            setDialogState(() {});
                            setState(() {});
                          },
                        ),
                    ],
                  ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEntrySummaryTile({
    required BuildContext context,
    required DateTime date,
    required bool isSavings,
    required List<Entry> entries,
    required double total,
  }) {
    final count = entries.length;
    final showDescriptionInline = count == 1 && entries.first.description.isNotEmpty;
    
    return InkWell(
      onTap: () => _showEntryDetails(context, date, isSavings, entries),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSavings ? const Color(0xFFE8F5E9) : const Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSavings ? const Color(0xFF4CAF50) : const Color(0xFFFF8F00),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSavings ? const Color(0xFF4CAF50) : const Color(0xFFFF8F00),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isSavings ? Icons.savings : Icons.paid,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        isSavings ? 'Savings' : 'Tips',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSavings ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                          fontSize: 14,
                        ),
                      ),
                      if (count > 1) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSavings ? const Color(0xFF4CAF50) : const Color(0xFFFF8F00),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${count}x',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: isSavings ? const Color(0xFF4CAF50) : const Color(0xFFFF8F00),
                        ),
                      ],
                    ],
                  ),
                  if (showDescriptionInline)
                    Text(
                      entries.first.description,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Text(
              '₱${total.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isSavings ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntrySummaryTileWithRefresh({
    required BuildContext context,
    required DateTime date,
    required bool isSavings,
    required List<Entry> entries,
    required double total,
    required VoidCallback onRefresh,
  }) {
    final count = entries.length;
    final showDescriptionInline = count == 1 && entries.first.description.isNotEmpty;
    
    return InkWell(
      onTap: () => _showEntryDetailsWithRefresh(context, date, isSavings, entries, onRefresh),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSavings ? const Color(0xFFE8F5E9) : const Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSavings ? const Color(0xFF4CAF50) : const Color(0xFFFF8F00),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSavings ? const Color(0xFF4CAF50) : const Color(0xFFFF8F00),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isSavings ? Icons.savings : Icons.paid,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        isSavings ? 'Savings' : 'Tips',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSavings ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                          fontSize: 14,
                        ),
                      ),
                      if (count > 1) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSavings ? const Color(0xFF4CAF50) : const Color(0xFFFF8F00),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${count}x',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: isSavings ? const Color(0xFF4CAF50) : const Color(0xFFFF8F00),
                        ),
                      ],
                    ],
                  ),
                  if (showDescriptionInline)
                    Text(
                      entries.first.description,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Text(
              '₱${total.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isSavings ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEntryDetailsWithRefresh(BuildContext context, DateTime date, bool isSavings, List<Entry> entries, VoidCallback onParentRefresh) {
    final key = _dateKey(date);
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final currentEntries = (_entries[key] ?? [])
              .where((e) => e.isSavings == isSavings)
              .toList();
          final total = currentEntries.fold(0.0, (sum, e) => sum + e.amount);
          
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSavings ? const Color(0xFFE8F5E9) : const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isSavings ? Icons.savings : Icons.paid,
                    color: isSavings ? const Color(0xFF4CAF50) : const Color(0xFFFF8F00),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isSavings ? 'Savings Details' : 'Tip Details',
                    style: TextStyle(
                      color: isSavings ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                      fontSize: 15,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSavings ? const Color(0xFF4CAF50) : const Color(0xFFFF8F00),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '₱${total.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            content: currentEntries.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text('No entries remaining'),
                  )
                : SizedBox(
                    width: double.maxFinite,
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: currentEntries.length,
                      separatorBuilder: (_, __) => const Divider(height: 16),
                      itemBuilder: (context, index) {
                        final entry = currentEntries[index];
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: isSavings 
                                    ? const Color(0xFFE8F5E9) 
                                    : const Color(0xFFFFF8E1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isSavings ? const Color(0xFF4CAF50) : const Color(0xFFFF8F00),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '₱${entry.amount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (entry.description.isNotEmpty)
                                    Text(
                                      entry.description,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            // Delete button
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              onPressed: () {
                                _showDeleteConfirmation(context, date, entry, () {
                                  setDialogState(() {});
                                  onParentRefresh();
                                });
                              },
                              tooltip: 'Delete entry',
                            ),
                          ],
                        );
                      },
                    ),
                  ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEntryDetails(BuildContext context, DateTime date, bool isSavings, List<Entry> entries) {
    final key = _dateKey(date);
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final currentEntries = (_entries[key] ?? [])
              .where((e) => e.isSavings == isSavings)
              .toList();
          final total = currentEntries.fold(0.0, (sum, e) => sum + e.amount);
          
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSavings ? const Color(0xFFE8F5E9) : const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isSavings ? Icons.savings : Icons.paid,
                    color: isSavings ? const Color(0xFF4CAF50) : const Color(0xFFFF8F00),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isSavings ? 'Savings Details' : 'Tip Details',
                    style: TextStyle(
                      color: isSavings ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                      fontSize: 15,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSavings ? const Color(0xFF4CAF50) : const Color(0xFFFF8F00),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '₱${total.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            content: currentEntries.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text('No entries remaining'),
                  )
                : SizedBox(
                    width: double.maxFinite,
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: currentEntries.length,
                      separatorBuilder: (_, __) => const Divider(height: 16),
                      itemBuilder: (context, index) {
                        final entry = currentEntries[index];
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: isSavings 
                                    ? const Color(0xFFE8F5E9) 
                                    : const Color(0xFFFFF8E1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isSavings ? const Color(0xFF4CAF50) : const Color(0xFFFF8F00),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '₱${entry.amount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (entry.description.isNotEmpty)
                                    Text(
                                      entry.description,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            // Delete button
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              onPressed: () {
                                _showDeleteConfirmation(context, date, entry, () {
                                  setDialogState(() {});
                                  setState(() {});
                                });
                              },
                              tooltip: 'Delete entry',
                            ),
                          ],
                        );
                      },
                    ),
                  ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, DateTime date, Entry entry, VoidCallback onDeleted) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 24),
            const SizedBox(width: 8),
            const Text('Delete Entry?', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete this ${entry.isSavings ? "savings" : "tip"} entry?',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: entry.isSavings ? const Color(0xFFE8F5E9) : const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    entry.isSavings ? Icons.savings : Icons.paid,
                    color: entry.isSavings ? const Color(0xFF4CAF50) : const Color(0xFFFF8F00),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '₱${entry.amount.toStringAsFixed(2)}${entry.description.isNotEmpty ? " - ${entry.description}" : ""}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _deleteEntry(date, entry);
              Navigator.pop(ctx);
              onDeleted();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${entry.isSavings ? "Savings" : "Tip"} entry deleted'),
                  backgroundColor: Colors.orange[700],
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteEntry(DateTime date, Entry entryToDelete) {
    final key = _dateKey(date);
    if (_entries.containsKey(key)) {
      setState(() {
        _entries[key]!.removeWhere((e) => 
          e.amount == entryToDelete.amount && 
          e.description == entryToDelete.description &&
          e.isSavings == entryToDelete.isSavings &&
          e.timestamp == entryToDelete.timestamp
        );
        if (_entries[key]!.isEmpty) {
          _entries.remove(key);
        }
      });
      _saveEntries();
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  void _onSavingsEntry() {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final amount = double.tryParse(amountText) ?? 0;
    final description = _descriptionController.text.trim();
    final key = _dateKey(_inputDate);

    setState(() {
      _entries.putIfAbsent(key, () => []);
      _entries[key]!.add(Entry(amount: amount, description: description, isSavings: true));
    });
    _saveEntries();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Savings: ₱$amountText on ${_getMonthName(_inputDate.month)} ${_inputDate.day}'),
        backgroundColor: const Color(0xFF4CAF50),
      ),
    );

    _amountController.clear();
    _descriptionController.clear();
  }

  void _onTipEntry() {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final amount = double.tryParse(amountText) ?? 0;
    final description = _descriptionController.text.trim();
    final key = _dateKey(_inputDate);

    setState(() {
      _entries.putIfAbsent(key, () => []);
      _entries[key]!.add(Entry(amount: amount, description: description, isSavings: false));
    });
    _saveEntries();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tip: ₱$amountText on ${_getMonthName(_inputDate.month)} ${_inputDate.day}'),
        backgroundColor: const Color(0xFF81C784),
      ),
    );

    _amountController.clear();
    _descriptionController.clear();
  }

  void _selectInputDate(DateTime date) {
    setState(() {
      _inputDate = date;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isToday = _inputDate.year == DateTime.now().year &&
        _inputDate.month == DateTime.now().month &&
        _inputDate.day == DateTime.now().day;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Savings and Tip Note Calendar',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: AppDrawer(
        entries: _entries.map((k, v) => MapEntry(k, v.cast<dynamic>())),
        focusedMonth: _focusedMonth,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Calendar Box with navigation
              Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(8),
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
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '${_focusedMonth.year}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.keyboard_double_arrow_right, color: Color(0xFF4CAF50), size: 20),
                            onPressed: () => _changeYear(1),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          ),
                        ],
                      ),
                      // Month navigation
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left, color: Color(0xFF4CAF50), size: 24),
                            onPressed: () => _changeMonth(-1),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          ),
                          Expanded(
                            child: Center(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                transitionBuilder: (child, animation) {
                                  final offsetAnimation = Tween<Offset>(
                                    begin: Offset(_slideFromRight ? 1.0 : -1.0, 0.0),
                                    end: Offset.zero,
                                  ).animate(animation);
                                  return SlideTransition(position: offsetAnimation, child: child);
                                },
                                child: Text(
                                  _getMonthName(_focusedMonth.month),
                                  key: ValueKey<int>(_focusedMonth.month + _focusedMonth.year * 12),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right, color: Color(0xFF4CAF50), size: 24),
                            onPressed: () => _changeMonth(1),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          ),
                        ],
                      ),
                      const Divider(color: Color(0xFFE8F5E9), height: 8),
                      const SizedBox(height: 4),
                      // Mini day headers
                      _buildMiniDayHeaders(),
                      const SizedBox(height: 4),
                      // Mini calendar grid
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        transitionBuilder: (child, animation) {
                          final offsetAnimation = Tween<Offset>(
                            begin: Offset(_slideFromRight ? 1.0 : -1.0, 0.0),
                            end: Offset.zero,
                          ).animate(animation);
                          return SlideTransition(position: offsetAnimation, child: child);
                        },
                        child: KeyedSubtree(
                          key: ValueKey<int>(_focusedMonth.month + _focusedMonth.year * 12),
                          child: _buildMiniCalendarGrid(),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tap to select • Double-tap for details',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Selected date indicator
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  color: isToday ? const Color(0xFFE8F5E9) : const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isToday ? const Color(0xFF4CAF50) : const Color(0xFFFF8F00),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.edit_calendar,
                      color: isToday ? const Color(0xFF4CAF50) : const Color(0xFFFF8F00),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_getMonthName(_inputDate.month)} ${_inputDate.day}, ${_inputDate.year}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isToday ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (!isToday)
                      GestureDetector(
                        onTap: () => _selectInputDate(DateTime.now()),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Today',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              
              // Amount Input
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Amount (Pesos)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                        ],
                        decoration: const InputDecoration(
                          hintText: 'Enter amount',
                          prefixText: '₱ ',
                          prefixStyle: TextStyle(
                            color: Color(0xFF4CAF50),
                            fontWeight: FontWeight.bold,
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          isDense: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              
              // Description Input
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Description (Optional)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _descriptionController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'Enter description',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          isDense: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _hasAmount ? _onSavingsEntry : null,
                      icon: const Icon(Icons.savings, size: 18),
                      label: const Text('Savings', style: TextStyle(fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        disabledBackgroundColor: const Color(0xFFBDBDBD),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _hasAmount ? _onTipEntry : null,
                      icon: const Icon(Icons.paid, size: 18),
                      label: const Text('Tip', style: TextStyle(fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF81C784),
                        disabledBackgroundColor: const Color(0xFFBDBDBD),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniDayHeaders() {
    const days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return Row(
      children: days
          .map((day) => Expanded(
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4CAF50),
                    fontSize: 11,
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildMiniCalendarGrid() {
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final startWeekday = firstDayOfMonth.weekday % 7;
    final totalDays = lastDayOfMonth.day;

    List<TableRow> rows = [];
    List<Widget> currentRow = [];

    // Empty cells before first day
    for (int i = 0; i < startWeekday; i++) {
      currentRow.add(const SizedBox(height: 44));
    }

    // Day cells
    for (int day = 1; day <= totalDays; day++) {
      final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
      currentRow.add(_buildMiniDayCell(day, date));

      if (currentRow.length == 7) {
        rows.add(TableRow(children: currentRow));
        currentRow = [];
      }
    }

    // Fill remaining cells
    while (currentRow.isNotEmpty && currentRow.length < 7) {
      currentRow.add(const SizedBox(height: 44));
    }
    if (currentRow.isNotEmpty) {
      rows.add(TableRow(children: currentRow));
    }

    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: rows,
    );
  }

  Widget _buildMiniDayCell(int day, DateTime date) {
    final isToday = DateTime.now().year == date.year &&
        DateTime.now().month == date.month &&
        DateTime.now().day == date.day;
    final isInputDate = _inputDate.year == date.year &&
        _inputDate.month == date.month &&
        _inputDate.day == date.day;
    final hasSavings = _hasSavings(date);
    final hasTip = _hasTip(date);

    return GestureDetector(
      onTap: () => _selectInputDate(date),
      onDoubleTap: () => _showDateDetails(date),
      child: Container(
        height: 44,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isInputDate
              ? const Color(0xFFFFF3E0)
              : isToday
                  ? const Color(0xFFE8F5E9)
                  : const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(6),
          border: isInputDate
              ? Border.all(color: const Color(0xFFFF8F00), width: 2)
              : isToday
                  ? Border.all(color: const Color(0xFF4CAF50), width: 2)
                  : Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              day.toString(),
              style: TextStyle(
                fontSize: 13,
                color: isInputDate
                    ? const Color(0xFFE65100)
                    : isToday
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFF424242),
                fontWeight: isToday || isInputDate ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            // Entry icons
            if (hasSavings || hasTip)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasSavings)
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Icon(Icons.savings, size: 10, color: Colors.white),
                      ),
                    if (hasSavings && hasTip) const SizedBox(width: 2),
                    if (hasTip)
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF8F00),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Icon(Icons.paid, size: 10, color: Colors.white),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
