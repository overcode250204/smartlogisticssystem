import 'package:flutter/material.dart';
import 'package:smartlogisticssystem/core/app_theme.dart';
import 'package:smartlogisticssystem/data/model/inventory_transaction_response_model.dart';
import 'package:smartlogisticssystem/feature/inventory/services/export_service.dart';
import 'package:smartlogisticssystem/widgets/api_error_message.dart';
import 'package:smartlogisticssystem/widgets/dashboard_widgets.dart';

class ExportPage extends StatefulWidget {
  const ExportPage({super.key});

  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> {
  final ExportService _exportService = ExportService();

  List<InventoryTransactionResponse> _exportTransactions = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadExportHistory();
  }

  Future<void> _loadExportHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final transactions = await _exportService.getExportHistory();
      if (!mounted) return;

      setState(() {
        _exportTransactions = transactions;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = apiErrorMessage(error);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_errorMessage != null) {
      return _ExportHistoryErrorState(
        message: _errorMessage!,
        onReload: _loadExportHistory,
      );
    }

    return PageScroll(
      child: DashboardCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(child: SectionTitle('Lịch sử xuất hàng')),
                IconButton(
                  tooltip: 'Tải lại',
                  onPressed: _loadExportHistory,
                  icon: const Icon(Icons.refresh_rounded),
                  color: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_exportTransactions.isEmpty)
              const _ExportHistoryEmptyState()
            else
              _ExportHistoryTable(transactions: _exportTransactions),
          ],
        ),
      ),
    );
  }
}

class _ExportHistoryTable extends StatelessWidget {
  final List<InventoryTransactionResponse> transactions;

  const _ExportHistoryTable({required this.transactions});

  @override
  Widget build(BuildContext context) {
    return DarkTable(
      columns: const [
        DataColumn(label: Text('Mã GD')),
        DataColumn(label: Text('Lô hàng')),
        DataColumn(label: Text('Sản phẩm')),
        DataColumn(label: Text('Số lượng')),
        DataColumn(label: Text('Ngày xuất')),
        DataColumn(label: Text('Ghi chú')),
      ],
      rows: transactions
          .map(
            (item) => DataRow(
              cells: [
                DataCell(Text('GD${item.transactionId}')),
                DataCell(Text('LH${item.batch?.batchId ?? ''}')),
                DataCell(Text(item.batch?.productName ?? 'Không xác định')),
                DataCell(Text(item.quantity.toString())),
                DataCell(Text(dateTimeFormatter.format(item.createdAt))),
                const DataCell(Text('Xuất kho theo lô')),
              ],
            ),
          )
          .toList(),
    );
  }
}

class _ExportHistoryEmptyState extends StatelessWidget {
  const _ExportHistoryEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: AppColors.darkest.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 56,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 14),
          Text(
            'Chưa có giao dịch xuất hàng',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Các phiếu xuất được tạo bởi Staff sẽ hiển thị tại đây.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ExportHistoryErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onReload;

  const _ExportHistoryErrorState({
    required this.message,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.danger,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Không thể tải lịch sử xuất hàng',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onReload,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
