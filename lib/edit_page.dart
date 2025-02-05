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
  final TextEditingController option1Controller = TextEditingController();
  final TextEditingController option2Controller = TextEditingController();
  final TextEditingController option3Controller = TextEditingController();
  final TextEditingController option4Controller = TextEditingController();

  // 選択された正解のインデックス（0～3）
  int? selectedOptionIndex;

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

    setState(() => isLoading = true);
    try {
      final optionsList = [
        option1Controller.text.trim(),
        option2Controller.text.trim(),
        option3Controller.text.trim(),
        option4Controller.text.trim(),
      ];
      // 正解は選択されたoptionの内容
      final answer = optionsList[selectedOptionIndex!];

      final quiz = Quiz(
        question: questionController.text.trim(),
        // DBには"|"で区切って保存
        options: optionsList.join('|'),
        answer: answer,
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
      final optionsList = [
        option1Controller.text.trim(),
        option2Controller.text.trim(),
        option3Controller.text.trim(),
        option4Controller.text.trim(),
      ];
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

  /// 入力欄へ既存のQuizデータをセットする
  void _populateFields(Quiz quiz) {
    questionController.text = quiz.question;
    // 保存時はoptionsを"|"で結合しているので、splitして各コントローラーへ設定
    final optionsList = quiz.options.split('|');
    if (optionsList.length != 4) {
      _showErrorDialog('The options format is invalid for this quiz.');
      return;
    }
    option1Controller.text = optionsList[0];
    option2Controller.text = optionsList[1];
    option3Controller.text = optionsList[2];
    option4Controller.text = optionsList[3];
    // answerと各optionを比較し、一致するインデックスをselectedOptionIndexに設定
    final index = optionsList.indexWhere((option) => option == quiz.answer);
    selectedOptionIndex = index >= 0 ? index : null;
  }

  @override
  Widget build(BuildContext context) {
    // 画面幅に応じたレイアウト切替（600px未満＝スマートフォン、600px以上＝PC）
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 600;

    // 入力フォーム部分
    Widget formWidget = Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 質問入力
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
              // 4つのOption入力欄＋ラジオボタン
              for (int i = 0; i < 4; i++)
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
                          controller: i == 0
                              ? option1Controller
                              : i == 1
                                  ? option2Controller
                                  : i == 2
                                      ? option3Controller
                                      : option4Controller,
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
                    onPressed:
                        !isLoading && selectedQuiz == null ? _insert : null,
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
    );

    // クイズ一覧部分
    Widget listWidget = Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Questions List (${quizzes.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: quizzes.isEmpty
                  ? const Center(
                      child: Text('No questions registered'),
                    )
                  : ListView.separated(
                      itemCount: quizzes.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final quiz = quizzes[index];
                        // オプションを"|"で分割してリスト表示
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
                                Text('${i + 1}. ${optionsList[i]}'
                                    '${optionsList[i] == quiz.answer ? " (Answer)" : ""}'),
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
                                          _populateFields(quiz);
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
      // Scaffoldにこのプロパティを設定（trueがデフォルトなので省略可能ですが、明示的に設定してもOK）
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        // キーボードが出たときの高さ分だけ下部に余白を追加
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16.0,
          right: 16.0,
          top: 16.0,
        ),
        child: Stack(
          children: [
            // 既存のウィジェットツリー
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: isMobile
                  ? Column(
                      children: [
                        formWidget,
                        const SizedBox(height: 16),
                        SizedBox(
                          // キーボード表示時にリスト部分がオーバーフローしないように高さを調整
                          height: MediaQuery.of(context).size.height * 0.4,
                          child: listWidget,
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(flex: 1, child: formWidget),
                        const SizedBox(width: 16),
                        Expanded(flex: 1, child: listWidget),
                      ],
                    ),
            ),
            if (isLoading)
              Container(
                color: const Color.fromRGBO(0, 0, 0, 0.26),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
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
