import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _entriesKey = 'pocketlog_entries';

  // Save entries to SharedPreferences
  static Future<void> saveEntries(Map<String, List<dynamic>> entries) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Convert entries to a JSON-serializable format
    final Map<String, List<Map<String, dynamic>>> serializableEntries = {};
    
    entries.forEach((key, entryList) {
      serializableEntries[key] = entryList.map((entry) {
        return {
          'amount': entry.amount,
          'description': entry.description,
          'isSavings': entry.isSavings,
          'timestamp': entry.timestamp.toIso8601String(),
        };
      }).toList();
    });
    
    final jsonString = jsonEncode(serializableEntries);
    await prefs.setString(_entriesKey, jsonString);
  }

  // Load entries from SharedPreferences
  static Future<Map<String, List<Map<String, dynamic>>>> loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_entriesKey);
    
    if (jsonString == null || jsonString.isEmpty) {
      return {};
    }
    
    try {
      final Map<String, dynamic> decoded = jsonDecode(jsonString);
      final Map<String, List<Map<String, dynamic>>> entries = {};
      
      decoded.forEach((key, value) {
        entries[key] = (value as List).map((e) => e as Map<String, dynamic>).toList();
      });
      
      return entries;
    } catch (e) {
      return {};
    }
  }

  // Clear all entries
  static Future<void> clearEntries() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_entriesKey);
  }
}
