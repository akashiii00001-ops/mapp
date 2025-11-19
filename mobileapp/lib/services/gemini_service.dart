import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  // TODO: Insert your actual API key here or via environment variables
  static const String _apiKey = "YOUR_GEMINI_API_KEY"; 
  static const String _baseUrl = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent";

  static Future<String> generateContent(String prompt) async {
    final url = Uri.parse("$_baseUrl?key=$_apiKey");

    int attempt = 0;
    const maxRetries = 3;

    while (attempt <= maxRetries) {
      try {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "contents": [{
              "parts": [{"text": prompt}]
            }]
          }),
        );

        if (response.statusCode != 200) {
          throw Exception('HTTP error! status: ${response.statusCode}');
        }

        final data = jsonDecode(response.body);
        return data['candidates']?[0]['content']?['parts']?[0]['text'] ?? "No content generated.";
      } catch (e) {
        attempt++;
        if (attempt > maxRetries) return "Error: Failed to connect to AI service after multiple attempts.";
        await Future.delayed(Duration(milliseconds: 1000 * (1 << attempt)));
      }
    }
    return "Error: Connection timeout.";
  }
}