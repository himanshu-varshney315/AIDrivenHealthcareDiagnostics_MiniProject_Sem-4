import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_exceptions.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bottom_bar.dart';
import '../widgets/app_ui.dart';

class HealthAiScreen extends StatefulWidget {
  const HealthAiScreen({super.key});

  @override
  State<HealthAiScreen> createState() => _HealthAiScreenState();
}

class _HealthAiScreenState extends State<HealthAiScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_Message> _messages = [
    const _Message.ai(
      'Tell me what you feel, when it started, and how strong it is. I will turn it into clear care guidance.',
    ),
  ];
  bool _loading = false;

  static const _prompts = [
    'Fever and body ache since yesterday',
    'Dry cough with sore throat',
    'Headache after screen use',
    'Vomiting and dehydration',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send([String? prompt]) async {
    final text = (prompt ?? _controller.text).trim();
    if (text.isEmpty || _loading) return;
    _controller.clear();
    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _messages.add(_Message.user(text));
    });
    _jumpBottom();

    try {
      final response = await ApiService().analyzeSymptoms(text);
      final advice = _Advice.fromResponse(response);
      await NotificationService().add(
        title: advice.prediction.isEmpty
            ? 'Symptom analysis unavailable'
            : 'Symptom analysis complete',
        body: advice.prediction.isEmpty
            ? advice.summary
            : '${advice.prediction} guidance is ready.',
        severity: advice.urgency == 'high' ? 'Critical' : 'Healthy',
      );
      if (!mounted) return;
      setState(() {
        _loading = false;
        _messages.add(_Message.ai(advice.summary, advice: advice));
      });
      _jumpBottom();
    } on ForbiddenException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _messages.add(_Message.ai(error.message));
      });
      _jumpBottom();
    } on AuthException {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _messages.add(
          const _Message.ai(
            'Please sign in again to continue symptom analysis.',
          ),
        );
      });
      _jumpBottom();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _messages.add(
          const _Message.ai('Symptom analysis is unavailable right now.'),
        );
      });
      _jumpBottom();
    }
  }

  void _jumpBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 180,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      bottomNavigationBar: const AppBottomBar(selectedItem: 'Health AI'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                children: [
                  AppHeader(
                    eyebrow: 'Assistant',
                    title: 'Health AI',
                    subtitle:
                        'Describe symptoms in plain language and get guided next steps.',
                    trailing: const AppIconButton(
                      icon: Icons.auto_awesome_rounded,
                    ),
                  ),
                  const SizedBox(height: 20),
                  AppCard(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: AppTheme.heroGradient,
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AppBadge(
                          text: 'Patient-first guidance',
                          color: Colors.white,
                          backgroundColor: Color(0x29FFFFFF),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Share what changed today',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Include when symptoms started, how strong they feel, and anything that makes them better or worse.',
                          style: TextStyle(
                            color: Colors.white,
                            height: 1.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  AppCard(
                    color: AppTheme.softSurface,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Try a quick starter',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _prompts
                              .map(
                                (prompt) => ActionChip(
                                  onPressed: () => _send(prompt),
                                  avatar: const Icon(
                                    Icons.bolt_rounded,
                                    size: 18,
                                  ),
                                  label: Text(prompt),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  ..._messages.map((message) => _Bubble(message: message)),
                  if (_loading)
                    const _Bubble(
                      message: _Message.ai('Analyzing symptoms...'),
                      loading: true,
                    ),
                ],
              ),
            ),
            _Composer(
              controller: _controller,
              loading: _loading,
              onSend: () => _send(),
            ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final bool loading;
  final VoidCallback onSend;

  const _Composer({
    required this.controller,
    required this.loading,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: const InputDecoration(
                  hintText: 'Describe symptoms in your own words...',
                  prefixIcon: Icon(Icons.edit_note_rounded),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 56,
              height: 56,
              child: ElevatedButton(
                onPressed: loading ? null : onSend,
                style: ElevatedButton.styleFrom(padding: EdgeInsets.zero),
                child: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.arrow_upward_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final _Message message;
  final bool loading;

  const _Bubble({required this.message, this.loading = false});

  @override
  Widget build(BuildContext context) {
    final isUser = message.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        constraints: const BoxConstraints(maxWidth: 380),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.navy : Colors.white,
          borderRadius: BorderRadius.circular(24).copyWith(
            bottomRight: Radius.circular(isUser ? 10 : 24),
            bottomLeft: Radius.circular(isUser ? 24 : 10),
          ),
          border: isUser ? null : Border.all(color: AppTheme.border),
          boxShadow: isUser
              ? null
              : const [
                  BoxShadow(
                    color: Color(0x10000000),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
        ),
        child: loading
            ? const _Typing()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isUser ? Colors.white : AppTheme.textPrimary,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (message.advice != null) ...[
                    const SizedBox(height: 14),
                    _AdviceCard(advice: message.advice!),
                  ],
                ],
              ),
      ),
    );
  }
}

class _Typing extends StatelessWidget {
  const _Typing();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        3,
        (index) => Container(
          width: 8,
          height: 8,
          margin: EdgeInsets.only(right: index == 2 ? 0 : 6),
          decoration: const BoxDecoration(
            color: AppTheme.textMuted,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _AdviceCard extends StatelessWidget {
  final _Advice advice;

  const _AdviceCard({required this.advice});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.softSurface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniBadge('Possible ${advice.prediction}', AppTheme.blue),
              _MiniBadge(advice.confidenceLabel, AppTheme.aqua),
              _MiniBadge(advice.urgency.toUpperCase(), AppTheme.coral),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            advice.recommendation,
            style: const TextStyle(color: AppTheme.textMuted, height: 1.45),
          ),
          if (advice.extractedSymptoms.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: advice.extractedSymptoms
                  .map((item) => _MiniBadge(item, AppTheme.blue))
                  .toList(),
            ),
          ],
          if (advice.probabilities.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...advice.probabilities
                .take(3)
                .map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Text(
                          '${(entry.value * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: AppTheme.blue,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
          if (advice.seekCare.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              advice.seekCare,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ],
          if (advice.precautions.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...advice.precautions
                .take(2)
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        height: 1.35,
                      ),
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _MiniBadge(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _Message {
  final String text;
  final bool user;
  final _Advice? advice;

  const _Message._(this.text, {required this.user, this.advice});
  const _Message.user(String text) : this._(text, user: true);
  const _Message.ai(String text, {_Advice? advice})
    : this._(text, user: false, advice: advice);
}

class _Advice {
  final String summary;
  final String prediction;
  final double confidence;
  final String urgency;
  final String recommendation;
  final String seekCare;
  final List<String> extractedSymptoms;
  final List<String> precautions;
  final List<MapEntry<String, double>> probabilities;

  const _Advice({
    required this.summary,
    required this.prediction,
    required this.confidence,
    required this.urgency,
    required this.recommendation,
    required this.seekCare,
    required this.extractedSymptoms,
    required this.precautions,
    required this.probabilities,
  });

  factory _Advice.fromResponse(Map<String, dynamic> response) {
    if ((response['status_code'] ?? 200) >= 400 ||
        response['prediction'] == null) {
      return _Advice(
        summary: response['message']?.toString() ?? 'Analysis unavailable.',
        prediction: '',
        confidence: 0,
        urgency: 'medium',
        recommendation: 'Try again with clearer symptom details.',
        seekCare: 'Use urgent care for severe or worsening symptoms.',
        extractedSymptoms: const [],
        precautions: const [],
        probabilities: const [],
      );
    }
    final recommendations =
        (response['recommendations'] as List<dynamic>? ?? const [])
            .map((item) => item.toString())
            .toList();
    final probabilities =
        (response['probabilities'] as Map<String, dynamic>? ?? const {}).entries
            .map(
              (entry) =>
                  MapEntry(entry.key, (entry.value as num?)?.toDouble() ?? 0),
            )
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    final extractedSymptoms =
        (response['extracted_symptoms'] as List<dynamic>? ?? const [])
            .map((item) => item.toString())
            .toList();
    final precautions = (response['precautions'] as List<dynamic>? ?? const [])
        .map((item) => item.toString())
        .toList();

    return _Advice(
      summary:
          response['explanation']?.toString() ??
          'The system analyzed your symptoms.',
      prediction: response['prediction']?.toString() ?? '',
      confidence: ((response['confidence'] ?? 0) as num).toDouble(),
      urgency: response['urgency']?.toString().toLowerCase() ?? 'medium',
      recommendation: recommendations.isEmpty
          ? 'Track symptoms and arrange medical review if they continue.'
          : recommendations.first,
      seekCare: response['seek_care']?.toString() ?? '',
      extractedSymptoms: extractedSymptoms,
      precautions: precautions,
      probabilities: probabilities,
    );
  }

  String get confidenceLabel => '${(confidence * 100).toStringAsFixed(1)}%';
}
