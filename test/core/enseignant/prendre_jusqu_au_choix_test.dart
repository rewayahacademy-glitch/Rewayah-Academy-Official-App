// REMPLACEMENT-TEMPS-REEL (07/11/2026) : l'acceptation attend la fin de la
// fenetre de priorite dite par le serveur, puis rappelle avec la meme cle,
// sans jamais supposer d'issue (DECISION-REMPLACEMENT-2026-11-07.md).
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/enseignant/port_remplacements.dart';
import 'package:rewayah_academy/core/enseignant/remplacements_supabase.dart';

void main() {
  final DateTime maintenant = DateTime.utc(2026, 11, 8, 10);

  test('acceptee du premier coup : un seul appel, aucune attente', () async {
    int appels = 0;
    final List<Duration> attentes = <Duration>[];
    final Object? r = await prendreJusquAuChoix(
      appeler: () async {
        appels++;
        return <String, Object?>{'etat': 'acceptee'};
      },
      attendre: (Duration d) async => attentes.add(d),
      maintenant: () => maintenant,
    );
    expect((r! as Map<String, Object?>)['etat'], 'acceptee');
    expect(appels, 1);
    expect(attentes, isEmpty);
  });

  test(
    'en attente : dit la fenetre, attend sa fin, rappelle, rend le choix',
    () async {
      final List<Map<String, Object?>> reponses = <Map<String, Object?>>[
        <String, Object?>{
          'etat': 'enAttente',
          'finFenetre': maintenant
              .add(const Duration(seconds: 8))
              .toIso8601String(),
          'enTete': true,
        },
        <String, Object?>{'etat': 'dejaPrise'},
      ];
      final List<Duration> attentes = <Duration>[];
      final List<AttenteRemplacement> vues = <AttenteRemplacement>[];
      final Object? r = await prendreJusquAuChoix(
        appeler: () async => reponses.removeAt(0),
        attendre: (Duration d) async => attentes.add(d),
        maintenant: () => maintenant,
        enAttente: vues.add,
      );
      expect((r! as Map<String, Object?>)['etat'], 'dejaPrise');
      expect(vues.single.enTete, isTrue);
      expect(vues.single.fin, maintenant.add(const Duration(seconds: 8)));
      expect(attentes.single, const Duration(seconds: 9));
    },
  );

  test('horloge de l appareil tres decalee : l attente reste bornee', () async {
    final List<Duration> attentes = <Duration>[];
    await prendreJusquAuChoix(
      appeler: () async => attentes.isEmpty
          ? <String, Object?>{
              'etat': 'enAttente',
              'finFenetre': maintenant
                  .add(const Duration(hours: 1))
                  .toIso8601String(),
            }
          : <String, Object?>{'etat': 'acceptee'},
      attendre: (Duration d) async => attentes.add(d),
      maintenant: () => maintenant,
    );
    expect(attentes.single, const Duration(seconds: 11));
  });

  test('toujours en attente apres les essais : rend l attente, jamais un '
      'succes suppose', () async {
    int appels = 0;
    final Object? r = await prendreJusquAuChoix(
      appeler: () async {
        appels++;
        return <String, Object?>{
          'etat': 'enAttente',
          'finFenetre': maintenant.toIso8601String(),
        };
      },
      attendre: (Duration d) async {},
      maintenant: () => maintenant,
      essais: 3,
    );
    expect(appels, 3);
    expect((r! as Map<String, Object?>)['etat'], 'enAttente');
  });
}
