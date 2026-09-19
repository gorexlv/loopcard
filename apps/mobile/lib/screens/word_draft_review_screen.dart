import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/card_models.dart';
import '../theme/loop_theme.dart';
import '../widgets/app_page.dart';
import '../widgets/glass_surface.dart';

class WordDraftReviewScreen extends StatefulWidget {
  const WordDraftReviewScreen({
    super.key,
    required this.loadDrafts,
    required this.onSave,
    required this.initialDeckTitle,
    this.extensionMode = false,
  });

  final Future<List<WordCardDraft>> Function() loadDrafts;
  final Future<void> Function(String title, List<WordCardDraft> drafts) onSave;
  final String initialDeckTitle;
  final bool extensionMode;

  @override
  State<WordDraftReviewScreen> createState() => _WordDraftReviewScreenState();
}

class _WordDraftReviewScreenState extends State<WordDraftReviewScreen> {
  late final TextEditingController _titleController = TextEditingController(
    text: widget.initialDeckTitle,
  );
  final PageController _pageController = PageController();
  List<WordCardDraft>? _drafts;
  Object? _error;
  int _index = 0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _drafts = null;
      _error = null;
      _index = 0;
    });
    try {
      final drafts = await widget.loadDrafts();
      if (!mounted) return;
      setState(() {
        _drafts = drafts;
        if (drafts.isEmpty) _error = StateError('empty_generation');
      });
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  Future<void> _edit(int index) async {
    final drafts = _drafts;
    if (drafts == null || index >= drafts.length) return;
    final edited = await Navigator.of(context).push<WordCardDraft>(
      MaterialPageRoute(
        builder: (_) => WordDraftEditScreen(draft: drafts[index]),
      ),
    );
    if (edited == null || !mounted) return;
    setState(() => drafts[index] = edited);
  }

  void _remove(int index) {
    final drafts = _drafts;
    if (drafts == null || index >= drafts.length) return;
    setState(() {
      drafts.removeAt(index);
      _index = drafts.isEmpty ? 0 : _index.clamp(0, drafts.length - 1);
    });
    if (drafts.isNotEmpty) {
      _pageController.jumpToPage(_index);
    }
  }

  Future<void> _save() async {
    final drafts = _drafts;
    final title = _titleController.text.trim();
    if (drafts == null || drafts.isEmpty || title.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      await widget.onSave(title, List.unmodifiable(drafts));
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.tr('saveCardsFailed'))),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: context.l10n.tr(
        widget.extensionMode ? 'extensionTitle' : 'reviewDrafts',
      ),
      actions: [
        if (_drafts case final drafts?)
          Text(drafts.isEmpty ? '0 / 0' : '${_index + 1} / ${drafts.length}'),
      ],
      footer: SizedBox(
        height: 60,
        child: FilledButton(
          key: const ValueKey('save-generated-cards'),
          onPressed: _drafts?.isNotEmpty == true && !_saving ? _save : null,
          style: FilledButton.styleFrom(
            backgroundColor: LoopTheme.teal,
            foregroundColor: const Color(0xFF091413),
            disabledBackgroundColor: context.loopColors.divider,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
          ),
          child: _saving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Color(0xFF091413),
                  ),
                )
              : Text(
                  context.l10n.tr('saveCards', {'count': _drafts?.length ?? 0}),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Text(
            context.l10n.tr(
              widget.extensionMode
                  ? 'extensionSubtitle'
                  : 'reviewDraftsSubtitle',
            ),
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: context.loopColors.muted,
            ),
          ),
          const SizedBox(height: 20),
          if (!widget.extensionMode)
            TextField(
              key: const ValueKey('captured-deck-title'),
              controller: _titleController,
              textInputAction: TextInputAction.done,
              style: TextStyle(fontSize: 16, color: context.loopColors.ink),
              decoration: InputDecoration(
                labelText: context.l10n.tr('deckName'),
                filled: true,
                fillColor: context.loopColors.glass,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: context.loopColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: context.loopColors.border),
                ),
              ),
            ),
          const SizedBox(height: 24),
          SizedBox(height: 420, child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.tr('generationFailedTitle'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: context.loopColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.tr('generationFailedBody'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: context.loopColors.muted),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: _load,
              child: Text(context.l10n.tr('retry')),
            ),
          ],
        ),
      );
    }
    final drafts = _drafts;
    if (drafts == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: LoopTheme.teal,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              context.l10n.tr('generatingCards'),
              style: TextStyle(fontSize: 15, color: context.loopColors.ink),
            ),
            const SizedBox(height: 6),
            Text(
              context.l10n.tr('generationReviewHint'),
              style: TextStyle(fontSize: 12, color: context.loopColors.muted),
            ),
          ],
        ),
      );
    }
    if (drafts.isEmpty) return const SizedBox.shrink();
    return PageView.builder(
      controller: _pageController,
      itemCount: drafts.length,
      onPageChanged: (value) => setState(() => _index = value),
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: _DraftCard(
          draft: drafts[index],
          onEdit: () => _edit(index),
          onRemove: () => _remove(index),
        ),
      ),
    );
  }
}

class _DraftCard extends StatelessWidget {
  const _DraftCard({
    required this.draft,
    required this.onEdit,
    required this.onRemove,
  });

  final WordCardDraft draft;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      radius: 28,
      blur: 10,
      color: context.loopColors.glassStrong,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.tr('aiDraft'),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          color: LoopTheme.amber,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        draft.prompt,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 31,
                          height: 1,
                          fontWeight: FontWeight.w700,
                          color: context.loopColors.ink,
                        ),
                      ),
                      if (draft.wordContent case final content?) ...[
                        const SizedBox(height: 7),
                        Text(
                          [
                            content.partOfSpeech,
                            ...content.pronunciations.map((value) => value.ipa),
                          ].where((value) => value.isNotEmpty).join('  '),
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: context.loopColors.muted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                TextButton(
                  onPressed: onRemove,
                  child: Text(context.l10n.tr('removeCard')),
                ),
              ],
            ),
            if (draft.reason.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                draft.reason,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: context.loopColors.muted,
                ),
              ),
            ],
            if (draft.hint.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                '${context.l10n.tr('cardHint')}: ${draft.hint}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: context.loopColors.muted,
                ),
              ),
            ],
            const SizedBox(height: 18),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: draft.learningSections.length,
                separatorBuilder: (_, _) =>
                    Divider(height: 22, color: context.loopColors.divider),
                itemBuilder: (context, index) {
                  final section = draft.learningSections[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.sectionTitle(section.title),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: context.loopColors.muted,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        section.heading,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: context.loopColors.ink,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        section.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: context.loopColors.muted,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: TextButton(
                onPressed: onEdit,
                child: Text(context.l10n.tr('editCard')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WordDraftEditScreen extends StatefulWidget {
  const WordDraftEditScreen({super.key, required this.draft});

  final WordCardDraft draft;

  @override
  State<WordDraftEditScreen> createState() => WordDraftEditScreenState();
}

class WordDraftEditScreenState extends State<WordDraftEditScreen> {
  late final TextEditingController _prompt = TextEditingController(
    text: widget.draft.prompt,
  );
  late final TextEditingController _hint = TextEditingController(
    text: widget.draft.hint,
  );
  late final List<TextEditingController> _headings = [
    for (final section in widget.draft.learningSections)
      TextEditingController(text: section.heading),
  ];
  late final List<TextEditingController> _bodies = [
    for (final section in widget.draft.learningSections)
      TextEditingController(text: section.body),
  ];

  @override
  void dispose() {
    _prompt.dispose();
    _hint.dispose();
    for (final controller in [..._headings, ..._bodies]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _done() {
    if (_prompt.text.trim().isEmpty ||
        _headings.any((value) => value.text.trim().isEmpty) ||
        _bodies.any((value) => value.text.trim().isEmpty)) {
      return;
    }
    final originalSections = widget.draft.learningSections;
    final sections = [
      for (var index = 0; index < originalSections.length; index++)
        CardBackSection(
          title: originalSections[index].title,
          heading: _headings[index].text.trim(),
          body: _bodies[index].text.trim(),
        ),
    ];
    final originalContent = widget.draft.wordContent;
    WordCardContent? wordContent;
    if (originalContent != null && widget.draft.presentation.isEmpty) {
      final meaningChanged = sections[0].body != originalSections[0].body;
      final exampleChanged = sections[1].body != originalSections[1].body;
      WordNote? noteFor(String title) {
        final index = sections.indexWhere((section) => section.title == title);
        if (index < 0) return null;
        return WordNote(
          heading: sections[index].heading,
          body: sections[index].body,
        );
      }

      wordContent = originalContent.copyWith(
        definition: sections[0].heading,
        englishDefinition: meaningChanged
            ? sections[0].body
            : originalContent.englishDefinition,
        usagePatterns: meaningChanged
            ? const []
            : originalContent.usagePatterns,
        example: WordExample(
          sentence: sections[1].heading,
          translation: exampleChanged
              ? sections[1].body
              : originalContent.example.translation,
        ),
        collocations: exampleChanged ? const [] : originalContent.collocations,
        confusion: noteFor('Common confusion'),
        extension: noteFor('Extension'),
      );
    }
    Navigator.of(context).pop(
      widget.draft.copyWith(
        prompt: _prompt.text.trim(),
        hint: _hint.text.trim(),
        sections: sections,
        wordContent: wordContent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: context.l10n.tr('editCard'),
      actions: [
        TextButton(onPressed: _done, child: Text(context.l10n.tr('done'))),
      ],
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          TextField(
            controller: _prompt,
            decoration: InputDecoration(
              labelText: context.l10n.tr('cardFront'),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _hint,
            maxLength: 160,
            decoration: InputDecoration(labelText: context.l10n.tr('cardHint')),
          ),
          const SizedBox(height: 30),
          for (
            var index = 0;
            index < widget.draft.learningSections.length;
            index++
          ) ...[
            Text(
              widget.draft.learningSections[index].title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: context.loopColors.ink,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _headings[index],
              decoration: InputDecoration(
                labelText: context.l10n.tr('sectionHeading'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bodies[index],
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: context.l10n.tr('sectionBody'),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 28),
          ],
        ],
      ),
    );
  }
}
