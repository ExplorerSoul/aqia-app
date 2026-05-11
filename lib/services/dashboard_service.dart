import 'api_client.dart';

class RecentInterview {
  final String id;
  final String role;
  final String date;
  final int? score;

  const RecentInterview({
    required this.id,
    required this.role,
    required this.date,
    this.score,
  });

  factory RecentInterview.fromJson(Map<String, dynamic> json) {
    return RecentInterview(
      id: json['id'] as String? ?? '',
      role: json['role'] as String? ?? '',
      date: json['date'] as String? ?? '',
      score: json['score'] as int?,
    );
  }
}

class ProgressPoint {
  final String date;
  final int score;

  const ProgressPoint({required this.date, required this.score});

  factory ProgressPoint.fromJson(Map<String, dynamic> json) {
    return ProgressPoint(
      date: json['date'] as String? ?? '',
      score: (json['score'] as num?)?.toInt() ?? 0,
    );
  }
}

class DashboardData {
  final int totalInterviews;
  final int highestScore;
  final int avgScore;
  final List<RecentInterview> recentInterviews;
  final List<ProgressPoint> progressData;

  const DashboardData({
    required this.totalInterviews,
    required this.highestScore,
    required this.avgScore,
    required this.recentInterviews,
    required this.progressData,
  });

  factory DashboardData.empty() => const DashboardData(
        totalInterviews: 0,
        highestScore: 0,
        avgScore: 0,
        recentInterviews: [],
        progressData: [],
      );

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      totalInterviews: (json['total_interviews'] as num?)?.toInt() ?? 0,
      highestScore: (json['highest_score'] as num?)?.toInt() ?? 0,
      avgScore: (json['avg_score'] as num?)?.toInt() ?? 0,
      recentInterviews: (json['recent_interviews'] as List<dynamic>? ?? [])
          .map((e) => RecentInterview.fromJson(e as Map<String, dynamic>))
          .toList(),
      progressData: (json['progress_data'] as List<dynamic>? ?? [])
          .map((e) => ProgressPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DashboardService {
  DashboardService._();
  static final DashboardService instance = DashboardService._();

  Future<DashboardData> fetchDashboard() async {
    final json = await ApiClient.instance.get('/api/dashboard');
    return DashboardData.fromJson(json as Map<String, dynamic>);
  }

  /// Save a completed interview session to the backend.
  /// Returns false if the daily limit (429) was hit.
  Future<bool> saveInterview({
    required String jobCategory,
    required int? overallScore,
    required List<Map<String, dynamic>> questions,
    required Map<String, int?> analyticsScores,
  }) async {
    try {
      await ApiClient.instance.post('/api/interviews', {
        'job_category': jobCategory,
        if (overallScore != null) 'overall_score': overallScore,
        'questions': questions,
        'analytics_scores': analyticsScores,
      });
      return true;
    } on ApiException catch (e) {
      if (e.statusCode == 429) return false; // daily limit
      rethrow;
    }
  }
}
