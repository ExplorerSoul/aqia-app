/// Dart port of the web app's promptBuilder.js.
/// Builds the system prompt that drives the Groq/Llama interview conversation.
class PromptBuilder {
  static const List<String> _domains = [
    'Software Engineering',
    'Data Science',
    'Product Management',
    'DevOps',
    'Machine Learning',
  ];

  static const Map<String, Map<String, String>> _domainTemplates = {
    'Software Engineering': {
      'focus': 'system design, code quality, debugging, technical decisions, scalability, and architecture',
      'style': 'act like a senior tech lead who values clean code, smart solutions, and practical engineering',
    },
    'Data Science': {
      'focus': 'data interpretation, statistical thinking, business insights, visualization, and analytical frameworks',
      'style': 'be like a curious data detective who loves uncovering stories in numbers and driving business impact',
    },
    'Product Management': {
      'focus': 'user empathy, strategic thinking, prioritization, cross-functional leadership, and business impact',
      'style': 'think like a strategic product leader who balances user needs with business goals and technical constraints',
    },
    'UI/UX Design': {
      'focus': 'user research, design thinking, prototyping, accessibility, and visual communication',
      'style': 'approach like a human-centered designer who champions the user at every step',
    },
    'Cybersecurity': {
      'focus': 'threat modeling, security architecture, incident response, compliance, and risk management',
      'style': 'think like a security engineer who balances protection with usability',
    },
    'Cloud Computing': {
      'focus': 'cloud architecture, cost optimization, scalability, managed services, and infrastructure as code',
      'style': 'act like a cloud architect who designs resilient, cost-effective systems',
    },
    'DevOps': {
      'focus': 'CI/CD pipelines, containerization, monitoring, infrastructure as code, and reliability',
      'style': 'think like a platform engineer who bridges development and operations',
    },
    'Machine Learning': {
      'focus': 'model design, training pipelines, evaluation, deployment, and ML system architecture',
      'style': 'engage like an ML engineer who cares about both research rigor and production reliability',
    },
    'AI Research': {
      'focus': 'research methodology, paper reading, experiment design, novel contributions, and ethical AI',
      'style': 'approach like a research scientist who values intellectual curiosity and rigorous experimentation',
    },
  };

  static const List<String> _conversationStarters = [
    "I'm excited to learn about your background. Tell me your story and what drew you to this role.",
    "Let's start with you — I'd love to hear about your journey and what interests you about this opportunity.",
    "Before we dive into the technical details, help me understand your background and motivation.",
    "I've reviewed your resume and I'm curious — walk me through your career journey so far.",
    "Tell me about yourself and what excites you most about the work you do.",
  ];

  List<String> get domains => List.unmodifiable(_domains);

  bool isValidDomain(String domain) => _domains.contains(domain);

  /// Lightweight resume analysis — extracts experience level, skills, companies.
  Map<String, dynamic> analyzeResume(String resumeText) {
    if (resumeText.trim().length < 50) {
      return {
        'experience': 'entry-level',
        'keySkills': <String>[],
        'companies': <String>[],
        'achievements': <String>[],
        'analysisQuality': 'minimal',
      };
    }

    final text = resumeText.toLowerCase();

    // Experience level
    String experience = 'entry-level';
    final yearRegex = RegExp(r'(\d+)\+?\s*years?');
    final yearMatches = yearRegex.allMatches(text);
    int maxYears = 0;
    for (final m in yearMatches) {
      final y = int.tryParse(m.group(1) ?? '0') ?? 0;
      if (y > maxYears) maxYears = y;
    }

    if (RegExp(r'\b(senior|sr\.?|lead|principal|architect|staff|director|manager|head of|vp)\b').hasMatch(text) || maxYears >= 7) {
      experience = 'senior-level';
    } else if (RegExp(r'\b(mid|intermediate|associate|specialist|analyst)\b').hasMatch(text) || maxYears >= 3) {
      experience = 'mid-level';
    } else if (RegExp(r'\b(junior|jr\.?|entry|intern|trainee)\b').hasMatch(text) || maxYears >= 1) {
      experience = 'junior-level';
    }

    // Skills
    const skillKeywords = [
      'javascript', 'python', 'java', 'c++', 'typescript', 'go', 'rust', 'kotlin', 'swift',
      'react', 'vue', 'angular', 'flutter', 'node.js', 'django', 'flask', 'spring',
      'sql', 'postgresql', 'mongodb', 'redis', 'elasticsearch',
      'aws', 'azure', 'gcp', 'docker', 'kubernetes', 'terraform',
      'pandas', 'tensorflow', 'pytorch', 'scikit-learn', 'tableau',
      'git', 'ci/cd', 'linux', 'graphql', 'rest',
    ];
    final keySkills = skillKeywords.where((s) => text.contains(s)).take(8).toList();

    // Achievements (lines with numbers/percentages)
    final achievementRegex = RegExp(
      r'(increased|improved|reduced|delivered|achieved|grew|saved|generated)[^.!?\n]*(\d+%|\d+x|\$\d+)',
      caseSensitive: false,
    );
    final achievements = achievementRegex
        .allMatches(resumeText)
        .map((m) => m.group(0)?.trim() ?? '')
        .where((s) => s.length > 20 && s.length < 150)
        .take(4)
        .toList();

    return {
      'experience': experience,
      'keySkills': keySkills,
      'companies': <String>[],
      'achievements': achievements,
      'analysisQuality': resumeText.length > 200 ? 'detailed' : 'basic',
    };
  }

  /// Build the full system prompt for the interview.
  String getInterviewPrompt(
    String domain,
    String resumeText,
    Map<String, dynamic> analysis,
  ) {
    final template = _domainTemplates[domain] ?? {
      'focus': 'relevant skills and professional experience',
      'style': 'be professional yet conversational, showing genuine interest in their background',
    };

    final experience = analysis['experience'] as String? ?? 'mid-level';
    final keySkills = (analysis['keySkills'] as List?)?.join(', ') ?? 'Various technologies';
    final achievements = (analysis['achievements'] as List?)?.join('\n') ?? '';
    final analysisQuality = analysis['analysisQuality'] as String? ?? 'basic';

    final starter = _conversationStarters[
        DateTime.now().millisecondsSinceEpoch % _conversationStarters.length];

    final experienceContext = _getExperienceContext(experience);

    return '''You are conducting a $domain interview. ${template['style']}.

🎯 CANDIDATE PROFILE:
Experience Level: $experience ($experienceContext)
Key Technologies: $keySkills
Analysis Quality: $analysisQuality

${achievements.isNotEmpty ? '🏆 ACHIEVEMENTS TO EXPLORE:\n$achievements\n' : ''}
📋 RESUME CONTEXT:
${resumeText.length > 1500 ? resumeText.substring(0, 1500) + '...' : resumeText}

🎪 INTERVIEW STRATEGY:
Focus Areas: ${template['focus']}

Your conversation should feel natural and engaging.
- Acknowledge the candidate's answers briefly before moving on.
- Ask ONE focused question at a time.
- Use resume context wherever possible.
- Adapt to students (minimal resume) with project/coursework/motivation questions.
- Sound genuinely curious, not robotic.

PHASE STRUCTURE:
1. OPENING → "$starter"
2. RESUME DEEP DIVE → Ask about projects, technologies, or achievements
3. DOMAIN EXPERTISE → Role-specific scenarios
4. BEHAVIORAL → Leadership, teamwork, problem-solving
5. CLOSING → Career goals

IMPORTANT: Keep responses concise (under 3-4 sentences) to avoid overwhelming audio output.
Start your response with a natural acknowledgement of the candidate's answer.
VARY acknowledgements — do not repeat the same one.''';
  }

  String _getExperienceContext(String level) {
    const contexts = {
      'entry-level': 'Focus on learning, projects, and motivation. Avoid expecting deep work experience.',
      'junior-level': 'Ask about hands-on experience, learning curve, and teamwork.',
      'mid-level': 'Explore ownership, problem-solving, and mentoring experiences.',
      'senior-level': 'Ask about architecture, leadership, and strategic decisions.',
    };
    return contexts[level] ?? contexts['mid-level']!;
  }

  /// Build the final review prompt that asks for a structured JSON report.
  String getReviewPrompt({
    required List<Map<String, String>> qaPairs,
    required List<Map<String, dynamic>> speechMetrics,
    bool endedEarly = false,
  }) {
    final brief = qaPairs.asMap().entries.map((e) {
      final idx = e.key;
      final qa = e.value;
      final m = idx < speechMetrics.length ? speechMetrics[idx] : <String, dynamic>{};
      final wpm = m['wpm'] ?? 0;
      final fillers = m['fillerCount'] ?? 0;
      return 'Q${idx + 1}: ${qa['question']}\nAnswer: ${qa['answer']}\n[Speech Metrics: $wpm words/min, $fillers filler words]';
    }).join('\n\n');

    return '''You are an experienced technical interviewer.
Review the candidate's answers below.
Respond ONLY with strict JSON (no markdown, no commentary).
{
  "score": {
    "overall": number,
    "communication": number,
    "technical": number,
    "problemSolving": number,
    "behavioral": number
  },
  "summary": string,
  "strengths": [string],
  "weaknesses": [string],
  "questions": [
    { "question": string, "yourAnswer": string, "suggestedAnswer": string, "notes": string, "score": number }
  ]
}

Rules:
- Fill all fields.
- Overall 0–100. Per-question score 0–10.
- summary = 3–5 sentences. MUST comment on communication confidence, speech pacing, and filler word usage.
- strengths & weaknesses ≥ 2 items each.
- suggestedAnswer = improved version of candidate's answer.

${endedEarly ? "Interview ended early — judge only provided answers." : ""}

Answers:
$brief''';
  }
}
