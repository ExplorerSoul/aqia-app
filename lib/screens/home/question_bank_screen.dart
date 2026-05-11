import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../services/api_client.dart';

/// A question asked in a past interview, stored locally.
class SavedQuestion {
  final String question;
  final String domain;
  final String yourAnswer;
  final String suggestedAnswer;
  final DateTime date;

  SavedQuestion({
    required this.question,
    required this.domain,
    required this.yourAnswer,
    required this.suggestedAnswer,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'question': question,
        'domain': domain,
        'yourAnswer': yourAnswer,
        'suggestedAnswer': suggestedAnswer,
        'date': date.toIso8601String(),
      };

  factory SavedQuestion.fromJson(Map<String, dynamic> j) => SavedQuestion(
        question: j['question'] as String? ?? '',
        domain: j['domain'] as String? ?? '',
        yourAnswer: j['yourAnswer'] as String? ?? '',
        suggestedAnswer: j['suggestedAnswer'] as String? ?? '',
        date: DateTime.tryParse(j['date'] as String? ?? '') ?? DateTime.now(),
      );
}

/// Persists question bank locally in SharedPreferences.
class QuestionBankService {
  static const _key = 'aqia_question_bank';

  static Future<List<SavedQuestion>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => SavedQuestion.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(List<SavedQuestion> questions) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(questions.map((q) => q.toJson()).toList()));
  }

  /// Add questions from a completed interview session.
  static Future<void> addFromSession({
    required String domain,
    required List<Map<String, String>> qaPairs,
    required List<Map<String, dynamic>> reviewQuestions,
  }) async {
    final existing = await load();
    for (int i = 0; i < qaPairs.length; i++) {
      final qa = qaPairs[i];
      final review = i < reviewQuestions.length ? reviewQuestions[i] : <String, dynamic>{};
      existing.add(SavedQuestion(
        question: qa['question'] ?? '',
        domain: domain,
        yourAnswer: qa['answer'] ?? '',
        suggestedAnswer: review['suggestedAnswer'] as String? ?? '',
        date: DateTime.now(),
      ));
    }
    // Keep last 200 questions
    final trimmed = existing.length > 200 ? existing.sublist(existing.length - 200) : existing;
    await save(trimmed);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

class QuestionBankScreen extends StatefulWidget {
  const QuestionBankScreen({super.key});

  @override
  State<QuestionBankScreen> createState() => _QuestionBankScreenState();
}

class _QuestionBankScreenState extends State<QuestionBankScreen> {
  List<SavedQuestion> _questions = [];
  List<SavedQuestion> _filtered = [];
  bool _loading = true;
  String _selectedDomain = 'All';
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final questions = await QuestionBankService.load();
    // Newest first
    questions.sort((a, b) => b.date.compareTo(a.date));
    if (mounted) {
      setState(() {
        _questions = questions;
        _filtered = questions;
        _loading = false;
      });
    }
  }

  void _filter(String domain) {
    setState(() {
      _selectedDomain = domain;
      _filtered = domain == 'All'
          ? _questions
          : _questions.where((q) => q.domain == domain).toList();
      _expandedIndex = null;
    });
  }

  List<String> get _domains {
    final domains = {'All', ..._questions.map((q) => q.domain)};
    return domains.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.blackBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.carbonBlack,
        title: const Text('Question Bank',
            style: TextStyle(color: AppTheme.whiteText, fontWeight: FontWeight.w600)),
        actions: [
          if (_questions.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_outline, color: AppTheme.grayText),
              onPressed: () => _confirmClear(context),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.purplePrimary))
          : _questions.isEmpty
              ? _buildEmpty()
              : Column(
                  children: [
                    _buildDomainFilter(),
                    Expanded(child: _buildList()),
                  ],
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.quiz_outlined, size: 64, color: AppTheme.grayText),
          const SizedBox(height: 16),
          const Text('No questions yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.whiteText)),
          const SizedBox(height: 8),
          Text('Complete an interview to build your question bank.',
              style: TextStyle(fontSize: 14, color: AppTheme.grayText),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildDomainFilter() {
    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _domains.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final domain = _domains[i];
          final isSelected = domain == _selectedDomain;
          return GestureDetector(
            onTap: () => _filter(domain),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.purplePrimary : AppTheme.carbonGrayDark,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppTheme.purplePrimary : AppTheme.glassBorder,
                ),
              ),
              child: Text(
                domain,
                style: TextStyle(
                  fontSize: 13,
                  color: isSelected ? Colors.white : AppTheme.lightGrayText,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildList() {
    if (_filtered.isEmpty) {
      return Center(
        child: Text('No questions for $_selectedDomain',
            style: TextStyle(color: AppTheme.grayText)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filtered.length,
      itemBuilder: (_, i) {
        final q = _filtered[i];
        final isExpanded = _expandedIndex == i;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GlassCard(
            padding: const EdgeInsets.all(0),
            onTap: () => setState(() => _expandedIndex = isExpanded ? null : i),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.purplePrimary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('Q${i + 1}',
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.purplePrimary)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(q.question,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.whiteText,
                                height: 1.4)),
                      ),
                      Icon(
                        isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: AppTheme.grayText,
                        size: 20,
                      ),
                    ],
                  ),
                ),
                if (isExpanded) ...[
                  Divider(color: AppTheme.glassBorder, height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Domain + date
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.gradientBlue.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(q.domain,
                                  style: TextStyle(
                                      fontSize: 11, color: AppTheme.gradientBlue)),
                            ),
                            const Spacer(),
                            Text(
                              '${q.date.day}/${q.date.month}/${q.date.year}',
                              style: TextStyle(fontSize: 11, color: AppTheme.grayText),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        // Your answer
                        Text('YOUR ANSWER',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.grayText,
                                letterSpacing: 0.8)),
                        const SizedBox(height: 6),
                        Text(q.yourAnswer.isEmpty ? '(No answer recorded)' : q.yourAnswer,
                            style: TextStyle(
                                fontSize: 13,
                                color: q.yourAnswer.isEmpty
                                    ? AppTheme.grayText
                                    : AppTheme.whiteText,
                                height: 1.5)),
                        if (q.suggestedAnswer.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Text('SUGGESTED ANSWER',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade400,
                                  letterSpacing: 0.8)),
                          const SizedBox(height: 6),
                          Text(q.suggestedAnswer,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.green.shade300,
                                  height: 1.5)),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ).animate(delay: (i * 30).ms).fadeIn(duration: 250.ms),
        );
      },
    );
  }

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.carbonGrayDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear Question Bank',
            style: TextStyle(color: AppTheme.whiteText)),
        content: const Text('This will delete all saved questions. This cannot be undone.',
            style: TextStyle(color: AppTheme.lightGrayText)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.grayText)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await QuestionBankService.clear();
              _load();
            },
            child: Text('Clear', style: TextStyle(color: Colors.red.shade400)),
          ),
        ],
      ),
    );
  }
}
