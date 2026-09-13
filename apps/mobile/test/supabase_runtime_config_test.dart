import 'package:flutter_test/flutter_test.dart';
import 'package:loopcard/auth/supabase_runtime_config.dart';

void main() {
  test('default mobile auth config targets the hosted Supabase project', () {
    final config = SupabaseRuntimeConfig.resolve(
      configuredUrl: '',
      configuredPublishableKey: '',
      legacyAnonKey: '',
    );

    expect(Uri.parse(config.url).scheme, 'https');
    expect(Uri.parse(config.url).host, 'hzntwddwaayzrgbwprif.supabase.co');
    expect(config.publishableKey, startsWith('sb_publishable_'));
  });

  test('compile-time auth config overrides the hosted defaults', () {
    final config = SupabaseRuntimeConfig.resolve(
      configuredUrl: 'https://example.supabase.co',
      configuredPublishableKey: 'sb_publishable_override',
      legacyAnonKey: '',
    );

    expect(config.url, 'https://example.supabase.co');
    expect(config.publishableKey, 'sb_publishable_override');
  });

  test('rejects an incomplete compile-time override', () {
    expect(
      () => SupabaseRuntimeConfig.resolve(
        configuredUrl: 'https://example.supabase.co',
        configuredPublishableKey: '',
        legacyAnonKey: '',
      ),
      throwsArgumentError,
    );
  });
}
