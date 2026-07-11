// File: lib/features/auth_nguyen/user_list_screen.dart
import 'dart:async'; // Bắt buộc phải có để dùng Timer (Debounce)
import 'package:flutter/material.dart';
import 'package:smartlogisticssystem/core/app_theme.dart';
import 'package:smartlogisticssystem/data/model/user_model.dart';
import 'package:smartlogisticssystem/feature/authentication/auth_service/auth_service.dart';
import 'package:smartlogisticssystem/feature/authentication/screens/login_screen.dart';
import 'package:smartlogisticssystem/feature/user/user_service/user_service.dart';

class UserListScreen extends StatefulWidget {
  final int currentRoleId;
  const UserListScreen({super.key, required this.currentRoleId});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();

  List<UserModel> _users = []; // Danh sách hiển thị trên bảng
  bool _isLoading = true;

  // --- QUẢN LÝ TÌM KIẾM VÀ LỌC ---
  final TextEditingController _searchController = TextEditingController();
  int? _filterRoleId;
  bool? _filterIsActive;
  Timer? _debounce;

  // --- QUẢN LÝ FORM THÊM / SỬA ---
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _idCardController = TextEditingController();
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  int _selectedRoleId = 3;
  bool _isActive = true; // Quản lý trạng thái Hoạt động/Đã nghỉ trong Form

  @override
  void initState() {
    super.initState();
    _performSearch(); // Gọi API tìm kiếm lần đầu tiên (Lấy tất cả)
  }

  @override
  void dispose() {
    _debounce?.cancel(); // Hủy Timer khi thoát màn hình
    _searchController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _idCardController.dispose();
    _originController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // Thuật toán Debounce: Chờ người dùng ngừng thao tác 0.5s rồi mới gọi API
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch();
    });
  }

  // Gọi API Tìm kiếm có 3 điều kiện xuống Backend
  Future<void> _performSearch() async {
    setState(() => _isLoading = true);

    final users = await _userService.searchUsers(
      keyword: _searchController.text.trim(),
      roleId: _filterRoleId,
      isActive: _filterIsActive,
    );

    setState(() {
      _users = users;
      _isLoading = false;
    });
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _confirmDelete(int userId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text(
          'Bạn có chắc chắn muốn xóa vĩnh viễn nhân sự này không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final success = await _userService.deleteUser(userId);
      if (success) {
        _showMessage('Xóa nhân sự thành công!');
        _performSearch(); // Refresh lại bảng
      } else {
        _showMessage('Xóa thất bại!', isError: true);
        setState(() => _isLoading = false);
      }
    }
  }

  // Hiển thị Form THÊM / SỬA

  Widget _buildRoleDropdown(StateSetter setStateDialog) {
    return DropdownButtonFormField<int>(
      value: _selectedRoleId,
      items: const [
        DropdownMenuItem(value: 1, child: Text('Admin')),
        DropdownMenuItem(
          value: 2,
          child: Text('WarehouseManager'),
        ),
        DropdownMenuItem(value: 3, child: Text('Driver')),
      ],
      onChanged: (val) => setStateDialog(() => _selectedRoleId = val!),
      decoration: const InputDecoration(
        labelText: 'Chức vụ *',
        prefixIcon: Icon(Icons.admin_panel_settings_outlined),
      ),
    );
  }

  void _showUserDialog({UserModel? userToEdit}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        // Nạp dữ liệu ban đầu
        if (userToEdit != null) {
          _nameController.text = userToEdit.fullName;
          _emailController.text = userToEdit.email ?? '';
          _phoneController.text = userToEdit.phone ?? '';
          _idCardController.text = userToEdit.identificationNumber ?? '';
          _originController.text = userToEdit.origin ?? '';
          _addressController.text = userToEdit.address ?? '';
          _passwordController.clear();
          _isActive = userToEdit.isActive;
          _selectedRoleId = userToEdit.roleName == 'Admin'
              ? 1
              : (userToEdit.roleName == 'WarehouseManager' ? 2 : 3);
        } else {
          _nameController.clear();
          _emailController.clear();
          _phoneController.clear();
          _idCardController.clear();
          _originController.clear();
          _addressController.clear();
          _passwordController.clear();
          _isActive = true;
          _selectedRoleId = 3;
        }

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(
                    userToEdit == null ? Icons.person_add : Icons.edit_note,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    userToEdit == null ? 'Thêm Nhân Sự Mới' : 'Sửa Thông Tin',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SizedBox(
                width: 600, // Tăng chiều rộng để thân thiện hơn
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Thông tin cơ bản',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const Divider(),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Họ tên *',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().length < 5)
                                        ? 'Họ tên phải từ 5 ký tự'
                                        : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(child: _buildRoleDropdown(setStateDialog)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _emailController,
                                decoration: const InputDecoration(
                                  labelText: 'Email *',
                                  prefixIcon: Icon(Icons.email_outlined),
                                ),
                                enabled: userToEdit == null,
                                validator:
                                    (v) => (v == null || !v.contains('@'))
                                        ? 'Email không hợp lệ'
                                        : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _phoneController,
                                decoration: const InputDecoration(
                                  labelText: 'Số điện thoại *',
                                  prefixIcon: Icon(Icons.phone_android),
                                ),
                                validator: (v) =>
                                    (v == null ||
                                            !RegExp(r'^(0)[0-9]{9}$')
                                                .hasMatch(v))
                                        ? 'SDT gồm 10 số, bắt đầu bằng 0'
                                        : null,
                              ),
                            ),
                          ],
                        ),
                        if (userToEdit == null) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            decoration: const InputDecoration(
                              labelText: 'Mật khẩu *',
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                            obscureText: true,
                            validator: (v) => (v == null || v.length < 6)
                                ? 'Mật khẩu phải từ 6 ký tự'
                                : null,
                          ),
                        ],
                        const SizedBox(height: 24),
                        const Text(
                          'Thông tin định danh & Địa chỉ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const Divider(),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _idCardController,
                          decoration: const InputDecoration(
                            labelText: 'Số CMT / CCCD',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _originController,
                                decoration: const InputDecoration(
                                  labelText: 'Quê quán',
                                  prefixIcon: Icon(Icons.location_on_outlined),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _addressController,
                                decoration: const InputDecoration(
                                  labelText: 'Địa chỉ thường trú',
                                  prefixIcon: Icon(Icons.home_outlined),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (userToEdit != null) ...[
                          const SizedBox(height: 24),
                          const Text(
                            'Trạng thái tài khoản',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const Divider(),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'Đang hoạt động',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              _isActive
                                  ? 'Nhân viên đang làm việc'
                                  : 'Nhân viên đã nghỉ / Chờ duyệt',
                            ),
                            value: _isActive,
                            activeColor: Colors.green,
                            onChanged: (bool value) {
                              setStateDialog(() => _isActive = value);
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      Navigator.pop(context);
                      setState(() => _isLoading = true);

                      bool success;
                      if (userToEdit == null) {
                        success = await _userService.createUser(
                          _nameController.text.trim(),
                          _emailController.text.trim(),
                          _phoneController.text.trim(),
                          _passwordController.text.trim(),
                          _selectedRoleId,
                          _idCardController.text.trim(),
                          _originController.text.trim(),
                          _addressController.text.trim(),
                        );
                      } else {
                        success = await _userService.updateUser(
                          userToEdit.userId!,
                          _nameController.text.trim(),
                          _phoneController.text.trim(),
                          _selectedRoleId,
                          _isActive,
                          _idCardController.text.trim(),
                          _originController.text.trim(),
                          _addressController.text.trim(),
                        );
                      }

                      if (success) {
                        _showMessage(
                          userToEdit == null
                              ? 'Thêm thành công!'
                              : 'Cập nhật thành công!',
                        );
                        _performSearch(); // Lấy lại dữ liệu
                      } else {
                        _showMessage(
                          'Có lỗi xảy ra, vui lòng thử lại!',
                          isError: true,
                        );
                        setState(() => _isLoading = false);
                      }
                    }
                  },
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = widget.currentRoleId == 1;

    return Scaffold(
      floatingActionButton: isAdmin
? FloatingActionButton(
              onPressed: () => _showUserDialog(),
              tooltip: 'Thêm nhân sự',
              child: const Icon(Icons.add),
            )
          : null,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // =====================================
            // KHU VỰC TÌM KIẾM VÀ LỌC (3 ĐIỀU KIỆN)
            // =====================================
            Column(
              children: [
                // 1. Ô Tìm kiếm Text
                TextField(
                  controller: _searchController,
                  onChanged: (value) =>
                      _onSearchChanged(), // Gọi hàm debounce khi gõ chữ
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm theo tên, email hoặc SĐT...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged();
                            },
                          ),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _performSearch,
                          tooltip: 'Làm mới',
                        ),
                      ],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),

                // 2. Hai ô Dropdown Lọc
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int?>(
                        value: _filterRoleId,
                        decoration: const InputDecoration(
                          labelText: 'Lọc Chức vụ',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: null,
                            child: Text('Tất cả chức vụ'),
                          ),
                          DropdownMenuItem(value: 1, child: Text('Admin')),
                          DropdownMenuItem(
                            value: 2,
                            child: Text('WarehouseManager'),
                          ),
                          DropdownMenuItem(value: 3, child: Text('Driver')),
                        ],
                        onChanged: (val) {
                          setState(() => _filterRoleId = val);
                          _onSearchChanged(); // Lọc lại ngay khi đổi dropdown
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<bool?>(
                        value: _filterIsActive,
                        decoration: const InputDecoration(
                          labelText: 'Lọc Trạng thái',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: null,
                            child: Text('Tất cả trạng thái'),
                          ),
                          DropdownMenuItem(
                            value: true,
                            child: Text('Đang làm việc / Đã duyệt'),
                          ),
                          DropdownMenuItem(
                            value: false,
                            child: Text('Đã nghỉ / Chờ duyệt'),
                          ),
                        ],
                        onChanged: (val) {
                          setState(() => _filterIsActive = val);
                          _onSearchChanged(); // Lọc lại ngay khi đổi dropdown
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // =====================================
            // BẢNG HIỂN THỊ DỮ LIỆU
            // =====================================
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SizedBox(
                        width: double.infinity,
                        child: DataTable(
                          headingRowColor: MaterialStateProperty.all(
                            Colors.blue.shade100,
                          ),
                          columns: [
                            const DataColumn(
                              label: Text(
                                'ID',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const DataColumn(
                              label: Text(
                                'Họ Tên',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const DataColumn(
                              label: Text(
                                'Email',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const DataColumn(
                              label: Text(
                                'Chức vụ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const DataColumn(
                              label: Text(
                                'Trạng thái',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (isAdmin)
                              const DataColumn(
                                label: Text(
                                  'Hành động',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                          rows: _users.map((user) {
                            return DataRow(
                              cells: [
                                DataCell(Text(user.userId.toString())),
                                DataCell(Text(user.fullName)),
                                DataCell(Text(user.email ?? '')),
                                DataCell(Text(user.roleName)),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: user.isActive
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      user.isActive ? 'Đang làm' : 'Chưa duyệt',
                                      style: TextStyle(
                                        color: user.isActive
                                            ? Colors.green
                                            : Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                if (isAdmin)
                                  DataCell(
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            color: Colors.blue,
                                          ),
                                          onPressed: () =>
                                              _showUserDialog(userToEdit: user),
                                          tooltip: 'Sửa / Duyệt',
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          onPressed: () =>
                                              _confirmDelete(user.userId!),
                                          tooltip: 'Xóa vĩnh viễn',
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
