import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:task_manager_mobile/core/constants/app_constants.dart';
import 'package:task_manager_mobile/core/network/api_client.dart';
import 'package:task_manager_mobile/features/tasks/domain/task.dart';

part 'tasks_repository.g.dart';

@Riverpod(keepAlive: true)
TasksRepository tasksRepository(Ref ref) {
  return TasksRepository(ref.watch(apiClientProvider));
}

class TasksRepository {
  final Dio _dio;

  TasksRepository(this._dio);

  Future<List<Task>> getTasks() async {
    try {
      final response = await _dio.get(AppConstants.taskListEndpoint);
      // Response: { tasks: [...] }
      final List data = response.data['tasks'];
      return data.map((e) => Task.fromJson(e)).toList();
    } catch (e) {
      throw e;
    }
  }

  Future<Task> createTask({
    required String title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? deadline,
    List<String>? tags,
  }) async {
    try {
      // API expects strings for enums? Or values?
      // Since models use JsonValue, toJson should handle it if we use it, but here we constructing map.
      final Map<String, dynamic> data = {
        'title': title,
        if (description != null) 'description': description,
        if (status != null) 'status': _$TaskStatusEnumMap[status],
        if (priority != null) 'priority': _$TaskPriorityEnumMap[priority],
        if (deadline != null) 'deadline': deadline.toIso8601String(),
        if (tags != null) 'tags': tags,
      };

      final response = await _dio.post(
        AppConstants.taskListEndpoint,
        data: data,
      );
      return Task.fromJson(response.data['task']);
    } catch (e) {
      throw e;
    }
  }

  Future<Task> updateTask({
    required String id,
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? deadline,
    List<String>? tags,
  }) async {
    try {
      final Map<String, dynamic> data = {
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (status != null) 'status': _$TaskStatusEnumMap[status],
        if (priority != null) 'priority': _$TaskPriorityEnumMap[priority],
        // If deadline is explicitly null, we should send null? The API might support it.
        // Assuming nullable update.
        if (deadline != null) 'deadline': deadline.toIso8601String(),
        if (tags != null) 'tags': tags,
      };

      final response = await _dio.patch(
        '${AppConstants.taskListEndpoint}/$id',
        data: data,
      );
      return Task.fromJson(response.data['task']);
    } catch (e) {
      throw e;
    }
  }

  Future<void> deleteTask(String id) async {
    try {
      await _dio.delete('${AppConstants.taskListEndpoint}/$id');
    } catch (e) {
      throw e;
    }
  }
}

// Helpers for Enum to String manual mapping since we don't have generated code available in this file scope easily without importing part file which is circular or unavailable during writing.
// Actually, we can rely on standard names if we match what JsonSerializable expects.
// JsonValue('todo') -> 'todo'
const _$TaskStatusEnumMap = {
  TaskStatus.todo: 'todo',
  TaskStatus.inProgress: 'in_progress',
  TaskStatus.completed: 'completed',
};

const _$TaskPriorityEnumMap = {
  TaskPriority.low: 'low',
  TaskPriority.medium: 'medium',
  TaskPriority.high: 'high',
};
