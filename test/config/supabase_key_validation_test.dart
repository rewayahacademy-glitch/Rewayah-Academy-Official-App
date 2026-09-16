import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/config/env.dart';

void main() {
  test('refuse les cles factices et les formes incompletes', () {
    expect(
      Env.cleSupabaseValide('cle-factice-playground-ne-jamais-utilisee'),
      isFalse,
    );
    expect(Env.cleSupabaseValide('eyJhbGciOiJIUzI1NiJ9.dummy.dummy'), isFalse);
    expect(Env.cleSupabaseValide('sb_publishable_fake'), isFalse);
    expect(Env.cleSupabaseValide(''), isFalse);
  });

  test('accepte une cle publishable opaque bien formee', () {
    expect(
      Env.cleSupabaseValide('sb_publishable_0123456789abcdefghijklmnop_abcdef'),
      isTrue,
    );
  });

  test('accepte la forme legacy anon JWT attendue par Supabase', () {
    expect(
      Env.cleSupabaseValide(
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
        'eyJpc3MiOiJzdXBhYmFzZSIsInJvbGUiOiJhbm9uIn0.signature',
      ),
      isTrue,
    );
  });
}
