import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../db/db_helper.dart';
import '../models/task.dart';
import 'package:flutter/foundation.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Task> tasks = [];
  String filter = "All";

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  Future<void> loadTasks() async {
    final allTasks = await DBHelper().getTasks();
    setState(() {
      final now = DateTime.now();
      if (kDebugMode) {print("Current time: $now");}

      if (filter == "Pending") {tasks = allTasks.where((t) => !t.isDone && !isOutdated(t)).toList();}
      else if (filter == "Completed") {tasks = allTasks.where((t) => t.isDone).toList();}
      else if (filter == "Outdated") {tasks = allTasks.where((t) => !t.isDone && isOutdated(t)).toList();}
      else {
        tasks = allTasks;
      }
    });
  }

  bool isOutdated(Task t) {
    if (t.dueDate == null || t.dueDate!.isEmpty) return false;
    try {
      final now = DateTime.now();
      final taskDate = DateFormat('dd MMM yyyy').parse(t.dueDate!);
      return taskDate.isBefore(DateTime(now.year, now.month, now.day));
    } catch (e) {
      return false;
    }
  }

  Color getDueDateColor(Task t) {
    if (t.isDone) return Colors.grey;
    if (isOutdated(t)) return Colors.red;
    return Colors.black87;
  }

  Future<void> generatePdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Center(child:pw.Text('📋 Task List', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),),),
            pw.SizedBox(height: 16),
            ...tasks.map((t) {

              // Determine color
              PdfColor color;
              if (t.isDone) {
                color = PdfColors.grey;
              } else if (isOutdated(t)) {
                color = PdfColors.red;
              } else {
                color = PdfColors.black;
              }

              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(t.title, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: color)),
                  if (t.description != null && t.description!.isNotEmpty)
                    pw.Text(t.description!, style: pw.TextStyle(fontSize: 14, color: color)),
                  if (t.dueDate != null && t.dueDate!.isNotEmpty)
                    pw.Text('Due Date: ${t.dueDate!}', style: pw.TextStyle(fontSize: 14, color: color)),
                  pw.Divider(),
                ],
              );
            }),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
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
            end: Alignment.bottomRight
          ).createShader(bounds),
          child: const Text('Task List',style: TextStyle(fontSize: 24,fontWeight: FontWeight.bold,color: Colors.white)),
        ),
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: filter,
              icon: const Icon(Icons.filter_list, color: Colors.blueAccent),
              items: const [
                DropdownMenuItem(value: "All", child: Text("All")),
                DropdownMenuItem(value: "Pending", child: Text("Pending")),
                DropdownMenuItem(value: "Completed", child: Text("Completed")),
                DropdownMenuItem(value: "Outdated", child: Text("Outdated")),
              ],
              onChanged: (value) {
                setState(() => filter = value!);
                loadTasks();
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
            onPressed: generatePdf),
          const SizedBox(width: 10),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadTasks,
        child: tasks.isEmpty
            ? const Center(
          child: Text('No tasks found 😶', style: TextStyle(fontSize: 16, color: Colors.grey))
        )
            : ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            final color = getDueDateColor(task);
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(task.title,textAlign: TextAlign.center,style: TextStyle(fontSize: 18,fontWeight: FontWeight.w600, color: color,
                        decoration: task.isDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (task.description != null && task.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          task.description!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                      ),
                    if (task.dueDate != null && task.dueDate!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text('Due Date: ${task.dueDate!}',textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
