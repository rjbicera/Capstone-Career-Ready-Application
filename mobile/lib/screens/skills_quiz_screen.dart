import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class _Question {
  const _Question({
    required this.text,
    required this.options,
    required this.correctIndex,
  });

  final String text;
  final List<String> options;
  final int correctIndex;
}

/// Question banks are intentionally small/illustrative — swap these
/// for a Firestore-backed question set once the backend module is ready.
const Map<String, List<_Question>> _questionBanks = {
  'Networking fundamentals': [
    _Question(
      text: 'Which OSI layer is responsible for routing between networks?',
      options: ['Data Link', 'Network', 'Transport', 'Session'],
      correctIndex: 1,
    ),
    _Question(
      text: 'What does DHCP automatically assign to devices on a network?',
      options: ['MAC addresses', 'DNS records', 'IP addresses', 'VLAN tags'],
      correctIndex: 2,
    ),
    _Question(
      text: 'Which protocol is connection-oriented and guarantees delivery?',
      options: ['UDP', 'ICMP', 'TCP', 'ARP'],
      correctIndex: 2,
    ),
    _Question(
      text: 'A /24 subnet mask allows how many usable host addresses?',
      options: ['254', '256', '128', '512'],
      correctIndex: 0,
    ),
    _Question(
      text: 'Which device operates primarily at Layer 2 of the OSI model?',
      options: ['Router', 'Switch', 'Firewall', 'Load balancer'],
      correctIndex: 1,
    ),
  ],
  'Cloud fundamentals': [
    _Question(
      text: 'Which cloud model gives the most control over the OS and runtime?',
      options: ['SaaS', 'PaaS', 'IaaS', 'FaaS'],
      correctIndex: 2,
    ),
    _Question(
      text: 'What is the main benefit of horizontal scaling?',
      options: [
        'Upgrading a single server\'s hardware',
        'Adding more servers to share the load',
        'Reducing the number of servers',
        'Encrypting data at rest',
      ],
      correctIndex: 1,
    ),
    _Question(
      text: 'Which service type is Firebase Firestore an example of?',
      options: [
        'Relational database',
        'NoSQL document database',
        'Object storage',
        'In-memory cache',
      ],
      correctIndex: 1,
    ),
    _Question(
      text: 'What does a CDN primarily improve?',
      options: [
        'Database consistency',
        'Content delivery latency',
        'Server-side authentication',
        'API rate limiting',
      ],
      correctIndex: 1,
    ),
    _Question(
      text: 'Which practice best supports zero-downtime deployments?',
      options: [
        'Manual server restarts',
        'Blue-green deployment',
        'Single fixed instance',
        'Disabling load balancers',
      ],
      correctIndex: 1,
    ),
  ],
  'Security basics': [
    _Question(
      text: 'What does the "principle of least privilege" mean?',
      options: [
        'Giving all users admin access',
        'Granting only the access needed to do a task',
        'Disabling all permissions by default',
        'Encrypting all least-used files',
      ],
      correctIndex: 1,
    ),
    _Question(
      text: 'Which of these is a form of multi-factor authentication?',
      options: [
        'Password + password',
        'Password + one-time code',
        'Username only',
        'CAPTCHA only',
      ],
      correctIndex: 1,
    ),
    _Question(
      text: 'What is the main risk of storing plaintext passwords?',
      options: [
        'Slower login times',
        'Immediate compromise if the database leaks',
        'Higher storage costs',
        'Reduced uptime',
      ],
      correctIndex: 1,
    ),
    _Question(
      text: 'Which attack tricks users into revealing credentials via fake emails/sites?',
      options: ['DDoS', 'Phishing', 'SQL injection', 'Brute force'],
      correctIndex: 1,
    ),
    _Question(
      text: 'What does HTTPS add on top of HTTP?',
      options: [
        'Faster page loads',
        'Encrypted transport via TLS/SSL',
        'Automatic caching',
        'Larger request limits',
      ],
      correctIndex: 1,
    ),
  ],
};

class SkillsQuizScreen extends StatefulWidget {
  const SkillsQuizScreen({super.key, required this.category});

  final String category;

  @override
  State<SkillsQuizScreen> createState() => _SkillsQuizScreenState();
}

class _SkillsQuizScreenState extends State<SkillsQuizScreen> {
  late final List<_Question> _questions;
  int _current = 0;
  int? _selectedOption;
  int _correctCount = 0;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _questions = _questionBanks[widget.category] ?? [];
  }

  void _selectOption(int index) {
    if (_selectedOption != null) return; // lock after first choice
    setState(() {
      _selectedOption = index;
      if (index == _questions[_current].correctIndex) {
        _correctCount++;
      }
    });
  }

  void _next() {
    if (_current < _questions.length - 1) {
      setState(() {
        _current++;
        _selectedOption = null;
      });
    } else {
      setState(() => _finished = true);
    }
  }

  void _finish() {
    final scorePercent = _questions.isEmpty
        ? 0.0
        : _correctCount / _questions.length;
    Navigator.of(context).pop(scorePercent);
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.textPrimary),
        ),
        body: const Center(
          child: Text('No questions available for this category yet.'),
        ),
      );
    }

    if (_finished) {
      final scorePercent = (_correctCount / _questions.length * 100).round();
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$scorePercent%',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Assessment complete',
                    style: AppTextStyles.title.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You got $_correctCount out of ${_questions.length} correct in ${widget.category}.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: _finish,
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final question = _questions[_current];
    final progress = (_current + 1) / _questions.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          widget.category,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Question ${_current + 1} of ${_questions.length}',
                style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                question.text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),

              ...List.generate(question.options.length, (index) {
                final isSelected = _selectedOption == index;
                final isCorrect = index == question.correctIndex;
                final hasAnswered = _selectedOption != null;

                Color borderColor = AppColors.border;
                Color bgColor = Colors.white;
                if (hasAnswered) {
                  if (isCorrect) {
                    borderColor = AppColors.primary;
                    bgColor = AppColors.primaryLight;
                  } else if (isSelected && !isCorrect) {
                    borderColor = AppColors.danger;
                    bgColor = const Color(0xFFFCEBEB);
                  }
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      onTap: () => _selectOption(index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(color: borderColor, width: 1.4),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                question.options[index],
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (hasAnswered && isCorrect)
                              const Icon(Icons.check_circle_rounded,
                                  size: 18, color: AppColors.primary),
                            if (hasAnswered && isSelected && !isCorrect)
                              const Icon(Icons.cancel_rounded,
                                  size: 18, color: AppColors.danger),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),

              const Spacer(),

              ElevatedButton(
                onPressed: _selectedOption == null ? null : _next,
                child: Text(
                  _current < _questions.length - 1 ? 'Next question' : 'See results',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
