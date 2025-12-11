import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:task_manager_mobile/features/tasks/data/tasks_repository.dart';
import 'package:task_manager_mobile/features/tasks/domain/task.dart';

part 'tasks_provider.g.dart';

@Riverpod(keepAlive: true)
class Tasks extends _$Tasks {
  @override
  FutureOr<List<Task>> build() async {
    return await ref.read(tasksRepositoryProvider).getTasks();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () async => await ref.read(tasksRepositoryProvider).getTasks(),
    );
  }

  Future<void> addTask({
    required String title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? deadline,
    List<String>? tags,
  }) async {
    final previousState = state;
    // Optimistic update difficult without ID, so just loading -> refresh
    // Or we could append the returned task.
    state = const AsyncValue.loading();
    try {
      final newTask = await ref
          .read(tasksRepositoryProvider)
          .createTask(
            title: title,
            description: description,
            status: status,
            priority: priority,
            deadline: deadline,
            tags: tags,
          );
      // Append to list if loaded
      if (previousState.hasValue) {
        state = AsyncValue.data([...previousState.value!, newTask]);
      } else {
        await refresh();
      }
    } catch (e) {
      state = previousState; // Revert
      throw e;
    }
  }

  Future<void> updateTask({
    required String id,
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? deadline,
    List<String>? tags,
  }) async {
    final previousState = state;
    if (!previousState.hasValue) return;

    // 1. Optimistic Update
    try {
      final currentTasks = previousState.value!;
      final taskIndex = currentTasks.indexWhere((t) => t.id == id);
      if (taskIndex != -1) {
        final taskToUpdate = currentTasks[taskIndex];
        final optimisticallyUpdatedTask = taskToUpdate.copyWith(
          title: title,
          description: description,
          status: status,
          priority: priority,
          deadline: deadline,
          // Tags handling might need more logic if we passed full Tag objects vs IDs,
          // but generic copyWith is safe for now if we don't change tags here frequently or if we do it cleanly.
          // For the swipe feature, we only change status.
        );

        final optimisticTasks = List<Task>.from(currentTasks);
        optimisticTasks[taskIndex] = optimisticallyUpdatedTask;
        state = AsyncValue.data(optimisticTasks);
      }
    } catch (e) {
      // If optimistic setup fails, just ignore and proceed to API calls
    }

    // 2. Perform API Call
    try {
      final updatedTask = await ref
          .read(tasksRepositoryProvider)
          .updateTask(
            id: id,
            title: title,
            description: description,
            status: status,
            priority: priority,
            deadline: deadline,
            tags: tags,
          );

      // 3. Confirm with Server Data
      // We re-read state to ensure we don't overwrite concurrent updates if possible,
      // but Riverpod Notifier state is synchronous here in this context usually.
      // Best to use the latest state.
      state.whenData((tasks) {
        final index = tasks.indexWhere((t) => t.id == id);
        if (index != -1) {
          final newTasks = List<Task>.from(tasks);
          newTasks[index] = updatedTask;
          state = AsyncValue.data(newTasks);
        }
      });
    } catch (e) {
      // 4. Revert on Error
      state = previousState;
      throw e;
    }
  }

  Future<void> deleteTask(String id) async {
    final previousState = state;
    // Optimistic delete
    if (previousState.hasValue) {
      state = AsyncValue.data(
        previousState.value!.where((t) => t.id != id).toList(),
      );
    }
    try {
      await ref.read(tasksRepositoryProvider).deleteTask(id);
    } catch (e) {
      state = previousState; // Revert
      throw e;
    }
  }
}
