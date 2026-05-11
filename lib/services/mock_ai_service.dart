import '../models/interview_report.dart';
import 'base_ai_service.dart';

/// Drop-in replacement for AiService that uses zero LLM tokens.
/// Activate by running: flutter run --dart-define=MOCK_MODE=true
///
/// Simulates the full interview flow with instant fake responses.
class MockAiService extends BaseAiService {
  int _questionCount = 0;
  int _maxQuestions = 3;
  String _domain = '';

  bool get isInterviewComplete => _questionCount >= _maxQuestions;

  static const List<String> _mockQuestions = [
    "Tell me about yourself and what drew you to software engineering.",
    "Describe a challenging technical problem you solved recently. What was your approach?",
    "How do you handle code reviews — both giving and receiving feedback?",
    "Walk me through how you would design a URL shortening service.",
    "Tell me about a time you had to learn a new technology quickly under pressure.",
  ];

  static const List<String> _mockAcknowledgements = [
    "That's a solid answer.",
    "Good, I appreciate the detail.",
    "Okay, that makes sense.",
    "Nice, thanks for sharing that.",
    "Great perspective.",
  ];

  Future<String> initializeInterview(
    String domain,
    String resumeText, {
    int maxQuestions = 3,
  }) async {
    _domain = domain;
    _maxQuestions = maxQuestions;
    _questionCount = 1;
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 600));
    return "Hello! I've reviewed your resume and I'm excited to chat. "
        "Can you briefly introduce yourself and tell me what brings you here today?";
  }

  Future<String> sendMessage(String userResponse) async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (_questionCount >= _maxQuestions) {
      return 'END_OF_INTERVIEW';
    }

    final ack = _mockAcknowledgements[_questionCount % _mockAcknowledgements.length];
    final nextQ = _mockQuestions[_questionCount % _mockQuestions.length];
    _questionCount++;
    return "$ack $nextQ";
  }

  Future<Map<String, dynamic>> generateReview({
    required List<Map<String, String>> qaPairs,
    required List<Map<String, dynamic>> speechMetrics,
    bool endedEarly = false,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    return {
      'score': {
        'overall': 78,
        'communication': 82,
        'technical': 75,
        'problemSolving': 80,
        'behavioral': 70,
      },
      'summary':
          'The candidate demonstrated solid communication skills and a good understanding of core engineering principles. '
          'They spoke at a comfortable pace with minimal filler words. '
          'Technical depth could be improved with more specific examples. '
          'Overall a promising candidate worth moving forward.',
      'strengths': [
        'Clear and structured communication',
        'Good problem-solving approach',
        'Comfortable with technical concepts',
      ],
      'weaknesses': [
        'Could provide more concrete examples',
        'Needs to elaborate on system design decisions',
      ],
      'questions': qaPairs.asMap().entries.map((e) {
        final idx = e.key;
        final qa = e.value;
        return {
          'question': qa['question'] ?? '',
          'yourAnswer': qa['answer'] ?? '',
          'suggestedAnswer':
              'A strong answer would include a specific example from your experience, '
              'explain the context, your actions, and the measurable outcome. '
              'Use the STAR method: Situation, Task, Action, Result.',
          'notes': 'Good attempt. Add more specifics to strengthen this answer.',
          'score': 7 + (idx % 3),
        };
      }).toList(),
      'speechMetrics': {
        'avgWpm': 112,
        'totalFiller': 3,
      },
      'speechRecommendation':
          'Your pacing was good at ~112 words/min. Keep filler words minimal.',
    };
  }

  InterviewReport buildReport(
      Map<String, dynamic> reviewJson, List<Map<String, String>> qaPairs) {
    final score = reviewJson['score'] as Map<String, dynamic>? ?? {};
    final questions = (reviewJson['questions'] as List<dynamic>?) ?? [];

    return InterviewReport(
      candidateName: 'Candidate',
      overallScore: score['overall'] as int? ?? 78,
      communicationScore: score['communication'] as int? ?? 82,
      technicalScore: score['technical'] as int? ?? 75,
      problemSolvingScore: score['problemSolving'] as int? ?? 80,
      behavioralScore: score['behavioral'] as int? ?? 70,
      wordsPerMinute: reviewJson['speechMetrics']?['avgWpm'] as int? ?? 112,
      fillerWords: reviewJson['speechMetrics']?['totalFiller'] as int? ?? 3,
      speechRecommendation:
          reviewJson['speechRecommendation'] as String? ?? '',
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
}
