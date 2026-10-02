import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../presentation/providers/app_providers.dart';
import 'ai_expense_tools.dart';

String get _groqApiKey =>
    dotenv.env['GROQ_API_KEY'] ??
    dotenv.env['VITE_GROQ_API_KEY'] ??
    const String.fromEnvironment('GROQ_API_KEY');

class ChatMessage {
  ChatMessage({required this.isUser, required this.text});
  final bool isUser;
  final String text;
}

class AssistantState {
  AssistantState({this.messages = const [], this.isLoading = false, this.error});
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;
}

class GeminiAssistantController extends Notifier<AssistantState> {
  static const List<String> _models = [
    'openai/gpt-oss-120b',
    'openai/gpt-oss-20b',
    'qwen/qwen3.8-27b',
  ];

  int _currentModelIndex = 0;
  late final AiExpenseTools _tools;
  final List<Map<String, dynamic>> _apiMessages = [];

  @override
  AssistantState build() {
    if (_groqApiKey.isEmpty) {
      return AssistantState(
        error: 'Groq API key not configured. Add GROQ_API_KEY to your .env file.',
      );
    }

    final repository = ref.watch(transactionRepositoryProvider);
    _tools = AiExpenseTools(repository);

    final today = DateTime.now().toIso8601String().substring(0, 10);
    _apiMessages.clear();
    _apiMessages.add({
      'role': 'system',
      'content': 'You are a helpful AI Expense Assistant inside a personal finance app. '
          'Your goal is to answer questions about the user\'s expenses based ONLY on the data returned by function calls. '
          'The currency is INR (₹). Convert amounts in paise to rupees (divide by 100) before presenting them. '
          'Today\'s date is $today. '
          'Never invent data. If a tool returns no data, inform the user clearly. '
          'Do not offer financial advice or predictions.',
    });

    return AssistantState();
  }

  void newChat() {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    _apiMessages.clear();
    _apiMessages.add({
      'role': 'system',
      'content': 'You are a helpful AI Expense Assistant inside a personal finance app. '
          'Your goal is to answer questions about the user\'s expenses based ONLY on the data returned by function calls. '
          'The currency is INR (₹). Convert amounts in paise to rupees (divide by 100) before presenting them. '
          'Today\'s date is $today. '
          'Never invent data. If a tool returns no data, inform the user clearly. '
          'Do not offer financial advice or predictions.',
    });
    state = AssistantState();
  }

  Future<void> sendMessage(String text) async {
    if (_groqApiKey.isEmpty) {
      state = AssistantState(
        messages: state.messages,
        isLoading: false,
        error: 'Groq API key not configured. Add GROQ_API_KEY to your .env file.',
      );
      return;
    }

    state = AssistantState(
      messages: [...state.messages, ChatMessage(isUser: true, text: text)],
      isLoading: true,
      error: null,
    );

    // Save snapshot of history in case we need to retry on error
    final historySnapshot = List<Map<String, dynamic>>.from(
      _apiMessages.map((m) => Map<String, dynamic>.from(m)),
    );

    _apiMessages.add({'role': 'user', 'content': text});

    bool success = false;
    int attempts = 0;

    while (!success && attempts < _models.length) {
      final model = _models[_currentModelIndex];
      try {
        final answer = await _runConversationLoop(model);
        state = AssistantState(
          messages: [...state.messages, ChatMessage(isUser: false, text: answer)],
          isLoading: false,
        );
        success = true;
      } catch (e) {
        attempts++;
        if (attempts < _models.length) {
          _currentModelIndex = (_currentModelIndex + 1) % _models.length;
          // Restore history snapshot + current user message
          _apiMessages.clear();
          _apiMessages.addAll(
            historySnapshot.map((m) => Map<String, dynamic>.from(m)),
          );
          _apiMessages.add({'role': 'user', 'content': text});
        } else {
          state = AssistantState(
            messages: state.messages,
            isLoading: false,
            error: 'All Groq models failed: ${e.toString()}',
          );
          return;
        }
      }
    }
  }

  Future<String> _runConversationLoop(String model) async {
    const url = 'https://api.groq.com/openai/v1/chat/completions';
    int toolIterations = 0;
    const maxIterations = 5;

    while (toolIterations < maxIterations) {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $_groqApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': model,
          'messages': _apiMessages,
          'tools': _tools.openAiTools,
          'tool_choice': 'auto',
        }),
      );

      if (response.statusCode != 200) {
        final body = response.body;
        throw Exception('Groq API error [${response.statusCode}]: $body');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = json['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        throw Exception('No response choices returned by Groq.');
      }

      final choice = choices[0] as Map<String, dynamic>;
      final assistantMsg = choice['message'] as Map<String, dynamic>;
      _apiMessages.add(Map<String, dynamic>.from(assistantMsg));

      final toolCalls = assistantMsg['tool_calls'] as List<dynamic>?;
      if (toolCalls != null && toolCalls.isNotEmpty) {
        toolIterations++;
        for (final call in toolCalls) {
          final id = call['id'] as String;
          final fn = call['function'] as Map<String, dynamic>;
          final name = fn['name'] as String;
          final argsRaw = fn['arguments'] as String? ?? '{}';
          final args = jsonDecode(argsRaw) as Map<String, dynamic>;

          final result = await _tools.handleCall(name, args);
          _apiMessages.add({
            'role': 'tool',
            'tool_call_id': id,
            'name': name,
            'content': jsonEncode(result),
          });
        }
        // Continue loop to send tool responses back to the model
      } else {
        // Model provided final text
        return assistantMsg['content'] as String? ?? 'No response text received.';
      }
    }

    return 'Maximum tool call depth reached without final answer.';
  }
}

final assistantProvider = NotifierProvider<GeminiAssistantController, AssistantState>(
  GeminiAssistantController.new,
);
