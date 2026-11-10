// ignore_for_file: body_might_complete_normally_catch_error

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

extension FastQueryExtension<T> on Query<T> {
  Future<QuerySnapshot<T>> getFast(
      {Duration timeout = const Duration(seconds: 5)}) async {
    try {
      final cacheSnap = await get(const GetOptions(source: Source.cache));
      if (cacheSnap.docs.isNotEmpty) {
        get(const GetOptions(source: Source.server)).catchError((e) {
          debugPrint('[FirestoreCache] Background server sync error: $e');
        });
        return cacheSnap;
      }
    } catch (_) {}

    try {
      return await get(const GetOptions(source: Source.serverAndCache))
          .timeout(timeout);
    } catch (_) {
      try {
        return await get(const GetOptions(source: Source.cache));
      } catch (_) {
        return await get();
      }
    }
  }
}

extension FastDocExtension<T> on DocumentReference<T> {
  Future<DocumentSnapshot<T>> getFast(
      {Duration timeout = const Duration(seconds: 5)}) async {
    try {
      final cacheSnap = await get(const GetOptions(source: Source.cache));
      if (cacheSnap.exists && cacheSnap.data() != null) {
        get(const GetOptions(source: Source.server)).catchError((e) {
          debugPrint('[FirestoreCache] Background doc sync error: $e');
        });
        return cacheSnap;
      }
    } catch (_) {}

    // 2. Fetch from server
    try {
      return await get(const GetOptions(source: Source.serverAndCache))
          .timeout(timeout);
    } catch (_) {
      try {
        return await get(const GetOptions(source: Source.cache));
      } catch (_) {
        return await get();
      }
    }
  }
}

class NetworkSyncService {
  static Future<bool> isInternetConnected() async {
    try {
      final res = await http
          .get(
            Uri.parse('https://www.google.com/generate_204'),
          )
          .timeout(const Duration(milliseconds: 2500));
      return res.statusCode == 204 || res.statusCode == 200;
    } catch (_) {
      try {
        final res2 = await http
            .get(
              Uri.parse('https://dns.google/resolve?name=example.com'),
            )
            .timeout(const Duration(milliseconds: 2000));
        return res2.statusCode == 200;
      } catch (_) {
        return false;
      }
    }
  }

  static Future<bool> hasPendingWrites() async {
    try {
      await FirebaseFirestore.instance
          .waitForPendingWrites()
          .timeout(const Duration(milliseconds: 1200));
      return false;
    } catch (_) {
      return true;
    }
  }

  static Future<bool> syncPendingWrites(
      {Duration timeout = const Duration(seconds: 10)}) async {
    try {
      await FirebaseFirestore.instance.waitForPendingWrites().timeout(timeout);
      return true;
    } catch (_) {
      return false;
    }
  }
}
