import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

class SpeechMessage {
  final int? id;
  final DateTime createdAt;
  final String text;

  SpeechMessage({this.id, required this.createdAt, required this.text});

  SpeechMessage copyWith({
    int? id,
    DateTime? createdAt,
    String? text,
  }) =>
      SpeechMessage(
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        text: text ?? this.text,
      );
}

class SpeechRepository {
  static const String dbFileName = "speech.db";
  static const String tableName = "messages";

  static const List<List<String>> migration = [
    [
      """
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        text TEXT
      );
      """
    ],
  ];

  Future<void> _migrate(Database db, int oldVersion, int newVersion) async {
    for (var i = oldVersion + 1; i <= newVersion; i++) {
      for (var query in migration[i - 1]) {
        debugPrint("$dbFileName: migrate to version $i \"$query\"");
        await db.execute(query);
      }
    }
  }

  Future<Database> get db async {
    return await openDatabase(
      dbFileName,
      onCreate: (Database db, int version) async {
        await _migrate(db, 0, version);
      },
      onUpgrade: _migrate,
      onDowngrade: (Database db, int oldVersion, int newVersion) async {
        // DB 作り直し
        await db.execute("DROP TABLE $tableName");
        await _migrate(db, 0, newVersion);
      },
      version: migration.length,
    );
  }

  Future<List<SpeechMessage>> getMessages(int limit) async {
    final messages = await (await db).query(
      tableName,
      orderBy: "created_at",
      limit: limit,
    );
    return List.generate(messages.length, (i) {
      return SpeechMessage(
        id: messages[i]["id"] as int,
        createdAt: DateTime.parse(messages[i]["created_at"] as String),
        text: messages[i]["text"] as String,
      );
    });
  }

  Future<SpeechMessage> append(SpeechMessage message) async {
    final id = await (await db).insert(tableName, {
      "created_at": message.createdAt.toUtc().toIso8601String(),
      "text": message.text,
    });
    return message.copyWith(id: id);
  }

  Future<void> remove(SpeechMessage message) async {
    await (await db).delete(
      tableName,
      where: "id = ?",
      whereArgs: [message.id],
    );
  }
}
