import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../model.dart';

/// 共通のロジックやUI部品を含む抽象クラス
abstract class EditPage extends StatefulWidget {
  const EditPage({super.key});
}

/// 共通の状態管理ロジック
abstract class EditPageState<T extends EditPage> extends State<T> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // テキストフィールド用コントローラーをリストで管理（4個生成）
  final List<TextEditingController> optionControllers =
      List.generate(4, (_) => TextEditingController());
  final TextEditingController questionController = TextEditingController();

  // 選択された正解のインデックス（0～3）を ValueNotifier で管理
  final ValueNotifier<int?> _selectedOptionNotifier = ValueNotifier<int?>(null);

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
      if (mounted) {
        setState(() {
          quizzes = loadedQuizzes;
        });
      }
    } catch (e) {
      _showErrorDialog('Failed to load data: $e');
    }
  }

  void _clearFields() {
    // テキストフィールドは各コントローラーで管理しているので直接クリア
    for (final controller in optionControllers) {
      controller.clear();
    }
    questionController.clear();
    // 選択中の正解は ValueNotifier 経由で更新
    _selectedOptionNotifier.value = null;
    setState(() {
      selectedQuiz = null;
    });
  }

  bool _validateInputs() {
    if (questionController.text.trim().isEmpty ||
        optionControllers.any((c) => c.text.trim().isEmpty)) {
      _showErrorDialog(
          'Please fill in all fields for question and all options.');
      return false;
    }
    if (_selectedOptionNotifier.value == null) {
      _showErrorDialog('Please select the correct answer.');
      return false;
    }
    return true;
  }

  // オプションのテキストをまとめて取得する getter
  List<String> get optionsList =>
      optionControllers.map((c) => c.text.trim()).toList();

  Future<void> _insert() async {
    if (!_validateInputs()) return;

    try {
      final options = optionsList;
      final answer = options[_selectedOptionNotifier.value!];

      final quiz = Quiz(
        question: questionController.text.trim(),
        options: options.join('|'),
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
      final options = optionsList;
      final answer = options[_selectedOptionNotifier.value!];

      final updatedQuiz = Quiz(
        id: quiz.id,
        question: questionController.text.trim(),
        options: options.join('|'),
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

  /// 既存の Quiz データを各フィールドにセットする
  void _populateFields(Quiz quiz) {
    questionController.text = quiz.question;
    final options = quiz.options.split('|');
    if (options.length != optionControllers.length) {
      _showErrorDialog('The options format is invalid for this quiz.');
      return;
    }
    for (int i = 0; i < optionControllers.length; i++) {
      optionControllers[i].text = options[i];
    }
    final index = options.indexWhere((option) => option == quiz.answer);
    // ラジオボタンの更新は ValueNotifier 経由で行う
    _selectedOptionNotifier.value = index >= 0 ? index : null;
    setState(() {
      selectedQuiz = quiz;
    });
  }

  /// 入力フォーム部分のウィジェット（共通）
  Widget buildFormWidget() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: RepaintBoundary(
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
                        // Radio ボタン部分は ValueListenableBuilder で局所的に更新
                        ValueListenableBuilder<int?>(
                          valueListenable: _selectedOptionNotifier,
                          builder: (context, selected, _) {
                            return Radio<int>(
                              value: i,
                              groupValue: selected,
                              onChanged: (value) {
                                // ラジオボタン変更時は setState を使わずに ValueNotifier を更新
                                _selectedOptionNotifier.value = value;
                              },
                            );
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
      ),
    );
  }

  /// クイズ一覧部分のウィジェット（共通）
  Widget buildListWidget(double listHeight) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: RepaintBoundary(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Questions List (${quizzes.length})',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                          final options = quiz.options.split('|');
                          return RepaintBoundary(
                            child: ListTile(
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
                                  for (int i = 0; i < options.length; i++)
                                    Text(
                                      '${i + 1}. ${options[i]}${options[i] == quiz.answer ? " (Answer)" : ""}',
                                    ),
                                ],
                              ),
                              leading:
                                  CircleAvatar(child: Text('${index + 1}')),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () {
                                      _populateFields(quiz);
                                    },
                                    tooltip: 'Edit',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    color: Colors.red,
                                    onPressed: () =>
                                        _showDeleteConfirmDialog(quiz),
                                    tooltip: 'Delete',
                                  ),
                                ],
                              ),
                              selected: selectedQuiz?.id == quiz.id,
                              selectedTileColor:
                                  const Color.fromRGBO(0, 0, 255, 0.1),
                              onTap: () {
                                // タップでも編集状態にする（任意）
                                _populateFields(quiz);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
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
          final double listHeight = constraints.maxHeight * 0.4;
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
    for (final controller in optionControllers) {
      controller.dispose();
    }
    _selectedOptionNotifier.dispose();
    super.dispose();
  }
}
