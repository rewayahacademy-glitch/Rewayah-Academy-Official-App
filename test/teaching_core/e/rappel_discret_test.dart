import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_classe/port_rappel_discret.dart';
import 'package:rewayah_academy/core/tc_classe/rappel_discret.dart';

/// Le rappel discret (spec section 10.2).
///
/// **Reussite silencieuse, echec dit.** Il n'existe aucun accuse de reception,
/// aucune boucle « envoye / revenu / confirme », et aucun micro ouvert a
/// distance : ce port n'a pas de methode qui le permettrait.
void main() {
  group('reussite silencieuse', () {
    test('un rappel qui part ne rend rien', () async {
      final List<(String, String)> partis = <(String, String)>[];
      final RappelDiscretCadence rappel = RappelDiscretCadence(
        transport: ({required String sessionId, required String academyId}) async =>
            partis.add((sessionId, academyId)),
      );

      // `rappeler` rend `Future<void>` : il n'y a **rien** a lire, et c'est la
      // garantie. Un transport qui rendrait un accuse ferait naitre la boucle
      // de notifications que la spec interdit.
      await rappel.rappeler(sessionId: 's1', academyId: 'RA-AB0012');
      expect(partis, <(String, String)>[('s1', 'RA-AB0012')]);
    });
  });

  group('echec', () {
    test('sans transport branche, le rappel dit qu il n aboutit pas', () async {
      // Le defaut du produit tant qu'Agent Z n'a pas branche
      // `PortRealtimePedagogique.emettreCible`. Un transport muet ferait croire
      // a l'enseignant que l'eleve a ete appele.
      final RappelDiscretCadence rappel = RappelDiscretCadence();
      await expectLater(
        rappel.rappeler(sessionId: 's1', academyId: 'RA-AB0012'),
        throwsA(
          isA<EchecRappel>().having(
            (EchecRappel e) => e.motif,
            'motif',
            MotifEchecRappel.transport,
          ),
        ),
      );
    });

    test('un motif nomme par le transport n est pas reemballe', () async {
      // Sans ce `rethrow`, « droit refuse » deviendrait « transport », et
      // l'enseignant lirait un probleme de reseau la ou son acces est en cause.
      final RappelDiscretCadence rappel = RappelDiscretCadence(
        transport: ({required String sessionId, required String academyId}) =>
            Future<void>.error(
              const EchecRappel(MotifEchecRappel.droitRefuse),
            ),
      );
      await expectLater(
        rappel.rappeler(sessionId: 's1', academyId: 'RA-AB0012'),
        throwsA(
          isA<EchecRappel>().having(
            (EchecRappel e) => e.motif,
            'motif',
            MotifEchecRappel.droitRefuse,
          ),
        ),
      );
    });

    test('un echec ne pose pas de cooldown', () async {
      // Une coupure reseau d'une seconde ne doit pas couter quarante-cinq
      // secondes de silence a l'eleve.
      final RappelDiscretCadence rappel = RappelDiscretCadence();
      await expectLater(
        rappel.rappeler(sessionId: 's1', academyId: 'RA-AB0012'),
        throwsA(isA<EchecRappel>()),
      );
      expect(
        rappel.cooldownRestant(sessionId: 's1', academyId: 'RA-AB0012'),
        isNull,
      );
    });
  });

  group('cooldown', () {
    test('un second rappel immediat est refuse, sans reproche', () async {
      DateTime maintenant = DateTime.utc(2026, 9, 20, 10);
      final RappelDiscretCadence rappel = RappelDiscretCadence(
        transport: ({required String sessionId, required String academyId}) async {},
        maintenant: () => maintenant,
      );

      await rappel.rappeler(sessionId: 's1', academyId: 'RA-AB0012');
      expect(
        rappel.cooldownRestant(sessionId: 's1', academyId: 'RA-AB0012'),
        cooldownRappelDiscret,
      );
      await expectLater(
        rappel.rappeler(sessionId: 's1', academyId: 'RA-AB0012'),
        throwsA(
          isA<EchecRappel>().having(
            (EchecRappel e) => e.motif,
            'motif',
            MotifEchecRappel.cooldown,
          ),
        ),
      );

      // Le temps passe : l'action redevient possible.
      maintenant = maintenant.add(cooldownRappelDiscret);
      expect(
        rappel.cooldownRestant(sessionId: 's1', academyId: 'RA-AB0012'),
        isNull,
      );
      await rappel.rappeler(sessionId: 's1', academyId: 'RA-AB0012');
    });

    test('le cooldown est par eleve, pas par enseignant', () async {
      // Appeler Amina ne doit pas empecher d'appeler Ilyas une seconde plus
      // tard.
      final DateTime maintenant = DateTime.utc(2026, 9, 20, 10);
      final RappelDiscretCadence rappel = RappelDiscretCadence(
        transport: ({required String sessionId, required String academyId}) async {},
        maintenant: () => maintenant,
      );
      await rappel.rappeler(sessionId: 's1', academyId: 'RA-AB0012');
      await rappel.rappeler(sessionId: 's1', academyId: 'RA-CD0044');
      expect(
        rappel.cooldownRestant(sessionId: 's1', academyId: 'RA-CD0044'),
        cooldownRappelDiscret,
      );
    });

    test('le cooldown est aussi par seance', () async {
      final DateTime maintenant = DateTime.utc(2026, 9, 20, 10);
      final RappelDiscretCadence rappel = RappelDiscretCadence(
        transport: ({required String sessionId, required String academyId}) async {},
        maintenant: () => maintenant,
      );
      await rappel.rappeler(sessionId: 's1', academyId: 'RA-AB0012');
      expect(
        rappel.cooldownRestant(sessionId: 's2', academyId: 'RA-AB0012'),
        isNull,
      );
    });
  });

  test('le port n offre aucun accuse de reception', () {
    // Verite de conception, verifiee par la surface du type : trois membres, et
    // aucun ne dit si l'eleve a vu le rappel. C'est ce qui rend la boucle de
    // notifications impossible a ecrire par accident.
    final RappelDiscretCadence rappel = RappelDiscretCadence();
    expect(rappel, isA<PortRappelDiscret>());
    expect(rappel.cooldown, cooldownRappelDiscret);
  });
}
