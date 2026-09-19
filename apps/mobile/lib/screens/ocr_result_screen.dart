import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/loop_theme.dart';
import '../widgets/app_page.dart';

class OcrResultScreen extends StatefulWidget {
  const OcrResultScreen({super.key, required this.words, this.onConfirm});

  final List<String> words;
  final FutureOr<void> Function(List<String>)? onConfirm;

  @override
  State<OcrResultScreen> createState() => _OcrResultScreenState();
}

class _OcrResultScreenState extends State<OcrResultScreen> {
  late final Set<String> _selectedWords = widget.words.take(30).toSet();
  bool _confirming = false;

  void _toggleWord(String word, bool selected) {
    setState(() {
      if (selected) {
        _selectedWords.add(word);
      } else {
        _selectedWords.remove(word);
      }
    });
  }

  Future<void> _confirm() async {
    final selected = widget.words
        .where(_selectedWords.contains)
        .toList(growable: false);
    final onConfirm = widget.onConfirm;
    if (onConfirm != null) {
      setState(() => _confirming = true);
      try {
        await onConfirm(selected);
      } finally {
        if (mounted) setState(() => _confirming = false);
      }
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.l10n.tr('confirmedWords', {'count': selected.length}),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: context.l10n.tr('recognitionResults'),
      footer: SizedBox(
        height: 60,
        child: FilledButton(
          onPressed: _selectedWords.isEmpty || _confirming ? null : _confirm,
          style: FilledButton.styleFrom(
            backgroundColor: LoopTheme.teal,
            foregroundColor: const Color(0xFF091413),
            disabledBackgroundColor: const Color(0x4DFFFFFF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          child: _confirming
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Color(0xFF091413),
                  ),
                )
              : Text(
                  context.l10n.tr('confirmSelection'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
      child: CustomScrollView(
        key: const ValueKey('recognized-word-list'),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                context.l10n.tr('selectedWords', {
                  'count': _selectedWords.length,
                }),
                style: TextStyle(fontSize: 14, color: context.loopColors.muted),
              ),
            ),
          ),
          SliverList.separated(
            itemCount: widget.words.length,
            separatorBuilder: (context, _) => Divider(
              height: 1,
              indent: 54,
              color: context.loopColors.divider,
            ),
            itemBuilder: (context, index) {
              final word = widget.words[index];
              return CheckboxListTile(
                value: _selectedWords.contains(word),
                onChanged: (value) => _toggleWord(word, value ?? false),
                activeColor: LoopTheme.teal,
                checkColor: const Color(0xFF091413),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: const EdgeInsets.symmetric(horizontal: 2),
                minTileHeight: 64,
                title: Text(
                  word,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: context.loopColors.ink,
                  ),
                ),
                shape: const RoundedRectangleBorder(),
              );
            },
          ),
        ],
      ),
    );
  }
}
