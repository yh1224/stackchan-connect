import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

class StackchanConfig {
  final int? id;
  final String name;
  final String ipAddress;
  final Map<String, Object?> config;

  StackchanConfig({
    this.id,
    required this.name,
    required this.ipAddress,
    this.config = const {},
  });

  StackchanConfig copyWith({
    int? id,
    String? name,
    String? ipAddress,
    Map<String, Object?>? config,
  }) =>
      StackchanConfig(
        id: id ?? this.id,
        name: name ?? this.name,
        ipAddress: ipAddress ?? this.ipAddress,
        config: config ?? this.config,
      );
}

class StackchanRepository {
  static const String dbFileName = "stackchan.db";
  static const String tableName = "stackchan";

  static const List<List<String>> migration = [
    [
      """
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        ip_address TEXT,
        config TEXT
      );
      """,
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
        // Re-create the database
        await db.execute("DROP TABLE $tableName");
        await _migrate(db, 0, newVersion);
      },
      version: migration.length,
    );
  }

  Future<List<StackchanConfig>> getStackchanConfigs() async {
    final messages = await (await db).query(tableName, orderBy: "name");
    return List.generate(messages.length, (i) {
      return StackchanConfig(
        id: messages[i]["id"] as int,
        name: messages[i]["name"] as String,
        ipAddress: messages[i]["ip_address"] as String,
        config: jsonDecode(messages[i]["config"] as String).cast<String, Object?>(),
      );
    });
  }

  Future<StackchanConfig> save(StackchanConfig stackchanConfig) async {
    if (stackchanConfig.id == null) {
      final id = await (await db).insert(
        tableName,
        {
          "name": stackchanConfig.name,
          "ip_address": stackchanConfig.ipAddress,
          "config": jsonEncode(stackchanConfig.config),
        },
      );
      return stackchanConfig.copyWith(id: id);
    } else {
      await (await db).update(
        tableName,
        {
          "name": stackchanConfig.name,
          "ip_address": stackchanConfig.ipAddress,
          "config": jsonEncode(stackchanConfig.config),
        },
        where: "id = ?",
        whereArgs: [stackchanConfig.id],
      );
      return stackchanConfig;
    }
  }

  Future<void> remove(StackchanConfig stackchanConfig) async {
    await (await db).delete(
      tableName,
      where: "id = ?",
      whereArgs: [stackchanConfig.id],
    );
  }
}
