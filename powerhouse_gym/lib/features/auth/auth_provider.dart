import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/dio_client.dart';
import '../../core/services/storage_service.dart';

class UserModel {
  final String id, name, role;
  final String? phone, membershipPlan, membershipExpiry, batchName, status, rollNo, address, fatherName, bodyType, dateOfJoining;
  final bool mustChangePassword;

  const UserModel({
    required this.id, required this.name, required this.role,
    this.phone, this.membershipPlan, this.membershipExpiry, this.batchName,
    this.status, this.rollNo, this.address, this.fatherName, this.bodyType,
    this.dateOfJoining, this.mustChangePassword = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
    id: j['id'] ?? '', name: j['name'] ?? '', role: j['role'] ?? 'user',
    phone: j['phone'], membershipPlan: j['membership_plan'],
    membershipExpiry: j['membership_expiry'], batchName: j['batch_name'],
    status: j['status'], rollNo: j['roll_no'], address: j['address'],
    fatherName: j['father_name'], bodyType: j['body_type'],
    dateOfJoining: j['date_of_joining'],
    mustChangePassword: j['must_change_password'] == true,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'role': role, 'phone': phone,
    'membership_plan': membershipPlan, 'membership_expiry': membershipExpiry,
    'batch_name': batchName, 'status': status, 'roll_no': rollNo,
    'address': address, 'father_name': fatherName, 'body_type': bodyType,
    'date_of_joining': dateOfJoining, 'must_change_password': mustChangePassword,
  };
}

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;
  const AuthState({this.user, this.isLoading = false, this.error});
  bool get isLoggedIn => user != null;
  bool get mustChangePassword => user?.mustChangePassword == true;
  AuthState copyWith({UserModel? user, bool? isLoading, String? error}) =>
      AuthState(user: user ?? this.user, isLoading: isLoading ?? this.isLoading, error: error);
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) { _tryAutoLogin(); }

  Future<void> _tryAutoLogin() async {
    final userData = await StorageService.getUser();
    if (userData != null) {
      try {
        final map = jsonDecode(userData);
        state = AuthState(user: UserModel.fromJson(Map<String, dynamic>.from(map)));
      } catch (_) {}
    }
  }

  Future<String?> login(String phone, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await apiCall(dio.post('/auth/login', data: {'phone': phone, 'password': password}));
      if (result['success'] == true) {
        final token = result['data']['token'];
        final userMap = Map<String, dynamic>.from(result['data']['user']);
        await StorageService.saveToken(token);
        await StorageService.saveUser(jsonEncode(userMap));
        state = AuthState(user: UserModel.fromJson(userMap));
        return null;
      } else {
        state = state.copyWith(isLoading: false, error: result['message']);
        return result['message'] ?? 'Login failed';
      }
    } catch(e) {
      final msg = e.toString();
      state = state.copyWith(isLoading: false, error: msg);
      return msg;
    }
  }

  Future<void> refreshUser() async {
    try {
      final result = await apiCall(dio.get('/auth/me'));
      if (result['success'] == true) {
        final userMap = Map<String, dynamic>.from(result['data']);
        await StorageService.saveUser(jsonEncode(userMap));
        state = AuthState(user: UserModel.fromJson(userMap));
      }
    } catch(_) {}
  }

  Future<void> logout() async {
    await StorageService.clear();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());
