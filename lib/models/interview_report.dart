/// Full interview performance report generated after completing an interview.
class InterviewReport {
  final String candidateName;
  final int overallScore;
  final int communicationScore;
  final int technicalScore;
  final int problemSolvingScore;
  final int behavioralScore;
  final int wordsPerMinute;
  final int fillerWords;
  final String speechRecommendation;
  final String executiveSummary;
  final List<String> keyStrengths;
  final List<String> areasForImprovement;
  final List<QaAnalysis> detailedQa;

  InterviewReport({
    required this.candidateName,
    required this.overallScore,
    required this.communicationScore,
    required this.technicalScore,
    required this.problemSolvingScore,
    required this.behavioralScore,
    required this.wordsPerMinute,
    required this.fillerWords,
    required this.speechRecommendation,
    required this.executiveSummary,
    required this.keyStrengths,
    required this.areasForImprovement,
    required this.detailedQa,
  });

  factory InterviewReport.fromJson(Map<String, dynamic> json) {
    return InterviewReport(
      candidateName: json['candidateName'] as String? ?? 'Candidate',
      overallScore: _parseInt(json['overallScore'], 72),
      communicationScore: _parseInt(json['communicationScore'], 60),
      technicalScore: _parseInt(json['technicalScore'], 80),
      problemSolvingScore: _parseInt(json['problemSolvingScore'], 70),
      behavioralScore: _parseInt(json['behavioralScore'], 50),
      wordsPerMinute: _parseInt(json['wordsPerMinute'], 81),
      fillerWords: _parseInt(json['fillerWords'], 6),
      speechRecommendation: json['speechRecommendation'] as String? ?? '',
      executiveSummary: json['executiveSummary'] as String? ?? '',
      keyStrengths: List<String>.from(json['keyStrengths'] ?? []),
      areasForImprovement: List<String>.from(json['areasForImprovement'] ?? []),
      detailedQa: (json['detailedQa'] as List<dynamic>?)
              ?.map((e) => QaAnalysis.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  static int _parseInt(dynamic v, int def) {
    if (v == null) return def;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? def;
  }
}

class QaAnalysis {
  final int questionNumber;
  final String question;
  final String userResponse;
  final String suggestedImprovement;

  QaAnalysis({
    required this.questionNumber,
    required this.question,
    required this.userResponse,
    required this.suggestedImprovement,
  });

  factory QaAnalysis.fromJson(Map<String, dynamic> json) {
    final v = json['questionNumber'];
    final qn = v is int ? v : (v is double ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? 1);
    return QaAnalysis(
      questionNumber: qn,
      question: json['question'] as String? ?? '',
      userResponse: json['userResponse'] as String? ?? '',
      suggestedImprovement: json['suggestedImprovement'] as String? ?? '',
    );
  }
}
