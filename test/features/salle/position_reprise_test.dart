// CAHIER-C1 (06/11/2026) : la position de reprise tenue par le serveur.
// La memoire de la salle envoie chaque nouvelle page, une fois ; la
// preparation de seance relit la page ; la reponse serveur se lit sans
// supposer une page.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/fiche_groupe/preparation_seance.dart';
import 'package:rewayah_academy/features/salle/memoire_page_classe.dart';
import 'package:rewayah_academy/features/salle/position_reprise.dart';
import 'package:rewayah_academy/features/salle/position_reprise_supabase.dart';

/// Un port qui retient les envois et rend des pages fixees.
class FauxPositionReprise implements PortPositionReprise {
  FauxPositionReprise({this.pageClasse, this.pageSeance, this.echecs = 0});

  final int? pageClasse;
  final int? pageSeance;
  int echecs;
  final List<(String, int)> envois = <(String, int)>[];

  @override
  Future<int?> pageDeLaClasse(String groupeId) async => pageClasse;

  @override
  Future<int?> pageDeLaSeance(String sessionId) async => pageSeance;

  @override
  Future<void> enregistrer({
    required String sessionId,
    required int page,
  }) async {
    if (echecs > 0) {
      echecs--;
      throw StateError('reseau');
    }
    envois.add((sessionId, page));
  }
}

Future<void> _laisserPartir() => Future<void>.delayed(Duration.zero);

void main() {
  group('MemoirePageClasse vers le serveur', () {
    test(
      'une page change : un seul envoi, meme apres plusieurs ecritures',
      () async {
        final FauxPositionReprise port = FauxPositionReprise();
        final MemoirePageClasse memoire = MemoirePageClasse(port);

        memoire.ecrire('c1', 14, sessionId: 's1');
        memoire.ecrire('c1', 14, sessionId: 's1');
        await _laisserPartir();
        memoire.ecrire('c1', 14, sessionId: 's1');
        await _laisserPartir();

        expect(port.envois, <(String, int)>[('s1', 14)]);
        expect(memoire.lire('c1'), 14);

        memoire.ecrire('c1', 15, sessionId: 's1');
        await _laisserPartir();
        expect(port.envois, <(String, int)>[('s1', 14), ('s1', 15)]);
      },
    );

    test(
      'un echec d envoi : la meme page repart a la prochaine ecriture',
      () async {
        final FauxPositionReprise port = FauxPositionReprise(echecs: 1);
        final MemoirePageClasse memoire = MemoirePageClasse(port);

        memoire.ecrire('c1', 14, sessionId: 's1');
        await _laisserPartir();
        expect(port.envois, isEmpty);
        // La salle ne perd pas la page pour autant.
        expect(memoire.lire('c1'), 14);

        memoire.ecrire('c1', 14, sessionId: 's1');
        await _laisserPartir();
        expect(port.envois, <(String, int)>[('s1', 14)]);
      },
    );

    test(
      'sans Classe recue (remplacant) : la page part quand meme au serveur',
      () async {
        final FauxPositionReprise port = FauxPositionReprise();
        final MemoirePageClasse memoire = MemoirePageClasse(port);

        memoire.ecrire(null, 22, sessionId: 's9');
        await _laisserPartir();

        expect(port.envois, <(String, int)>[('s9', 22)]);
      },
    );

    test('page hors du Coran ou sans seance : rien ne part', () async {
      final FauxPositionReprise port = FauxPositionReprise();
      final MemoirePageClasse memoire = MemoirePageClasse(port);

      memoire.ecrire('c1', 0, sessionId: 's1');
      memoire.ecrire('c1', 605, sessionId: 's1');
      memoire.ecrire('c1', 30);
      await _laisserPartir();

      expect(port.envois, isEmpty);
      expect(memoire.lire('c1'), 30);
    });
  });

  group('preparationSeanceProvider', () {
    test('la page lue au serveur devient la position de reprise', () async {
      final ProviderContainer conteneur = ProviderContainer(
        overrides: <Override>[
          portPositionRepriseProvider.overrideWithValue(
            FauxPositionReprise(pageClasse: 14),
          ),
        ],
      );
      addTearDown(conteneur.dispose);

      conteneur.listen(preparationSeanceProvider('c1'), (_, _) {});
      await conteneur.read(pageRepriseClasseProvider('c1').future);

      final PreparationSeance? preparation = conteneur.read(
        preparationSeanceProvider('c1'),
      );
      expect(preparation?.pageReprise, 14);
      expect(preparation?.estVide, isFalse);
      expect(t.cahierC1.onReprendPage(page: 14), 'On reprend page 14');
    });

    test(
      'aucune page connue : aucune preparation, jamais une page supposee',
      () async {
        final ProviderContainer conteneur = ProviderContainer();
        addTearDown(conteneur.dispose);

        await conteneur.read(pageRepriseClasseProvider('c1').future);
        expect(conteneur.read(preparationSeanceProvider('c1')), isNull);
      },
    );
  });

  group('pageDepuisReponse', () {
    test('une ligne, aucune ligne, valeur inattendue', () {
      expect(
        pageDepuisReponse(<Object?>[
          <String, Object?>{'page': 14, 'presentee_le': '2026-11-06T10:00:00Z'},
        ]),
        14,
      );
      expect(pageDepuisReponse(<Object?>[]), isNull);
      expect(pageDepuisReponse(null), isNull);
      expect(pageDepuisReponse(<String, Object?>{'page': 700}), isNull);
      expect(pageDepuisReponse(<String, Object?>{'page': '14'}), isNull);
    });
  });
}
