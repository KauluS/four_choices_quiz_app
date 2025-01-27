class Quiz {
  final int? id;
  final String question;
  final String options;
  final String answer;

  Quiz(
      {this.id,
      required this.question,
      required this.options,
      required this.answer});

  // データベースから取得したマップをモデルに変換するファクトリコンストラクタ
  factory Quiz.fromMap(Map<String, dynamic> map) {
    return Quiz(
      id: map['id'],
      question: map['question'],
      options: map['options'],
      answer: map['answer'],
    );
  }

  // モデルをデータベースに挿入するためのマップに変換するメソッド
  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      'question': question,
      'options': options,
      'answer': answer,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }
}
