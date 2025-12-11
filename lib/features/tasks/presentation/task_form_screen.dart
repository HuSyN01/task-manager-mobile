import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_manager_mobile/features/tasks/domain/task.dart';
import 'package:task_manager_mobile/features/tasks/presentation/tasks_provider.dart';
import 'package:intl/intl.dart';

class TaskFormScreen extends ConsumerStatefulWidget {
  final String? taskId;
  const TaskFormScreen({super.key, this.taskId});

  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends ConsumerState<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  TaskStatus _status = TaskStatus.todo;
  TaskPriority _priority = TaskPriority.medium;
  DateTime? _deadline;

  bool _isLoading = false;
  Task? _existingTask;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (widget.taskId != null && _existingTask == null) {
      final tasks = ref.read(tasksProvider).asData?.value;

      if (tasks != null) {
        try {
          final task = tasks.firstWhere((t) => t.id == widget.taskId);

          _existingTask = task;

          _titleController.text = task.title;
          _descriptionController.text = task.description ?? "";
          _status = task.status;
          _priority = task.priority;
          _deadline = task.deadline;
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(tasksProvider.notifier);

      final description = _descriptionController.text.isEmpty
          ? null
          : _descriptionController.text;

      if (widget.taskId == null) {
        await notifier.addTask(
          title: _titleController.text,
          description: description,
          status: _status,
          priority: _priority,
          deadline: _deadline,
        );
      } else {
        await notifier.updateTask(
          id: widget.taskId!,
          title: _titleController.text,
          description: description,
          status: _status,
          priority: _priority,
          deadline: _deadline,
        );
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.taskId == null
                  ? "Task created successfully"
                  : "Task updated successfully",
            ),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _delete() async {
    if (widget.taskId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Task"),
        content: const Text("Are you sure you want to delete this task?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);

      try {
        await ref.read(tasksProvider.notifier).deleteTask(widget.taskId!);
        if (mounted) context.pop();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Error: $e")));
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.taskId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "Edit Task" : "New Task"),
        actions: [
          if (isEditing)
            IconButton(
              onPressed: _isLoading ? null : _delete,
              icon: const Icon(Icons.delete, color: Colors.red),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "Title"),
                validator: (value) =>
                    value == null || value.isEmpty ? "Title is required" : null,
              ),
              const SizedBox(height: 18),

              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: "Description",
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 18),

              // -------------------------
              // FIXED (Responsive Dropdown Row)
              // -------------------------
              LayoutBuilder(
                builder: (context, constraints) {
                  return Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<TaskPriority>(
                          isExpanded: true,
                          value: _priority,
                          decoration: const InputDecoration(
                            labelText: "Priority",
                          ),
                          items: TaskPriority.values.map((p) {
                            return DropdownMenuItem(
                              value: p,
                              child: Text(
                                p.name.toUpperCase(),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (v) => setState(() => _priority = v!),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: DropdownButtonFormField<TaskStatus>(
                          isExpanded: true,
                          value: _status,
                          decoration: const InputDecoration(
                            labelText: "Status",
                          ),
                          items: TaskStatus.values.map((s) {
                            return DropdownMenuItem(
                              value: s,
                              child: Text(
                                s.name.replaceAll('_', ' ').toUpperCase(),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (v) => setState(() => _status = v!),
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 18),

              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Deadline"),
                subtitle: Text(
                  _deadline == null
                      ? "No deadline selected"
                      : DateFormat("MMM d, yyyy – HH:mm").format(_deadline!),
                ),
                trailing: const Icon(Icons.calendar_month),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _deadline ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                  );

                  if (date != null) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(
                        _deadline ?? DateTime.now(),
                      ),
                    );

                    if (time != null) {
                      setState(() {
                        _deadline = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    }
                  }
                },
              ),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(isEditing ? "Update Task" : "Create Task"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
