import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartlogisticssystem/core/networking.dart';
import 'package:smartlogisticssystem/data/model/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final ApiClient _client = ApiClient();

  final String _firebaseApiKey = dotenv.env['FIREBASE_API_KEY'] ?? '';

  FirebaseAuth get _firebaseAuth => FirebaseAuth.instance;

  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await _client.post(
        'auth/v1/login',
        data: {'email': email, 'password': password},
      );

      print('Phản hồi từ Server: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;
        final userData = responseData['data'] as Map<String, dynamic>?;

        if (userData == null) return null;

        return {
          'roleId': _parseInt(userData['roleId']),
          'userId': _parseInt(userData['userId']),
          'fullName': userData['fullName'],
          'roleName': userData['roleName'],
        };
      }

      return null;
    } catch (e) {
      print('Fail to Login: $e');
      if (e is DioException) {
        print('Response Status Code: ${e.response?.statusCode}');
        print('Response Data: ${e.response?.data}');
      }
      return null;
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      print('Error logout $e');
    }
  }

  Future<bool> registerDriver(UserModel userDTO) async {
    try {
      print(userDTO.toString());
      final response = await _client.post(
        'auth/register-driver',
        data: userDTO.toJson(),
      );
      print(response);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Lỗi đăng ký: $e');
      if (e is DioException) {
        print('Response Status Code: ${e.response?.statusCode}');
        print('Response Data: ${e.response?.data}');
      }
      return false;
    }
  }

  int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.parse(value.toString());
  }

  Future<Map<String, dynamic>?> loginWithFirebase(
    String email,
    String password,
  ) async {
    try {
      final _dio = Dio();
      final responseFromFirebase = await _dio.post(
        'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$_firebaseApiKey',
        data: {'email': email, 'password': password, 'returnSecureToken': true},
      );
      print(responseFromFirebase.toString());
      if (responseFromFirebase.statusCode == 200) {
        String idToken = responseFromFirebase.data['idToken'];
        final response = await _client.post(
          'auth/v2/login',
          data: {'token': idToken, 'email': email, 'password': password},
        );
        if (response.statusCode == 200) {
          return response.data['data'];
        }
      }
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future<String?> sendOtpToPhone(String phoneNumber) async {
    try {
      final _dio = Dio();
      String formattedPhone = phoneNumber.startsWith('0')
          ? '+84${phoneNumber.substring(1)}'
          : phoneNumber;

      final response = await _dio.post(
        'https://identitytoolkit.googleapis.com/v1/accounts:sendVerificationCode?key=$_firebaseApiKey',
        data: {'phoneNumber': formattedPhone},
      );
      if (response.statusCode == 200) {
        return response.data['sessionInfo'];
      }
      return null;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future<Map<String, dynamic>?> verifyOptAndLogin({
    required String sessionInfo,
    required String otpCode,
    required String phoneNumber,
  }) async {
    try {
      final _dio = Dio();
      final responseFromFirebase = await _dio.post(
        'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPhoneNumber?key=$_firebaseApiKey',
        data: {'sessionInfo': sessionInfo, 'code': otpCode},
      );
      if (responseFromFirebase.statusCode == 200) {
        String idToken = responseFromFirebase.data['idToken'];
        print(idToken);
        final response = await _client.post(
          'auth/v2/login',
          data: {'token': idToken, 'phone': phoneNumber},
        );

        if (response.statusCode == 200) {
          return response.data['data'];
        }
        return null;
      }
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future<void> sendOtpToRealPhone({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onFailed,
  }) async {
    try {
      // Định dạng số về chuẩn quốc tế +84
      String formattedPhone = phoneNumber.startsWith('0')
          ? '+84${phoneNumber.substring(1)}'
          : phoneNumber;

      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        timeout: const Duration(seconds: 60),
        // Tự động xác thực nếu Firebase đọc được SMS (chỉ có trên Android)
        verificationCompleted: (PhoneAuthCredential credential) async {
          print('⚡ Tự động xác thực SMS thành công!');
        },
        // Thất bại (Ví dụ: Sai định dạng, nhà mạng chặn...)
        verificationFailed: (FirebaseAuthException e) {
          print('❌ Lỗi Firebase Auth SDK: ${e.message}');
          onFailed(e.message ?? 'Xác thực thất bại');
        },
        // Gửi mã thành công -> Trả verificationId về cho giao diện lưu lại
        codeSent: (String verificationId, int? resendToken) {
          print('👉 Đã gửi SMS thật! VerificationId: $verificationId');
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      onFailed(e.toString());
    }
  }

  Future<Map<String, dynamic>?> verifyOtpAndLoginV2({
    required String verificationId,
    required String otpCode,
    required String phoneNumber,
  }) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otpCode,
      );

      UserCredential userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );

      String? idToken = await userCredential.user?.getIdToken();

      if (idToken != null) {
        print('🔥 Lấy ID Token từ SDK thành công: $idToken');

        final response = await _client.post(
          'auth/v2/login',
          data: {'token': idToken, 'phone': phoneNumber},
        );

        if (response.statusCode == 200) {
          return response.data['data'];
        }
      }
      return null;
    } catch (e) {
      print('❌ Lỗi xác thực OTP: $e');
      return null;
    }
  }
}
