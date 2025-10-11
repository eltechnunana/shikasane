import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../database/database_helper.dart';
import '../models/expense.dart';
import '../../data/repositories/expense_repository.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  bool get isConfigured => Firebase.apps.isNotEmpty;
  bool get isSignedIn => isConfigured && _auth.currentUser != null;

  CollectionReference<Map<String, dynamic>> _userCollection(String sub) {
    final uid = _auth.currentUser!.uid;
    return _firestore.collection('users').doc(uid).collection(sub);
  }

  CollectionReference<Map<String, dynamic>> get expensesCol => _userCollection('expenses');

  Future<void> pushPendingExpenses(DatabaseHelper dbHelper) async {
    if (!isSignedIn) return;
    final pending = await dbHelper.getPendingOutbox(DatabaseHelper.tableExpenses);
    for (final row in pending) {
      final op = row['operation'] as String;
      final payloadStr = row['payload'] as String;
      final payload = jsonDecode(payloadStr) as Map<String, dynamic>;
      try {
        if (op == 'delete') {
          final id = (payload['id'] as num).toInt().toString();
          await expensesCol.doc(id).set({
            'id': id,
            'deleted': true,
            'updatedAt': payload['updatedAt'],
          }, SetOptions(merge: true));
        } else {
          final expense = Expense.fromJson(payload);
          final id = expense.id!.toString();
          final data = Map<String, dynamic>.from(payload);
          data['deleted'] = false;
          data['id'] = expense.id;
          await expensesCol.doc(id).set(data, SetOptions(merge: true));
        }
        await dbHelper.markOutboxSent(row['id'] as int);
      } catch (_) {
        // Leave in outbox; will retry on next sync
      }
    }
  }

  Future<void> pullExpenses({
    required ExpenseRepository expenseRepository,
    DateTime? since,
  }) async {
    if (!isSignedIn) return;
    Query<Map<String, dynamic>> query = expensesCol;
    if (since != null) {
      query = query.where('updatedAt', isGreaterThan: since.toIso8601String());
    }
    final snapshot = await query.get();
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final deleted = data['deleted'] == true;
      final idStr = doc.id;
      final id = int.tryParse(idStr);
      if (id == null) continue;
      if (deleted) {
        await expenseRepository.deleteExpenseFromRemote(id);
      } else {
        final merged = Map<String, dynamic>.from(data);
        merged['id'] = id;
        try {
          final expense = Expense.fromJson(merged);
          await expenseRepository.upsertExpenseFromRemote(expense);
        } catch (_) {
          // Skip invalid payloads
        }
      }
    }
  }
}