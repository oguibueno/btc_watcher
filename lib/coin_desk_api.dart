import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CoinDeskApi {
  static const String baseApiUrl = 'https://api.coindesk.com/v1/bpi/';

  static Future<Map<String, dynamic>> fetchData() async {
    final response = await http.get(
      Uri.parse("${baseApiUrl}currentprice.json"),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load data');
    }
  }

  static Future<Map<String, dynamic>> fetchHistoricalData({
    required String start,
    required String end,
    required String currency,
  }) async {
    final response = await http.get(
      Uri.parse(
          "${baseApiUrl}historical/close.json?start=$start&end=$end&currency=$currency&index=$currency"),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load data');
    }
  }
}
