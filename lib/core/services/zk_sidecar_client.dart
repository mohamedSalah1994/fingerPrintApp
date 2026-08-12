import 'dart:convert';

import 'package:http/http.dart' as http;

/// Local Python sidecar that talks to ZKTeco over LAN (pyzk).
class ZkSidecarClient {
  ZkSidecarClient({this.baseUrl = 'http://127.0.0.1:8765'});

  final String baseUrl;

  Uri _u(String path, [Map<String, String>? query]) =>
      Uri.parse('$baseUrl$path').replace(queryParameters: query);

  Future<Map<String, dynamic>> health() async {
    final res = await http.get(_u('/health')).timeout(const Duration(seconds: 3));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> testConnection({
    required String ip,
    int port = 4370,
    int commKey = 0,
    bool forceUdp = false,
  }) async {
    final res = await http
        .post(
          _u('/test-connection'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'ip': ip,
            'port': port,
            'comm_key': commKey,
            'force_udp': forceUdp,
          }),
        )
        .timeout(const Duration(seconds: 20));
    final body = jsonDecode(res.body);
    if (res.statusCode >= 300) {
      throw Exception(body['detail'] ?? body.toString());
    }
    return body as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> sync({String? deviceId}) async {
    final res = await http
        .post(
          _u('/sync'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            if (deviceId != null) 'device_id': deviceId,
          }),
        )
        .timeout(const Duration(seconds: 90));
    final body = jsonDecode(res.body);
    if (res.statusCode >= 300) {
      throw Exception(body['detail'] ?? body.toString());
    }
    return body as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> deviceUsers(String deviceId) async {
    final res = await http
        .get(_u('/device-users', {'device_id': deviceId}))
        .timeout(const Duration(seconds: 45));
    final body = jsonDecode(res.body);
    if (res.statusCode >= 300) {
      throw Exception(body['detail'] ?? body.toString());
    }
    final users = (body['users'] as List?) ?? const [];
    return users.cast<Map<String, dynamic>>();
  }

  Future<void> startLoop() async {
    await http.post(_u('/sync-loop/start')).timeout(const Duration(seconds: 5));
  }

  Future<void> stopLoop() async {
    await http.post(_u('/sync-loop/stop')).timeout(const Duration(seconds: 5));
  }
}
