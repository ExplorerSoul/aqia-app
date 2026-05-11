import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../models/interview_session.dart';
import '../../models/interview_report.dart';
import '../../services/ai_service.dart';
import '../../services/speech_service.dart';
import '../../services/dashboard_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/waveform_animation.dart';
import 'interview_report_screen.dart';
import 'question_bank_screen.dart';

class InterviewScreen extends StatefulWidget {
  final InterviewConfig config;
  const InterviewScreen({super.key, required this.config});

  @override
  State<InterviewScreen> createState() => _InterviewScreenState();
}

class _InterviewScreenState extends State<InterviewScreen> {
  final _textController = TextEditingController();
  late final AiService _ai;
  final _speech = SpeechService.instance;

  // State
  bool _initialized = false;
  bool _started = false;
  bool _isLoading = true;
  bool _isSpeaking = false;
  bool _isListening = false;
  bool _isTranscribing = false;
  bool _useTextInput = false;

  String _currentQuestion = '';
  int _questionNumber = 1;
  String _liveTranscript = '';

  // History for report
  final List<Map<String, String>> _qaPairs = [];
  final List<Map<String, dynamic>> _speechMetrics = [];

  DateTime? _answerStartTime;

  @override
  void initState() {
    super.initState();
    _ai = AiService();
    _speech.reset();
    _initInterview();
  }

  @override
  void dispose() {
    _textController.dispose();
    _speech.stopAll();
    super.dispose();
  }

  // ─── Init ─────────────────────────────────────────────────────────────────

  Future<void> _initInterview() async {
    try {
      final opener = await _ai.initializeInterview(
        widget.config.domain,
        widget.config.resumeText ?? '',
        maxQuestions: widget.config.numQuestions,
      );
      if (mounted) {
        setState(() {
          _currentQuestion = opener;
          _initialized = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start interview: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  // ─── Speech ───────────────────────────────────────────────────────────────

  Future<void> _speakQuestion(String text) async {
    if (!mounted) return;
    setState(() => _isSpeaking = true);

    final clean = text
        .replaceAll(RegExp(r'[*_`~#]'), '')
        .replaceAll(RegExp(r'https?://\S+'), 'link')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();

    await _speech.speak(clean);

    if (mounted) {
      setState(() {
        _isSpeaking = false;
        _answerStartTime = DateTime.now();
      });
      // Auto-start mic in voice mode
      if (!_useTextInput) _startListening();
    }
  }

  Future<void> _startListening() async {
    if (_isListening) return;
    setState(() {
      _isListening = true;
      _liveTranscript = '';
    });
    try {
      await _speech.startRecording(
        onLiveTranscript: (text) {
          if (mounted) setState(() => _liveTranscript = text);
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isListening = false;
          _useTextInput = true; // fallback to text
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mic error: $e. Switched to text input.')),
        );
      }
    }
  }

  Future<String> _stopListeningAndTranscribe() async {
    if (!_isListening) return _liveTranscript;
    setState(() {
      _isListening = false;
      _isTranscribing = true;
    });
    final text = await _speech.stopRecordingAndTranscribe();
    if (mounted) {
      setState(() {
        _isTranscribing = false;
        if (text.isNotEmpty) _liveTranscript = text;
      });
    }
    return text.isNotEmpty ? text : _liveTranscript;
  }

  // ─── Interview flow ───────────────────────────────────────────────────────

  Future<void> _submitAnswer() async {
    String answer;
    if (_useTextInput) {
      answer = _textController.text.trim();
    } else {
      answer = await _stopListeningAndTranscribe();
    }

    if (answer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide an answer')),
      );
      return;
    }

    // Compute speech metrics
    final durationSec = _answerStartTime != null
        ? ((DateTime.now().millisecondsSinceEpoch - _answerStartTime!.millisecondsSinceEpoch) / 1000).round()
        : 10;
    final wordCount = answer.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final wpm = durationSec > 0 ? ((wordCount / durationSec) * 60).round() : 0;
    final fillerRegex = RegExp(r'\b(um|umm|uh|uhh|like|you know|basically|actually|literally)\b', caseSensitive: false);
    final fillerCount = fillerRegex.allMatches(answer).length;

    _qaPairs.add({'question': _currentQuestion, 'answer': answer});
    _speechMetrics.add({'wpm': wpm, 'fillerCount': fillerCount, 'durationSec': durationSec});

    setState(() {
      _isLoading = true;
      _liveTranscript = '';
      _textController.clear();
    });

    try {
      final response = await _ai.sendMessage(answer);

      if (response == 'END_OF_INTERVIEW' || _ai.isInterviewComplete) {
        await _finishInterview();
        return;
      }

      if (mounted) {
        setState(() {
          _currentQuestion = response;
          _questionNumber++;
          _isLoading = false;
          _answerStartTime = null;
        });
        await _speakQuestion(response);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _finishInterview({bool endedEarly = false}) async {
    await _speech.stopAll();
    setState(() => _isLoading = true);

    try {
      // Guard: no valid answers
      if (_qaPairs.isEmpty || _qaPairs.every((q) => (q['answer'] ?? '').isEmpty)) {
        if (mounted) Navigator.pop(context);
        return;
      }

      final reviewJson = await _ai.generateReview(
        qaPairs: _qaPairs,
        speechMetrics: _speechMetrics,
        endedEarly: endedEarly,
      );

      // Compute aggregate speech metrics
      int totalWpm = 0, totalFiller = 0, validCount = 0;
      for (final m in _speechMetrics) {
        if ((m['wpm'] as int? ?? 0) > 0) {
          totalWpm += m['wpm'] as int;
          totalFiller += m['fillerCount'] as int;
          validCount++;
        }
      }
      reviewJson['speechMetrics'] = {
        'avgWpm': validCount > 0 ? (totalWpm / validCount).round() : 0,
        'totalFiller': totalFiller,
      };

      final report = _ai.buildReport(reviewJson, _qaPairs);

      // Save to backend (best-effort, non-blocking)
      _saveInterviewToBackend(reviewJson);

      // Save to local question bank
      final reviewQuestions = (reviewJson['questions'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [];
      QuestionBankService.addFromSession(
        domain: widget.config.domain,
        qaPairs: _qaPairs,
        reviewQuestions: reviewQuestions,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => InterviewReportScreen(report: report)),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating report: $e')),
        );
      }
    }
  }

  void _saveInterviewToBackend(Map<String, dynamic> reviewJson) {
    final score = reviewJson['score'] as Map<String, dynamic>? ?? {};
    final questions = (reviewJson['questions'] as List<dynamic>?) ?? [];

    DashboardService.instance.saveInterview(
      jobCategory: widget.config.domain,
      overallScore: (score['overall'] as num?)?.toInt(),
      questions: _qaPairs.asMap().entries.map((e) {
        final idx = e.key;
        final qa = e.value;
        final qDetail = idx < questions.length ? questions[idx] as Map<String, dynamic> : <String, dynamic>{};
        return {
          'question_asked': qa['question'] ?? '',
          'user_answer': qa['answer'] ?? '',
          'ai_feedback': qDetail['notes'] as String? ?? '',
          'score': qDetail['score'] as int?,
        };
      }).toList(),
      analyticsScores: {
        'Communication': (score['communication'] as num?)?.toInt(),
        'Technical': (score['technical'] as num?)?.toInt(),
        'Problem Solving': (score['problemSolving'] as num?)?.toInt(),
        'Behavioral': (score['behavioral'] as num?)?.toInt(),
      },
    ).then((saved) {
      if (!saved && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Daily interview limit reached. Results saved locally.'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    }).catchError((_) {});
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading && !_initialized) {
      return Scaffold(
        backgroundColor: AppTheme.blackBackground,
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppTheme.purplePrimary),
              SizedBox(height: 16),
              Text('Preparing your interview...', style: TextStyle(color: AppTheme.lightGrayText)),
            ],
          ),
        ),
      );
    }

    if (!_started) {
      return _buildStartScreen();
    }

    return Scaffold(
      backgroundColor: AppTheme.blackBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.carbonBlack,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () async {
            await _speech.stopAll();
            if (mounted) Navigator.pop(context);
          },
        ),
        title: Text(
          'Question $_questionNumber / ${widget.config.numQuestions}',
          style: const TextStyle(fontSize: 16, color: AppTheme.lightGrayText),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : () => _finishInterview(endedEarly: true),
            child: const Text('End', style: TextStyle(color: AppTheme.grayText)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.purplePrimary))
          : _buildInterviewBody(),
    );
  }

  Widget _buildStartScreen() {
    return Scaffold(
      backgroundColor: AppTheme.blackBackground,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.purplePrimary, AppTheme.gradientBlue],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.mic, size: 44, color: Colors.white),
              ),
              const SizedBox(height: 24),
              const Text(
                'Ready to Interview?',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.whiteText),
              ),
              const SizedBox(height: 12),
              Text(
                'Domain: ${widget.config.domain}\n${widget.config.numQuestions} questions',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: AppTheme.lightGrayText),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap Start to begin. The AI will speak each question aloud.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppTheme.grayText),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: AppTheme.buttonGradientDecoration(),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() => _started = true);
                        _speakQuestion(_currentQuestion);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 18),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.rocket_launch, color: Colors.white, size: 22),
                            SizedBox(width: 12),
                            Text('Start Interview',
                                style: TextStyle(
                                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInterviewBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question card
          Row(
            children: [
              Text(
                'Question $_questionNumber',
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.whiteText),
              ).animate().fadeIn(duration: 300.ms),
              const SizedBox(width: 12),
              if (_isSpeaking)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.purplePrimary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.purplePrimary.withValues(alpha: 0.5)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.volume_up, size: 14, color: AppTheme.purplePrimary),
                      SizedBox(width: 4),
                      Text('Speaking', style: TextStyle(fontSize: 12, color: AppTheme.purplePrimary)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Text(
              _currentQuestion,
              style: const TextStyle(
                  fontSize: 17, color: AppTheme.whiteText, fontWeight: FontWeight.w500, height: 1.4),
            ),
          ),
          const SizedBox(height: 24),

          // Input mode toggle
          Row(
            children: [
              Expanded(child: _inputToggle('Voice', Icons.mic, !_useTextInput, () {
                setState(() => _useTextInput = false);
                if (!_isListening) _startListening();
              })),
              const SizedBox(width: 12),
              Expanded(child: _inputToggle('Text', Icons.keyboard, _useTextInput, () async {
                if (_isListening) await _stopListeningAndTranscribe();
                setState(() {
                  _useTextInput = true;
                  _textController.text = _liveTranscript;
                });
              })),
            ],
          ),
          const SizedBox(height: 16),

          // Answer area
          if (!_useTextInput) ...[
            if (_isListening)
              const WaveformAnimation(isActive: true, color: AppTheme.purplePrimary),
            const SizedBox(height: 8),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isListening ? Icons.fiber_manual_record : Icons.mic_off,
                        size: 14,
                        color: _isListening ? Colors.red : AppTheme.grayText,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isTranscribing
                            ? 'Finalizing transcript...'
                            : _isListening
                                ? 'Listening...'
                                : 'Tap mic to start',
                        style: TextStyle(
                          fontSize: 12,
                          color: _isListening ? Colors.red : AppTheme.grayText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _liveTranscript.isEmpty ? 'Your answer will appear here...' : _liveTranscript,
                    style: TextStyle(
                      fontSize: 15,
                      color: _liveTranscript.isEmpty ? AppTheme.grayText : AppTheme.whiteText,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Mic control row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isListening ? () => _stopListeningAndTranscribe() : _startListening,
                    icon: Icon(_isListening ? Icons.stop : Icons.mic),
                    label: Text(_isListening ? 'Stop Recording' : 'Start Recording'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                        color: _isListening ? Colors.red : AppTheme.purplePrimary,
                      ),
                      foregroundColor: _isListening ? Colors.red : AppTheme.purplePrimary,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            GlassCard(
              padding: EdgeInsets.zero,
              child: TextField(
                controller: _textController,
                maxLines: 6,
                style: const TextStyle(color: AppTheme.whiteText),
                decoration: InputDecoration(
                  hintText: 'Type your answer here...',
                  hintStyle: TextStyle(color: AppTheme.whiteText.withValues(alpha: 0.4)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: AppTheme.buttonGradientDecoration(),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: (_isLoading || _isSpeaking || _isTranscribing) ? null : _submitAnswer,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.center,
                    child: (_isLoading || _isTranscribing)
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            _ai.isInterviewComplete ? 'Finish & Get Report' : 'Submit Answer',
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _inputToggle(String label, IconData icon, bool isActive, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.purplePrimary.withValues(alpha: 0.3) : AppTheme.carbonGrayDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? AppTheme.purplePrimary : AppTheme.glassBorder,
              width: isActive ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: isActive ? AppTheme.purplePrimary : AppTheme.grayText),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                    color: isActive ? AppTheme.whiteText : AppTheme.grayText,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
