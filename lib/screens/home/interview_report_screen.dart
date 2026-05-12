import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../theme/app_theme.dart';
import '../../models/interview_report.dart';
import '../../widgets/glass_card.dart';

class InterviewReportScreen extends StatelessWidget {
  final InterviewReport report;
  final VoidCallback? onDone;
  const InterviewReportScreen({super.key, required this.report, this.onDone});

  // ─── Download as PDF ──────────────────────────────────────────────────────

  Future<void> _downloadReport(BuildContext context) async {
    try {
      final pdf = PdfDocument();
      final page = pdf.pages.add();
      final graphics = page.graphics;
      final titleFont = PdfStandardFont(PdfFontFamily.helvetica, 18, style: PdfFontStyle.bold);
      final headFont = PdfStandardFont(PdfFontFamily.helvetica, 13, style: PdfFontStyle.bold);
      final bodyFont = PdfStandardFont(PdfFontFamily.helvetica, 11);
      final smallFont = PdfStandardFont(PdfFontFamily.helvetica, 10);
      final black = PdfSolidBrush(PdfColor(30, 30, 30));
      final gray = PdfSolidBrush(PdfColor(100, 100, 100));
      final green = PdfSolidBrush(PdfColor(22, 163, 74));

      double y = 20;
      const double left = 40;
      const double width = 500;

      // Title
      graphics.drawString('AQIA — Interview Performance Report', titleFont,
          brush: black, bounds: Rect.fromLTWH(left, y, width, 30));
      y += 36;

      // Scores
      graphics.drawString('PERFORMANCE SCORES', headFont,
          brush: black, bounds: Rect.fromLTWH(left, y, width, 20));
      y += 24;
      final scores = [
        'Overall: ${report.overallScore}',
        'Communication: ${report.communicationScore}',
        'Technical: ${report.technicalScore}',
        'Problem Solving: ${report.problemSolvingScore}',
        'Behavioral: ${report.behavioralScore}',
      ];
      for (final s in scores) {
        graphics.drawString(s, bodyFont,
            brush: black, bounds: Rect.fromLTWH(left, y, width, 18));
        y += 18;
      }
      y += 10;

      // Speech
      graphics.drawString('SPEECH ANALYTICS', headFont,
          brush: black, bounds: Rect.fromLTWH(left, y, width, 20));
      y += 24;
      graphics.drawString(
          '${report.wordsPerMinute} words/min   |   ${report.fillerWords} filler words',
          bodyFont, brush: green, bounds: Rect.fromLTWH(left, y, width, 18));
      y += 18;
      if (report.speechRecommendation.isNotEmpty) {
        graphics.drawString(report.speechRecommendation, smallFont,
            brush: gray, bounds: Rect.fromLTWH(left, y, width, 36));
        y += 40;
      }
      y += 10;

      // Summary
      graphics.drawString('EXECUTIVE SUMMARY', headFont,
          brush: black, bounds: Rect.fromLTWH(left, y, width, 20));
      y += 24;
      graphics.drawString(report.executiveSummary, bodyFont,
          brush: black,
          bounds: Rect.fromLTWH(left, y, width, 80),
          format: PdfStringFormat(wordWrap: PdfWordWrapType.word));
      y += 90;

      // Strengths
      graphics.drawString('KEY STRENGTHS', headFont,
          brush: black, bounds: Rect.fromLTWH(left, y, width, 20));
      y += 24;
      for (final s in report.keyStrengths) {
        graphics.drawString('✓  $s', bodyFont,
            brush: green, bounds: Rect.fromLTWH(left, y, width, 18));
        y += 18;
      }
      y += 10;

      // Weaknesses
      graphics.drawString('AREAS FOR IMPROVEMENT', headFont,
          brush: black, bounds: Rect.fromLTWH(left, y, width, 20));
      y += 24;
      for (final w in report.areasForImprovement) {
        graphics.drawString('•  $w', bodyFont,
            brush: black, bounds: Rect.fromLTWH(left, y, width, 18));
        y += 18;
      }
      y += 16;

      // Q&A — new page per question if needed
      for (final qa in report.detailedQa) {
        if (y > 650) {
          pdf.pages.add();
          y = 20;
        }
        graphics.drawString('Q${qa.questionNumber}: ${qa.question}', headFont,
            brush: black, bounds: Rect.fromLTWH(left, y, width, 20));
        y += 24;
        graphics.drawString('Your answer:', smallFont,
            brush: gray, bounds: Rect.fromLTWH(left, y, width, 16));
        y += 16;
        graphics.drawString(qa.userResponse, bodyFont,
            brush: black,
            bounds: Rect.fromLTWH(left, y, width, 60),
            format: PdfStringFormat(wordWrap: PdfWordWrapType.word));
        y += 68;
        graphics.drawString('Suggested improvement:', smallFont,
            brush: gray, bounds: Rect.fromLTWH(left, y, width, 16));
        y += 16;
        graphics.drawString(qa.suggestedImprovement, bodyFont,
            brush: green,
            bounds: Rect.fromLTWH(left, y, width, 60),
            format: PdfStringFormat(wordWrap: PdfWordWrapType.word));
        y += 72;
      }

      final bytes = await pdf.save();
      pdf.dispose();

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/AQIA_Report_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'AQIA Interview Report',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not generate PDF: $e')),
        );
      }
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.blackBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.carbonBlack,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (onDone != null) {
              onDone!();
            } else {
              Navigator.popUntil(context, (r) => r.isFirst);
            }
          },
        ),
        title: const Text('Performance Review',
            style: TextStyle(color: AppTheme.whiteText, fontWeight: FontWeight.w600, fontSize: 17)),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined, color: AppTheme.purplePrimary),
            tooltip: 'Download Report',
            onPressed: () => _downloadReport(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildScoreCard(),
            const SizedBox(height: 14),
            _buildSpeechCard(),
            const SizedBox(height: 14),
            _buildSummaryCard(),
            const SizedBox(height: 14),
            _buildStrengths(),
            const SizedBox(height: 14),
            _buildWeaknesses(),
            const SizedBox(height: 20),
            _buildQaSection(),
            const SizedBox(height: 32),
            // Download button at bottom too
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  if (onDone != null) {
                    onDone!();
                  } else {
                    Navigator.popUntil(context, (r) => r.isFirst);
                  }
                },
                icon: const Icon(Icons.home_outlined, size: 18),
                label: const Text('Back to Dashboard'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppTheme.border),
                  foregroundColor: AppTheme.textSecondary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('PERFORMANCE SCORE'),
          const SizedBox(height: 16),
          // Overall big score
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${report.overallScore}',
                style: TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.bold,
                  color: _scoreColor(report.overallScore),
                  height: 1,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('/100',
                    style: TextStyle(fontSize: 16, color: AppTheme.grayText)),
              ),
              const Spacer(),
              Text('OVERALL',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.grayText,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          // Sub scores as progress bars
          _scoreBar('Communication', report.communicationScore, AppTheme.gradientBlue),
          _scoreBar('Technical', report.technicalScore, AppTheme.purplePrimary),
          _scoreBar('Problem Solving', report.problemSolvingScore, Colors.amber),
          _scoreBar('Behavioral', report.behavioralScore, Colors.teal),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _scoreBar(String label, int score, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(fontSize: 13, color: AppTheme.lightGrayText)),
              Text('$score', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 6,
              backgroundColor: AppTheme.carbonGray,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeechCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.successLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.successBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.mic, color: AppTheme.success, size: 18),
            const SizedBox(width: 8),
            Text('SPEECH ANALYTICS',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                    color: AppTheme.success, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _speechStat(
                '${report.wordsPerMinute}', 'words / min', AppTheme.success)),
              const SizedBox(width: 12),
              Expanded(child: _speechStat(
                '${report.fillerWords}', 'filler words',
                report.fillerWords > 5 ? AppTheme.warning : AppTheme.success)),
            ],
          ),
          if (report.speechRecommendation.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(report.speechRecommendation,
                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4)),
          ],
        ],
      ),
    ).animate(delay: 100.ms).fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _speechStat(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('EXECUTIVE SUMMARY'),
          const SizedBox(height: 10),
          Text(report.executiveSummary,
              style: const TextStyle(fontSize: 14, color: AppTheme.whiteText, height: 1.6)),
        ],
      ),
    ).animate(delay: 200.ms).fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildStrengths() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.green.shade900.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade700.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.thumb_up_outlined, color: Colors.green.shade400, size: 18),
            const SizedBox(width: 8),
            _label('KEY STRENGTHS'),
          ]),
          const SizedBox(height: 12),
          ...report.keyStrengths.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.green.shade400, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(s, style: const TextStyle(fontSize: 13, color: AppTheme.whiteText, height: 1.4))),
                  ],
                ),
              )),
        ],
      ),
    ).animate(delay: 300.ms).fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildWeaknesses() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.orange.shade900.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade700.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.trending_up, color: Colors.orange.shade400, size: 18),
            const SizedBox(width: 8),
            _label('AREAS TO IMPROVE'),
          ]),
          const SizedBox(height: 12),
          ...report.areasForImprovement.map((w) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.arrow_forward_ios, color: Colors.orange.shade400, size: 12),
                    const SizedBox(width: 8),
                    Expanded(child: Text(w, style: const TextStyle(fontSize: 13, color: AppTheme.whiteText, height: 1.4))),
                  ],
                ),
              )),
        ],
      ),
    ).animate(delay: 400.ms).fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildQaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Detailed Q&A Analysis',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.whiteText)),
        const SizedBox(height: 14),
        ...report.detailedQa.asMap().entries.map((e) =>
            _buildQaItem(e.value, e.key)),
      ],
    ).animate(delay: 500.ms).fadeIn(duration: 400.ms);
  }

  Widget _buildQaItem(QaAnalysis qa, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question badge + text
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.purplePrimary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Q${qa.questionNumber}',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.purplePrimary)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(qa.question,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.whiteText, height: 1.4)),
          const SizedBox(height: 12),

          // Your response — full width
          _qaBox(
            label: 'YOUR RESPONSE',
            text: qa.userResponse,
            labelColor: AppTheme.lightGrayText,
            bgColor: AppTheme.carbonGrayDark,
            borderColor: AppTheme.glassBorder,
          ),
          const SizedBox(height: 8),

          // Suggested improvement — full width
          _qaBox(
            label: 'SUGGESTED IMPROVEMENT',
            text: qa.suggestedImprovement,
            labelColor: Colors.green.shade400,
            bgColor: Colors.green.shade900.withValues(alpha: 0.15),
            borderColor: Colors.green.shade700.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }

  Widget _qaBox({
    required String label,
    required String text,
    required Color labelColor,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: labelColor,
                  letterSpacing: 0.8)),
          const SizedBox(height: 8),
          Text(text,
              style: const TextStyle(fontSize: 14, color: AppTheme.whiteText, height: 1.5)),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(text,
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppTheme.grayText,
            letterSpacing: 1.2));
  }

  Color _scoreColor(int score) {
    if (score >= 80) return Colors.green.shade400;
    if (score >= 60) return Colors.amber;
    return Colors.red.shade400;
  }
}
