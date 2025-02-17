// // session_service.dart
// import 'dart:convert';
// import 'package:http/http.dart' as http;

// class SessionService {
//   static const String baseUrl =
//       'http://127.0.0.1:8000/api/create-session'; // Update with your actual API base URL

//   Future<Map<String, String>> createSession() async {
//     try {
//       final response = await http.post(
//         Uri.parse('$baseUrl/sessions/create'),
//         headers: {'Content-Type': 'application/json'},
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         return {
//           'sessionId': data['session_id'],
//           'otp': data['otp'],
//         };
//       } else {
//         throw Exception('Failed to create session: ${response.statusCode}');
//       }
//     } catch (e) {
//       throw Exception('Error creating session: $e');
//     }
//   }

//   Future<String> getOtp(String sessionId) async {
//     try {
//       final response = await http.get(
//         Uri.parse('$baseUrl/sessions/$sessionId/otp'),
//         headers: {'Content-Type': 'application/json'},
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         return data['otp'];
//       } else {
//         throw Exception('Failed to get OTP: ${response.statusCode}');
//       }
//     } catch (e) {
//       throw Exception('Error getting OTP: $e');
//     }
//   }
// }
