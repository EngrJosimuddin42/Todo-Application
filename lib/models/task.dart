class Task {
  final int? id;
  String title;
  String? description;
  bool isDone;
  String? dueDate;

  Task({
    this.id,
    required this.title,
    this.description,
    this.isDone = false,
    this.dueDate,
  });

  // Create a Task object from a Map
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      isDone: map['isDone'] == 1,
      dueDate: map['dueDate'],
    );
  }

  //Convert a Task object to a Map (for saving to the database)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isDone': isDone ? 1 : 0,
      'dueDate': dueDate,
    };
  }
}
