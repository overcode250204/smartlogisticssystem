import 'package:flutter/material.dart';
import 'package:smartlogisticssystem/core/app_theme.dart';
import 'package:smartlogisticssystem/data/model/exception_reason_response_model.dart';
import 'package:smartlogisticssystem/data/model/fail_point_request_model.dart';
import 'package:smartlogisticssystem/feature/driver/local_trip/services/exception_reason_service.dart';

/// Shows a bottom sheet asking the driver to pick a failure reason
/// (+ optional notes). Returns a [FailPointRequest], or null if cancelled.
Future<FailPointRequest?> showFailPointSheet(BuildContext context) {
  return showModalBottomSheet<FailPointRequest>(
    context: context,
    isScrollControlled: true,
    builder: (context) => const _FailPointSheet(),
  );
}

class _FailPointSheet extends StatefulWidget {
  const _FailPointSheet();

  @override
  State<_FailPointSheet> createState() => _FailPointSheetState();
}

class _FailPointSheetState extends State<_FailPointSheet> {
  final ExceptionReasonService _reasonService = ExceptionReasonService();
  final TextEditingController _notesController = TextEditingController();

  bool _isLoading = true;
  String? _errorMessage;
  List<ExceptionReasonResponse> _reasons = const [];
  ExceptionReasonResponse? _selectedReason;

  @override
  void initState() {
    super.initState();
    _loadReasons();
  }

  Future<void> _loadReasons() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final reasons = await _reasonService.getActiveReasons();
      setState(() {
        _reasons = reasons;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Không thể tải danh sách lý do thất bại';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lý do giao hàng thất bại',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 16),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
          if (!_isLoading && _errorMessage != null)
            Text(_errorMessage!, style: const TextStyle(color: AppColors.danger)),
          if (!_isLoading && _errorMessage == null) ...[
            DropdownButtonFormField<ExceptionReasonResponse>(
              value: _selectedReason,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Chọn lý do'),
              items: _reasons
                  .map(
                    (reason) => DropdownMenuItem(
                      value: reason,
                      child: Text(reason.reasonText, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selectedReason = value),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Ghi chú (không bắt buộc)',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _selectedReason == null
                    ? null
                    : () => Navigator.pop(
                        context,
                        FailPointRequest(
                          reasonId: _selectedReason!.reasonId,
                          notes: _notesController.text,
                        ),
                      ),
                style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
                child: const Text('Xác nhận thất bại'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
