// File: lib/features/auth_nguyen/user_list_screen.dart
import 'package:flutter/material.dart';
import 'package:smartlogisticssystem/data/model/user_model.dart';
import 'package:smartlogisticssystem/feature/user/user_service/user_service.dart';

class UserListScreen extends StatefulWidget {
  final int currentRoleId;
  const UserListScreen({super.key, required this.currentRoleId});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final UserService _userService = UserService();
  List<UserModel> _users = [];
  bool _isLoading = true;

  // Key để quản lý form validate
  final _formKey = GlobalKey<FormState>();

  // Controllers cho Form Thêm/Sửa
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  int _selectedRoleId = 3; // 1: Admin, 2: Thủ kho, 3: Tài xế

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Lấy dữ liệu từ server
  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    final users = await _userService.getAllUsers();
    setState(() {
      _users = users;
      _isLoading = false;
    });
  }

  // Hiển thị thông báo góc dưới màn hình
  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  // Xử lý XÓA
  Future<void> _confirmDelete(int userId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text(
          'Bạn có chắc chắn muốn cho nhân sự này nghỉ việc không?',
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
        _fetchUsers();
      } else {
        _showMessage('Xóa thất bại!', isError: true);
        setState(() => _isLoading = false);
      }
    }
  }

  // Hiển thị Form THÊM / SỬA với tính năng VALIDATE
  void _showUserDialog({UserModel? userToEdit}) {
    if (userToEdit != null) {
      _nameController.text = userToEdit.fullName;
      _emailController.text = userToEdit.email;
      _phoneController.text = userToEdit.phone ?? '';
      _passwordController.clear();
      _selectedRoleId = userToEdit.roleName == 'Admin'
          ? 1
          : (userToEdit.roleName == 'WarehouseManager' ? 2 : 3);
    } else {
      _nameController.clear();
      _emailController.clear();
      _phoneController.clear();
      _passwordController.clear();
      _selectedRoleId = 3;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(
            userToEdit == null ? 'Thêm Nhân Sự Mới' : 'Sửa Thông Tin',
          ),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey, // Bắt buộc truyền key vào đây
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Họ tên *'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty)
                        return 'Vui lòng nhập họ tên';
                      if (value.trim().length < 5)
                        return 'Họ tên phải từ 5 ký tự';
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email *'),
                    enabled: userToEdit == null,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty)
                        return 'Vui lòng nhập email';
                      final emailRegex = RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      );
                      if (!emailRegex.hasMatch(value.trim()))
                        return 'Email không đúng định dạng';
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại *',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty)
                        return 'Vui lòng nhập số điện thoại';
                      final phoneRegex = RegExp(r'^(0)[0-9]{9}$');
                      if (!phoneRegex.hasMatch(value.trim()))
                        return 'SDT gồm 10 số và bắt đầu bằng 0';
                      return null;
                    },
                  ),
                  if (userToEdit == null)
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Mật khẩu *',
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Vui lòng nhập mật khẩu';
                        if (value.length < 6) return 'Mật khẩu phải từ 6 ký tự';
                        return null;
                      },
                    ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: _selectedRoleId,
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('Admin')),
                      DropdownMenuItem(
                        value: 2,
                        child: Text('WarehouseManager'),
                      ),
                      DropdownMenuItem(value: 3, child: Text('Driver')),
                    ],
                    onChanged: (val) => setState(() => _selectedRoleId = val!),
                    decoration: const InputDecoration(
                      labelText: 'Chức vụ *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
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
                // KIỂM TRA FORM: Nếu hợp lệ mới chạy API
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
                    );
                  } else {
                    success = await _userService.updateUser(
                      userToEdit.userId,
                      _nameController.text.trim(),
                      _phoneController.text.trim(),
                      _selectedRoleId,
                    );
                  }

                  if (success) {
                    _showMessage(
                      userToEdit == null
                          ? 'Thêm thành công!'
                          : 'Cập nhật thành công!',
                    );
                    _fetchUsers();
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
  }

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = widget.currentRoleId == 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Nhân sự'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchUsers),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () => _showUserDialog(),
              tooltip: 'Thêm nhân sự',
              child: const Icon(Icons.add),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
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
                        DataCell(Text(user.email)),
                        DataCell(Text(user.roleName)),
                        DataCell(
                          Text(
                            user.isActive ? 'Đang làm' : 'Đã nghỉ',
                            style: TextStyle(
                              color: user.isActive ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
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
                                  tooltip: 'Sửa thông tin',
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _confirmDelete(user.userId),
                                  tooltip: 'Cho nghỉ việc',
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
    );
  }
}
