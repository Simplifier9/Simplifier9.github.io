import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// This will be globally accessible
String baseUrl = kIsWeb ? 'http://127.0.0.1:8000/' : '';

/// Call this before app runs
Future<void> detectBaseUrl() async {
  if (kIsWeb) {
    baseUrl = 'http://127.0.0.1:8000/';
    return;
  }

  const possibleIPs = [
    '192.168.1.2',
    '192.168.1.3',
    '192.168.1.4',
    '192.168.1.5',
    '192.168.1.6',
    '192.168.43.1',
  ];

  for (final ip in possibleIPs) {
    try {
      final response = await http
          .get(Uri.parse('http://$ip:8000/ping/'))
          .timeout(const Duration(seconds: 1));
      if (response.statusCode == 200) {
        baseUrl = 'http://$ip:8000/';
        print("✅ baseUrl set to $baseUrl");
        return;
      }
    } catch (_) {}
  }

  throw Exception("❌ No working IP found for baseUrl.");
}
