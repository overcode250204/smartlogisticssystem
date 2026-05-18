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

  // Controllers cho Form Thêm/Sửa
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  int _selectedRoleId = 3;

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
        content: const Text('Bạn có chắc chắn muốn cho nhân sự này nghỉ việc không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
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

  // Hiển thị Form THÊM / SỬA
  void _showUserDialog({UserModel? userToEdit}) {
    // Điền dữ liệu cũ nếu là chế độ Sửa
    if (userToEdit != null) {
      _nameController.text = userToEdit.fullName;
      _emailController.text = userToEdit.email;
      _phoneController.text = userToEdit.phone ?? '';
      _passwordController.clear();
      _selectedRoleId = userToEdit.roleName == 'Admin' ? 1 
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
      barrierDismissible: false, // Bắt buộc bấm Hủy hoặc Lưu mới đóng
      builder: (context) {
        return AlertDialog(
          title: Text(userToEdit == null ? 'Thêm Nhân Sự Mới' : 'Sửa Thông Tin'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Họ tên')),
                TextField(
                  controller: _emailController, 
                  decoration: const InputDecoration(labelText: 'Email'),
                  enabled: userToEdit == null, // Không cho sửa email nếu đã tồn tại
                ),
                TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Số điện thoại')),
                if (userToEdit == null) // Chỉ yêu cầu pass khi tạo mới
                  TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Mật khẩu'), obscureText: true),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _selectedRoleId,
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('Admin')),
                    DropdownMenuItem(value: 2, child: Text('Thủ kho')),
                    DropdownMenuItem(value: 3, child: Text('Tài xế')),
                  ],
                  onChanged: (val) => setState(() => _selectedRoleId = val!),
                  decoration: const InputDecoration(labelText: 'Chức vụ', border: OutlineInputBorder()),
                )
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); // Đóng hộp thoại
                setState(() => _isLoading = true);

                bool success;
                if (userToEdit == null) {
                  // Gọi API Thêm
                  success = await _userService.createUser(
                    _nameController.text.trim(),
                    _emailController.text.trim(),
                    _phoneController.text.trim(),
                    _passwordController.text.trim(),
                    _selectedRoleId,
                  );
                } else {
                  // Gọi API Sửa
                  success = await _userService.updateUser(
                    userToEdit.userId,
                    _nameController.text.trim(),
                    _phoneController.text.trim(),
                    _selectedRoleId,
                  );
                }

                if (success) {
                  _showMessage(userToEdit == null ? 'Thêm thành công!' : 'Cập nhật thành công!');
                  _fetchUsers(); // Tải lại danh sách
                } else {
                  _showMessage('Có lỗi xảy ra, vui lòng thử lại!', isError: true);
                  setState(() => _isLoading = false);
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
    // Chỉ ID 1 (Admin) mới có quyền
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
              onPressed: () => _showUserDialog(), // Thêm mới
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
                  headingRowColor: MaterialStateProperty.all(Colors.blue.shade100),
                  columns: [
                    const DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
                    const DataColumn(label: Text('Họ Tên', style: TextStyle(fontWeight: FontWeight.bold))),
                    const DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
                    const DataColumn(label: Text('Chức vụ', style: TextStyle(fontWeight: FontWeight.bold))),
                    const DataColumn(label: Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.bold))),
                    if (isAdmin) const DataColumn(label: Text('Hành động', style: TextStyle(fontWeight: FontWeight.bold))),
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
                            style: TextStyle(color: user.isActive ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (isAdmin)
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _showUserDialog(userToEdit: user), // Sửa
                                  tooltip: 'Sửa thông tin',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _confirmDelete(user.userId), // Xóa
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