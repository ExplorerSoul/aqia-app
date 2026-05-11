import '../models/interview_report.dart';

/// Common interface for AiService and MockAiService.
abstract class BaseAiService {
  bool get isInterviewComplete;

  Future<String> initializeInterview(
    String domain,
    String resumeText, {
    int maxQuestions = 8,
  });

  Future<String> sendMessage(String userResponse);

  Future<Map<String, dynamic>> generateReview({
    required List<Map<String, String>> qaPairs,
    required List<Map<String, dynamic>> speechMetrics,
    bool endedEarly = false,
  });

  InterviewReport buildReport(
    Map<String, dynamic> reviewJson,
    List<Map<String, String>> qaPairs,
  );
}
