import 'dart:io';
import 'package:flutter/material.dart';

import '../widgets/app_page.dart';
import '../ocr/photo_batch.dart';

class PhotoBatchScreen extends StatefulWidget {
  const PhotoBatchScreen({super.key, required this.flow});
  final PhotoCaptureFlow flow;
  @override
  State<PhotoBatchScreen> createState() => _PhotoBatchScreenState();
}

class _PhotoBatchScreenState extends State<PhotoBatchScreen> {
  final _batch = PhotoBatch();
  bool _busy = false;
  String? _error;
  Future<void> _capture([CapturedPhoto? previous]) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final photo = await widget.flow.capturePhoto();
      if (!mounted || photo == null) return;
      setState(() {
        if (previous == null) {
          _batch.add(photo);
        } else if (!photo.error) {
          _batch.replace(previous.id, photo);
        } else {
          _error = '重拍识别失败，已保留原照片。请重试。';
        }
      });
    } catch (_) {
      if (mounted) setState(() => _error = '拍摄失败，请检查相机权限后重试。');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _retry(CapturedPhoto photo) async {
    setState(() => _busy = true);
    try {
      final next = await widget.flow.recognizePhoto(photo);
      if (mounted) setState(() => _batch.replace(photo.id, next));
    } catch (_) {
      if (mounted) setState(() => _error = '云端识别失败，已保留照片。请检查登录和网络后重试。');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit(CapturedPhoto photo) async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _PhotoTextEditor(text: photo.text),
    );
    if (result != null && mounted) {
      setState(() => _batch.replace(photo.id, photo.withText(result.trim())));
    }
  }

  @override
  Widget build(BuildContext context) => AppPage(
    title: '拍照素材 · ${_batch.photos.length}/10',
    contentGutters: false,
    child: Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            '连续拍摄后一起提交。逐张校对识别内容，最多 10 张照片、4000 字。照片将上传至云端，由 OpenRouter 的 Qwen3-VL 识别，请联网使用。',
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        if (_busy) const LinearProgressIndicator(),
        Expanded(
          child: _batch.photos.isEmpty
              ? const Center(child: Text('拍下第一张学习素材'))
              : ListView.builder(
                  itemCount: _batch.photos.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, i) {
                    final p = _batch.photos[i];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                InkWell(
                                  onTap: () => showDialog<void>(
                                    context: context,
                                    builder: (context) => Dialog(
                                      child: InteractiveViewer(
                                        child: Image.file(
                                          File(p.path),
                                          errorBuilder: (_, _, _) =>
                                              const Text('照片暂不可用'),
                                        ),
                                      ),
                                    ),
                                  ),
                                  child: Image.file(
                                    File(p.path),
                                    width: 76,
                                    height: 90,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const SizedBox(
                                      width: 76,
                                      height: 90,
                                      child: Icon(Icons.photo),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '照片 ${i + 1}\n${p.error ? '识别失败 · 请重试、重拍或校对' : p.text}',
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            Wrap(
                              spacing: 8,
                              children: [
                                TextButton(
                                  onPressed: _busy ? null : () => _edit(p),
                                  child: const Text('校对 / 删减'),
                                ),
                                TextButton(
                                  onPressed: _busy ? null : () => _capture(p),
                                  child: const Text('重拍'),
                                ),
                                if (p.error)
                                  TextButton(
                                    onPressed: _busy ? null : () => _retry(p),
                                    child: const Text('重试识别'),
                                  ),
                                TextButton(
                                  onPressed: _busy
                                      ? null
                                      : () =>
                                            setState(() => _batch.remove(p.id)),
                                  child: const Text('删除'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        if (!_batch.canSubmit && _batch.photos.isNotEmpty)
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text('请处理识别失败或空白素材，并将总文字控制在 4000 字内。'),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy || _batch.photos.length >= 10
                      ? null
                      : () => _capture(),
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: Text(_batch.photos.isEmpty ? '拍照' : '补拍'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _busy || !_batch.canSubmit
                      ? null
                      : () => Navigator.pop(context, _batch.sources),
                  child: const Text('提交并定制卡片'),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _PhotoTextEditor extends StatefulWidget {
  const _PhotoTextEditor({required this.text});
  final String text;
  @override
  State<_PhotoTextEditor> createState() => _PhotoTextEditorState();
}

class _PhotoTextEditorState extends State<_PhotoTextEditor> {
  late final _controller = TextEditingController(text: widget.text);
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('校对素材'),
    content: SizedBox(
      width: 440,
      child: TextField(
        controller: _controller,
        minLines: 4,
        maxLines: 12,
        maxLength: 4000,
        decoration: const InputDecoration(helperText: '可修改文字、删除不需要的词或内容'),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('取消'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, _controller.text),
        child: const Text('完成'),
      ),
    ],
  );
}
