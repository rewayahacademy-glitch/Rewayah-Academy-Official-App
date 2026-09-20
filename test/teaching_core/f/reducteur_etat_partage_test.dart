import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_etat_partage/reducteur_etat_partage.dart';
import 'package:rewayah_academy/core/tc_etat_partage/shared_content_state.dart';

import 'support/fabriques.dart';

/// L'ordonnancement de l'etat partage, prouve sans transport ni SDK.
///
/// **C'est l'invariant central du lot F** : une revision ancienne n'ecrase
/// jamais une revision recente, quelle que soit sa provenance -- un paquet
/// duplique, un paquet hors ordre ou une lecture de backend servie par une
/// replique en retard.
void main() {
  group('ReducteurEtatPartage', () {
    test('la premiere revision est retenue, revision zero comprise', () {
      final ReducteurEtatPartage reducteur = ReducteurEtatPartage(
        sessionId: seanceF,
      );
      expect(reducteur.revisionCourante, -1);
      expect(reducteur.etat, isNull);

      final ResultatRevision suite = reducteur.appliquer(
        etatPartage(revision: 0),
      );

      // La revision 0 est celle du premier support pose devant la classe : la
      // confondre avec l'absence d'etat la ferait refuser.
      expect(suite.suite, SuiteRevision.appliquee);
      expect(suite.aChange, isTrue);
      expect(reducteur.revisionCourante, 0);
    });

    test('une revision croissante remplace la precedente', () {
      final ReducteurEtatPartage reducteur = ReducteurEtatPartage(
        sessionId: seanceF,
      )..appliquer(etatPartage(revision: 4, page: 3));

      final ResultatRevision suite = reducteur.appliquer(
        etatPartage(revision: 5, page: 7),
      );

      expect(suite.suite, SuiteRevision.appliquee);
      expect(reducteur.etat!.contentPosition.page, 7);
    });

    test('un paquet duplique est ecarte et ne change rien', () {
      final ReducteurEtatPartage reducteur = ReducteurEtatPartage(
        sessionId: seanceF,
      )..appliquer(etatPartage(revision: 4, page: 3));

      final ResultatRevision suite = reducteur.appliquer(
        etatPartage(revision: 4, page: 99),
      );

      expect(suite.suite, SuiteRevision.dupliquee);
      expect(suite.aChange, isFalse);
      // A revision egale, le premier arrive gagne : la page 99 ne passe pas.
      expect(reducteur.etat!.contentPosition.page, 3);
    });

    test(
      'un paquet hors ordre n ecrase JAMAIS une revision plus recente',
      () {
        final ReducteurEtatPartage reducteur = ReducteurEtatPartage(
          sessionId: seanceF,
        )..appliquer(etatPartage(revision: 9, page: 40));

        final ResultatRevision suite = reducteur.appliquer(
          etatPartage(revision: 8, page: 12),
        );

        expect(suite.suite, SuiteRevision.obsolete);
        expect(suite.aChange, isFalse);
        expect(reducteur.etat!.revision, 9);
        expect(reducteur.etat!.contentPosition.page, 40);
      },
    );

    test('une lacune de revisions ne bloque rien', () {
      final ReducteurEtatPartage reducteur = ReducteurEtatPartage(
        sessionId: seanceF,
      )..appliquer(etatPartage(revision: 5, page: 3));

      // 6, 7 et 8 n'arriveront jamais. 9 porte l'etat COMPLET a sa revision :
      // c'est ce qui permet a un arrivant tardif de se mettre a jour avec un
      // seul message, et ce qui rend l'historique inutile.
      final ResultatRevision suite = reducteur.appliquer(
        etatPartage(revision: 9, page: 41),
      );

      expect(suite.suite, SuiteRevision.appliquee);
      expect(reducteur.etat!.contentPosition.page, 41);
    });

    test('un paquet d une autre seance est refuse', () {
      final ReducteurEtatPartage reducteur = ReducteurEtatPartage(
        sessionId: seanceF,
      )..appliquer(etatPartage(revision: 2));

      final ResultatRevision suite = reducteur.appliquer(
        etatPartage(revision: 50, sessionId: autreSeance),
      );

      expect(suite.suite, SuiteRevision.seanceEtrangere);
      expect(reducteur.etat!.revision, 2);
    });

    test('restaurer(null) n efface pas l etat connu', () {
      final ReducteurEtatPartage reducteur = ReducteurEtatPartage(
        sessionId: seanceF,
      )..appliquer(etatPartage(revision: 3, page: 20));

      final ResultatRevision suite = reducteur.restaurer(null);

      expect(suite.aChange, isFalse);
      expect(reducteur.etat!.contentPosition.page, 20);
    });

    test(
      'une restauration de backend en retard n ecrase pas le temps reel',
      () {
        final ReducteurEtatPartage reducteur = ReducteurEtatPartage(
          sessionId: seanceF,
        )..appliquer(etatPartage(revision: 7, page: 30));

        // Le backend fait autorite sur le CONTENU, jamais sur le sens du temps.
        final ResultatRevision suite = reducteur.restaurer(
          etatPartage(revision: 6, page: 12),
        );

        expect(suite.suite, SuiteRevision.obsolete);
        expect(reducteur.etat!.revision, 7);
      },
    );

    test('une restauration plus recente est adoptee', () {
      final ReducteurEtatPartage reducteur = ReducteurEtatPartage(
        sessionId: seanceF,
      )..appliquer(etatPartage(revision: 2, page: 5));

      final ResultatRevision suite = reducteur.restaurer(
        etatPartage(revision: 11, page: 60),
      );

      expect(suite.suite, SuiteRevision.appliquee);
      expect(reducteur.etat!.contentPosition.page, 60);
    });

    test('vider oublie tout, pour une sortie volontaire', () {
      final ReducteurEtatPartage reducteur = ReducteurEtatPartage(
        sessionId: seanceF,
      )..appliquer(etatPartage(revision: 3));

      reducteur.vider();

      expect(reducteur.etat, isNull);
      expect(reducteur.revisionCourante, -1);
    });
  });

  group('SharedContentState.suivante', () {
    test('incremente la revision sans que l appelant la choisisse', () {
      final SharedContentState depart = etatPartage(revision: 4);

      final SharedContentState apres = depart.suivante(
        updatedBy: profilEnseignant,
        maintenantUtc: DateTime.utc(2026, 9, 20, 11),
        contentPosition: positionPage(9),
      );

      expect(apres.revision, 5);
      expect(apres.contentPosition.page, 9);
      expect(apres.updatedAtUtc.isUtc, isTrue);
    });

    test('distingue « ne touche pas » de « retire la valeur »', () {
      final SharedContentState depart = etatPartage(
        revision: 1,
        plage: plagePages(3, 5),
      );

      final SharedContentState inchange = depart.suivante(
        updatedBy: profilEnseignant,
        maintenantUtc: DateTime.utc(2026, 9, 20, 11),
      );
      final SharedContentState retire = depart.suivante(
        updatedBy: profilEnseignant,
        maintenantUtc: DateTime.utc(2026, 9, 20, 11),
        contentRange: null,
      );

      expect(inchange.contentRange, isNotNull);
      expect(retire.contentRange, isNull);
    });
  });
}
