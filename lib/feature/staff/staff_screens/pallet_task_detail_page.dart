import 'package:flutter/material.dart';
import 'package:smartlogisticssystem/data/model/pallet_model.dart';
import 'package:smartlogisticssystem/feature/staff/services/pallet_task_service.dart';

class PalletTaskDetailPage extends StatefulWidget {
  final int palletId;

  const PalletTaskDetailPage({super.key, required this.palletId});

  @override
  State<PalletTaskDetailPage> createState() => _PalletTaskDetailPageState();
}

class _PalletTaskDetailPageState extends State<PalletTaskDetailPage> {
  final PalletTaskService _service = PalletTaskService();
  final TextEditingController _orderCodeController = TextEditingController();
  bool _loading = true;
  bool _submitting = false;
  PalletModel? _pallet;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _orderCodeController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final pallet = await _service.getTaskById(widget.palletId);
      if (!mounted) return;
      setState(() {
        _pallet = pallet;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _runAction(Future<void> Function() action) async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
    });
    try {
      await action();
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  Future<void> _scanOrder() async {
    final orderCode = _orderCodeController.text.trim();
    if (orderCode.isEmpty) return;
    await _runAction(() async {
      await _service.scanOrder(palletId: widget.palletId, orderCode: orderCode);
      _orderCodeController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã quét đơn hàng')));
    });
  }

  @override
  Widget build(BuildContext context) {
    final pallet = _pallet;
    final items = pallet?.palletItems ?? const [];
    final scanned = items.where((item) => item.isScanned).length;
    final allScanned = items.isNotEmpty && scanned == items.length;
    final canScan = pallet?.status == 'CAN_SEAL';
    final canMoveToCanSeal = pallet?.status == 'CREATING' && items.isNotEmpty;
    final canSeal = pallet?.status == 'CAN_SEAL' && allScanned;

    return Scaffold(
      appBar: AppBar(
        title: Text(pallet?.palletCode ?? 'Chi tiết pallet'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Không tải được pallet: $_error'),
              ),
            )
          : pallet == null
          ? const Center(child: Text('Không tìm thấy pallet'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SummaryCard(
                  pallet: pallet,
                  scanned: scanned,
                  total: items.length,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _orderCodeController,
                        enabled: canScan && !_submitting,
                        decoration: const InputDecoration(
                          labelText: 'Mã đơn hàng',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.qr_code_scanner),
                        ),
                        onSubmitted: (_) => _scanOrder(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed: canScan && !_submitting ? _scanOrder : null,
                      icon: const Icon(Icons.check),
                      label: const Text('Quét'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: canMoveToCanSeal && !_submitting
                            ? () => _runAction(
                                () => _service.markCanSeal(widget.palletId),
                              )
                            : null,
                        icon: const Icon(Icons.lock_clock),
                        label: const Text('Cho phép quét'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: canSeal && !_submitting
                            ? () => _runAction(
                                () => _service.seal(widget.palletId),
                              )
                            : null,
                        icon: const Icon(Icons.inventory),
                        label: const Text('Hoàn tất pallet'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'Đơn hàng trong pallet',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                ...items.map((item) {
                  final order = item.order;
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        item.isScanned
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: item.isScanned ? Colors.green : Colors.grey,
                      ),
                      title: Text(order?.orderCode ?? 'Không có mã đơn'),
                      subtitle: Text(
                        '${order?.customerName ?? 'Không có khách hàng'} • '
                        '${order?.deliveryProvince ?? 'Không có tỉnh'}',
                      ),
                      trailing: Text(order?.status ?? ''),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final PalletModel pallet;
  final int scanned;
  final int total;

  const _SummaryCard({
    required this.pallet,
    required this.scanned,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : scanned / total;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              pallet.palletCode ?? 'Pallet #${pallet.palletId ?? ''}',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 12),
            Wrap(
              spacing: 18,
              runSpacing: 8,
              children: [
                _Metric(label: 'Trạng thái', value: pallet.status ?? 'N/A'),
                _Metric(label: 'Đã quét', value: '$scanned/$total'),
                _Metric(
                  label: 'Tuyến',
                  value: pallet.routeConfig?.routeName ?? 'N/A',
                ),
                _Metric(
                  label: 'Linehaul',
                  value:
                      pallet.linehaulTrip?.linehaultripCode ??
                      pallet.linehaulTrip?.linehaulId?.toString() ??
                      'N/A',
                ),
                _Metric(
                  label: 'Khối lượng',
                  value: '${pallet.totalWeightKg ?? 0} kg',
                ),
                _Metric(
                  label: 'Thể tích',
                  value: '${pallet.totalVolumeM3 ?? 0} m3',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
