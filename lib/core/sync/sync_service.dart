import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../database/database_helper.dart';
import '../../data/repositories/expense_repository.dart';
import 'firestore_service.dart';

class SyncService {
  SyncService({
    DatabaseHelper? databaseHelper,
    ExpenseRepository? expenseRepository,
    FirestoreService? firestoreService,
  })  : _dbHelper = databaseHelper ?? DatabaseHelper(),
        _expenseRepo = expenseRepository ?? ExpenseRepository(),
        _firestore = firestoreService ?? FirestoreService();

  final DatabaseHelper _dbHelper;
  final ExpenseRepository _expenseRepo;
  final FirestoreService _firestore;

  Future<bool> _isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  Future<DateTime?> _getLastSync() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString('lastSyncAt');
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  Future<void> _setLastSync(DateTime ts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastSyncAt', ts.toIso8601String());
  }

  Future<void> syncNow() async {
    if (!await _isOnline()) {
      return;
    }
    final last = await _getLastSync();
    final now = DateTime.now().toUtc();
    try {
      await _firestore.pushPendingExpenses(_dbHelper);
      await _firestore.pullExpenses(expenseRepository: _expenseRepo, since: last);
      await _setLastSync(now);
    } catch (_) {
      // Swallow errors for now; keep last sync unchanged on failure
    }
  }
}

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService();
});