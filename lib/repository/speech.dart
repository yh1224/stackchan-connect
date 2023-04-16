import 'package:sqflite/sqflite.dart';

class SpeechMessage {
  final int? id;
  final DateTime createdAt;
  final String text;

  SpeechMessage({this.id, required this.createdAt, required this.text});
}

class SpeechRepository {
  static const String dbFileName = "speech.db";
  static const String tableName = "messages";

  Future<Database> get db async {
    return await openDatabase(
      dbFileName,
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE messages (id INTEGER PRIMARY KEY AUTOINCREMENT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, text TEXT)",
        );
      },
      version: 1,
    );
  }

  Future<List<SpeechMessage>> getMessages(int limit) async {
    final messages = await (await db).query(tableName, orderBy: "created_at", limit: limit);
    return List.generate(messages.length, (i) {
      return SpeechMessage(
        id: messages[i]["id"] as int,
        createdAt: DateTime.parse(messages[i]["created_at"] as String),
        text: messages[i]["text"] as String,
      );
    });
  }

  void append(SpeechMessage message) async {
    await (await db).insert(tableName, {
      "created_at": message.createdAt.toUtc().toIso8601String(),
      "text": message.text,
    });
  }

  void remove(SpeechMessage message) async {
    await (await db).delete(tableName, where: "id = ?", whereArgs: [message.id]);
  }

  void clearAll() async {
    await (await db).delete(tableName);
  }
}
