import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:task_manager_mobile/features/auth/presentation/login_screen.dart';
import 'package:task_manager_mobile/features/auth/presentation/register_screen.dart';
import 'package:task_manager_mobile/features/dashboard/presentation/dashboard_screen.dart';
import 'package:task_manager_mobile/features/tasks/presentation/task_list_screen.dart';
import 'package:task_manager_mobile/features/tasks/presentation/task_form_screen.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const DashboardScreen(),
        routes: [
          GoRoute(
            path: 'tasks',
            builder: (context, state) => const TaskListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const TaskFormScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) =>
                    TaskFormScreen(taskId: state.pathParameters['id']),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
