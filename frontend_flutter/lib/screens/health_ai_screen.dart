import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../widgets/app_bottom_bar.dart';

class HealthAiScreen extends StatefulWidget {
  const HealthAiScreen({super.key});

  @override
  State<HealthAiScreen> createState() => _HealthAiScreenState();
}

class _HealthAiScreenState extends State<HealthAiScreen> {
  final TextEditingController _queryController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _quickPrompts = const [
    'I have fever and body pain',
    'Dry cough with sore throat',
    'Mild headache after screen use',
    'Stomach acidity after meals',
    'Seasonal cold and sneezing',
    'Light weakness and dehydration',
  ];

  late final List<_ChatMessage> _messages = [
    const _ChatMessage.assistant(
      text:
          'Describe your symptoms in simple words. I will respond with likely causes, precautions, medicines to discuss, and when to seek medical care.',
    ),
  ];

  bool _isLoading = false;

  @override
  void dispose() {
    _queryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _applyPrompt(String prompt) {
    _queryController.text = prompt;
    _submitQuery();
  }

  Future<void> _submitQuery() async {
    final query = _queryController.text.trim();
    if (query.isEmpty || _isLoading) return;

    FocusScope.of(context).unfocus();
    _queryController.clear();

    setState(() {
      _isLoading = true;
      _messages.add(_ChatMessage.user(text: query));
      _messages.add(const _ChatMessage.assistantTyping());
    });
    _scrollToBottom();

    final response = await ApiService().analyzeSymptoms(query);
    if (!mounted) return;

    final advice = _HealthAiAdvice.fromApiResponse(response);
    setState(() {
      _isLoading = false;
      if (_messages.isNotEmpty && _messages.last.isTyping) {
        _messages.removeLast();
      }
      _messages.add(_ChatMessage.assistant(text: advice.summary, advice: advice));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FC),
      bottomNavigationBar: const AppBottomBar(selectedItem: 'Health AI'),
      appBar: AppBar(
        title: const Text('Health AI'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF1F2430),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEAF6FF), Color(0xFFF6F0FF), Color(0xFFF8FAFD)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                  children: [
                    const _ConversationHero(),
                    const SizedBox(height: 16),
                    const _SafetyBanner(),
                    const SizedBox(height: 16),
                    _QuickPromptTray(
                      prompts: _quickPrompts,
                      onPromptTap: _applyPrompt,
                    ),
                    const SizedBox(height: 18),
                    ..._messages.map((message) => _ChatBubble(message: message)),
                  ],
                ),
              ),
              _ComposerBar(
                controller: _queryController,
                isLoading: _isLoading,
                onSend: _submitQuery,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConversationHero extends StatelessWidget {
  const _ConversationHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E2C45), Color(0xFF31476F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16000000),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Color(0x26FFFFFF),
                child: Icon(
                  Icons.favorite_rounded,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Chat with Health AI',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Tell me what you are feeling, how long it has been happening, and any details like fever, cough, pain, or fatigue.',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Color(0xFFD9E6FF),
            ),
          ),
        ],
      ),
    );
  }
}

class _SafetyBanner extends StatelessWidget {
  const _SafetyBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF3D795)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: Color(0xFFAA7A15)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Supportive guidance only. Use a doctor or emergency care for severe, worsening, or persistent symptoms.',
              style: TextStyle(
                height: 1.4,
                color: Color(0xFF6D5619),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickPromptTray extends StatelessWidget {
  final List<String> prompts;
  final ValueChanged<String> onPromptTap;

  const _QuickPromptTray({
    required this.prompts,
    required this.onPromptTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick prompts',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1F2430),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: prompts.length,
            separatorBuilder: (_, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final prompt = prompts[index];
              return ActionChip(
                onPressed: () => onPromptTap(prompt),
                backgroundColor: Colors.white.withValues(alpha: 0.96),
                side: BorderSide(
                  color: const Color(0xFFD9E2F0).withValues(alpha: 0.9),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                label: Text(prompt),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final _ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == _MessageRole.user;
    final bubbleColor = isUser
        ? const Color(0xFF243148)
        : Colors.white.withValues(alpha: 0.96);
    final textColor = isUser ? Colors.white : const Color(0xFF364152);
    final crossAxisAlignment = isUser
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;
    final align = isUser ? Alignment.centerRight : Alignment.centerLeft;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: crossAxisAlignment,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: isUser
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              children: [
                if (!isUser)
                  const CircleAvatar(
                    radius: 14,
                    backgroundColor: Color(0xFFDBE9FF),
                    child: Icon(
                      Icons.health_and_safety_rounded,
                      size: 16,
                      color: Color(0xFF315EA8),
                    ),
                  ),
                if (!isUser) const SizedBox(width: 8),
                Text(
                  isUser ? 'You' : 'Health AI',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF7A8494),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: align,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: isUser
                      ? const []
                      : const [
                          BoxShadow(
                            color: Color(0x12000000),
                            blurRadius: 14,
                            offset: Offset(0, 8),
                          ),
                        ],
                ),
                child: message.isTyping
                    ? const _TypingIndicator()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.text,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: textColor,
                              fontWeight: message.advice == null
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                            ),
                          ),
                          if (message.advice != null) ...[
                            const SizedBox(height: 14),
                            _AdviceSummaryCard(advice: message.advice!),
                          ],
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

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
          decoration: BoxDecoration(
            color: const Color(0xFF92A2BC).withValues(alpha: 0.85),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _AdviceSummaryCard extends StatelessWidget {
  final _HealthAiAdvice advice;

  const _AdviceSummaryCard({required this.advice});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F9FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDE7F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (advice.prediction.isNotEmpty)
                _StatusPill(
                  text: 'Possible ${advice.prediction}',
                  textColor: const Color(0xFF315EA8),
                  backgroundColor: const Color(0xFFDEEAFE),
                ),
              _StatusPill(
                text: 'Confidence ${advice.confidenceLabel}',
                textColor: advice.urgency == 'high'
                    ? const Color(0xFFB4515C)
                    : const Color(0xFF546274),
                backgroundColor: advice.urgency == 'high'
                    ? const Color(0xFFFFE6EA)
                    : const Color(0xFFE9EFF8),
              ),
              _StatusPill(
                text: 'Urgency ${advice.urgencyLabel}',
                textColor: advice.urgency == 'high'
                    ? const Color(0xFFB4515C)
                    : const Color(0xFF4D7B5E),
                backgroundColor: advice.urgency == 'high'
                    ? const Color(0xFFFFE6EA)
                    : const Color(0xFFE6F6EA),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SectionText(
            title: 'Best next step',
            body: advice.recommendation,
          ),
          if (advice.precautions.isNotEmpty) ...[
            const SizedBox(height: 12),
            _SectionList(
              title: 'Precautions',
              items: advice.precautions,
            ),
          ],
          if (advice.medicines.isNotEmpty) ...[
            const SizedBox(height: 12),
            _SectionList(
              title: 'Medicines to discuss',
              items: advice.medicines,
            ),
          ],
          const SizedBox(height: 12),
          _SectionText(
            title: 'When to seek care',
            body: advice.seekCare,
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;
  final Color textColor;
  final Color backgroundColor;

  const _StatusPill({
    required this.text,
    required this.textColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

class _SectionText extends StatelessWidget {
  final String title;
  final String body;

  const _SectionText({
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1F2430),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          body,
          style: const TextStyle(
            fontSize: 13,
            height: 1.45,
            color: Color(0xFF556070),
          ),
        ),
      ],
    );
  }
}

class _SectionList extends StatelessWidget {
  final String title;
  final List<String> items;

  const _SectionList({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1F2430),
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => _BulletLine(text: item)),
      ],
    );
  }
}

class _BulletLine extends StatelessWidget {
  final String text;

  const _BulletLine({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 7,
            height: 7,
            margin: const EdgeInsets.only(top: 6),
            decoration: const BoxDecoration(
              color: Color(0xFF5F8EF6),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                height: 1.45,
                color: Color(0xFF525B6B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComposerBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSend;

  const _ComposerBar({
    required this.controller,
    required this.isLoading,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FB),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFDDE5F0)),
                ),
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  decoration: const InputDecoration(
                    hintText: 'Type your symptoms here...',
                    hintStyle: TextStyle(color: Color(0xFF8A93A3)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.fromLTRB(16, 14, 16, 14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 54,
              height: 54,
              child: ElevatedButton(
                onPressed: isLoading ? null : onSend,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF243148),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
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

enum _MessageRole { user, assistant }

class _ChatMessage {
  final _MessageRole role;
  final String text;
  final _HealthAiAdvice? advice;
  final bool isTyping;

  const _ChatMessage._({
    required this.role,
    required this.text,
    this.advice,
    this.isTyping = false,
  });

  const _ChatMessage.user({required String text})
    : this._(role: _MessageRole.user, text: text);

  const _ChatMessage.assistant({
    required String text,
    _HealthAiAdvice? advice,
  }) : this._(role: _MessageRole.assistant, text: text, advice: advice);

  const _ChatMessage.assistantTyping()
    : this._(role: _MessageRole.assistant, text: '', isTyping: true);
}

class _HealthAiAdvice {
  final String title;
  final String summary;
  final String recommendation;
  final List<String> precautions;
  final List<String> medicines;
  final String seekCare;
  final String prediction;
  final double confidence;
  final String urgency;

  const _HealthAiAdvice({
    required this.title,
    required this.summary,
    required this.recommendation,
    required this.precautions,
    required this.medicines,
    required this.seekCare,
    required this.prediction,
    required this.confidence,
    required this.urgency,
  });

  factory _HealthAiAdvice.fromApiResponse(Map<String, dynamic> response) {
    if ((response['status_code'] ?? 200) >= 400 ||
        response['prediction'] == null) {
      return _HealthAiAdvice(
        title: 'Analysis unavailable',
        summary:
            response['message']?.toString() ??
            'Could not analyze symptoms right now.',
        recommendation:
            'Try again with clearer symptoms, or use a clinician if the situation feels urgent.',
        precautions: const [
          'Do not rely only on the app for emergency symptoms.',
          'Track whether symptoms are worsening or spreading.',
        ],
        medicines: const [
          'Avoid starting new medicines without clinician advice.',
        ],
        seekCare: 'Seek in-person medical advice if symptoms are concerning.',
        prediction: '',
        confidence: 0,
        urgency: 'medium',
      );
    }

    final prediction = response['prediction']?.toString() ?? '';
    final confidence = ((response['confidence'] ?? 0) as num).toDouble();
    final recommendations =
        (response['recommendations'] as List<dynamic>? ?? const [])
            .map((item) => item.toString())
            .toList();

    return _HealthAiAdvice(
      title: prediction.isEmpty ? 'AI Symptom Review' : 'Possible $prediction',
      summary:
          response['explanation']?.toString() ??
          'The system analyzed the symptom text.',
      recommendation: recommendations.isNotEmpty
          ? recommendations.first
          : 'Track symptoms and arrange medical review if they continue.',
      precautions: (response['precautions'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      medicines:
          (response['recommended_medicines'] as List<dynamic>? ?? const [])
              .map((item) => item.toString())
              .toList(),
      seekCare:
          response['seek_care']?.toString() ??
          'Consult a doctor if symptoms persist or worsen.',
      prediction: prediction,
      confidence: confidence,
      urgency: response['urgency']?.toString() ?? 'medium',
    );
  }

  String get confidenceLabel => '${(confidence * 100).toStringAsFixed(1)}%';

  String get urgencyLabel {
    switch (urgency.toLowerCase()) {
      case 'high':
        return 'High';
      case 'low':
        return 'Low';
      default:
        return 'Medium';
    }
  }
}
