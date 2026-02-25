import 'dart:convert';
import 'package:http/http.dart' as http;

class ClaudeService {
  static const String apiUrl = 'https://api.anthropic.com/v1/messages';
  static const String model = 'claude-sonnet-4-20250514';

  Future<String> getAIResponse({
    required String userMessage,
    required String userContext,
    String language = 'English',
  }) async {
    try {
      final systemPrompt = _buildSystemPrompt(language);
      final userPrompt = _buildUserPrompt(userMessage, userContext);

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'anthropic-version': '2023-06-01',
          // API key is handled by the backend automatically
        },
        body: jsonEncode({
          'model': model,
          'max_tokens': 1024,
          'system': systemPrompt,
          'messages': [
            {
              'role': 'user',
              'content': userPrompt,
            }
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['content'][0]['text'];
      } else {
        throw Exception('Failed to get AI response: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error communicating with AI: $e');
    }
  }

  String _buildSystemPrompt(String language) {
    return '''You are a helpful customer support agent for Meesho, an Indian e-commerce platform. 

Your responsibilities:
1. Answer customer queries about orders, products, returns, refunds, and general shopping
2. Be polite, empathetic, and professional
3. Provide accurate information based on the context provided
4. If you cannot resolve an issue, offer to escalate to a human agent
5. Respond in $language language
6. Keep responses concise but helpful (2-4 sentences max)
7. Use emojis appropriately to make conversation friendly

Common scenarios you handle:
- Order tracking: Check order status and delivery estimates
- Returns & Refunds: Guide through return process, check refund status
- Product queries: Answer questions about size, material, availability
- Account issues: Help with login, profile updates
- Payment issues: Address payment failures, refund queries
- Complaints: Listen empathetically and offer solutions

Important guidelines:
- For refunds: Standard refund time is 5-7 business days
- For returns: Return window is 7 days from delivery
- For exchanges: Available for size/color issues
- Escalate if: Customer is very upset, complex technical issue, refund delay >10 days

Always be helpful and customer-focused! 🛍️''';
  }

  String _buildUserPrompt(String message, String context) {
    return '''Customer Context:
$context

Customer Message: $message

Please respond helpfully and professionally. If you need to take an action (like tracking an order or processing a return), indicate it clearly in your response using this format:
[ACTION: action_name | param1: value1 | param2: value2]

Available actions:
- TRACK_ORDER: orderId
- INITIATE_RETURN: orderId, itemId
- CHECK_REFUND: orderId
- ESCALATE: reason
- SEARCH_PRODUCT: query
- CHECK_AVAILABILITY: productId

Respond to the customer now:''';
  }

  // Extract actions from AI response
  Map<String, dynamic>? extractAction(String response) {
    final regex = RegExp(r'\[ACTION: ([^\]]+)\]');
    final match = regex.firstMatch(response);

    if (match != null) {
      final actionString = match.group(1)!;
      final parts = actionString.split('|').map((e) => e.trim()).toList();

      final action = parts[0];
      final params = <String, String>{};

      for (var i = 1; i < parts.length; i++) {
        final keyValue = parts[i].split(':');
        if (keyValue.length == 2) {
          params[keyValue[0].trim()] = keyValue[1].trim();
        }
      }

      return {
        'action': action,
        'params': params,
      };
    }

    return null;
  }

  // Remove action tags from response
  String cleanResponse(String response) {
    return response.replaceAll(RegExp(r'\[ACTION: [^\]]+\]'), '').trim();
  }
}