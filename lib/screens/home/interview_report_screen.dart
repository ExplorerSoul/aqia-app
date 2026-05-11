import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../models/interview_report.dart';
import '../../widgets/glass_card.dart';

/// Full interview performance report matching the design from the reference images.
class InterviewReportScreen extends StatelessWidget {
  final InterviewReport report;

  const InterviewReportScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.blackBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
        ),
        title: const Text(
          'Interview Performance Review',
          style: TextStyle(
            color: AppTheme.whiteText,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildPerformanceScoreCard(),
            const SizedBox(height: 16),
            _buildSpeechAnalyticsCard(),
            const SizedBox(height: 16),
            _buildExecutiveSummaryCard(),
            const SizedBox(height: 16),
            _buildStrengthsAndImprovement(),
            const SizedBox(height: 20),
            _buildDetailedQa(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(Icons.assignment, color: AppTheme.purplePrimary, size: 28),
        const SizedBox(width: 12),
        const Text(
          'Interview Performance Review',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppTheme.whiteText,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.05, end: 0);
  }

  Widget _buildPerformanceScoreCard() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PERFORMANCE SCORE',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.lightGrayText,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '${report.overallScore}\nOVERALL',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.whiteText,
                  height: 1.2,
                ),
              ),
              _scoreChip('${report.communicationScore}', 'COMMUNICATION'),
              _scoreChip('${report.technicalScore}', 'TECHNICAL'),
              _scoreChip('${report.problemSolvingScore}', 'PROBLEM SOLVING'),
              _scoreChip('${report.behavioralScore}', 'BEHAVIORAL'),
            ],
          ),
        ],
      ),
    )
        .animate(delay: 100.ms)
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.05, end: 0);
  }

  Widget _scoreChip(String score, String label) {
    return Column(
      children: [
        Text(
          score,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.whiteText,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: AppTheme.lightGrayText,
          ),
        ),
      ],
    );
  }

  Widget _buildSpeechAnalyticsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.shade900.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade700.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.mic, color: Colors.green.shade400, size: 22),
              const SizedBox(width: 8),
              const Text(
                'SPEECH ANALYTICS',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.whiteText,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                '${report.wordsPerMinute} WORDS / MINUTE',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade300,
                ),
              ),
              const SizedBox(width: 24),
              Text(
                '${report.fillerWords} FILLER WORDS ("um", "uh")',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade300,
                ),
              ),
            ],
          ),
          if (report.speechRecommendation.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              report.speechRecommendation,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.lightGrayText,
              ),
            ),
          ],
        ],
      ),
    )
        .animate(delay: 200.ms)
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.05, end: 0);
  }

  Widget _buildExecutiveSummaryCard() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'EXECUTIVE SUMMARY',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.lightGrayText,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            report.executiveSummary,
            style: const TextStyle(
              fontSize: 15,
              color: AppTheme.whiteText,
              height: 1.5,
            ),
          ),
        ],
      ),
    )
        .animate(delay: 300.ms)
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.05, end: 0);
  }

  Widget _buildStrengthsAndImprovement() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade900.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade700.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.handshake, color: Colors.green.shade400, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'KEY STRENGTHS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.whiteText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...report.keyStrengths.map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade400, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            s,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.whiteText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade900.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade700.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.red.shade400, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'AREAS FOR IMPROVEMENT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.whiteText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...report.areasForImprovement.map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.cancel, color: Colors.red.shade400, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            s,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.whiteText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    )
        .animate(delay: 400.ms)
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.05, end: 0);
  }

  Widget _buildDetailedQa() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detailed Q&A Analysis',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.whiteText,
          ),
        ),
        const SizedBox(height: 16),
        ...report.detailedQa.map((qa) => _buildQaItem(qa)),
      ],
    )
        .animate(delay: 500.ms)
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.05, end: 0);
  }

  Widget _buildQaItem(QaAnalysis qa) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.purplePrimary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'QUESTION ${qa.questionNumber}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.purplePrimary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            qa.question,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.whiteText,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'YOUR RESPONSE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.lightGrayText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        qa.userResponse,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.whiteText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.green.shade900.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade700.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SUGGESTED IMPROVEMENT',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade300,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        qa.suggestedImprovement,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.whiteText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
