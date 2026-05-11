class InterviewFeedback {
  final double fluency;
  final double content;
  final double confidence;
  final int fillerWords;
  final String overallFeedback;
  final List<String> suggestions;
  final DateTime timestamp;
  
  InterviewFeedback({
    required this.fluency,
    required this.content,
    required this.confidence,
    required this.fillerWords,
    required this.overallFeedback,
    required this.suggestions,
    required this.timestamp,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'fluency': fluency,
      'content': content,
      'confidence': confidence,
      'fillerWords': fillerWords,
      'overallFeedback': overallFeedback,
      'suggestions': suggestions,
      'timestamp': timestamp.toIso8601String(),
    };
  }
  
  factory InterviewFeedback.fromMap(Map<String, dynamic> map) {
    return InterviewFeedback(
      fluency: (map['fluency'] ?? 0.0).toDouble(),
      content: (map['content'] ?? 0.0).toDouble(),
      confidence: (map['confidence'] ?? 0.0).toDouble(),
      fillerWords: map['fillerWords'] ?? 0,
      overallFeedback: map['overallFeedback'] ?? '',
      suggestions: List<String>.from(map['suggestions'] ?? []),
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }
  
  double get averageScore => (fluency + content + confidence) / 3;
}

