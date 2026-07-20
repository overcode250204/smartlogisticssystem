import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smartlogisticssystem/data/model/pallet_model.dart';
import 'package:smartlogisticssystem/feature/staff/services/pallet_task_service.dart';

class PalletTaskListPage extends StatefulWidget {
  const PalletTaskListPage({super.key});

  @override
  State<PalletTaskListPage> createState() => _PalletTaskListPageState();
}

class _PalletTaskListPageState extends State<PalletTaskListPage> {
  final PalletTaskService _service = PalletTaskService();
  late Future<List<PalletModel>> _tasksFuture;

  @override
  void initState() {
    super.initState();
    _tasksFuture = _service.getTasks();
  }

  void _refresh() {
    setState(() {
      _tasksFuture = _service.getTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đóng gói pallet'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<PalletModel>>(
        future: _tasksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Không tải được danh sách pallet: ${snapshot.error}',
                ),
              ),
            );
          }

          final tasks = snapshot.data ?? const [];
          if (tasks.isEmpty) {
            return const Center(
              child: Text(
                'Chưa có pallet cần đóng gói',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final task = tasks[index];
              final items = task.palletItems ?? const [];
              final scanned = items.where((item) => item.isScanned).length;
              return Card(
                elevation: 1,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade50,
                    child: const Icon(Icons.inventory_2, color: Colors.blue),
                  ),
                  title: Text(
                    task.palletCode ?? 'Pallet #${task.palletId ?? ''}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    '${task.routeConfig?.routeName ?? 'Chưa có tuyến'} • '
                    '$scanned/${items.length} đơn đã quét • '
                    '${task.status ?? 'N/A'}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    final id = task.palletId;
                    if (id != null) context.go('/staff/pallet-tasks/$id');
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
