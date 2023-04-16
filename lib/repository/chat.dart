import 'package:sqflite/sqflite.dart';

class ChatMessage {
  static const String kindRequest = "request";
  static const String kindReply = "reply";
  static const String kindError = "error";

  final int? id;
  final DateTime createdAt;
  final String kind;
  final String text;

  ChatMessage({this.id, required this.createdAt, required this.kind, required this.text});
}

class ChatRepository {
  static const String dbFileName = "messages.db";
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

  Future<List<ChatMessage>> getMessages(int limit) async {
    final messages = await (await db).query(tableName, orderBy: "created_at", limit: limit);
    return List.generate(messages.length, (i) {
      return ChatMessage(
        id: messages[i]["id"] as int,
        createdAt: DateTime.parse(messages[i]["created_at"] as String),
        kind: messages[i]["kind"] as String,
        text: messages[i]["text"] as String,
      );
    });
  }

  Future<void> append(ChatMessage message) async {
    await (await db).insert(tableName, {
      "created_at": message.createdAt.toUtc().toIso8601String(),
      "kind": message.kind,
      "text": message.text,
    });
  }

  Future<void> clearAll() async {
    await (await db).delete(tableName);
  }

  static const testMessages = [
    "こんにちは",
    "こんにちは！良い天気ですね。何かお話したいことがあれば、どうぞおっしゃってください。",
    "良い天気ではないが？",
    "そうですか。どちらかというと、天気はあまり良くないということでしょうか？天気予報を確認していなかったので、申し訳ありません。今日はどのような天気なのでしょうか？",
    "今日は雨です。ちょっと寒いですね。",
    "お天気が悪いと気持ちも下がってしまいますね。お出かけ前には天気予報を確認して、適切な服装で外出することをおすすめします。それでも寒さが厳しい場合は、暖かいお茶やスープなどで体を温めてくださいね。",
    "おすすめのスープははありますか？",
    "おすすめのスープですね。寒い日でも美味しくて温まるスープといえば、ポトフやビーフシチュー、クリームシチューがおすすめです。特にポトフは、野菜たっぷりで栄養もたっぷり取れます。また、味噌汁や鶏ガラスープも、体を温める効果があります。どんなスープが好みかによって異なるかもしれませんが、いかがでしょうか？",
  ];

  Future<void> prepareTestData() async {
    await clearAll();
    for (int i = 0; i < testMessages.length; i++) {
      await append(ChatMessage(
        createdAt: DateTime.now(),
        kind: (i % 2 == 0) ? ChatMessage.kindRequest : ChatMessage.kindReply,
        text: testMessages[i],
      ));
    }
  }
}
