import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class AuthService {
  String get apiBaseUrl =>
      "${dotenv.env['API_BASE_URL'] ?? 'http://127.0.0.1:3000/api'}/auth";

  Future<String> signUpWithGoogle() async {
    final url = Uri.parse("$apiBaseUrl/sign-up/social");

    final response = await http.post(url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          'provider': 'google',
          'callbackURL': 'skillwalletkool://auth-callback',
        }));

    final data = json.decode(response.body) as Map<String, dynamic>;

    launchUrl(Uri.parse(data["url"]));

    return data["url"];
  }
}
