class ProgressData {
  final double confidenceScore;
  final double accuracy;
  final double fluency;
  final DateTime date;
  
  ProgressData({
    required this.confidenceScore,
    required this.accuracy,
    required this.fluency,
    required this.date,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'confidenceScore': confidenceScore,
      'accuracy': accuracy,
      'fluency': fluency,
      'date': date.toIso8601String(),
    };
  }
  
  factory ProgressData.fromMap(Map<String, dynamic> map) {
    return ProgressData(
      confidenceScore: (map['confidenceScore'] ?? 0.0).toDouble(),
      accuracy: (map['accuracy'] ?? 0.0).toDouble(),
      fluency: (map['fluency'] ?? 0.0).toDouble(),
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
    );
  }
}

