import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ai/gemini_assistant_controller.dart';

class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) {
        setState(() => _hasText = hasText);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    setState(() => _hasText = false);
    ref.read(assistantProvider.notifier).sendMessage(text);
  }

  void _sendPredefined(String text) {
    ref.read(assistantProvider.notifier).sendMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assistantProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Auto-scroll when new messages arrive
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF212121) : const Color(0xFFF7F7F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF212121) : const Color(0xFFF7F7F8),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 14,
                    color: isDark ? const Color(0xFF10A37F) : const Color(0xFF0F8667),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Expense GPT',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'New Chat',
            icon: const Icon(Icons.edit_square, size: 20),
            onPressed: () {
              ref.read(assistantProvider.notifier).newChat();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (state.error != null)
            Container(
              color: theme.colorScheme.errorContainer,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              width: double.infinity,
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: theme.colorScheme.onErrorContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.error!,
                      style: TextStyle(fontSize: 13, color: theme.colorScheme.onErrorContainer),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: state.messages.isEmpty
                ? _buildChatGptEmptyState(isDark)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: state.messages.length + (state.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == state.messages.length && state.isLoading) {
                        return _buildChatGptThinking(isDark);
                      }
                      final msg = state.messages[index];
                      return _ChatGptMessageBubble(message: msg, isDark: isDark);
                    },
                  ),
          ),
          _buildChatGptInputBar(state.isLoading, isDark),
        ],
      ),
    );
  }

  /// ChatGPT Initial Load Screen with Central Logo and 4 Modern Prompt Cards
  Widget _buildChatGptEmptyState(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(height: 20),
                Column(
                  children: [
                    // Central ChatGPT circular icon
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? const Color(0xFF2F2F2F) : Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08),
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.auto_awesome,
                          size: 32,
                          color: Color(0xFF10A37F),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'What can I help with?',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: isDark ? Colors.white : const Color(0xFF1D1D1F),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ask questions about your transactions, spending habits, and income.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                // 2x2 Grid of ChatGPT Prompt Cards
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _PromptCard(
                            icon: Icons.calendar_month_outlined,
                            title: 'Monthly summary',
                            prompt: 'How much did I spend this month?',
                            isDark: isDark,
                            onTap: () => _sendPredefined('How much did I spend this month?'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _PromptCard(
                            icon: Icons.pie_chart_outline_rounded,
                            title: 'Top categories',
                            prompt: 'What are my top spending categories?',
                            isDark: isDark,
                            onTap: () => _sendPredefined('What are my top spending categories?'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _PromptCard(
                            icon: Icons.storefront_outlined,
                            title: 'Top merchants',
                            prompt: 'Where did I spend the most money?',
                            isDark: isDark,
                            onTap: () => _sendPredefined('Where did I spend the most money?'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _PromptCard(
                            icon: Icons.receipt_long_outlined,
                            title: 'Recent debits',
                            prompt: 'Show my latest 5 transactions',
                            isDark: isDark,
                            onTap: () => _sendPredefined('Show my latest 5 transactions'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  /// ChatGPT Style Animated Thinking Indicator
  Widget _buildChatGptThinking(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF10A37F),
            ),
            child: const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2F2F2F) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PulsingDot(delay: 0, isDark: isDark),
                const SizedBox(width: 4),
                _PulsingDot(delay: 150, isDark: isDark),
                const SizedBox(width: 4),
                _PulsingDot(delay: 300, isDark: isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ChatGPT Capsule Input Bar
  Widget _buildChatGptInputBar(bool isLoading, bool isDark) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2F2F2F) : Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.12),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  keyboardType: TextInputType.text,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Message Expense Assistant...',
                    hintStyle: TextStyle(
                      fontSize: 15,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _hasText && !isLoading
                      ? (isDark ? Colors.white : Colors.black87)
                      : (isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.1)),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.arrow_upward_rounded,
                    size: 20,
                    color: _hasText && !isLoading
                        ? (isDark ? Colors.black87 : Colors.white)
                        : (isDark ? Colors.white38 : Colors.black38),
                  ),
                  onPressed: (_hasText && !isLoading) ? _send : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Prompt Suggestion Card styled after ChatGPT's mobile home cards
class _PromptCard extends StatelessWidget {
  const _PromptCard({
    required this.icon,
    required this.title,
    required this.prompt,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String prompt;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2F2F2F) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 20,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                prompt,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.3,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Message Bubble styled after ChatGPT's clean feed
class _ChatGptMessageBubble extends StatelessWidget {
  const _ChatGptMessageBubble({required this.message, required this.isDark});
  final ChatMessage message;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    if (message.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, left: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2F2F2F) : const Color(0xFFE9E9EB),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            message.text,
            style: TextStyle(
              fontSize: 15,
              height: 1.4,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
      );
    }

    // AI message (Left aligned with ChatGPT avatar)
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(top: 2),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF10A37F),
            ),
            child: const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FormattedMarkdownText(text: message.text, isDark: isDark),
                const SizedBox(height: 6),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    Icons.copy_rounded,
                    size: 16,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  tooltip: 'Copy response',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: message.text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copied to clipboard'),
                        duration: Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Lightweight parser to render **bold** text and lists gracefully without external libraries
class _FormattedMarkdownText extends StatelessWidget {
  const _FormattedMarkdownText({required this.text, required this.isDark});
  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final baseColor = isDark ? Colors.white : const Color(0xFF1D1D1F);
    final spans = <TextSpan>[];

    // Regex to split **bold** markers
    final regex = RegExp(r'\*\*(.*?)\*\*');
    int lastIndex = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(text: text.substring(lastIndex, match.start)));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ));
      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex)));
    }

    return Text.rich(
      TextSpan(children: spans),
      style: TextStyle(
        fontSize: 15,
        height: 1.5,
        color: baseColor,
      ),
    );
  }
}

/// Animated pulsing dot for ChatGPT thinking state
class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.delay, required this.isDark});
  final int delay;
  final bool isDark;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.isDark ? Colors.white70 : Colors.black54,
        ),
      ),
    );
  }
}
