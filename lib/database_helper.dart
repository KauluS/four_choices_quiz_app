import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'model.dart';

class DatabaseHelper {
  // データベース名とバージョンを定義
  static final _databaseName = "quiz_app.db";
  static final _databaseVersion = 1;

  // テーブル名を定義
  static final table = 'quiz';

  // カラム名を定義
  static final columnId = 'id';
  static final columnQuestion = 'question';
  static final columnOptions = 'options';
  static final columnAnswer = 'answer';

  // プライベートコンストラクタ
  DatabaseHelper._privateConstructor();
  // シングルトンインスタンスを作成
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // データベースインスタンスを保持する変数
  static Database? _database;

  // データベースインスタンスを取得する非同期メソッド
  Future<Database> get database async {
    // 既にデータベースが初期化されている場合はそれを返す
    if (_database != null) return _database!;
    // 初期化されていない場合はデータベースを初期化
    _database = await _initDatabase();
    return _database!;
  }

  // データベースを初期化する非同期メソッド
  Future<Database> _initDatabase() async {
    // データベースのパスを作成
    String path =
        join((await getApplicationDocumentsDirectory()).path, _databaseName);

    // デスクトップ環境の場合はsqflite_common_ffiを使用
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      var databaseFactory = databaseFactoryFfi;
      return await databaseFactory.openDatabase(path,
          options: OpenDatabaseOptions(
            version: _databaseVersion,
            onCreate: _onCreate,
          ));
    } else {
      // モバイル環境の場合はsqfliteを使用
      return await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
      );
    }
  }

  // データベースを作成する非同期メソッド
  Future _onCreate(Database db, int version) async {
    // テーブルを作成するSQL文を実行
    await db.execute('''
      CREATE TABLE $table (
        $columnId INTEGER PRIMARY KEY,
        $columnQuestion TEXT NOT NULL,
        $columnOptions TEXT NOT NULL,
        $columnAnswer TEXT NOT NULL
      )
    ''');
  }

  // データを挿入する非同期メソッド
  Future<int> insert(Quiz quiz) async {
    // データベースインスタンスを取得
    Database db = await instance.database;
    // テーブルにデータを挿入
    return await db.insert(table, quiz.toMap());
  }

  // 全ての行をクエリする非同期メソッド
  Future<List<Quiz>> queryAllRows() async {
    // データベースインスタンスを取得
    Database db = await instance.database;
    // テーブルの全ての行をクエリ
    final List<Map<String, dynamic>> maps = await db.query(table);
    // マップをリストに変換
    return List.generate(maps.length, (i) {
      return Quiz.fromMap(maps[i]);
    });
  }

  // データを更新する非同期メソッド
  Future<int> update(Quiz quiz) async {
    // データベースインスタンスを取得
    Database db = await instance.database;
    // 更新する行のIDを取得
    int id = quiz.id!;
    // テーブルのデータを更新
    return await db
        .update(table, quiz.toMap(), where: '$columnId = ?', whereArgs: [id]);
  }

  // データを削除する非同期メソッド
  Future<int> delete(int id) async {
    // データベースインスタンスを取得
    Database db = await instance.database;
    // テーブルのデータを削除
    return await db.delete(table, where: '$columnId = ?', whereArgs: [id]);
  }
}
