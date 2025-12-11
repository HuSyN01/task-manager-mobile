import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:task_manager_mobile/core/constants/app_constants.dart';
import 'package:task_manager_mobile/core/network/api_client.dart';
import 'package:task_manager_mobile/features/auth/domain/user.dart';

part 'auth_repository.g.dart';

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return AuthRepository(ref.watch(apiClientProvider));
}

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  Future<User> signIn({required String email, required String password}) async {
    try {
      final response = await _dio.post(
        AppConstants.loginEndpoint,
        data: {'email': email, 'password': password},
      );
      // Better-auth returns user and session, but we might need to fetch /me or extract user from response
      // According to typical better-auth, sign-in returns session and user.
      // Let's assume the response structure is { user: User, session: ... } or just returns ok and we fetch me.
      // However, usually it returns the user object.
      // Let's check api/me for the user.

      // If sign in is successful, the cookie is set. We can fetch the user.
      return await getCurrentUser();
    } catch (e) {
      throw e;
    }
  }

  Future<User> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      await _dio.post(
        AppConstants.registerEndpoint,
        data: {'email': email, 'password': password, 'name': name},
      );
      // Auto login often happens, but if not we might need to login.
      // Better-auth usually auto-logs inside.
      return await getCurrentUser();
    } catch (e) {
      throw e;
    }
  }

  Future<User> getCurrentUser() async {
    try {
      final response = await _dio.get(AppConstants.userEndpoint);
      // Response expected: { user: { ... } }
      if (response.data['user'] == null) {
        throw Exception('User not found');
      }
      return User.fromJson(response.data['user']);
    } catch (e) {
      throw e;
    }
  }

  Future<void> signOut() async {
    await _dio.post('/api/auth/sign-out');
  }
}
