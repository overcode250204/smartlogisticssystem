import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:smartlogisticssystem/data/model/pallet_item_model.dart';
import 'package:smartlogisticssystem/data/model/pallet_model.dart';
import 'package:smartlogisticssystem/feature/staff/services/pallet_task_service.dart';
import 'package:smartlogisticssystem/feature/staff/services/pallet_task_state.dart';
import 'package:smartlogisticssystem/widgets/api_error_message.dart';
import 'package:smartlogisticssystem/widgets/barcode_scanner_sheet.dart';

/// Toạ độ gửi kèm khi xác nhận nhận hàng.
typedef GpsCoordinate = ({double latitude, double longitude});

class PalletTaskDetailPage extends StatefulWidget {
  final int palletId;

  /// Cho phép inject service trong test; production dùng ApiClient thật.
  final PalletTaskService? service;

  const PalletTaskDetailPage({
    super.key,
    required this.palletId,
    this.service,
  });

  @override
  State<PalletTaskDetailPage> createState() => _PalletTaskDetailPageState();
}

class _PalletTaskDetailPageState extends State<PalletTaskDetailPage> {
  late final PalletTaskService _service = widget.service ?? PalletTaskService();
  final TextEditingController _orderCodeController = TextEditingController();
  final TextEditingController _arrivalCodeController = TextEditingController();
  final TextEditingController _filterController = TextEditingController();
  final FocusNode _scanFocusNode = FocusNode();
  final FocusNode _arrivalFocusNode = FocusNode();

  bool _loading = true;
  bool _submitting = false;
  PalletModel? _pallet;
  String? _error;
  String? _scanError;
  String? _arrivalScanError;
  String _announcement = '';
  String _filter = '';

  /// Mã order đang được xác nhận nhận hàng (để chỉ disable đúng dòng đó).
  String? _confirmingOrderCode;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _orderCodeController.dispose();
    _arrivalCodeController.dispose();
    _filterController.dispose();
    _scanFocusNode.dispose();
    _arrivalFocusNode.dispose();
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
        _loading = false;
      });
      _focusScanFieldIfPossible();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = apiErrorMessage(error);
        _loading = false;
      });
    }
  }

  void _focusScanFieldIfPossible() {
    final pallet = _pallet;
    if (pallet == null) return;
    if (!PalletTaskState(pallet).canScan) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scanFocusNode.requestFocus();
    });
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green.shade700,
      ),
    );
  }

  /// Chạy một mutation rồi refetch task detail để tránh state cũ.
  /// Backend luôn là source of truth cho trạng thái sau thao tác.
  Future<void> _runAction(Future<void> Function() action) async {
    if (_submitting) return; // chống double-submit / double-tap
    setState(() => _submitting = true);
    try {
      await action();
      await _load();
    } catch (error) {
      final message = apiErrorMessage(error);
      if (!mounted) return;
      setState(() => _announcement = message);
      _showSnack(message, isError: true);
      // Refetch để không hiển thị dữ liệu stale sau khi thất bại.
      await _load();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _scanOrder() async {
    if (_submitting) return;
    final orderCode = _orderCodeController.text.trim();
    if (orderCode.isEmpty) {
      setState(() => _scanError = 'Vui lòng nhập hoặc quét mã đơn hàng.');
      _scanFocusNode.requestFocus();
      return;
    }

    setState(() {
      _scanError = null;
      _submitting = true;
    });

    try {
      await _service.scanOrder(
        palletId: widget.palletId,
        orderCode: orderCode,
      );
      _orderCodeController.clear();
      if (mounted) {
        setState(() => _announcement = 'Đã quét đơn $orderCode');
        _showSnack('Đã quét đơn $orderCode');
      }
      await _load();
    } catch (error) {
      final message = apiErrorMessage(error);
      if (!mounted) return;
      // Giữ lại mã để staff sửa, và bôi chọn sẵn toàn bộ text.
      _orderCodeController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _orderCodeController.text.length,
      );
      setState(() {
        _scanError = message;
        _announcement = message;
      });
      _showSnack(message, isError: true);
      // Refetch để chắc chắn progress trên UI khớp backend (không tăng sai).
      await _load();
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
        _scanFocusNode.requestFocus();
      }
    }
  }

  /// Mở camera quét mã, đưa kết quả vào input rồi tự động gọi API scan.
  Future<void> _scanOrderWithCamera() async {
    if (_submitting) return;
    // Đóng bàn phím trước khi mở camera để không bị che / giật layout.
    FocusScope.of(context).unfocus();

    final code = await scanBarcodeWithCamera(context);
    if (!mounted || code == null || code.isEmpty) {
      // Người dùng đóng camera mà không quét — focus lại input để nhập tay.
      if (mounted) _scanFocusNode.requestFocus();
      return;
    }

    _orderCodeController.text = code;
    await _scanOrder();
  }

  Future<void> _confirmAndSeal(PalletTaskState state) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xác nhận dán seal'),
        content: Text(
          'Dán seal pallet ${state.pallet.palletCode ?? '#${state.pallet.palletId}'} '
          'với ${state.totalCount} đơn hàng (đã quét ${state.scannedCount}/${state.totalCount})?\n\n'
          'Sau khi seal, pallet không thể quét thêm đơn.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Dán seal'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await _runAction(() async {
      await _service.seal(widget.palletId);
      if (mounted) {
        setState(() => _announcement = 'Đã dán seal pallet');
        _showSnack('Đã dán seal pallet thành công');
      }
    });
  }

  /// Toạ độ dùng để xác nhận hàng đến kho.
  ///
  /// KHÔNG lấy GPS thiết bị: backend (`PalletServiceImpl.confirmOrderArrival` /
  /// `confirmPalletArrival`) validate khoảng cách ≤500m tới toạ độ
  /// `routeConfig.toWarehouse`, không phải vị trí thiết bị hay địa chỉ giao
  /// hàng của khách. Lấy đúng nguồn đó từ dữ liệu pallet đã tải, dùng chung cho
  /// cả confirm order lẫn confirm pallet — mọi order trong pallet luôn cùng
  /// route với pallet (backend chặn ROUTE_MISMATCH khi thêm order vào pallet),
  /// nên toWarehouse của pallet cũng chính là toWarehouse của từng order.
  /// Trả null nếu pallet chưa có tuyến/kho đích -> nơi gọi phải chặn, không gọi API.
  GpsCoordinate? _resolveArrivalCoordinate() {
    final warehouse = _pallet?.routeConfig?.toWarehouse;
    if (warehouse == null) return null;
    return (latitude: warehouse.latitude, longitude: warehouse.longitude);
  }

  Future<void> _confirmPalletArrival(PalletTaskState state) async {
    final palletCode = state.pallet.palletCode;
    if (palletCode == null || _submitting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xác nhận đã nhận pallet?'),
        content: Text(
          'Bạn xác nhận pallet $palletCode với ${state.totalCount} đơn hàng đã đến nơi?\n\n'
          'Hệ thống sẽ dùng vị trí hiện tại của bạn để kiểm tra bạn đang ở kho nhận. '
          'Thao tác này chỉ đổi trạng thái pallet sang "Đã tới nơi", '
          'không tự động xác nhận từng đơn hàng.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final location = _resolveArrivalCoordinate();
    if (location == null) {
      _showSnack(
        'Không thể xác nhận pallet vì chưa có tọa độ kho nhận.',
        isError: true,
      );
      return;
    }

    debugPrint(
      '[ARRIVAL DEBUG] palletCode=$palletCode '
      'latitude=${location.latitude} longitude=${location.longitude} '
      'source=routeConfig.toWarehouse',
    );

    await _runAction(() async {
      await _service.confirmPalletArrival(
        palletCode: palletCode,
        latitude: location.latitude,
        longitude: location.longitude,
      );
      if (mounted) {
        setState(() => _announcement = 'Đã xác nhận pallet đến nơi');
        _showSnack('Đã xác nhận pallet đến nơi');
      }
    });
  }

  Future<void> _confirmOrderArrival(String orderCode, {bool fromScan = false}) async {
    if (_submitting || _confirmingOrderCode != null) return;

    if (!fromScan) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Xác nhận đã nhận đơn?'),
          content: Text('Xác nhận đơn $orderCode đã đến kho nhận?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Huỷ'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Xác nhận'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    final location = _resolveArrivalCoordinate();
    if (location == null) {
      setState(() {
        if (fromScan) {
          _arrivalScanError = 'Không thể xác nhận vì chưa có tọa độ kho nhận.';
        }
      });
      _showSnack('Không thể xác nhận vì chưa có tọa độ kho nhận.', isError: true);
      return;
    }

    debugPrint(
      '[ARRIVAL DEBUG] orderCode=$orderCode '
      'latitude=${location.latitude} longitude=${location.longitude} '
      'source=routeConfig.toWarehouse',
    );

    setState(() => _confirmingOrderCode = orderCode);
    try {
      await _service.confirmOrderArrival(
        orderCode: orderCode,
        latitude: location.latitude,
        longitude: location.longitude,
      );
      if (mounted) {
        setState(() => _announcement = 'Đã nhận đơn $orderCode');
        _showSnack('Đã nhận đơn $orderCode');
      }
      await _load();
    } catch (error) {
      final message = apiErrorMessage(error);
      if (!mounted) return;
      setState(() {
        _announcement = message;
        if (fromScan) _arrivalScanError = message;
      });
      _showSnack(message, isError: true);
      await _load(); // tránh state stale, không tăng progress giả
    } finally {
      if (mounted) setState(() => _confirmingOrderCode = null);
    }
  }

  Future<void> _scanConfirmArrival() async {
    final orderCode = _arrivalCodeController.text.trim();
    if (orderCode.isEmpty) {
      setState(() => _arrivalScanError = 'Vui lòng nhập hoặc quét mã đơn hàng.');
      _arrivalFocusNode.requestFocus();
      return;
    }
    setState(() => _arrivalScanError = null);
    await _confirmOrderArrival(orderCode, fromScan: true);
    if (mounted && _arrivalScanError == null) {
      _arrivalCodeController.clear();
    } else {
      _arrivalCodeController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _arrivalCodeController.text.length,
      );
    }
    _arrivalFocusNode.requestFocus();
  }

  /// Mở camera quét mã đơn, đưa kết quả vào ô nhập rồi tự động xác nhận đã nhận.
  Future<void> _scanArrivalWithCamera() async {
    if (_submitting || _confirmingOrderCode != null) return;
    // Đóng bàn phím trước khi mở camera để không bị che / giật layout.
    FocusScope.of(context).unfocus();

    final code = await scanBarcodeWithCamera(context);
    if (!mounted || code == null || code.isEmpty) {
      // Người dùng đóng camera mà không quét — focus lại input để nhập tay.
      if (mounted) _arrivalFocusNode.requestFocus();
      return;
    }

    _arrivalCodeController.text = code;
    await _scanConfirmArrival();
  }

  @override
  Widget build(BuildContext context) {
    final pallet = _pallet;
    final state = pallet == null ? null : PalletTaskState(pallet);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Quay lại',
          icon: const Icon(Icons.arrow_back),
          // Ưu tiên pop stack; nếu không pop được (mở trực tiếp qua deep link)
          // thì quay về danh sách nhiệm vụ.
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/staff/pallet-tasks');
            }
          },
        ),
        title: Text(pallet?.palletCode ?? 'Chi tiết nhiệm vụ'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: _loading || _submitting ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Semantics(
            liveRegion: true,
            child: SizedBox(
              height: 0,
              child: Text(_announcement, style: const TextStyle(fontSize: 1)),
            ),
          ),
          Expanded(child: _buildBody(context, state)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, PalletTaskState? state) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.black38),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (state == null) {
      return const Center(child: Text('Không tìm thấy pallet'));
    }

    final items = state.sortedItems(query: _filter);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SummaryCard(state: state),
          const SizedBox(height: 16),
          _buildScanSection(context, state),
          const SizedBox(height: 16),
          _buildSealSection(context, state),
          if (state.showArrivalSection) ...[
            const SizedBox(height: 16),
            _buildArrivalSection(context, state),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Đơn hàng trong pallet (${state.totalCount})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (state.totalCount > 3)
            TextField(
              controller: _filterController,
              decoration: const InputDecoration(
                labelText: 'Lọc theo mã đơn',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) => setState(() => _filter = value),
            ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('Không có đơn hàng nào khớp')),
            )
          else
            ...items.map(
              (item) => _OrderTile(
                item: item,
                arrivalEnabled:
                    state.showArrivalSection && !state.isArrivalReadOnly,
                canConfirmArrival: state.canConfirmOrderArrival(item),
                isArrived: state.isOrderArrived(item),
                confirming:
                    _confirmingOrderCode == (item.order?.orderCode ?? ''),
                busy: _submitting || _confirmingOrderCode != null,
                onConfirmArrival: () =>
                    _confirmOrderArrival(item.order?.orderCode ?? ''),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildArrivalSection(BuildContext context, PalletTaskState state) {
    return Card(
      color: Colors.teal.withValues(alpha: 0.04),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Xác nhận pallet đã đến',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: state.arrivalProgress,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              color: Colors.teal,
            ),
            const SizedBox(height: 6),
            Text(
              'Đã nhận ${state.arrivedOrderCount}/${state.totalCount} đơn'
              '${state.pendingArrivalCount > 0 ? ' • còn ${state.pendingArrivalCount}' : ''}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (state.isPalletArrived)
              Row(
                children: const [
                  Icon(Icons.check_circle, color: Colors.teal),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pallet đã được xác nhận đến nơi.',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              )
            else ...[
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: Colors.teal),
                  onPressed: state.canConfirmPalletArrival && !_submitting
                      ? () => _confirmPalletArrival(state)
                      : null,
                  icon: const Icon(Icons.warehouse),
                  label: const Text(
                    'Xác nhận đã nhận pallet',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 4),
              Text(
                'Hoặc quét từng đơn để xác nhận đã nhận',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _arrivalCodeController,
                focusNode: _arrivalFocusNode,
                enabled: _confirmingOrderCode == null && !_submitting,
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r'\s')),
                ],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
                decoration: InputDecoration(
                  labelText: 'Mã đơn hàng',
                  hintText: 'Quét mã order để xác nhận đã nhận',
                  errorText: _arrivalScanError,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.qr_code_scanner),
                  // Nút camera ngay trong ô nhập để dễ bấm trên mobile.
                  suffixIcon: IconButton(
                    tooltip: 'Quét bằng camera',
                    icon: const Icon(Icons.photo_camera),
                    onPressed: _confirmingOrderCode == null && !_submitting
                        ? _scanArrivalWithCamera
                        : null,
                  ),
                ),
                onSubmitted: (_) => _scanConfirmArrival(),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _confirmingOrderCode == null && !_submitting
                            ? _scanConfirmArrival
                            : null,
                        icon: const Icon(Icons.check),
                        label: const Text('Xác nhận đã quét'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _confirmingOrderCode == null && !_submitting
                            ? _scanArrivalWithCamera
                            : null,
                        icon: const Icon(Icons.photo_camera),
                        label: const Text('Quét bằng camera'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScanSection(BuildContext context, PalletTaskState state) {
    final canScan = state.canScan && !state.isReadOnly;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quét đơn hàng',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            if (!canScan)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  state.isReadOnly
                      ? 'Pallet ở trạng thái "${state.statusLabel}" — chỉ xem, không thể quét thêm.'
                      : 'Pallet đang ở trạng thái ${state.statusLabel}. '
                            'Bấm "Bắt đầu quét" để chuyển pallet sang CAN_SEAL trước khi quét đơn.',
                ),
              ),
            if (canScan) ...[
              TextField(
                controller: _orderCodeController,
                focusNode: _scanFocusNode,
                autofocus: true,
                enabled: !_submitting,
                textInputAction: TextInputAction.done,
                inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
                decoration: InputDecoration(
                  labelText: 'Mã đơn hàng',
                  hintText: 'Quét hoặc nhập mã order',
                  errorText: _scanError,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.qr_code_scanner),
                  // Nút camera ngay trong ô nhập để dễ bấm trên mobile.
                  suffixIcon: IconButton(
                    tooltip: 'Quét bằng camera',
                    icon: const Icon(Icons.photo_camera),
                    onPressed: _submitting ? null : _scanOrderWithCamera,
                  ),
                ),
                onSubmitted: (_) => _scanOrder(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: _submitting ? null : _scanOrder,
                        icon: _submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check),
                        label: const Text(
                          'Xác nhận scan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _submitting ? null : _scanOrderWithCamera,
                        icon: const Icon(Icons.photo_camera),
                        label: const Text(
                          'Quét bằng camera',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (state.canMarkCanSeal) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _submitting
                      ? null
                      : () => _runAction(
                          () => _service.markCanSeal(widget.palletId),
                        ),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Bắt đầu quét'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSealSection(BuildContext context, PalletTaskState state) {
    final blockers = state.sealBlockers;
    final unscanned = state.unscannedOrderCodes;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hoàn tất pallet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            if (state.isReadOnly)
              Row(
                children: [
                  const Icon(Icons.lock, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pallet ở trạng thái "${state.statusLabel}".',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              )
            else if (blockers.isEmpty)
              Row(
                children: const [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Expanded(child: Text('Đủ điều kiện dán seal.')),
                ],
              )
            else ...[
              const Text(
                'Chưa thể dán seal:',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              ...blockers.map(
                (reason) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, size: 16),
                      const SizedBox(width: 6),
                      Expanded(child: Text(reason)),
                    ],
                  ),
                ),
              ),
              if (unscanned.isNotEmpty && unscanned.length <= 10) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: unscanned
                      .map(
                        (code) => Chip(
                          label: Text(code),
                          visualDensity: VisualDensity.compact,
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
            if (!state.isReadOnly) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: state.canSeal && !_submitting
                      ? () => _confirmAndSeal(state)
                      : null,
                  icon: const Icon(Icons.lock),
                  label: const Text(
                    'Seal pallet',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  final PalletItemModel item;

  /// Khu vực nhận hàng đang hoạt động (pallet IN_TRANSIT, chưa read-only).
  final bool arrivalEnabled;

  /// Backend cho phép xác nhận nhận đơn này (order IN_TRANSIT_LINEHAUL).
  final bool canConfirmArrival;

  /// Đơn đã đến hub (ARRIVED_AT_HUB).
  final bool isArrived;

  /// Đơn này đang được xác nhận.
  final bool confirming;

  /// Có mutation nhận-hàng nào đó đang chạy (khoá tạm các nút khác).
  final bool busy;

  final VoidCallback onConfirmArrival;

  const _OrderTile({
    required this.item,
    this.arrivalEnabled = false,
    this.canConfirmArrival = false,
    this.isArrived = false,
    this.confirming = false,
    this.busy = false,
    required this.onConfirmArrival,
  });

  @override
  Widget build(BuildContext context) {
    final order = item.order;
    final scanned = item.isScanned;

    // Trong pha nhận hàng, badge phản ánh trạng thái arrival thay vì scan.
    final showArrival = arrivalEnabled || isArrived;
    final badgeArrived = isArrived;
    final badgeText = showArrival
        ? (isArrived ? 'Đã nhận' : 'Chưa nhận')
        : (scanned ? 'Đã quét' : 'Chưa quét');
    final badgeColor = showArrival
        ? (badgeArrived ? Colors.teal : Colors.grey)
        : (scanned ? Colors.green : Colors.grey);

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              showArrival
                  ? (isArrived
                        ? Icons.warehouse
                        : Icons.local_shipping_outlined)
                  : (scanned
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked),
              color: badgeColor,
            ),
            title: Text(
              order?.orderCode ?? 'Không có mã đơn',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${order?.customerName ?? 'Không có khách hàng'} • '
                  '${order?.deliveryProvince ?? 'Không có tỉnh'}',
                ),
                if (scanned && item.scannedAt != null)
                  Text(
                    'Quét lúc: ${item.scannedAt}',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  color: badgeColor == Colors.grey
                      ? Colors.black54
                      : badgeColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          // Chỉ hiện nút khi backend cho phép xác nhận nhận đơn này.
          if (arrivalEnabled && canConfirmArrival && !isArrived)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: (busy && !confirming) || confirming
                      ? null
                      : onConfirmArrival,
                  icon: confirming
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: const Text('Xác nhận đã nhận'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final PalletTaskState state;

  const _SummaryCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final pallet = state.pallet;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    pallet.palletCode ?? 'Pallet #${pallet.palletId ?? ''}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                PalletStatusBadge(
                  status: state.status,
                  label: state.statusLabel,
                ),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: state.progress,
              minHeight: 10,
              backgroundColor: Colors.grey.shade200,
            ),
            const SizedBox(height: 8),
            Text(
              'Đã quét ${state.scannedCount}/${state.totalCount} đơn',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 18,
              runSpacing: 8,
              children: [
                _Metric(
                  label: 'Tuyến',
                  value: pallet.routeConfig?.routeName ?? 'N/A',
                ),
                _Metric(
                  label: 'Linehaul',
                  value:
                      pallet.linehaulTrip?.linehaultripCode ??
                      pallet.linehaulTrip?.linehaulId?.toString() ??
                      'Chưa gán',
                ),
                _Metric(
                  label: 'Khối lượng',
                  value: '${pallet.totalWeightKg ?? 0} kg',
                ),
                _Metric(
                  label: 'Thể tích',
                  value: '${pallet.totalVolumeM3 ?? 0} m3',
                ),
                _Metric(label: 'Tạo lúc', value: pallet.createdAt ?? 'N/A'),
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
