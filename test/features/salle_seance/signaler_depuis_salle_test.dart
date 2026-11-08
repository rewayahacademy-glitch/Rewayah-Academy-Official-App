// NON-BRANCHE-LIVRAISON 7 (08/11/2026) : « Signaler un besoin » depuis la
// salle. La tuile du panneau Eleves etait masquee dans la vraie salle (aucun
// `onSignaler`) ; elle suit desormais la capacite de la feuille
// (`signalementDisponible`), la meme que sur la fiche de l'eleve. La feuille
// ouverte depuis la salle porte la Classe et la seance, donc elle envoie
// vraiment ; sans reseau, rien ne part et la feuille le dit.
// Chaque test ci-dessous est ROUGE sans ce lot.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/enseignant/modeles_enseignant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/tc_parcours/port_signalement.dart';
import 'package:rewayah_academy/features/fiche_groupe/fiche_eleve_enseignant.dart';
import 'package:rewayah_academy/features/salle_seance/signalement_seance.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../../support/harnais.dart';

const VueSeance _vue = VueSeance(
  role: RoleSeance.enseignant,
  nomClasse: 'An-Nour',
  nomEnseignant: 'Sayyida Amina',
  initialesEnseignant: 'SA',
);

const EleveSeance _eleve = EleveSeance(
  prenom: 'Yasmine',
  statut: StatutEleveSeance.connecte,
  id: 'RA-26-4817',
);

const EleveFiche _fiche = EleveFiche(
  membre: MembreSeance(
    studentId: 'RA-26-4817',
    identifiantImmuable: 'RA-26-4817',
    prenom: 'Yasmine',
  ),
  classe: 'An-Nour',
  groupeId: 'c1',
  seanceId: 's1',
);

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  test('la capacite : Classe connue et serveur present', () {
    expect(
      signalementDisponible(SignalementMemoire('enseignant-test'), 'c1'),
      isTrue,
    );
    expect(
      signalementDisponible(SignalementMemoire('enseignant-test'), null),
      isFalse,
    );
    expect(
      signalementDisponible(const SignalementIndisponible(), 'c1'),
      isFalse,
    );
  });

  test('la fiche ouverte depuis la salle porte la Classe et la seance', () {
    final EleveFiche fiche = eleveFicheDepuisSeance(
      _eleve,
      _vue,
      seanceId: 's1',
      groupeId: 'c1',
    );
    expect(fiche.groupeId, 'c1');
    expect(fiche.seanceId, 's1');
    expect(fiche.membre.identifiantImmuable, 'RA-26-4817');
  });

  test('la vraie salle passe la tuile, gardee par la capacite', () {
    final String salle = File('lib/features/salle/salle_page.dart')
        .readAsStringSync();
    expect(salle, contains('onSignaler:\n          signalementDisponible('));
    expect(salle, contains('groupeId: widget.groupeId,'));
  });

  group('la feuille', () {
    Future<List<SignalementBesoin>> envoyer(
      WidgetTester tester, {
      required bool horsLigne,
      bool refus = false,
    }) async {
      final List<SignalementBesoin> envoyes = <SignalementBesoin>[];
      await tester.pumpWidget(
        hote(
          Scaffold(
            body: SingleChildScrollView(
              child: SignalerBesoin(
                eleve: _fiche,
                envoi: (SignalementBesoin s) async {
                  envoyes.add(s);
                  if (refus) throw StateError('refus du serveur');
                },
              ),
            ),
          ),
          surcharges: <Override>[
            serviceReseauProvider.overrideWithValue(
              FauxServiceReseau(horsLigneRendu: horsLigne),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(CategorieBesoin.pedagogique.libelle));
      await tester.enterText(
        find.byKey(SignalerBesoin.detailsKey),
        'Yasmine perd le fil apres la deuxieme page',
      );
      await tester.pumpAndSettle();
      final Finder bouton = find.byKey(SignalerBesoin.envoyerKey);
      await tester.ensureVisible(bouton);
      await tester.tap(bouton);
      await tester.pumpAndSettle();
      return envoyes;
    }

    testWidgets('hors ligne : rien ne part, la feuille le dit et garde la '
        'saisie', (WidgetTester tester) async {
      final List<SignalementBesoin> envoyes = await envoyer(
        tester,
        horsLigne: true,
      );
      expect(envoyes, isEmpty);
      expect(find.text(t.tc.parcours.signalement.horsLigne), findsOneWidget);
      expect(find.byKey(SignalerBesoin.confirmationKey), findsNothing);
      expect(
        find.text('Yasmine perd le fil apres la deuxieme page'),
        findsOneWidget,
      );
    });

    testWidgets('en ligne : la seance et la Classe partent avec le '
        'signalement', (WidgetTester tester) async {
      final List<SignalementBesoin> envoyes = await envoyer(
        tester,
        horsLigne: false,
      );
      expect(envoyes.single.seanceId, 's1');
      expect(find.byKey(SignalerBesoin.confirmationKey), findsOneWidget);
    });

    testWidgets('refus du serveur : la phrase d echec, jamais la phrase '
        'hors ligne', (WidgetTester tester) async {
      await envoyer(tester, horsLigne: false, refus: true);
      expect(find.text(t.tc.parcours.signalement.echec), findsOneWidget);
      expect(find.text(t.tc.parcours.signalement.horsLigne), findsNothing);
      expect(find.text(t.commun.reessayer), findsOneWidget);
    });
  });
}
