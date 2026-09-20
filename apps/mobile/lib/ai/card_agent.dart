import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/card_models.dart';

class CardPreset {
  const CardPreset(
    this.id,
    this.skill,
    this.name,
    this.front,
    this.back,
    this.layout,
  );
  final String id, skill, name, front, back, layout;
  Map<String, dynamic> get rules => {
    'preset': id,
    'skill': skill,
    'front': front,
    'back': back,
    'layout': layout,
  };
  static const all = [
    CardPreset(
      'word-simple',
      'word',
      '简洁单词',
      '单词居中，音标与词性作为辅助信息',
      '释义、双语例句与常用句型同页，搭配与词形按需查看',
      'centered',
    ),
    CardPreset(
      'word-detail',
      'word',
      '单词详解',
      '单词左对齐，音标与词性作为辅助信息',
      '释义、例句与搭配、易混淆点分区排列',
      'stacked',
    ),
    CardPreset(
      'knowledge-qa',
      'knowledge',
      '知识问答',
      '突出问题，必要背景作为辅助信息',
      '先给简短答案，再解释或分步推导',
      'stacked',
    ),
    CardPreset(
      'poetry-overview',
      'poetry',
      '诗词全篇',
      '题目、作者、朝代分行居中',
      '原文与释义逐句对应，字词注释独立分节；双调词按上阕、下阕切换',
      'centered',
    ),
    CardPreset(
      'poetry-recall',
      'poetry',
      '诗词接句',
      '展示上一句，不泄露下一句',
      '下一句原文在上，释义在下',
      'centered',
    ),
    CardPreset(
      'classical-translation',
      'classical',
      '古文研读',
      '题目、作者、朝代分行居中',
      '原文、释义、字词注释各一页；有可靠背景时增加背景页',
      'stacked',
    ),
    CardPreset(
      'classical-words',
      'classical',
      '古文字词',
      '展示字词，必要时附语境',
      '原句、读音、文中古义依次排列',
      'centered',
    ),
  ];
}

Map<String, dynamic> draftToJson(WordCardDraft card) => {
  'prompt': card.prompt,
  'hint': card.hint,
  'presentation': card.presentation,
  if (card.wordContent != null) 'word_data': card.wordContent!.toJson(),
  'sections': [
    for (final s in card.sections)
      {'title': s.title, 'heading': s.heading, 'body': s.body},
  ],
};
WordCardDraft draftFromJson(Map<String, dynamic> json) => WordCardDraft(
  prompt: json['prompt'] as String,
  hint: json['hint'] as String? ?? '',
  presentation: Map<String, dynamic>.from(json['presentation'] as Map? ?? {}),
  wordContent: json['word_data'] is Map
      ? WordCardContent.fromJson(Map<String, dynamic>.from(json['word_data']))
      : null,
  sections: [
    for (final s in json['sections'] as List)
      CardBackSection(
        title: s['title'],
        heading: s['heading'],
        body: s['body'],
      ),
  ],
);

abstract interface class CardAgent {
  String get owner;
  Future<Map<String, dynamic>> send(Map<String, dynamic> request);
}

class SupabaseCardAgent implements CardAgent {
  const SupabaseCardAgent(this.client);
  final SupabaseClient client;
  @override
  String get owner => client.auth.currentUser?.id ?? 'signed-out';
  @override
  Future<Map<String, dynamic>> send(Map<String, dynamic> request) async {
    if (client.auth.currentUser == null) {
      throw StateError('authentication_required');
    }
    final result = await client.functions.invoke('card-agent', body: request);
    if (result.status != 200 || result.data is! Map) {
      throw StateError('agent_failed');
    }
    return Map<String, dynamic>.from(result.data);
  }
}

class AgentSessionStore {
  AgentSessionStore(this.owner);
  final String owner;
  String get _key => 'card-agent-session-v1:$owner';
  Future<Map<String, dynamic>?> load() async {
    final value = (await SharedPreferences.getInstance()).getString(_key);
    if (value == null) return null;
    return Map<String, dynamic>.from(jsonDecode(value));
  }

  Future<void> save(Map<String, dynamic> session) async {
    if (!await (await SharedPreferences.getInstance()).setString(
      _key,
      jsonEncode(session),
    )) {
      throw StateError('session_save_failed');
    }
  }

  Future<void> clear() async =>
      (await SharedPreferences.getInstance()).remove(_key);
}

Map<String, dynamic> cloneAgentJson(Map<String, dynamic> value) =>
    Map<String, dynamic>.from(jsonDecode(jsonEncode(value)));
