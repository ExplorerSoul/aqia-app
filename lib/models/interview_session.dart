/// Configuration for starting an interview session.
class InterviewConfig {
  final String domain;
  final int numQuestions;
  final String? resumePath;
  /// Extracted or pasted resume text for AI context. Set when PDF is parsed or user pastes.
  final String? resumeText;

  const InterviewConfig({
    required this.domain,
    required this.numQuestions,
    this.resumePath,
    this.resumeText,
  });
}

/// Represents an active interview session with questions.
class InterviewSession {
  final String sessionId;
  final InterviewConfig config;
  final List<String> questions;
  final DateTime startedAt;

  InterviewSession({
    required this.sessionId,
    required this.config,
    required this.questions,
    required this.startedAt,
  });

  int get totalQuestions => questions.length;
}
