class SupabaseRuntimeConfig {
  const SupabaseRuntimeConfig({
    required this.url,
    required this.publishableKey,
  });

  static const _hostedUrl = 'https://hzntwddwaayzrgbwprif.supabase.co';
  static const _hostedPublishableKey =
      'sb_publishable_T_9Wjo2bbpSjrCOyT6Rs_w_otz0_18g';

  final String url;
  final String publishableKey;

  static SupabaseRuntimeConfig resolve({
    required String configuredUrl,
    required String configuredPublishableKey,
    required String legacyAnonKey,
  }) {
    final configuredKey = configuredPublishableKey.isNotEmpty
        ? configuredPublishableKey
        : legacyAnonKey;
    final hasUrl = configuredUrl.isNotEmpty;
    final hasKey = configuredKey.isNotEmpty;
    if (hasUrl != hasKey) {
      throw ArgumentError(
        'SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY must be provided together.',
      );
    }
    return SupabaseRuntimeConfig(
      url: hasUrl ? configuredUrl : _hostedUrl,
      publishableKey: hasKey ? configuredKey : _hostedPublishableKey,
    );
  }
}
