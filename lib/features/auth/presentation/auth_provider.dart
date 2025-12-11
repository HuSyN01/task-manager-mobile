import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:task_manager_mobile/features/auth/data/auth_repository.dart';
import 'package:task_manager_mobile/features/auth/domain/user.dart';

part 'auth_provider.g.dart';

@Riverpod(keepAlive: true)
class Auth extends _$Auth {
  @override
  FutureOr<User?> build() async {
    // Attempt to recover session
    try {
      return await ref.read(authRepositoryProvider).getCurrentUser();
    } catch (e) {
      return null;
    }
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await ref
          .read(authRepositoryProvider)
          .signIn(email: email, password: password);
    });
  }

  Future<void> signUp(String email, String password, String name) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await ref
          .read(authRepositoryProvider)
          .signUp(email: email, password: password, name: name);
    });
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    await ref.read(authRepositoryProvider).signOut();
    state = const AsyncValue.data(null);
  }
}
