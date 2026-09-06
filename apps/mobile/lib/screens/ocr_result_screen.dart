import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/loop_theme.dart';
import '../widgets/design_canvas.dart';
import '../widgets/glass_surface.dart';

class OcrResultScreen extends StatefulWidget {
  const OcrResultScreen({super.key, required this.words, this.onConfirm});

  final List<String> words;
  final ValueChanged<List<String>>? onConfirm;

  @override
  State<OcrResultScreen> createState() => _OcrResultScreenState();
}

class _OcrResultScreenState extends State<OcrResultScreen> {
  late final Set<String> _selectedWords = widget.words.toSet();

  void _toggleWord(String word, bool selected) {
    setState(() {
      if (selected) {
        _selectedWords.add(word);
      } else {
        _selectedWords.remove(word);
      }
    });
  }

  void _confirm() {
    final selected = widget.words
        .where(_selectedWords.contains)
        .toList(growable: false);
    final onConfirm = widget.onConfirm;
    if (onConfirm != null) {
      onConfirm(selected);
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
    return DesignCanvas(
      child: GradientPage(
        children: [
          Positioned(
            left: 20,
            top: 44,
            child: IconButton(
              tooltip: context.l10n.tr('back'),
              onPressed: () => Navigator.of(context).maybePop(),
              icon: Icon(
                Icons.arrow_back_rounded,
                color: context.loopColors.ink,
              ),
            ),
          ),
          Positioned(
            left: 32,
            top: 104,
            child: Text(
              context.l10n.tr('recognitionResults'),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: context.loopColors.ink,
              ),
            ),
          ),
          Positioned(
            left: 32,
            top: 148,
            child: Text(
              context.l10n.tr('selectedWords', {
                'count': _selectedWords.length,
              }),
              style: TextStyle(fontSize: 14, color: context.loopColors.muted),
            ),
          ),
          Positioned(
            left: 32,
            top: 188,
            width: 326,
            height: 500,
            child: GlassSurface(
              radius: 30,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 14),
                itemCount: widget.words.length,
                separatorBuilder: (context, _) => Divider(
                  height: 1,
                  indent: 24,
                  endIndent: 24,
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                    title: Text(
                      word,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        color: context.loopColors.ink,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned(
            left: 32,
            top: 724,
            width: 326,
            height: 60,
            child: FilledButton(
              onPressed: _selectedWords.isEmpty ? null : _confirm,
              style: FilledButton.styleFrom(
                backgroundColor: LoopTheme.teal,
                foregroundColor: const Color(0xFF091413),
                disabledBackgroundColor: const Color(0x4DFFFFFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text(
                context.l10n.tr('confirmSelection'),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
