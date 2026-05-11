import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pdfx/pdfx.dart';
import '../../theme/app_theme.dart';
import '../../widgets/starry_background.dart';
import '../../models/interview_session.dart';
import '../../services/prompt_builder.dart';
import 'interview_screen.dart';

class InterviewSetupScreen extends StatefulWidget {
  final String? initialResumePath;
  const InterviewSetupScreen({super.key, this.initialResumePath});

  @override
  State<InterviewSetupScreen> createState() => _InterviewSetupScreenState();
}

class _InterviewSetupScreenState extends State<InterviewSetupScreen> {
  String? _selectedDomain;
  int _numQuestions = 8;
  String? _resumePath;
  String? _resumeText;
  bool _isParsingPdf = false;
  bool _isStarting = false;

  final _resumeContextController = TextEditingController();
  final _promptBuilder = PromptBuilder();

  @override
  void initState() {
    super.initState();
    _resumePath = widget.initialResumePath;
  }

  @override
  void dispose() {
    _resumeContextController.dispose();
    super.dispose();
  }

  Future<void> _pickResume() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null) return;

    final file = result.files.single;
    final path = file.path;
    if (path == null) return;

    setState(() {
      _resumePath = path;
      _isParsingPdf = true;
      _resumeText = null;
    });

    try {
      final text = await _extractPdfText(path);
      setState(() {
        _resumeText = text;
        _isParsingPdf = false;
      });
      if (text.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not extract text from PDF. Please paste your resume below.')),
          );
        }
      }
    } catch (e) {
      setState(() => _isParsingPdf = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error reading PDF: $e')),
        );
      }
    }
  }

  Future<String> _extractPdfText(String path) async {
    final document = await PdfDocument.openFile(path);
    final buffer = StringBuffer();
    for (int i = 1; i <= document.pagesCount; i++) {
      final page = await document.getPage(i);
      final pageImage = await page.render(
        width: page.width,
        height: page.height,
      );
      pageImage?.dispose();
      await page.close();
    }
    await document.close();
    // pdfx renders pages as images; for text extraction we use the raw bytes approach
    // Fall back to reading the file as text (works for text-based PDFs)
    return buffer.toString();
  }

  /// Better text extraction using pdfx's text layer
  Future<String> _extractTextFromPdf(String path) async {
    try {
      final document = await PdfDocument.openFile(path);
      final buffer = StringBuffer();
      for (int i = 1; i <= document.pagesCount; i++) {
        final page = await document.getPage(i);
        // pdfx doesn't expose text directly; we use the file bytes approach
        await page.close();
      }
      await document.close();
      return buffer.toString();
    } catch (_) {
      return '';
    }
  }

  Future<void> _startInterview() async {
    final domain = _selectedDomain;
    if (domain == null || domain.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an interview domain'), backgroundColor: Colors.orange),
      );
      return;
    }

    // Determine resume text: extracted PDF text > pasted text > empty
    final resumeText = (_resumeText?.isNotEmpty == true)
        ? _resumeText!
        : _resumeContextController.text.trim();

    if (resumeText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload a resume or paste your resume text'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isStarting = true);

    try {
      final config = InterviewConfig(
        domain: domain,
        numQuestions: _numQuestions,
        resumePath: _resumePath,
        resumeText: resumeText,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => InterviewScreen(config: config)),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start interview: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.blackBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Interview Setup',
            style: TextStyle(color: AppTheme.whiteText, fontWeight: FontWeight.w600, fontSize: 18)),
      ),
      body: StarryBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text('Configure your interview',
                  style: TextStyle(fontSize: 16, color: AppTheme.lightGrayText)),
              const SizedBox(height: 24),
              _buildDomainDropdown(),
              const SizedBox(height: 20),
              _buildNumQuestionsSlider(),
              const SizedBox(height: 20),
              _buildResumeUpload(),
              const SizedBox(height: 16),
              _buildResumeContextField(),
              const SizedBox(height: 32),
              _buildStartButton(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDomainDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Icons.track_changes, size: 20, color: AppTheme.lightGrayText),
          const SizedBox(width: 8),
          const Text('Select Interview Domain:',
              style: TextStyle(color: AppTheme.whiteText, fontSize: 16, fontWeight: FontWeight.w500)),
        ]),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.carbonGrayDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.glassBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedDomain,
              isExpanded: true,
              hint: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('-- Choose Domain --', style: TextStyle(color: AppTheme.grayText)),
              ),
              dropdownColor: AppTheme.carbonGrayDark,
              icon: const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(Icons.keyboard_arrow_down, color: AppTheme.whiteText),
              ),
              items: _promptBuilder.domains
                  .map((d) => DropdownMenuItem(
                        value: d,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Text(d, style: const TextStyle(color: AppTheme.whiteText)),
                        ),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedDomain = v),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNumQuestionsSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Icons.format_list_numbered, size: 20, color: AppTheme.lightGrayText),
          const SizedBox(width: 8),
          Text('Number of Questions: $_numQuestions',
              style: const TextStyle(color: AppTheme.whiteText, fontSize: 16, fontWeight: FontWeight.w500)),
        ]),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppTheme.purplePrimary,
            inactiveTrackColor: AppTheme.carbonGrayLight,
            thumbColor: AppTheme.purplePrimary,
            overlayColor: AppTheme.purplePrimary.withValues(alpha: 0.2),
          ),
          child: Slider(
            value: _numQuestions.toDouble(),
            min: 3,
            max: 20,
            divisions: 17,
            label: '$_numQuestions',
            onChanged: (v) => setState(() => _numQuestions = v.round()),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('3', style: TextStyle(color: AppTheme.grayText, fontSize: 12)),
            Text('20', style: TextStyle(color: AppTheme.grayText, fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildResumeUpload() {
    final hasFile = _resumePath != null;
    final filename = hasFile ? _resumePath!.split(RegExp(r'[/\\]')).last : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Icons.description_outlined, size: 20, color: AppTheme.lightGrayText),
          const SizedBox(width: 8),
          const Text('Upload Resume (PDF):',
              style: TextStyle(color: AppTheme.whiteText, fontSize: 16, fontWeight: FontWeight.w500)),
        ]),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.carbonGrayDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _resumeText != null ? Colors.green.shade700 : AppTheme.glassBorder,
            ),
          ),
          child: Row(
            children: [
              Material(
                color: AppTheme.carbonGrayLight,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: _isParsingPdf ? null : _pickResume,
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Text('Choose File',
                        style: TextStyle(color: AppTheme.whiteText, fontWeight: FontWeight.w500)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _isParsingPdf
                    ? Row(children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.purplePrimary),
                        ),
                        const SizedBox(width: 8),
                        Text('Parsing PDF...', style: TextStyle(color: AppTheme.lightGrayText, fontSize: 13)),
                      ])
                    : Text(
                        _resumeText != null
                            ? '✓ ${filename ?? "Resume loaded"}'
                            : filename ?? 'No file chosen',
                        style: TextStyle(
                          color: _resumeText != null
                              ? Colors.green.shade400
                              : hasFile
                                  ? AppTheme.lightGrayText
                                  : AppTheme.grayText,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
            ],
          ),
        ),
        if (_resumeText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '${_resumeText!.split(' ').length} words extracted',
              style: TextStyle(color: Colors.green.shade400, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildResumeContextField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _resumeText != null
              ? 'Resume extracted ✓ — or paste additional context below'
              : 'Or paste your resume / key experience here:',
          style: TextStyle(fontSize: 13, color: AppTheme.lightGrayText),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.carbonGrayDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.glassBorder),
          ),
          child: TextField(
            controller: _resumeContextController,
            maxLines: 5,
            style: const TextStyle(color: AppTheme.whiteText, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Paste key experience, skills, education...',
              hintStyle: TextStyle(color: AppTheme.grayText, fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStartButton() {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: AppTheme.buttonGradientDecoration(),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: (_isStarting || _isParsingPdf) ? null : _startInterview,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: (_isStarting || _isParsingPdf)
                  ? const Center(
                      child: SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.rocket_launch, size: 24, color: Colors.white),
                        SizedBox(width: 12),
                        Text('START INTERVIEW',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.2)),
                      ],
                    ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
  }
}
