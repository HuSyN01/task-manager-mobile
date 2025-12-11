import 'dart:io';

class AppConstants {
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'https://tm.salarhussain.workers.dev/'; // Android Emulator
    } else {
      return 'https://tm.salarhussain.workers.dev/'; // iOS Simulator / Web
    }
  }

  static const String taskListEndpoint = '/api/tasks';
  static const String registerEndpoint = '/api/auth/sign-up/email';
  static const String loginEndpoint = '/api/auth/sign-in/email';
  static const String userEndpoint = '/api/me';
  static const String tagsEndpoint = '/api/tags';
}
