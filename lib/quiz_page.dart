import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'model.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  QuizPageState createState() => QuizPageState();
}

class QuizPageState extends State<QuizPage> with TickerProviderStateMixin {
  int score = 0;
  int currentQuestionIndex = 0;
  List<Quiz> questions = [];
  bool isAnswered = false;

  // 結果表示用アニメーション（回答後のアニメーション用）
  late AnimationController _resultAnimationController;
  // カウントダウン用の AnimationController（10秒間のカウントダウン）
  late AnimationController _countdownController;

  @override
  void initState() {
    super.initState();
    _resultAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _countdownController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );

    // カウントダウン終了時に時間切れダイアログを表示する
    _countdownController.addStatusListener((status) {
      if (status == AnimationStatus.completed && !isAnswered) {
        showTimeUpDialog();
      }
    });

    fetchQuestions();
  }

  Future<void> fetchQuestions() async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final fetchedQuestions = await dbHelper.queryAllRows();
      if (mounted) {
        setState(() {
          questions = fetchedQuestions;
        });
        if (questions.isEmpty) {
          showNoQuestionsDialog();
        } else {
          startTimer();
        }
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to load questions: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  void showNoQuestionsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('No Questions Found'),
        content:
            const Text('The database is empty. Please add questions first.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }

  /// カウントダウンタイマーをリセットし開始する
  void startTimer() {
    _countdownController.reset();
    _countdownController.forward();
  }

  void showTimeUpDialog() {
    isAnswered = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.timer_off, color: Colors.red),
            SizedBox(width: 8),
            Text("Time's Up!"),
          ],
        ),
        content: const Text('You ran out of time for this question.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              nextQuestion();
            },
            child: const Text('Next Question'),
          ),
        ],
      ),
    );
  }

  void nextQuestion() {
    isAnswered = false;
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        _resultAnimationController.reset();
      });
      startTimer();
    } else {
      _countdownController.stop();
      showEndDialog();
    }
  }

  void checkAnswer(String selectedOption) {
    if (isAnswered) return;

    isAnswered = true;
    _countdownController.stop();
    final isCorrect = selectedOption == questions[currentQuestionIndex].answer;

    if (isCorrect) {
      setState(() {
        score++;
      });
    }

    _resultAnimationController.forward();
    showResultDialog(isCorrect, selectedOption);
  }

  void showResultDialog(bool isCorrect, String selectedOption) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isCorrect ? Icons.check_circle : Icons.cancel,
              color: isCorrect ? Colors.green : Colors.red,
              size: 80,
            ),
            const SizedBox(height: 16),
            Text(
              isCorrect ? 'Correct!' : 'Wrong!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isCorrect ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isCorrect
                  ? 'Great job!'
                  : 'Correct answer: ${questions[currentQuestionIndex].answer}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                nextQuestion();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isCorrect ? Colors.green : Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Next Question'),
            ),
          ],
        ),
      ),
    );
  }

  void showEndDialog() {
    final percentage =
        questions.isNotEmpty ? (score / questions.length * 100).round() : 0;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.emoji_events, color: Colors.amber),
            SizedBox(width: 8),
            Text('Quiz Complete!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$percentage%',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Score: $score/${questions.length}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            Text(
              _getResultMessage(percentage),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }

  String _getResultMessage(int percentage) {
    if (percentage >= 90) return 'Excellent! You\'re a master!';
    if (percentage >= 70) return 'Great job! Keep it up!';
    if (percentage >= 50) return 'Good effort! Keep practicing!';
    return 'Keep studying and try again!';
  }

  @override
  Widget build(BuildContext context) {
    // 画面幅によりレイアウトを調整（モバイル or PC）
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    // クイズ取得中 or クイズが存在しない場合の表示
    if (questions.isEmpty) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blue.shade300, Colors.blue.shade600],
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 16),
                Text(
                  'Loading questions...',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final question = questions[currentQuestionIndex];
    final options = question.options.split('|');

    // エラー：選択肢が想定（4個）通りでない場合
    if (options.length != 4) {
      return Scaffold(
        body: Center(
          child: Text(
            'Invalid options format for this question.',
            style: TextStyle(fontSize: 18, color: Colors.red.shade700),
          ),
        ),
      );
    }

    final double gridChildAspectRatio = isMobile ? 2.5 : 3.5;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade300, Colors.blue.shade600],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ヘッダー部分
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                    Text(
                      'Question ${currentQuestionIndex + 1}/${questions.length}',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Score: $score',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // カウントダウンのプログレスインジケーター（AnimatedBuilder で更新）
                AnimatedBuilder(
                  animation: _countdownController,
                  builder: (context, child) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: 1.0 - _countdownController.value,
                        backgroundColor:
                            const Color.fromRGBO(255, 255, 255, 0.3),
                        color: Colors.white,
                        minHeight: 8,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                // 質問カード
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      question.question,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // 選択肢グリッド
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: gridChildAspectRatio,
                    children: options.map((option) {
                      return ElevatedButton(
                        onPressed:
                            isAnswered ? null : () => checkAnswer(option),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.blue.shade700,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 24,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        child: Text(
                          option,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _countdownController.dispose();
    _resultAnimationController.dispose();
    super.dispose();
  }
}
