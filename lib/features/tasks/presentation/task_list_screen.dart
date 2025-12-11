import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_manager_mobile/features/tasks/domain/task.dart';
import 'package:task_manager_mobile/features/tasks/presentation/tasks_provider.dart';
import 'package:intl/intl.dart';

class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  DateTimeRange? _selectedDateRange;

  void _showDateFilter() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: _selectedDateRange,
    );
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  void _clearFilter() {
    setState(() {
      _selectedDateRange = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          IconButton(
            icon: Icon(
              _selectedDateRange == null
                  ? Icons.filter_list
                  : Icons.filter_list_off,
              color: _selectedDateRange == null
                  ? null
                  : Theme.of(context).primaryColor,
            ),
            tooltip: _selectedDateRange == null
                ? 'Filter by Date'
                : 'Clear Filter',
            onPressed: _selectedDateRange == null
                ? _showDateFilter
                : _clearFilter,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(tasksProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: tasksAsync.when(
        data: (tasks) {
          // Apply Filter
          final filteredTasks = _selectedDateRange == null
              ? tasks
              : tasks.where((task) {
                  if (task.deadline == null) return false;
                  // Normalize to date-only for comparison (visual date matching)
                  final taskDate = DateTime(
                    task.deadline!.year,
                    task.deadline!.month,
                    task.deadline!.day,
                  );
                  final start = _selectedDateRange!.start;
                  final end = _selectedDateRange!.end;

                  // Determine if taskDate is within inclusive range [start, end]
                  return !taskDate.isBefore(start) && !taskDate.isAfter(end);
                }).toList();

          if (filteredTasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _selectedDateRange != null
                        ? Icons.filter_alt_off
                        : Icons.task,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _selectedDateRange != null
                        ? 'No tasks found in range'
                        : 'No tasks yet',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: Colors.grey),
                  ),
                  if (_selectedDateRange != null)
                    TextButton(
                      onPressed: _clearFilter,
                      child: const Text('Clear Filter'),
                    ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filteredTasks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final task = filteredTasks[index];
              return Dismissible(
                key: Key(task.id),
                direction: _getDismissDirection(task.status),
                background: _buildSwipeActionLeft(task.status),
                secondaryBackground: _buildSwipeActionRight(task.status),
                confirmDismiss: (direction) async {
                  TaskStatus? newStatus;
                  if (direction == DismissDirection.startToEnd) {
                    // Swipe Right (Previous Status)
                    if (task.status == TaskStatus.inProgress) {
                      newStatus = TaskStatus.todo;
                    } else if (task.status == TaskStatus.completed) {
                      newStatus = TaskStatus.inProgress;
                    }
                  } else if (direction == DismissDirection.endToStart) {
                    // Swipe Left (Next Status)
                    if (task.status == TaskStatus.todo) {
                      newStatus = TaskStatus.inProgress;
                    } else if (task.status == TaskStatus.inProgress) {
                      newStatus = TaskStatus.completed;
                    }
                  }

                  if (newStatus != null) {
                    await ref
                        .read(tasksProvider.notifier)
                        .updateTask(id: task.id, status: newStatus);
                  }
                  return false; // Do not dismiss the widget
                },
                child: TaskCard(task: task),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/tasks/new');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  DismissDirection _getDismissDirection(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return DismissDirection.endToStart; // Can only go to In Progress
      case TaskStatus.inProgress:
        return DismissDirection.horizontal; // Can go to Todo or Completed
      case TaskStatus.completed:
        return DismissDirection.startToEnd; // Can only go to In Progress
    }
  }

  Widget _buildSwipeActionLeft(TaskStatus status) {
    // Background for swiping Right (Start to End) -> Moving Backward
    Color color;
    IconData icon;
    String label;

    if (status == TaskStatus.inProgress) {
      color = Colors.orange;
      icon = Icons.arrow_back;
      label = "Move to To-Do";
    } else if (status == TaskStatus.completed) {
      color = Colors.blue;
      icon = Icons.arrow_back;
      label = "Move to In Progress";
    } else {
      return const SizedBox();
    }

    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 20),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeActionRight(TaskStatus status) {
    // Secondary Background for swiping Left (End to Start) -> Moving Forward
    Color color;
    IconData icon;
    String label;

    if (status == TaskStatus.todo) {
      color = Colors.blue;
      icon = Icons.arrow_forward;
      label = "Start Task";
    } else if (status == TaskStatus.inProgress) {
      color = Colors.green;
      icon = Icons.check;
      label = "Complete Task";
    } else {
      return const SizedBox();
    }

    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Icon(icon, color: Colors.white),
        ],
      ),
    );
  }
}

class TaskCard extends ConsumerWidget {
  final Task task;
  const TaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Color priorityColor;
    switch (task.priority) {
      case TaskPriority.high:
        priorityColor = Colors.red;
        break;
      case TaskPriority.medium:
        priorityColor = Colors.orange;
        break;
      case TaskPriority.low:
        priorityColor = Colors.green;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            context.push('/tasks/${task.id}');
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: priorityColor.withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        task.priority.name.toUpperCase(),
                        style: TextStyle(
                          color: priorityColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (task.description != null &&
                    task.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    task.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatusChip(task.status),
                    if (task.deadline != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Colors.grey[700],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              DateFormat('MMM d').format(task.deadline!),
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(TaskStatus status) {
    Color color;
    String label;
    switch (status) {
      case TaskStatus.todo:
        color = Colors.grey;
        label = 'To Do';
        break;
      case TaskStatus.inProgress:
        color = Colors.blue;
        label = 'In Progress';
        break;
      case TaskStatus.completed:
        color = Colors.green;
        label = 'Done';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
