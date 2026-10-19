import 'package:flutter/material.dart';
import '../models/task_item.dart';
import '../widgets/retro_card.dart';

class TasksView extends StatefulWidget {
  final List<TaskItem> tasks;
  final VoidCallback onTasksUpdated;
  final Function(String) onTaskToggled; // Merkezi tetikleyiciyi ekledik

  const TasksView({
    super.key,
    required this.tasks,
    required this.onTasksUpdated,
    required this.onTaskToggled,
  });

  @override
  State<TasksView> createState() => _TasksViewState();
}

class _TasksViewState extends State<TasksView> {
  bool _isCompletedExpanded = false;

  void _showTaskDialog({TaskItem? existingTask}) {
    TextEditingController titleController = TextEditingController(
      text: existingTask?.title ?? "",
    );
    DateTime selectedDate = existingTask?.date ?? DateTime.now();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: RetroCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      existingTask == null
                          ? "Yeni Görev Ekle"
                          : "Görevi Düzenle",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: "Görev Başlığı",
                        labelStyle: TextStyle(color: Colors.white54),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF535882)),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFE5A96A)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Tarih: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                          style: const TextStyle(color: Colors.white70),
                        ),
                        TextButton(
                          onPressed: () async {
                            DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              setModalState(() => selectedDate = picked);
                            }
                          },
                          child: const Text(
                            "Tarih Seç",
                            style: TextStyle(color: Color(0xFFE5A96A)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE5A96A),
                        foregroundColor: const Color(0xFF282A45),
                      ),
                      onPressed: () {
                        if (titleController.text.isNotEmpty) {
                          setState(() {
                            if (existingTask == null) {
                              widget.tasks.add(
                                TaskItem(
                                  id: DateTime.now().millisecondsSinceEpoch
                                      .toString(),
                                  title: titleController.text,
                                  date: selectedDate,
                                ),
                              );
                            } else {
                              existingTask.title = titleController.text;
                              existingTask.date = selectedDate;
                            }
                            widget.tasks.sort(
                              (a, b) => a.date.compareTo(b.date),
                            );
                          });
                          widget.onTasksUpdated();
                          Navigator.pop(context);
                        }
                      },
                      child: Text(
                        existingTask == null ? "Oluştur" : "Kaydet",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _deleteTask(TaskItem task) {
    setState(() {
      widget.tasks.remove(task);
    });
    widget.onTasksUpdated();
  }

  @override
  void initState() {
    super.initState();
    widget.tasks.sort((a, b) => a.date.compareTo(b.date));
  }

  Widget _buildTaskCard(TaskItem task) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: RetroCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: GestureDetector(
            onTap: () {
              // YENİ: Sadece Merkezi Tetikleyiciyi çağırıyoruz, gerisini o hallediyor
              widget.onTaskToggled(task.id);
            },
            child: Icon(
              task.isCompleted
                  ? Icons.check_box
                  : Icons.check_box_outline_blank,
              color: task.isCompleted
                  ? Colors.lightGreen
                  : const Color(0xFFE5A96A),
              size: 28,
            ),
          ),
          title: Text(
            task.title,
            style: TextStyle(
              color: task.isCompleted ? Colors.lightGreen : Colors.white,
              fontWeight: FontWeight.bold,
              decoration: null,
            ),
          ),
          subtitle: Text(
            "${task.date.day}/${task.date.month}/${task.date.year}",
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white70, size: 20),
                onPressed: () => _showTaskDialog(existingTask: task),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete,
                  color: Colors.redAccent,
                  size: 20,
                ),
                onPressed: () => _deleteTask(task),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uncompletedTasks = widget.tasks.where((t) => !t.isCompleted).toList();
    final completedTasks = widget.tasks.where((t) => t.isCompleted).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Tüm Görevler",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.add_circle,
                  color: Color(0xFFE5A96A),
                  size: 32,
                ),
                onPressed: () => _showTaskDialog(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (uncompletedTasks.isEmpty && completedTasks.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text(
                          "Henüz bir görev eklemedin.",
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                    ),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: uncompletedTasks.length,
                    itemBuilder: (context, index) {
                      return _buildTaskCard(uncompletedTasks[index]);
                    },
                  ),

                  if (completedTasks.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isCompletedExpanded = !_isCompletedExpanded;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 12.0,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1F36),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isCompletedExpanded
                                ? const Color(0xFFE5A96A).withValues(alpha: 0.7)
                                : const Color(0xFF535882).withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.task_alt,
                                  color: _isCompletedExpanded
                                      ? const Color(0xFFE5A96A)
                                      : Colors.white70,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "Tamamlananlar (${completedTasks.length})",
                                  style: TextStyle(
                                    color: _isCompletedExpanded
                                        ? const Color(0xFFE5A96A)
                                        : Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Icon(
                              _isCompletedExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: _isCompletedExpanded
                                  ? const Color(0xFFE5A96A)
                                  : Colors.white70,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_isCompletedExpanded)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: completedTasks.length,
                        itemBuilder: (context, index) {
                          return _buildTaskCard(completedTasks[index]);
                        },
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
