import 'package:flutter/foundation.dart';

class PocketBaseService {
  static final PocketBaseService _instance = PocketBaseService._internal();
  factory PocketBaseService() => _instance;
  PocketBaseService._internal();

  // DUMMY IMPLEMENTATION - REMOVED POCKETBASE DEPENDENCY

  Future<void> init({String? userId}) async {
    debugPrint("🚀 PocketBaseService: DUMMY Initialized");
  }

  Future<void> saveData(Map<String, dynamic> data) async {}

  Future<Map<String, dynamic>?> getUserMetrics() async {
    return null;
  }

  Future<void> sendHeartbeat() async {}

  Future<String?> verifyAdminAccessCode(String inputCode) async {
    return null;
  }

  Future<Map<String, dynamic>> fetchAllMetrics() async {
    return {'items': [], 'totalCount': 0};
  }

  Future<bool> deleteMetricsRecord(String recordId) async {
    return false;
  }

  Future<String?> getUniqueSessionId() async {
    return "dummy-session-id";
  }

  Future<void> updateSession(Map<String, dynamic> data) async {}

  Future<Map<String, dynamic>?> getSessionData() async {
    return null;
  }

  Future<void> subscribeToSession(Function(Map<String, dynamic>) onUpdate) async {}

  void unsubscribe() {}
}
