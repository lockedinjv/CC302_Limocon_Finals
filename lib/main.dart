import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const TaskFlowApp());
}

const navy = Color(0xFF172554);
const blue = Color(0xFF4361EE);
const purple = Color(0xFF7C3AED);
const background = Color(0xFFF6F7FC);
const muted = Color(0xFF7B849B);

class Task {
  String id;
  String title;
  String description;
  String category;
  String priority;
  String dueDate;
  bool completed;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.dueDate,
    this.completed = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'category': category,
    'priority': priority,
    'dueDate': dueDate,
    'completed': completed,
  };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id']?.toString() ?? '',
    title: json['title']?.toString() ?? '',
    description: json['description']?.toString() ?? '',
    category: json['category']?.toString() ?? 'Personal',
    priority: json['priority']?.toString() ?? 'Medium',
    dueDate: json['dueDate']?.toString() ?? '',
    completed: json['completed'] == true,
  );
}

class TaskFlowApp extends StatelessWidget {
  const TaskFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TaskFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: background,
        colorScheme: ColorScheme.fromSeed(seedColor: blue),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: background,
          foregroundColor: navy,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: const TaskHomePage(),
    );
  }
}

class TaskHomePage extends StatefulWidget {
  const TaskHomePage({super.key});

  @override
  State<TaskHomePage> createState() => _TaskHomePageState();
}

class _TaskHomePageState extends State<TaskHomePage> {
  List<Task> tasks = [];
  bool loading = true;
  bool quoteLoading = false;
  String search = '';
  String filter = 'All';
  String quote = 'Small steps lead to big achievements.';

  @override
  void initState() {
    super.initState();
    loadTasks();
    fetchQuote();
  }

  Future<void> loadTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('taskflow_tasks');

      if (saved != null) {
        final decoded = jsonDecode(saved) as List;
        tasks = decoded
            .map((item) => Task.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load saved tasks.')),
        );
      }
    }

    if (mounted) setState(() => loading = false);
  }

  Future<void> saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'taskflow_tasks',
      jsonEncode(tasks.map((task) => task.toJson()).toList()),
    );
  }

  Future<void> fetchQuote() async {
    if (mounted) setState(() => quoteLoading = true);

    try {
      final response = await http
          .get(Uri.parse('https://dummyjson.com/quotes/random'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (mounted && data['quote'] != null) {
          setState(() => quote = data['quote'].toString());
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          quote = 'Keep going. Every completed task is progress.';
        });
      }
    }

    if (mounted) setState(() => quoteLoading = false);
  }

  List<Task> get visibleTasks {
    return tasks.where((task) {
      final query = search.toLowerCase();

      final matchesSearch =
          task.title.toLowerCase().contains(query) ||
          task.description.toLowerCase().contains(query);

      final matchesFilter =
          filter == 'All' ||
          (filter == 'Active' && !task.completed) ||
          (filter == 'Completed' && task.completed) ||
          task.priority == filter;

      return matchesSearch && matchesFilter;
    }).toList();
  }

  String dateText(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> openTaskForm({Task? task}) async {
    final titleController = TextEditingController(text: task?.title ?? '');
    final descriptionController = TextEditingController(
      text: task?.description ?? '',
    );

    String category = task?.category ?? 'Personal';
    String priority = task?.priority ?? 'Medium';

    DateTime? dueDate = task == null || task.dueDate.isEmpty
        ? null
        : DateTime.tryParse(task.dueDate);

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
              title: Text(
                task == null ? 'Create a task' : 'Edit task',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: navy,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      autofocus: true,
                      maxLength: 80,
                      decoration: const InputDecoration(
                        labelText: 'Task title *',
                        hintText: 'What needs to be done?',
                        prefixIcon: Icon(Icons.edit_note),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Add some details',
                        prefixIcon: Icon(Icons.notes),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: ['Personal', 'School', 'Work', 'Other'].map((
                        value,
                      ) {
                        return DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => category = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: priority,
                      decoration: const InputDecoration(
                        labelText: 'Priority',
                        prefixIcon: Icon(Icons.flag_outlined),
                      ),
                      items: ['Low', 'Medium', 'High'].map((value) {
                        return DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => priority = value);
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_month),
                        label: Text(
                          dueDate == null
                              ? 'Choose due date'
                              : dateText(dueDate!),
                        ),
                        onPressed: () async {
                          final now = DateTime.now();

                          final picked = await showDatePicker(
                            context: dialogContext,
                            initialDate:
                                dueDate ??
                                DateTime(now.year, now.month, now.day),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );

                          if (picked != null) {
                            setDialogState(() => dueDate = picked);
                          }
                        },
                      ),
                    ),
                    if (dueDate != null)
                      TextButton(
                        onPressed: () {
                          setDialogState(() => dueDate = null);
                        },
                        child: const Text('Remove due date'),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: blue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final title = titleController.text.trim();

                    if (title.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a task title.'),
                        ),
                      );
                      return;
                    }

                    setState(() {
                      if (task == null) {
                        tasks.insert(
                          0,
                          Task(
                            id: DateTime.now().microsecondsSinceEpoch
                                .toString(),
                            title: title,
                            description: descriptionController.text.trim(),
                            category: category,
                            priority: priority,
                            dueDate: dueDate?.toIso8601String() ?? '',
                          ),
                        );
                      } else {
                        task.title = title;
                        task.description = descriptionController.text.trim();
                        task.category = category;
                        task.priority = priority;
                        task.dueDate = dueDate?.toIso8601String() ?? '';
                      }
                    });

                    await saveTasks();

                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            task == null
                                ? 'Task created successfully!'
                                : 'Task updated successfully!',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  child: Text(task == null ? 'Create Task' : 'Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    descriptionController.dispose();
  }

  Future<void> deleteTask(Task task) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Delete task?'),
        content: Text('Delete "${task.title}" permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        tasks.removeWhere((item) => item.id == task.id);
      });

      await saveTasks();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task deleted.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Color priorityColor(String priority) {
    if (priority == 'High') return const Color(0xFFEF4444);
    if (priority == 'Medium') return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  Widget sectionTitle(String title, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: navy,
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: muted, fontSize: 13)),
        ],
      ],
    );
  }

  Widget summaryCard(String label, int value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEAECF4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withAlpha(22),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 21),
            ),
            const SizedBox(height: 14),
            Text(
              '$value',
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: navy,
              ),
            ),
            const SizedBox(height: 3),
            Text(label, style: const TextStyle(fontSize: 12, color: muted)),
          ],
        ),
      ),
    );
  }

  Widget progressCard(int completed, double progress) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [navy, Color(0xFF3730A3), blue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: blue.withAlpha(35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 21),
              SizedBox(width: 9),
              Text(
                'YOUR DAILY PROGRESS',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  tasks.isEmpty
                      ? 'Ready to get started?'
                      : completed == tasks.length
                      ? 'Amazing work!'
                      : 'Keep it up!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            tasks.isEmpty
                ? 'Create your first task and start your journey.'
                : '$completed of ${tasks.length} tasks completed',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white24,
              color: const Color(0xFF67E8F9),
            ),
          ),
        ],
      ),
    );
  }

  Widget quoteCard() {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF0FF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE1E5FF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              color: purple,
              size: 25,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DAILY INSPIRATION',
                  style: TextStyle(
                    fontSize: 11,
                    color: purple,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '"$quote"',
                  style: const TextStyle(
                    color: navy,
                    fontSize: 14,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (quoteLoading) ...[
                  const SizedBox(height: 10),
                  const LinearProgressIndicator(minHeight: 2, color: purple),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'New quote',
            onPressed: quoteLoading ? null : fetchQuote,
            icon: const Icon(Icons.refresh, color: purple),
          ),
        ],
      ),
    );
  }

  Widget taskCard(Task task) {
    final color = priorityColor(task.priority);
    final parsedDate = task.dueDate.isEmpty
        ? null
        : DateTime.tryParse(task.dueDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEAECF4)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: task.completed,
              activeColor: blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              onChanged: (value) async {
                setState(() => task.completed = value ?? false);
                await saveTasks();
              },
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        color: task.completed ? muted : navy,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        decoration: task.completed
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    if (task.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        task.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: muted,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                    const SizedBox(height: 11),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        _tag(task.category, const Color(0xFFEEF0FF), navy),
                        _tag(task.priority, color.withAlpha(24), color),
                        if (parsedDate != null)
                          _tag(
                            dateText(parsedDate),
                            const Color(0xFFF0F2F6),
                            const Color(0xFF596174),
                            icon: Icons.calendar_today_outlined,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz, color: muted),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              onSelected: (value) {
                if (value == 'edit') openTaskForm(task: task);
                if (value == 'delete') deleteTask(task);
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 19),
                      SizedBox(width: 10),
                      Text('Edit task'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 19, color: Colors.red),
                      SizedBox(width: 10),
                      Text('Delete task', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(
    String text,
    Color backgroundColor,
    Color foregroundColor, {
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: foregroundColor),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: TextStyle(
              color: foregroundColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 35),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEAECF4)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF0FF),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(Icons.checklist_rounded, size: 38, color: blue),
          ),
          const SizedBox(height: 15),
          Text(
            tasks.isEmpty ? 'Nothing on your list yet' : 'No tasks found',
            style: const TextStyle(
              color: navy,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            tasks.isEmpty
                ? 'Add your first task and make today count.'
                : 'Try another search or change your filter.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: muted, fontSize: 13, height: 1.5),
          ),
          if (tasks.isEmpty) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => openTaskForm(),
              icon: const Icon(Icons.add),
              label: const Text('Create your first task'),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final completed = tasks.where((task) => task.completed).length;
    final active = tasks.length - completed;
    final progress = tasks.isEmpty ? 0.0 : completed / tasks.length;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [blue, purple]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.task_alt_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'TaskFlow',
              style: TextStyle(
                color: navy,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: IconButton(
                tooltip: 'Refresh daily quote',
                onPressed: quoteLoading ? null : fetchQuote,
                icon: const Icon(Icons.refresh_rounded, color: blue),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openTaskForm(),
        backgroundColor: blue,
        foregroundColor: Colors.white,
        elevation: 5,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'New Task',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: blue))
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
                children: [
                  const Text(
                    'Make today',
                    style: TextStyle(color: muted, fontSize: 15),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Count on you. ✨',
                    style: TextStyle(
                      color: navy,
                      fontSize: 29,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Organize your tasks. Focus on what matters.',
                    style: TextStyle(color: muted, fontSize: 13),
                  ),
                  const SizedBox(height: 23),
                  Row(
                    children: [
                      summaryCard(
                        'Total Tasks',
                        tasks.length,
                        Icons.checklist_rounded,
                        blue,
                      ),
                      const SizedBox(width: 10),
                      summaryCard(
                        'In Progress',
                        active,
                        Icons.timelapse_rounded,
                        const Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 10),
                      summaryCard(
                        'Completed',
                        completed,
                        Icons.task_alt_rounded,
                        const Color(0xFF10B981),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  progressCard(completed, progress),
                  const SizedBox(height: 18),
                  quoteCard(),
                  const SizedBox(height: 27),
                  sectionTitle(
                    'My Tasks',
                    subtitle: '$active active · $completed completed',
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    onChanged: (value) => setState(() => search = value),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search_rounded, color: blue),
                      hintText: 'Search your tasks...',
                      hintStyle: const TextStyle(color: muted),
                      suffixIcon: search.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                setState(() => search = '');
                              },
                              icon: const Icon(Icons.close),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 13),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children:
                          [
                            'All',
                            'Active',
                            'Completed',
                            'High',
                            'Medium',
                            'Low',
                          ].map((value) {
                            final selected = filter == value;

                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(value),
                                selected: selected,
                                showCheckmark: false,
                                selectedColor: blue,
                                backgroundColor: Colors.white,
                                side: BorderSide(
                                  color: selected
                                      ? blue
                                      : const Color(0xFFEAECF4),
                                ),
                                labelStyle: TextStyle(
                                  color: selected ? Colors.white : muted,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                onSelected: (_) {
                                  setState(() => filter = value);
                                },
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (visibleTasks.isEmpty)
                    emptyState()
                  else
                    ...visibleTasks.map(taskCard),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text(
                      'Stay focused. You are making progress.',
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
