import 'package:sqflite/sqflite.dart';

class Message {
  static const String kindRequest = "request";
  static const String kindReply = "reply";
  static const String kindError = "error";

  int? id;
  DateTime createdAt;
  String kind;
  String text;

  Message({this.id, required this.createdAt, required this.kind, required this.text});
}

class MessageRepository {
  static const String dbFileName = "messages";
  static const String tableName = "messages";

  Future<Database> get db async {
    return await openDatabase(
      dbFileName,
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE messages (id INTEGER PRIMARY KEY AUTOINCREMENT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, kind TEXT, text TEXT)",
        );
      },
      version: 1,
    );
  }

  Future<List<Message>> getMessages(int limit) async {
    final messages = await (await db).query(tableName, orderBy: "created_at", limit: limit);
    return List.generate(messages.length, (i) {
      return Message(
        id: messages[i]['id'] as int,
        createdAt: DateTime.parse(messages[i]['created_at'] as String),
        kind: messages[i]['kind'] as String,
        text: messages[i]['text'] as String,
      );
    });
  }

  void append(Message message) async {
    await (await db).insert(tableName, {
      "created_at": message.createdAt.toUtc().toIso8601String(),
      "kind": message.kind,
      "text": message.text,
    });
  }

  void clearAll() async {
    await (await db).delete(tableName);
  }
}
