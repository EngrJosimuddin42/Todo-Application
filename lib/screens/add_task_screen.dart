import 'package:flutter/material.dart';
import '../db/db_helper.dart';
import '../models/task.dart';
import 'package:intl/intl.dart';

class AddTaskScreen extends StatefulWidget {
  final Task? task;

  const AddTaskScreen({super.key, this.task});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  String? selectedDate;

  @override
  void initState() {
    super.initState();

    // Load previous data when in edit mode
    if (widget.task != null) {
      titleController.text = widget.task!.title;
      descriptionController.text = widget.task!.description ?? '';
      selectedDate = widget.task!.dueDate;
    }
  }

  // 📅 Date Picker
  Future<void> _pickDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate != null
          ? DateFormat('dd MMM yyyy').parse(selectedDate!)
          : DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6A11CB),
              onPrimary: Colors.white,
              onSurface: Colors.black87),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Color(0xFF6A11CB)))),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedDate = DateFormat('dd MMM yyyy').format(picked);
      });
    }
  }

  // 🟣 Save / Update Task with duplicate check
  void saveTask() async {
    final title = titleController.text.trim();
    final description = descriptionController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Please enter a task title'),
          backgroundColor: Colors.deepPurple),
      );
      return;
    }

    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Please select a due date'),
          backgroundColor: Colors.deepPurple),
      );
      return;
    }

    final newTask = Task(
      id: widget.task?.id,
      title: title,
      description: description.isEmpty ? null : description,
      isDone: widget.task?.isDone ?? false,
      dueDate: selectedDate,
    );

    try {
      // ✅ Duplicate check
      List<Task> existingTasks = await DBHelper().getTasks();
      bool isDuplicate = existingTasks.any((task) {
        if (widget.task != null && task.id == widget.task!.id) return false;
        return task.title.toLowerCase() == title.toLowerCase() &&
            task.dueDate == selectedDate;
      });

      if (isDuplicate) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Task with same title and due date already exists'),
            backgroundColor: Colors.redAccent),
        );
        return;
      }

      if (widget.task == null) {
        await DBHelper().insertTask(newTask);}
      else {await DBHelper().updateTask(newTask);}
      if (!mounted) return;
      Navigator.pop(context, true);

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to save task: $e'),
          backgroundColor: Colors.redAccent),
      );
    }
  }

  // 🟣 TextField Decoration
  InputDecoration buildInputDecoration({required String label, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.deepPurple),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF6A11CB), width: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 3,
        centerTitle: true,
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            widget.task == null ? '➕ Add New Task' : '✏️ Edit Task',
            style: const TextStyle(fontSize: 24,fontWeight: FontWeight.bold,color: Colors.white,letterSpacing: 1.2)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [

            // Title
            TextField(
              controller: titleController,
              decoration: buildInputDecoration(label: 'Task Title', icon: Icons.title_rounded)),
            const SizedBox(height: 16),

            // Description
            TextField(
              controller: descriptionController,
              maxLines: 4,
              decoration: buildInputDecoration(label: 'Description', icon: Icons.notes_rounded)),
            const SizedBox(height: 16),

            // Due Date Picker
            InkWell(
              onTap: () => _pickDueDate(context),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade300, width: 1.5)),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, color: Colors.deepPurple),
                    const SizedBox(width: 12),
                    Text(selectedDate ?? 'Select Due Date',
                      style: TextStyle(fontSize: 16,color: selectedDate == null ? Colors.grey[600] : Colors.black87,fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: saveTask,
                icon: const Icon(Icons.save_rounded, size: 26),
                label: Text(
                  widget.task == null ? 'Save Task' : 'Update Task',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A11CB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
