import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'model.dart';

class EditPage extends StatefulWidget {
  const EditPage({super.key});

  @override
  EditPageState createState() => EditPageState();
}

class EditPageState extends State<EditPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final TextEditingController questionController = TextEditingController();
  final TextEditingController optionsController = TextEditingController();
  final TextEditingController answerController = TextEditingController();

  List<Quiz> quizzes = [];
  Quiz? selectedQuiz;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  Future<void> _loadQuizzes() async {
    setState(() => isLoading = true);
    try {
      final loadedQuizzes = await _dbHelper.queryAllRows();
      setState(() {
        quizzes = loadedQuizzes;
        isLoading = false;
      });
    } catch (e) {
      _showErrorDialog('Failed to load data: $e');
      setState(() => isLoading = false);
    }
  }

  void _clearFields() {
    setState(() {
      questionController.clear();
      optionsController.clear();
      answerController.clear();
      selectedQuiz = null;
    });
  }

  Future<void> _insert() async {
    if (!_validateInputs()) return;

    setState(() => isLoading = true);
    try {
      final quiz = Quiz(
        question: questionController.text.trim(),
        options: optionsController.text.trim(),
        answer: answerController.text.trim(),
      );
      await _dbHelper.insert(quiz);
      await _loadQuizzes();
      _clearFields();
      _showSnackBar('Question added');
    } catch (e) {
      _showErrorDialog('Failed to add question: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _update(Quiz quiz) async {
    if (!_validateInputs()) return;

    setState(() => isLoading = true);
    try {
      final updatedQuiz = Quiz(
        id: quiz.id,
        question: questionController.text.trim(),
        options: optionsController.text.trim(),
        answer: answerController.text.trim(),
      );
      await _dbHelper.update(updatedQuiz);
      await _loadQuizzes();
      _clearFields();
      _showSnackBar('Question updated');
    } catch (e) {
      _showErrorDialog('Failed to update question: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _delete(int id) async {
    setState(() => isLoading = true);
    try {
      await _dbHelper.delete(id);
      await _loadQuizzes();
      _clearFields();
      _showSnackBar('Question deleted');
    } catch (e) {
      _showErrorDialog('Failed to delete question: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  bool _validateInputs() {
    if (questionController.text.trim().isEmpty ||
        optionsController.text.trim().isEmpty ||
        answerController.text.trim().isEmpty) {
      _showErrorDialog('Please fill in all fields');
      return false;
    }
    return true;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(Quiz quiz) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm'),
        content: Text(
            'Are you sure you want to delete this question?\n\n${quiz.question}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _delete(quiz.id!);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Questions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _clearFields,
            tooltip: 'Clear Fields',
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        TextField(
                          controller: questionController,
                          decoration: const InputDecoration(
                            labelText: 'Question',
                            border: OutlineInputBorder(),
                            hintText: 'Enter the question',
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: optionsController,
                          decoration: const InputDecoration(
                            labelText: 'Options',
                            border: OutlineInputBorder(),
                            hintText: 'Enter options separated by commas',
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: answerController,
                          decoration: const InputDecoration(
                            labelText: 'Answer',
                            border: OutlineInputBorder(),
                            hintText: 'Enter the correct answer',
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('Add'),
                              onPressed: !isLoading && selectedQuiz == null
                                  ? _insert
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.edit),
                              label: const Text('Update'),
                              onPressed: !isLoading && selectedQuiz != null
                                  ? () => _update(selectedQuiz!)
                                  : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Questions List (${quizzes.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Card(
                    child: quizzes.isEmpty
                        ? const Center(
                            child: Text('No questions registered'),
                          )
                        : ListView.separated(
                            itemCount: quizzes.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (context, index) {
                              final quiz = quizzes[index];
                              return ListTile(
                                title: Text(
                                  quiz.question,
                                  style: TextStyle(
                                    fontWeight: selectedQuiz?.id == quiz.id
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Options: ${quiz.options}'),
                                    Text('Answer: ${quiz.answer}'),
                                  ],
                                ),
                                leading: CircleAvatar(
                                  child: Text('${index + 1}'),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: !isLoading
                                          ? () {
                                              setState(() {
                                                selectedQuiz = quiz;
                                                questionController.text =
                                                    quiz.question;
                                                optionsController.text =
                                                    quiz.options;
                                                answerController.text =
                                                    quiz.answer;
                                              });
                                            }
                                          : null,
                                      tooltip: 'Edit',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      color: Colors.red,
                                      onPressed: !isLoading
                                          ? () => _showDeleteConfirmDialog(quiz)
                                          : null,
                                      tooltip: 'Delete',
                                    ),
                                  ],
                                ),
                                selected: selectedQuiz?.id == quiz.id,
                                selectedTileColor: Colors.blue.withValues(alpha: 0.1 * 255),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    questionController.dispose();
    optionsController.dispose();
    answerController.dispose();
    super.dispose();
  }
}
