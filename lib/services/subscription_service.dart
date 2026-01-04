import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/api_config.dart';

class SubscriptionService {
  static const String _tokenKey = 'auth_token';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<Map<String, dynamic>> getSubscriptionStatus() async {
    final token = await _getToken();
    if (token == null) return {};

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.subscriptionStatusEndpoint),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {};
    } catch (e) {
      print('Error fetching subscription status: $e');
      return {};
    }
  }

  Future<String?> deductCredits({required String serviceType}) async {
    final token = await _getToken();
    if (token == null) return "Auth Error";

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.deductCreditsEndpoint),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'serviceType': serviceType}),
      );

      if (response.statusCode == 200) {
        return null; // Success
      } else {
        final error = jsonDecode(response.body);
        return error['detail'] ?? "Transaction Failed";
      }
    } catch (e) {
      print('Error deducting credits: $e');
      return "Network Error";
    }
  }

  Future<Map<String, dynamic>?> createOrder(String planName) async {
    final token = await _getToken();
    if (token == null) return null;

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.createOrderEndpoint),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'planName': planName}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      print('Create Order Failed: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      print('Error creating order: $e');
      return null;
    }
  }

  Future<bool> verifyPayment({
    required String paymentId,
    required String orderId,
    required String signature,
    required String planName,
  }) async {
    final token = await _getToken();
    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.verifyPaymentEndpoint),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'razorpay_payment_id': paymentId,
          'razorpay_order_id': orderId,
          'razorpay_signature': signature,
          'planName': planName,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error verifying payment: $e');
      return false;
    }
  }
}
