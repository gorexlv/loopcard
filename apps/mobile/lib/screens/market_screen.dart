import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../data/deck_repository.dart';
import '../l10n/app_localizations.dart';
import '../theme/loop_theme.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key, required this.onAddDeck});

  final Future<MarketAddResult> Function(String slug) onAddDeck;

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  static const _configuredBaseUrl = String.fromEnvironment(
    'MARKET_BASE_URL',
    defaultValue: 'https://loopcard.dev',
  );

  late final Uri _marketOrigin = Uri.parse(_configuredBaseUrl);
  late final WebViewController _controller;
  int _progress = 0;
  bool _loadFailed = false;
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFF4F1E9))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) => setState(() => _progress = progress),
          onPageStarted: (_) => setState(() => _loadFailed = false),
          onWebResourceError: (error) {
            if (error.isForMainFrame ?? true) {
              setState(() => _loadFailed = true);
            }
          },
          onNavigationRequest: _handleNavigation,
        ),
      )
      ..loadRequest(
        _marketOrigin.replace(
          path: '/market',
          queryParameters: {'embedded': '1'},
        ),
      );
  }

  NavigationDecision _handleNavigation(NavigationRequest request) {
    final uri = Uri.tryParse(request.url);
    if (uri == null) return NavigationDecision.prevent;
    if (uri.scheme == 'loopcard' &&
        uri.host == 'market' &&
        uri.path == '/import') {
      final slug = uri.queryParameters['slug'];
      if (slug != null && slug.isNotEmpty) _addDeck(slug);
      return NavigationDecision.prevent;
    }
    final trusted =
        uri.scheme == _marketOrigin.scheme &&
        uri.host == _marketOrigin.host &&
        uri.port == _marketOrigin.port;
    return trusted ? NavigationDecision.navigate : NavigationDecision.prevent;
  }

  Future<void> _addDeck(String slug) async {
    if (_adding) return;
    setState(() => _adding = true);
    try {
      final result = await widget.onAddDeck(slug);
      if (!mounted) return;
      final message = result == MarketAddResult.added
          ? context.l10n.tr('marketAdded')
          : context.l10n.tr('marketAlreadyAdded');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.tr('marketAddFailed'))),
      );
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.tr('market')),
        backgroundColor: context.loopColors.pageBackground,
        foregroundColor: context.loopColors.ink,
        surfaceTintColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          if (!_loadFailed) WebViewWidget(controller: _controller),
          if (_loadFailed)
            Center(
              child: FilledButton.icon(
                onPressed: () => _controller.reload(),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(context.l10n.tr('marketLoadFailed')),
              ),
            ),
          if (_progress < 100 && !_loadFailed)
            LinearProgressIndicator(value: _progress / 100),
          if (_adding)
            const ColoredBox(
              color: Color(0x33000000),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
