import 'package:flutter/material.dart';
import 'edit_page_mobile.dart';
import 'edit_page_desktop.dart';
import 'quiz_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  /// ボタン内に表示する【アイコン＋テキスト】を生成するヘルパー
  Widget _buildButtonContent(IconData icon, String label) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // 背景グラデーション
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade300,
              Colors.blue.shade600,
            ],
          ),
        ),
        child: SafeArea(
          // CenterとPaddingで全体を中央にまとめ、横幅の余白を確保
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              // mainAxisSize.minで必要な分だけ高さをとる
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.quiz,
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'English Quiz',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Test your English knowledge',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color.fromRGBO(255, 255, 255, 0.9),
                    ),
                  ),
                  const SizedBox(height: 48),
                  // 「Start Quiz」ボタン（ElevatedButton）
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const QuizPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: _buildButtonContent(Icons.play_arrow, 'Start Quiz'),
                  ),
                  const SizedBox(height: 16),
                  // 「Edit Questions」ボタン（OutlinedButton）
                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) {
                            final width = MediaQuery.of(context).size.width;
                            return width >= 600
                                ? const EditPageDesktop()
                                : const EditPageMobile();
                          },
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _buildButtonContent(Icons.edit, 'Edit Questions'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
