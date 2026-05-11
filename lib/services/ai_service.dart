import 'dart:convert';
import 'api_client.dart';
import 'base_ai_service.dart';
import 'prompt_builder.dart';
import '../models/interview_report.dart';

/// Wraps the backend /api/chat proxy (Groq Llama-3.3-70b).
/// Maintains conversation history for the duration of an interview session.
class AiService extends BaseAiService {
  final PromptBuilder _promptBuilder = PromptBuilder();

  final List<Map<String, dynamic>> _conversationHistory = [];
  int _questionCount = 0;
  int _maxQuestions = 8;
  String _domain = '';

  static const String _model = 'llama-3.3-70b-versatile';

  bool get isInterviewComplete => _questionCount >= _maxQuestions;

  /// Initialize a new interview session. Returns the opening question.
  Future<String> initializeInterview(
    String domain,
    String resumeText, {
    int maxQuestions = 8,
  }) async {
    _domain = domain;
    _maxQuestions = maxQuestions;
    _questionCount = 1; // opener counts as question 1
    _conversationHistory.clear();

    final analysis = _promptBuilder.analyzeResume(resumeText);
    final systemPrompt = _promptBuilder.getInterviewPrompt(domain, resumeText, analysis);

    _conversationHistory.add({'role': 'system', 'content': systemPrompt});

    const opener =
        "Hello! I've reviewed your resume and I'm excited to chat. Can you briefly introduce yourself and tell me what brings you here today?";
    _conversationHistory.add({'role': 'assistant', 'content': opener});
    return opener;
  }

  /// Send a user message and get the next AI question.
  /// Returns 'END_OF_INTERVIEW' when the question limit is reached.
  Future<String> sendMessage(String userResponse) async {
    if (userResponse.isNotEmpty) {
      _conversationHistory.add({'role': 'user', 'content': userResponse});
    }

    // After submitting answer to question N, check if we've hit the limit
    if (_questionCount >= _maxQuestions) {
      return 'END_OF_INTERVIEW';
    }

    final response = await ApiClient.instance.post('/api/chat', {
      'model': _model,
      'messages': List<Map<String, dynamic>>.from(_conversationHistory),
      'temperature': 0.6,
      'max_tokens': 1024,
    });

    final aiText = response['choices'][0]['message']['content'] as String;
    _conversationHistory.add({'role': 'assistant', 'content': aiText});
    _questionCount++; // increment after receiving next question
    return aiText;
  }

  /// Generate the final structured review report.
  Future<Map<String, dynamic>> generateReview({
    required List<Map<String, String>> qaPairs,
    required List<Map<String, dynamic>> speechMetrics,
    bool endedEarly = false,
  }) async {
    final prompt = _promptBuilder.getReviewPrompt(
      qaPairs: qaPairs,
      speechMetrics: speechMetrics,
      endedEarly: endedEarly,
    );

    final response = await ApiClient.instance.post('/api/chat', {
      'model': _model,
      'messages': [
        ..._conversationHistory,
        {'role': 'user', 'content': prompt},
      ],
      'temperature': 0.4,
      'max_tokens': 3000,
      'response_format': {'type': 'json_object'},
    });

    final raw = response['choices'][0]['message']['content'] as String;
    return _parseJson(raw);
  }

  Map<String, dynamic> _parseJson(String raw) {
    String cleaned = raw.trim();
    // Strip markdown fences if present
    if (cleaned.startsWith('```')) {
      cleaned = cleaned
          .replaceFirst(RegExp(r'^```\w*\n?'), '')
          .replaceFirst(RegExp(r'\n?```$'), '');
    }
    try {
      return jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (_) {
      // Try to extract JSON object
      final match = RegExp(r'\{[\s\S]*\}').firstMatch(cleaned);
      if (match != null) {
        return jsonDecode(match.group(0)!) as Map<String, dynamic>;
      }
      return {};
    }
  }

  /// Build an InterviewReport from the review JSON (for the report screen).
  InterviewReport buildReport(Map<String, dynamic> reviewJson, List<Map<String, String>> qaPairs) {
    final score = reviewJson['score'] as Map<String, dynamic>? ?? {};
    final questions = (reviewJson['questions'] as List<dynamic>?) ?? [];

    return InterviewReport(
      candidateName: 'Candidate',
      overallScore: _parseInt(score['overall'], 72),
      communicationScore: _parseInt(score['communication'], 60),
      technicalScore: _parseInt(score['technical'], 80),
      problemSolvingScore: _parseInt(score['problemSolving'], 70),
      behavioralScore: _parseInt(score['behavioral'], 50),
      wordsPerMinute: _parseInt(reviewJson['speechMetrics']?['avgWpm'], 81),
      fillerWords: _parseInt(reviewJson['speechMetrics']?['totalFiller'], 0),
      speechRecommendation: reviewJson['speechRecommendation'] as String? ?? '',
      executiveSummary: reviewJson['summary'] as String? ?? '',
      keyStrengths: List<String>.from(reviewJson['strengths'] ?? []),
      areasForImprovement: List<String>.from(reviewJson['weaknesses'] ?? []),
      detailedQa: questions.asMap().entries.map((e) {
        final q = e.value as Map<String, dynamic>;
        return QaAnalysis(
          questionNumber: e.key + 1,
          question: q['question'] as String? ?? '',
          userResponse: q['yourAnswer'] as String? ?? '',
          suggestedImprovement: q['suggestedAnswer'] as String? ?? '',
        );
      }).toList(),
    );
  }

  static int _parseInt(dynamic v, int def) {
    if (v == null) return def;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? def;
  }
}
