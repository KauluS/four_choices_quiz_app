import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'model.dart';

/// 共通のロジックやUI部品を含む抽象クラス
abstract class EditPage extends StatefulWidget {
  const EditPage({super.key});
}

/// 共通の状態管理ロジック
abstract class EditPageState<T extends EditPage> extends State<T> {
  // データベースヘルパー
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // テキストフィールド用コントローラー
  final TextEditingController questionController = TextEditingController();
  final TextEditingController option1Controller = TextEditingController();
  final TextEditingController option2Controller = TextEditingController();
  final TextEditingController option3Controller = TextEditingController();
  final TextEditingController option4Controller = TextEditingController();

  // 選択された正解のインデックス（0～3）
  int? selectedOptionIndex;

  List<Quiz> quizzes = [];
  Quiz? selectedQuiz;

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  Future<void> _loadQuizzes() async {
    try {
      final loadedQuizzes = await _dbHelper.queryAllRows();
      setState(() {
        quizzes = loadedQuizzes;
      });
    } catch (e) {
      _showErrorDialog('Failed to load data: $e');
    }
  }

  void _clearFields() {
    setState(() {
      questionController.clear();
      option1Controller.clear();
      option2Controller.clear();
      option3Controller.clear();
      option4Controller.clear();
      selectedOptionIndex = null;
      selectedQuiz = null;
    });
  }

  bool _validateInputs() {
    if (questionController.text.trim().isEmpty ||
        option1Controller.text.trim().isEmpty ||
        option2Controller.text.trim().isEmpty ||
        option3Controller.text.trim().isEmpty ||
        option4Controller.text.trim().isEmpty) {
      _showErrorDialog(
          'Please fill in all fields for question and all options.');
      return false;
    }
    if (selectedOptionIndex == null) {
      _showErrorDialog('Please select the correct answer.');
      return false;
    }
    return true;
  }

  Future<void> _insert() async {
    if (!_validateInputs()) return;

    try {
      final optionControllers = [
        option1Controller,
        option2Controller,
        option3Controller,
        option4Controller
      ];
      final optionsList = optionControllers
          .map((controller) => controller.text.trim())
          .toList();
      final answer = optionsList[selectedOptionIndex!];

      final quiz = Quiz(
        question: questionController.text.trim(),
        options: optionsList.join('|'),
        answer: answer,
      );
      await _dbHelper.insert(quiz);
      await _loadQuizzes();
      _clearFields();
      _showSnackBar('Question added');
    } catch (e) {
      _showErrorDialog('Failed to add question: $e');
    }
  }

  Future<void> _update(Quiz quiz) async {
    if (!_validateInputs()) return;

    try {
      final optionControllers = [
        option1Controller,
        option2Controller,
        option3Controller,
        option4Controller
      ];
      final optionsList = optionControllers
          .map((controller) => controller.text.trim())
          .toList();
      final answer = optionsList[selectedOptionIndex!];

      final updatedQuiz = Quiz(
        id: quiz.id,
        question: questionController.text.trim(),
        options: optionsList.join('|'),
        answer: answer,
      );
      await _dbHelper.update(updatedQuiz);
      await _loadQuizzes();
      _clearFields();
      _showSnackBar('Question updated');
    } catch (e) {
      _showErrorDialog('Failed to update question: $e');
    }
  }

  Future<void> _delete(int id) async {
    try {
      await _dbHelper.delete(id);
      await _loadQuizzes();
      _clearFields();
      _showSnackBar('Question deleted');
    } catch (e) {
      _showErrorDialog('Failed to delete question: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('OK')),
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
              child: const Text('Cancel')),
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

  /// 既存のQuizデータを各フィールドにセットする
  void _populateFields(Quiz quiz) {
    questionController.text = quiz.question;
    final optionsList = quiz.options.split('|');
    final optionControllers = [
      option1Controller,
      option2Controller,
      option3Controller,
      option4Controller
    ];
    if (optionsList.length != optionControllers.length) {
      _showErrorDialog('The options format is invalid for this quiz.');
      return;
    }
    for (int i = 0; i < optionControllers.length; i++) {
      optionControllers[i].text = optionsList[i];
    }
    final index = optionsList.indexWhere((option) => option == quiz.answer);
    selectedOptionIndex = index >= 0 ? index : null;
  }

  /// 入力フォーム部分のウィジェット（共通）
  Widget buildFormWidget() {
    final optionControllers = [
      option1Controller,
      option2Controller,
      option3Controller,
      option4Controller
    ];
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 質問入力欄
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
              // 4つのオプション入力欄＋ラジオボタン
              for (int i = 0; i < optionControllers.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Radio<int>(
                        value: i,
                        groupValue: selectedOptionIndex,
                        onChanged: (value) {
                          setState(() {
                            selectedOptionIndex = value;
                          });
                        },
                      ),
                      Expanded(
                        child: TextField(
                          controller: optionControllers[i],
                          decoration: InputDecoration(
                            labelText: 'Option ${i + 1}',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                    onPressed: selectedQuiz == null ? _insert : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text('Update'),
                    onPressed: selectedQuiz != null
                        ? () => _update(selectedQuiz!)
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// クイズ一覧部分のウィジェット（共通）
  Widget buildListWidget(double listHeight) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Questions List (${quizzes.length})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: listHeight,
              child: quizzes.isEmpty
                  ? const Center(child: Text('No questions registered'))
                  : ListView.separated(
                      itemCount: quizzes.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final quiz = quizzes[index];
                        final optionsList = quiz.options.split('|');
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
                              for (int i = 0; i < optionsList.length; i++)
                                Text(
                                    '${i + 1}. ${optionsList[i]}${optionsList[i] == quiz.answer ? " (Answer)" : ""}'),
                            ],
                          ),
                          leading: CircleAvatar(child: Text('${index + 1}')),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  setState(() {
                                    selectedQuiz = quiz;
                                    _populateFields(quiz);
                                  });
                                },
                                tooltip: 'Edit',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                color: Colors.red,
                                onPressed: () => _showDeleteConfirmDialog(quiz),
                                tooltip: 'Delete',
                              ),
                            ],
                          ),
                          selected: selectedQuiz?.id == quiz.id,
                          selectedTileColor:
                              const Color.fromRGBO(0, 0, 255, 0.1),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// 各画面ごとにレイアウトを実装するための抽象メソッド
  Widget buildLayout(
      BuildContext context, Widget formWidget, Widget listWidget);

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
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          double listHeight = constraints.maxHeight * 0.4;
          final formWidget = buildFormWidget();
          final listWidget = buildListWidget(listHeight);
          return SingleChildScrollView(
            child: buildLayout(context, formWidget, listWidget),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    questionController.dispose();
    option1Controller.dispose();
    option2Controller.dispose();
    option3Controller.dispose();
    option4Controller.dispose();
    super.dispose();
  }
}
