import 'dart:math';
import 'package:flutter/material.dart';

import '../widgets/app_page.dart';
import '../ai/card_agent.dart';
import '../cards/editorial_card.dart';
import '../models/card_models.dart';
import '../theme/loop_theme.dart';
import 'word_draft_review_screen.dart';

String _sessionId() {
  final bytes = List.generate(16, (_) => Random.secure().nextInt(256));
  bytes[6] = (bytes[6] & 15) | 64;
  bytes[8] = (bytes[8] & 63) | 128;
  final h = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
}

class CardAgentScreen extends StatefulWidget {
  const CardAgentScreen({
    super.key,
    required this.agent,
    required this.store,
    required this.sources,
    required this.onSave,
    this.restored,
  });
  final CardAgent agent;
  final AgentSessionStore store;
  final List<Map<String, dynamic>> sources;
  final Map<String, dynamic>? restored;
  final Future<void> Function(String, List<String>, List<WordCardDraft>) onSave;
  @override
  State<CardAgentScreen> createState() => _CardAgentScreenState();
}

class _CardAgentScreenState extends State<CardAgentScreen> {
  final _input = TextEditingController();
  final _title = TextEditingController(text: '拍照卡片');
  final _scroll = ScrollController();
  late String _id;
  late List<Map<String, dynamic>> _sources;
  late List<Map<String, dynamic>> _messages;
  late Map<String, dynamic> _rules;
  int _revision = 1;
  bool _busy = false;
  bool _saved = false;
  String? _error;
  Map<String, dynamic>? _retryRequest;
  Future<void> _writes = Future.value();
  @override
  void initState() {
    super.initState();
    final restored = widget.restored;
    _id = restored?['id'] as String? ?? _sessionId();
    _sources = [
      for (final s in restored?['sources'] ?? widget.sources)
        Map<String, dynamic>.from(s),
    ];
    _rules = Map<String, dynamic>.from(
      restored?['rules'] ?? CardPreset.all.first.rules,
    );
    _revision = restored?['revision'] as int? ?? 1;
    _messages = [
      for (final m in restored?['messages'] ?? []) Map<String, dynamic>.from(m),
    ];
    _title.text = restored?['title'] as String? ?? '拍照卡片';
    _saved = restored?['saved'] == true;
    _retryRequest = restored?['pending'] is Map
        ? Map<String, dynamic>.from(restored!['pending'])
        : null;
    if (_retryRequest != null) _error = '上次请求未完成，可重试。';
    if (_messages.isEmpty) {
      _messages.add({
        'role': 'assistant',
        'content':
            '已收到 ${_sources.length} 张照片的素材。选一种排版查看正反面示例，或告诉我你希望怎样制作卡片。确认规则后点击生成。',
      });
    }
    _persist();
  }

  @override
  void dispose() {
    _input.dispose();
    _title.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _persist() {
    // Snapshot now; serialize writes so an earlier state cannot overwrite a later one.
    final state = {
      'id': _id,
      'sources': _sources,
      'rules': _rules,
      'revision': _revision,
      'messages': _messages,
      'title': _title.text,
      'saved': _saved,
      'pending': _retryRequest,
    };
    // JSON encoding in the store must happen before another interaction mutates state.
    final snapshot = _deepCopy(state);
    _writes = _writes
        .catchError((_) {})
        .then((_) => widget.store.save(snapshot));
    return _writes.catchError((_) {
      if (mounted) setState(() => _error = '会话暂未保存到设备，请保留当前页面并重试。');
    });
  }

  Map<String, dynamic> _deepCopy(Map<String, dynamic> value) =>
      cloneAgentJson(value);
  void _bottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_scroll.hasClients) {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  });
  void _select(CardPreset preset) {
    setState(() {
      _rules = preset.rules;
      _revision++;
      _retryRequest = null;
      _error = null;
      _messages.add({'role': 'user', 'content': '选用「${preset.name}」'});
      _messages.add({
        'role': 'assistant',
        'content': '已应用「${preset.name}」。这是排版示例，点击生成后会使用你的素材。',
        'rules': Map.of(_rules),
        'revision': _revision,
        'example': true,
        'cards': [draftToJson(_example())],
      });
    });
    _persist();
    _bottom();
  }

  WordCardDraft _example() {
    final literary = switch (_rules['preset']) {
      'poetry-overview' => (
        '《静夜思》· 李白',
        <CardBackSection>[
          const CardBackSection(
            title: '原文',
            heading: '静夜思',
            body: '床前明月光，疑是地上霜。\n举头望明月，低头思故乡。',
          ),
          const CardBackSection(
            title: '白话释义',
            heading: '思念故乡',
            body: '明月引起了对故乡的思念。',
          ),
        ],
      ),
      'poetry-recall' => (
        '床前明月光',
        <CardBackSection>[
          const CardBackSection(
            title: '下一句',
            heading: '疑是地上霜。',
            body: '《静夜思》· 李白',
          ),
          const CardBackSection(
            title: '释义',
            heading: '月光如霜',
            body: '床前明亮的月光，让人以为是地上的霜。',
          ),
        ],
      ),
      'classical-translation' => (
        '学而时习之，不亦说乎？',
        <CardBackSection>[
          const CardBackSection(
            title: '白话翻译',
            heading: '学习与温习',
            body: '学习后按时温习，不也是令人愉快的吗？',
          ),
          const CardBackSection(
            title: '重点字词',
            heading: '说',
            body: 'yuè，同“悦”，愉快。',
          ),
          const CardBackSection(
            title: '句意',
            heading: '温习的乐趣',
            body: '强调学习后反复温习带来的乐趣。',
          ),
        ],
      ),
      'classical-words' => (
        '说',
        <CardBackSection>[
          const CardBackSection(
            title: '原句',
            heading: '《论语·学而》',
            body: '学而时习之，不亦说乎？',
          ),
          const CardBackSection(title: '读音', heading: 'yuè', body: '此处同“悦”。'),
          const CardBackSection(
            title: '文中古义',
            heading: '高兴、愉快',
            body: '表示温习之后的愉快心情。',
          ),
        ],
      ),
      _ => null,
    };
    if (literary != null) {
      return WordCardDraft(
        prompt: literary.$1,
        sections: literary.$2,
        presentation: {..._rules, 'skill_version': '1'},
      );
    }
    final word = _rules['skill'] == 'word';
    return WordCardDraft(
      prompt: word ? 'example' : '这里显示从素材提炼的问题',
      hint: word ? '/ɪɡˈzɑːmpəl/ · n.' : '必要的背景或提示',
      presentation: {..._rules, 'skill_version': '1'},
      sections: [
        CardBackSection(
          title: word ? '释义' : '答案',
          heading: word ? '例子；示例' : '这里显示简短答案',
          body: '排版示例 · 正式内容将在生成后显示',
        ),
        CardBackSection(
          title: word ? '例句' : '解释',
          heading: word ? 'This is an example.' : '推导步骤',
          body: word ? '这是一个例子。' : '按顺序解释概念或解题过程。',
        ),
        if (_rules['preset'] == 'word-detail')
          const CardBackSection(
            title: '易混淆点',
            heading: '对比说明',
            body: '有可靠内容时展示，不确定时省略。',
          ),
      ],
    );
  }

  Future<void> _send(String action, {Map<String, dynamic>? retry}) async {
    if (_busy || _saved) return;
    if (retry == null && action == 'chat' && _input.text.trim().isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
      if (retry == null) {
        _messages.add({
          'role': 'user',
          'content': action == 'chat' ? _input.text.trim() : '按当前规则生成卡片',
        });
        if (action == 'chat') _input.clear();
      }
    });
    final request =
        retry ??
        {
          'action': action,
          'sources': _sources,
          'rules': Map.of(_rules),
          'locale': Localizations.localeOf(context).toLanguageTag(),
          'messages': [
            for (final m in _messages.takeLast(60))
              {'role': m['role'], 'content': m['content']},
          ],
        };
    _retryRequest = request;
    await _persist();
    _bottom();
    try {
      final result = await widget.agent.send(request);
      if (!mounted) return;
      final rules = Map<String, dynamic>.from(result['rules']);
      final cards = [
        for (final c in result['cards'] as List) Map<String, dynamic>.from(c),
      ];
      setState(() {
        _revision++;
        _rules = rules;
        for (final c in cards) {
          c['presentation'] = {
            ...Map<String, dynamic>.from(c['presentation'] ?? {}),
            'session_id': _id,
            'revision': _revision,
          };
        }
        _messages.add({
          'role': 'assistant',
          'content': result['reply'],
          'preview': request['action'] == 'chat',
          'rules': Map.of(rules),
          'revision': _revision,
          'cards': cards,
        });
        _retryRequest = null;
      });
    } catch (_) {
      if (mounted) setState(() => _error = '服务暂时不可用，素材与对话已保留。请重试。');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        await _persist();
        _bottom();
      }
    }
  }

  int get _currentDraftMessage => _messages.lastIndexWhere(
    (m) =>
        m['example'] != true &&
        m['preview'] != true &&
        m['revision'] == _revision &&
        (m['cards'] as List? ?? []).isNotEmpty,
  );
  Future<void> _edit(int message, int card) async {
    final rows = _messages[message]['cards'] as List;
    final edited = await Navigator.push<WordCardDraft>(
      context,
      MaterialPageRoute(
        builder: (_) => WordDraftEditScreen(
          draft: draftFromJson(Map<String, dynamic>.from(rows[card])),
        ),
      ),
    );
    if (edited != null && mounted) {
      setState(() => rows[card] = draftToJson(edited));
      await _persist();
    }
  }

  Future<void> _save() async {
    final index = _currentDraftMessage;
    if (_busy || _saved || index < 0 || _title.text.trim().isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onSave(
        _title.text.trim(),
        [for (final s in _sources) s['text'] as String],
        [
          for (final c in _messages[index]['cards'])
            draftFromJson(Map<String, dynamic>.from(c)),
        ],
      );
      _saved = true;
      await _persist();
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) setState(() => _error = '保存失败，可重试；不会重复创建卡组。');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Card Agent',
    actions: [
      IconButton(
        tooltip: '查看素材',
        icon: const Icon(Icons.description_outlined),
        onPressed: () => showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('本次素材'),
            content: SingleChildScrollView(
              child: Text(
                [
                  for (var i = 0; i < _sources.length; i++)
                    '照片 ${i + 1}\n${_sources[i]['text']}',
                ].join('\n\n'),
              ),
            ),
          ),
        ),
      ),
    ],
    contentGutters: false,
    child: Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length + 1,
            itemBuilder: (context, i) {
              if (i == _messages.length) return _choices();
              final m = _messages[i];
              final user = m['role'] == 'user';
              final rows = m['cards'] as List? ?? [];
              final current = i == _currentDraftMessage && !_saved;
              return Align(
                alignment: user ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 680),
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: user ? context.loopColors.glass : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user ? '你' : 'Card Agent',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const SizedBox(height: 8),
                      SelectableText(m['content']),
                      if (m['rules'] != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          '正面：${m['rules']['front']}\n背面：${m['rules']['back']}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      if (rows.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          m['example'] == true
                              ? '排版示例 · 非生成结果'
                              : m['preview'] == true
                              ? '方案预览 · 根据素材生成，尚未批量生成'
                              : current
                              ? '当前草稿 · 尚未保存'
                              : _saved && m['revision'] == _revision
                              ? '已保存'
                              : '历史草稿 · 规则版本 ${m['revision']}',
                        ),
                        AgentCardCarousel(
                          key: ValueKey('$i-${rows.length}'),
                          cards: [
                            for (final c in rows)
                              draftFromJson(Map<String, dynamic>.from(c)),
                          ],
                          onEdit: current && !_busy
                              ? (index) => _edit(i, index)
                              : null,
                          onRemove: current && !_busy
                              ? (index) {
                                  setState(() => rows.removeAt(index));
                                  _persist();
                                }
                              : null,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (_busy) const LinearProgressIndicator(),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
                if (_retryRequest != null)
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => _send(
                            _retryRequest!['action'],
                            retry: _retryRequest,
                          ),
                    child: const Text('重试'),
                  ),
              ],
            ),
          ),
        if (_currentDraftMessage >= 0 && !_saved)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _title,
                    maxLength: 120,
                    onChanged: (_) {
                      setState(() {});
                      _persist();
                    },
                    decoration: const InputDecoration(
                      labelText: '卡组名称',
                      counterText: '',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _busy || _title.text.trim().isEmpty ? null : _save,
                  child: const Text('确认保存'),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  enabled: !_busy && !_saved,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 3000,
                  decoration: const InputDecoration(
                    hintText: '例如：背面先显示例句，再显示释义',
                    counterText: '',
                  ),
                  onSubmitted: (_) => _send('chat'),
                ),
              ),
              IconButton(
                tooltip: '发送',
                onPressed: _busy || _saved ? null : () => _send('chat'),
                icon: const Icon(Icons.send_outlined),
              ),
            ],
          ),
        ),
      ],
    ),
  );
  Widget _choices() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ExpansionTile(
        key: ValueKey('presets-$_revision'),
        title: const Text('常用正反面排版'),
        initiallyExpanded:
            _messages.length == 1 && _messages.first['cards'] == null,
        tilePadding: EdgeInsets.zero,
        children: [
          for (final p in CardPreset.all)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton(
                onPressed: _busy || _saved ? null : () => _select(p),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      '${p.name}${_rules['preset'] == p.id ? ' · 已选' : ''}\n正面：${p.front}\n背面：${p.back}',
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      Text('当前规则\n正面：${_rules['front']}\n背面：${_rules['back']}'),
      const SizedBox(height: 12),
      FilledButton.icon(
        onPressed: _busy || _saved ? null : () => _send('generate'),
        icon: const Icon(Icons.auto_awesome_outlined),
        label: const Text('按当前规则生成卡片'),
      ),
    ],
  );
}

extension _LastMessages on List<Map<String, dynamic>> {
  Iterable<Map<String, dynamic>> takeLast(int n) =>
      skip(length > n ? length - n : 0);
}

class AgentCardCarousel extends StatefulWidget {
  const AgentCardCarousel({
    super.key,
    required this.cards,
    this.onEdit,
    this.onRemove,
  });
  final List<WordCardDraft> cards;
  final ValueChanged<int>? onEdit, onRemove;
  @override
  State<AgentCardCarousel> createState() => _AgentCardCarouselState();
}

class _AgentCardCarouselState extends State<AgentCardCarousel> {
  int _index = 0;
  bool _back = false;
  @override
  Widget build(BuildContext context) {
    if (widget.cards.isEmpty) return const SizedBox.shrink();
    final d = widget.cards[_index.clamp(0, widget.cards.length - 1)];
    return Column(
      children: [
        Row(
          children: [
            Text('${_index + 1} / ${widget.cards.length}'),
            const Spacer(),
            TextButton(
              onPressed: () => setState(() => _back = !_back),
              child: Text(_back ? '查看正面' : '查看背面'),
            ),
          ],
        ),
        SizedBox(
          height: 340,
          width: double.infinity,
          child: EditorialCard(
            card: StudyCard(
              id: 'preview',
              prompt: d.prompt,
              hint: d.hint,
              sections: d.sections,
              wordContent: d.wordContent,
              presentation: d.presentation,
            ),
            kind: cardKindForGenerationSkill(
              d.presentation['skill'] as String?,
            ),
            face: _back ? CardFace.back : CardFace.front,
          ),
        ),
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            IconButton(
              tooltip: '上一张',
              onPressed: _index > 0
                  ? () => setState(() {
                      _index--;
                      _back = false;
                    })
                  : null,
              icon: const Icon(Icons.chevron_left),
            ),
            IconButton(
              tooltip: '下一张',
              onPressed: _index < widget.cards.length - 1
                  ? () => setState(() {
                      _index++;
                      _back = false;
                    })
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
            if (widget.onEdit != null)
              TextButton(
                onPressed: () => widget.onEdit!(_index),
                child: const Text('编辑'),
              ),
            if (widget.onRemove != null)
              TextButton(
                onPressed: () => widget.onRemove!(_index),
                child: const Text('删除'),
              ),
          ],
        ),
      ],
    );
  }
}
