import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smartlogisticssystem/data/model/pallet_model.dart';
import 'package:smartlogisticssystem/feature/staff/services/pallet_task_service.dart';
import 'package:smartlogisticssystem/feature/staff/services/pallet_task_state.dart';
import 'package:smartlogisticssystem/widgets/api_error_message.dart';

class PalletTaskListPage extends StatefulWidget {
  /// Cho phép inject service trong test; production dùng ApiClient thật.
  final PalletTaskService? service;

  const PalletTaskListPage({super.key, this.service});

  @override
  State<PalletTaskListPage> createState() => _PalletTaskListPageState();
}

class _PalletTaskListPageState extends State<PalletTaskListPage> {
  late final PalletTaskService _service = widget.service ?? PalletTaskService();
  final TextEditingController _searchController = TextEditingController();

  bool _loading = true;
  String? _error;
  List<PalletModel> _tasks = const [];
  String _query = '';
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tasks = await _service.getTasks();
      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = apiErrorMessage(error);
        _loading = false;
      });
    }
  }

  List<PalletModel> get _visibleTasks {
    final query = _query.trim().toUpperCase();
    return _tasks.where((task) {
      if (_statusFilter != null && task.status != _statusFilter) return false;
      if (query.isEmpty) return true;
      if ((task.palletCode ?? '').toUpperCase().contains(query)) return true;
      final items = task.palletItems ?? const [];
      return items.any(
        (item) => (item.order?.orderCode ?? '').toUpperCase().contains(query),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          // List thường là route gốc (mở bằng context.go) nên không pop được;
          // khi đó quay về màn hình chính của staff thay vì pop stack rỗng.
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/staff');
            }
          },
        ),
        title: const Text('Nhiệm vụ của tôi'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(onRefresh: _load, child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) return const _TaskListSkeleton();

    if (_error != null) {
      return _StateMessage(
        icon: Icons.wifi_off,
        title: 'Không tải được danh sách nhiệm vụ',
        message: _error!,
        actionLabel: 'Thử lại',
        onAction: _load,
      );
    }

    final tasks = _visibleTasks;

    return Column(
      children: [
        _buildFilters(context),
        Expanded(
          child: tasks.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 40),
                    _StateMessage(
                      icon: Icons.inventory_2_outlined,
                      title: _tasks.isEmpty
                          ? 'Chưa có pallet cần đóng gói'
                          : 'Không có nhiệm vụ khớp bộ lọc',
                      message: _tasks.isEmpty
                          ? 'Khi hệ thống tạo pallet mới, nhiệm vụ sẽ xuất hiện tại đây.'
                          : 'Thử xoá từ khoá tìm kiếm hoặc bỏ lọc trạng thái.',
                      actionLabel: 'Tải lại',
                      onAction: _load,
                    ),
                  ],
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: tasks.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _TaskCard(task: tasks[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildFilters(BuildContext context) {
    final statuses =
        {
          for (final task in _tasks)
            if (task.status != null) task.status!,
        }.toList()..sort();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tổng ${_tasks.length} nhiệm vụ',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Tìm theo mã pallet hoặc mã đơn',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
          if (statuses.length > 1) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Tất cả'),
                    selected: _statusFilter == null,
                    onSelected: (_) => setState(() => _statusFilter = null),
                  ),
                  const SizedBox(width: 8),
                  for (final status in statuses) ...[
                    ChoiceChip(
                      label: Text(
                        PalletTaskState(PalletModel(status: status)).statusLabel,
                      ),
                      selected: _statusFilter == status,
                      onSelected: (selected) => setState(
                        () => _statusFilter = selected ? status : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final PalletModel task;

  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final state = PalletTaskState(task);
    final id = task.palletId;

    return Card(
      elevation: 1,
      child: InkWell(
        onTap: id == null ? null : () => context.go('/staff/pallet-tasks/$id'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.palletCode ?? 'Pallet #${task.palletId ?? ''}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  PalletStatusBadge(
                    status: state.status,
                    label: state.statusLabel,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                task.routeConfig?.routeName ?? 'Chưa có tuyến',
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: state.progress,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    '${state.scannedCount}/${state.totalCount} đơn đã quét',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: id == null
                        ? null
                        : () => context.go('/staff/pallet-tasks/$id'),
                    icon: const Icon(Icons.chevron_right),
                    label: const Text('Xem chi tiết'),
                  ),
                ],
              ),
              if (task.createdAt != null)
                Text(
                  'Tạo lúc: ${task.createdAt}',
                  style: const TextStyle(color: Colors.black45, fontSize: 12),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskListSkeleton extends StatelessWidget {
  const _TaskListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, _) => Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _StateMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.black38),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
