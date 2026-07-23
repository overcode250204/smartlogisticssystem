import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartlogisticssystem/core/app_theme.dart';
import 'package:smartlogisticssystem/feature/admin_ai/models/admin_ai_chat_models.dart';
import 'package:smartlogisticssystem/feature/admin_ai/service/admin_ai_assistant_service.dart';
import 'package:smartlogisticssystem/widgets/api_error_message.dart';
import 'package:smartlogisticssystem/widgets/dashboard_widgets.dart';

class AdminAiAssistantPage extends StatefulWidget {
  const AdminAiAssistantPage({super.key});

  @override
  State<AdminAiAssistantPage> createState() => _AdminAiAssistantPageState();
}

class _AdminAiAssistantPageState extends State<AdminAiAssistantPage> {
  static const _timeFilters = [
    _TimeFilterOption('TODAY', 'Hôm nay'),
    _TimeFilterOption('WEEK', 'Tuần này'),
    _TimeFilterOption('MONTH', 'Tháng này'),
  ];

  static const _suggestedQuestions = [
    'Tình hình vận hành tháng này thế nào?',
    'Có điểm nghẽn nào trong đơn hàng hoặc chuyến xe không?',
    'Tồn kho thấp đang tập trung ở nhóm hàng nào?',
    'Có cảnh báo giao hàng nào cần ưu tiên xử lý không?',
  ];

  final AdminAiAssistantService _service = AdminAiAssistantService();
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<AdminAiConversationMessage> _messages = [];

  String _timeFilter = 'MONTH';
  bool _isSending = false;
  String? _errorMessage;

  @override
  void dispose() {
    _questionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendQuestion([String? question]) async {
    final submittedQuestion = (question ?? _questionController.text).trim();
    if (submittedQuestion.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
      _errorMessage = null;
      _messages.add(
        AdminAiConversationMessage(
          content: submittedQuestion,
          createdAt: DateTime.now(),
          fromUser: true,
        ),
      );
      _questionController.clear();
    });
    _scrollToBottom();

    try {
      final response = await _service.chat(
        question: submittedQuestion,
        timeFilter: _timeFilter,
      );
      if (!mounted) return;

      setState(() {
        _messages.add(
          AdminAiConversationMessage(
            content: response.answer,
            createdAt: DateTime.now(),
            fromUser: false,
            response: response,
          ),
        );
      });
      _scrollToBottom();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = apiErrorMessage(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageScroll(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 18),
            _buildFilters(),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 1000;
                if (isCompact) {
                  return Column(
                    children: [
                      _buildConversationPanel(),
                      const SizedBox(height: 16),
                      _buildOperationsPanel(),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: _buildConversationPanel()),
                    const SizedBox(width: 18),
                    Expanded(flex: 3, child: _buildOperationsPanel()),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle('Trợ lý vận hành AI'),
            SizedBox(height: 6),
            Text(
              'Tra cứu dữ liệu vận hành và nhận gợi ý xử lý cho Admin.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Text(
          'Cập nhật lúc: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Phạm vi dữ liệu:',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          for (final option in _timeFilters)
            ChoiceChip(
              label: Text(option.label),
              selected: _timeFilter == option.value,
              labelStyle: TextStyle(
                color: _timeFilter == option.value
                    ? Colors.white
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
              selectedColor: AppColors.primary,
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: _timeFilter == option.value
                      ? AppColors.primary
                      : AppColors.border,
                ),
              ),
              onSelected: _isSending
                  ? null
                  : (selected) {
                      if (!selected) return;
                      setState(() {
                        _timeFilter = option.value;
                      });
                    },
            ),
        ],
      ),
    );
  }

  Widget _buildConversationPanel() {
    return DashboardCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _buildConversationHeader(),
          const Divider(height: 1, color: AppColors.border),
          SizedBox(
            height: 520,
            child: _messages.isEmpty
                ? _buildEmptyConversation()
                : ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(18),
                    itemCount: _messages.length + (_isSending ? 1 : 0),
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      if (_isSending && index == _messages.length) {
                        return const _ThinkingBubble();
                      }
                      return _MessageBubble(message: _messages[index]);
                    },
                  ),
          ),
          if (_errorMessage != null) _buildErrorBanner(),
          const Divider(height: 1, color: AppColors.border),
          _buildComposer(),
        ],
      ),
    );
  }

  Widget _buildConversationHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.psychology_alt_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hỏi đáp vận hành',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Dựa trên dữ liệu đơn hàng, chuyến xe, kho, tồn kho và cảnh báo.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (_messages.isNotEmpty)
            IconButton(
              tooltip: 'Xóa hội thoại',
              onPressed: _isSending
                  ? null
                  : () {
                      setState(() {
                        _messages.clear();
                        _errorMessage = null;
                      });
                    },
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyConversation() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.manage_search_outlined,
                  color: AppColors.primary,
                  size: 34,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Bắt đầu bằng một câu hỏi vận hành cụ thể.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Bạn có thể hỏi theo tình hình tổng quan, điểm nghẽn, tồn kho, chuyến xe hoặc cảnh báo cần ưu tiên.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: _suggestedQuestions
                    .map(
                      (question) => ActionChip(
                        label: Text(question),
                        avatar: const Icon(Icons.bolt_outlined, size: 16),
                        onPressed: _isSending
                            ? null
                            : () => _sendQuestion(question),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComposer() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _questionController,
              enabled: !_isSending,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                hintText: 'Nhập câu hỏi cho trợ lý vận hành...',
                prefixIcon: Icon(Icons.chat_bubble_outline),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isSending ? null : () => _sendQuestion(),
              icon: _isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(_isSending ? 'Đang hỏi' : 'Gửi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationsPanel() {
    AdminAiChatResponse? latestResponse;
    for (final message in _messages.reversed) {
      if (message.response != null) {
        latestResponse = message.response;
        break;
      }
    }

    return Column(
      children: [
        _buildScopeCard(),
        const SizedBox(height: 16),
        if (latestResponse != null) _buildLatestResponseCard(latestResponse),
      ],
    );
  }

  Widget _buildScopeCard() {
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.dataset_outlined, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Dữ liệu đang tra cứu',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _DataScopeRow(
            icon: Icons.dashboard_customize_outlined,
            label: 'Thống kê vận chuyển',
            value: _selectedTimeLabel,
          ),
          const _DataScopeRow(
            icon: Icons.inventory_2_outlined,
            label: 'Đơn hàng và cảnh báo',
            value: 'Theo dữ liệu DB chính',
          ),
          const _DataScopeRow(
            icon: Icons.local_shipping_outlined,
            label: 'Chuyến xe và phương tiện',
            value: 'Linehaul, local trip, fleet',
          ),
          const _DataScopeRow(
            icon: Icons.warehouse_outlined,
            label: 'Tồn kho',
            value: 'Các batch thấp tồn',
          ),
        ],
      ),
    );
  }

  Widget _buildLatestResponseCard(AdminAiChatResponse response) {
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SeverityBadge(severity: response.severity),
              const Spacer(),
              Text(
                '${(response.confidence * 100).round()}%',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (response.usedData.isNotEmpty) ...[
            const Text(
              'Nguồn dữ liệu',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: response.usedData
                  .map(
                    (item) => Chip(
                      label: Text(item),
                      visualDensity: VisualDensity.compact,
                      side: const BorderSide(color: AppColors.border),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (response.fallback) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Hãy thử hỏi cụ thể hơn theo mã đơn, mã chuyến, kho hoặc khoảng thời gian.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String get _selectedTimeLabel {
    return _timeFilters
        .firstWhere((option) => option.value == _timeFilter)
        .label;
  }
}

class _TimeFilterOption {
  final String value;
  final String label;

  const _TimeFilterOption(this.value, this.label);
}

class _MessageBubble extends StatelessWidget {
  final AdminAiConversationMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final response = message.response;
    final alignment = message.fromUser
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;
    final bubbleColor = message.fromUser
        ? AppColors.primary
        : AppColors.darkest;
    final textColor = message.fromUser ? Colors.white : AppColors.textPrimary;

    return Column(
      crossAxisAlignment: alignment,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(10),
              border: message.fromUser
                  ? null
                  : Border.all(color: AppColors.border),
            ),
            child: Text(
              message.content,
              style: TextStyle(
                color: textColor,
                height: 1.45,
                fontWeight: message.fromUser
                    ? FontWeight.w700
                    : FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          DateFormat('HH:mm').format(message.createdAt),
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (response != null) ...[
          const SizedBox(height: 10),
          _ResponseDetails(response: response),
        ],
      ],
    );
  }
}

class _ResponseDetails extends StatelessWidget {
  final AdminAiChatResponse response;

  const _ResponseDetails({required this.response});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 760),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SeverityBadge(severity: response.severity),
              const SizedBox(width: 8),
              if (response.fallback)
                const _SoftBadge(
                  icon: Icons.info_outline,
                  label: 'Cần thêm phạm vi',
                ),
            ],
          ),
          if (response.insights.isNotEmpty) ...[
            const SizedBox(height: 10),
            _DetailList(
              title: 'Nhận định',
              icon: Icons.insights_outlined,
              items: response.insights,
            ),
          ],
          if (response.recommendedActions.isNotEmpty) ...[
            const SizedBox(height: 10),
            _DetailList(
              title: 'Hành động đề xuất',
              icon: Icons.task_alt_outlined,
              items: response.recommendedActions,
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailList extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> items;

  const _DetailList({
    required this.title,
    required this.icon,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 7),
                    child: Icon(
                      Icons.circle,
                      size: 6,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.darkest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text(
              'Đang tra cứu dữ liệu vận hành...',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeverityBadge extends StatelessWidget {
  final String severity;

  const _SeverityBadge({required this.severity});

  @override
  Widget build(BuildContext context) {
    final normalized = severity.toUpperCase();
    final color = switch (normalized) {
      'HIGH' => AppColors.danger,
      'MEDIUM' => AppColors.warning,
      _ => AppColors.success,
    };
    final label = switch (normalized) {
      'HIGH' => 'Ưu tiên cao',
      'MEDIUM' => 'Theo dõi',
      _ => 'Ổn định',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SoftBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.info, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.info,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _DataScopeRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DataScopeRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
