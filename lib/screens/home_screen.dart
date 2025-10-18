import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/db_helper.dart';
import '../models/task.dart';
import 'add_task_screen.dart';
import 'task_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Task> allTasks = [];
  List<Task> displayedTasks = [];
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  Future<void> loadTasks() async {
    final tasks = await DBHelper().getTasks();
    setState(() {
      allTasks = tasks;
      applySearch();
    });
  }

  void applySearch() {
    setState(() {
      if (searchQuery.isEmpty) {
        displayedTasks = allTasks;
      } else {
        displayedTasks = allTasks
            .where((t) =>
            t.title.toLowerCase().contains(searchQuery.toLowerCase()))
            .toList();
      }
    });
  }

  void toggleDone(Task task) async {
    task.isDone = !task.isDone;
    await DBHelper().updateTask(task);
    loadTasks();
  }

  void deleteTask(Task task) async {
    await DBHelper().deleteTask(task.id!);
    loadTasks();
  }

  Color getDueDateColor(String? dueDate, bool isDone) {
    if (isDone) return Colors.grey;
    if (dueDate == null || dueDate.isEmpty) return Colors.black87;

    try {
      final now = DateTime.now();
      final date = DateFormat('dd MMM yyyy').parse(dueDate);

      if (date.isBefore(DateTime(now.year, now.month, now.day))) {
        return Colors.redAccent; // Overdue
      } else if (date.day == now.day &&
          date.month == now.month &&
          date.year == now.year) {
        return Colors.blue; // Today
      } else {
        return Colors.green; // Future
      }
    } catch (e) {
      return Colors.black87;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 4,
        centerTitle: true,
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight).createShader(bounds),
          child: const Text('📝 My Tasks',style: TextStyle(fontSize: 26,fontWeight: FontWeight.bold,color: Colors.white, letterSpacing: 1.3)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.black),
            onPressed: () {
              Navigator.push(context,
                MaterialPageRoute(builder: (context) => const TaskListScreen()));
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              onChanged: (val) {
                searchQuery = val;
                applySearch();
              },
              decoration: InputDecoration(
                hintText: 'Search tasks...',
                prefixIcon: const Icon(Icons.search, color: Colors.deepPurple),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: displayedTasks.isEmpty
          ? const Center(
        child: Text('No tasks yet 😴', style: TextStyle(fontSize: 18,color: Colors.grey,fontStyle: FontStyle.italic)),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: displayedTasks.length,
        itemBuilder: (context, index) {
          final task = displayedTasks[index];
          final dueColor = getDueDateColor(task.dueDate, task.isDone);

          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 8),
                    child: Checkbox(
                      activeColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                      value: task.isDone,
                      onChanged: (val) => toggleDone(task),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(task.title, style: TextStyle(fontSize: 18,fontWeight: FontWeight.w600,
                            decoration: task.isDone
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            color: task.isDone
                                ? Colors.grey
                                : Colors.black87,
                          ),
                        ),
                        if (task.description != null &&
                            task.description!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(task.description!,style: const TextStyle(fontSize: 14, color: Colors.black54)),
                          ),
                        if (task.dueDate != null &&
                            task.dueDate!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today_rounded,
                                    size: 16, color: dueColor),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text('Due Date: ${task.dueDate!}',style: TextStyle(fontSize: 13,fontWeight: FontWeight.w600,color: dueColor)),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.edit,
                            color: Colors.blueAccent),
                        onPressed: () async {
                          await Navigator.push(context,
                            MaterialPageRoute(builder: (_) => AddTaskScreen(task: task)),
                          );
                          loadTasks();
                        },
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.redAccent),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Confirm Delete'),
                              content: const Text('Are you sure you want to delete this task?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent),
                                  onPressed: () {
                                    deleteTask(task);Navigator.of(ctx).pop();
                                  },
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AddTaskScreen()));
          loadTasks();
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, size: 30),
      ),
    );
  }
}
