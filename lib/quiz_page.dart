import 'package:flutter/material.dart';
import 'dart:async';
import 'database_helper.dart';
import 'model.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  QuizPageState createState() => QuizPageState();
}

class QuizPageState extends State<QuizPage>
    with SingleTickerProviderStateMixin {
  int score = 0;
  int currentQuestionIndex = 0;
  double timeLeft = 1.0;
  Timer? timer;
  List<Quiz> questions = [];
  late AnimationController _animationController;
  bool isAnswered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
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
      // Handle error if fetching fails
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

  void startTimer() {
    timeLeft = 1.0;
    timer?.cancel();
    timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) {
        setState(() {
          timeLeft -= 0.01;
          if (timeLeft <= 0) {
            timeLeft = 0;
            timer.cancel();
            if (!isAnswered) {
              showTimeUpDialog();
            }
          }
        });
      }
    });
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
            Text('Time\'s Up!'),
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
        _animationController.reset();
      });
      startTimer();
    } else {
      timer?.cancel();
      showEndDialog();
    }
  }

  void checkAnswer(String selectedOption) {
    if (isAnswered) return;

    isAnswered = true;
    timer?.cancel();
    bool isCorrect = selectedOption == questions[currentQuestionIndex].answer;

    if (isCorrect) {
      setState(() {
        score++;
      });
    }

    _animationController.forward();
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
    // Adjust layout based on screen width (mobile or PC)
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    if (questions.isEmpty) {
      // While fetching questions or after no questions, show a loading view
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

    // Show error if options are not formatted as expected.
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

    double gridChildAspectRatio = isMobile ? 2.5 : 3.5;

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
                // Header
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: timeLeft,
                    backgroundColor: const Color.fromRGBO(255, 255, 255, 0.3),
                    color: Colors.white,
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 32),
                // Question Card
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
                // Options grid
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
    timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }
}
