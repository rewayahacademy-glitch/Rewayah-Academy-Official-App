// CALENDRIER-ET-PAUSES (lot 2, 12/11/2026) : Pedagogie > Calendrier, monte par
// le VRAI routeur (l'application en demonstration d'administration). Les dates
// de l'ecole (liste, ajout, modification, publication, retrait) et les pauses
// (demandes a traiter, decisions recentes, pause d'exception). Cinq etats par
// section : chargement, contenu, vide, erreur, hors ligne. Un seul bouton plein.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/admin_domaine.dart';
import 'package:rewayah_academy/core/calendrier/libelles_calendrier.dart';
import 'package:rewayah_academy/core/calendrier/port_calendrier.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/champ_date.dart'
    show horlogeFormulairesProvider;
import 'package:rewayah_academy/core/widgets/offline_banner.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';

import '../../support/calendrier_pauses_faux.dart';
import '../../support/garde_interface.dart';
import '../../support/monter_admin_demo.dart';

Future<void> _monter(
  WidgetTester tester, {
  FauxCalendrierDirection? calendrier,
  FausPauses? pauses,
  bool horsLigne = false,
  bool sansPort = false,
  Size taille = const Size(1440, 1400),
  List<Override> extra = const <Override>[],
}) async {
  await monterAdminDemo(
    tester,
    route: Routes.adminPedagogieCalendrier,
    taille: taille,
    plus: <Override>[
      if (!sansPort) ...<Override>[
        portCalendrierDirectionProvider.overrideWithValue(
          calendrier ?? FauxCalendrierDirection(),
        ),
        portPausesProvider.overrideWithValue(pauses ?? FausPauses()),
      ],
      horsLigneProvider.overrideWith(
        (Ref ref) => Stream<bool>.value(horsLigne),
      ),
      ...extra,
    ],
  );
}

Future<void> _pause(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 500));
}

/// Touche un bouton de la feuille, apres l'avoir ramene a l'ecran (la feuille
/// defile).
Future<void> _toucher(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tap(cible);
}

Future<void> _versPauses(WidgetTester tester) async {
  // Au telephone, le selecteur de sections se replie en menu : on l'ouvre d'abord.
  if (find.text(t.calendrier.sections.pauses).evaluate().isEmpty) {
    await tester.tap(find.text(t.calendrier.sections.dates));
    await _pause(tester);
  }
  await tester.tap(find.text(t.calendrier.sections.pauses).last);
  await _pause(tester);
}

void main() {
  group('la navigation', () {
    test('septieme et derniere fonction de Pedagogie, jamais plus de sept', () {
      final List<String> chemins = <String>[
        for (final o in ongletsPedagogie()) o.chemin,
      ];
      expect(chemins.length, 7);
      expect(chemins.last, Routes.adminPedagogieCalendrier);
      expect(ongletsPedagogie().last.libelle, t.calendrier.titre);
    });
  });

  group('Dates de l ecole', () {
    testWidgets('la liste : genre, periode, a qui, etat de publication', (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      expect(find.text(t.calendrier.titre), findsWidgets);
      expect(find.text("Fermeture de l'Aïd al-Adha"), findsOneWidget);
      expect(find.text('Rencontre de récitation de printemps'), findsOneWidget);
      expect(find.text('Évaluation des 10-13 ans'), findsOneWidget);
      expect(find.text(t.calendrier.dates.publiee), findsNWidgets(2));
      expect(find.text(t.calendrier.dates.nonPubliee), findsOneWidget);
      expect(
        find.textContaining(
          'Du 16 mai 2027 au 25 mai 2027',
          findRichText: true,
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Pour\u00a0: Toute l'), findsWidgets);
    });

    testWidgets(
      'une fermeture dit les eleves concernes et que ses seances sont mises de cote, sans etre supprimees',
      (WidgetTester tester) async {
        await _monter(tester);
        expect(
          find.textContaining(t.calendrier.dates.elevesVises(n: 5)),
          findsOneWidget,
        );
        expect(
          find.textContaining(t.calendrier.dates.seancesNeutralisees(n: 4)),
          findsOneWidget,
        );
        expect(find.textContaining('sans être supprimées'), findsOneWidget);
        // Le texte qui promettait un geste inexistant a disparu.
        expect(find.textContaining('décide de leur sort'), findsNothing);
        // Une rencontre n'a ni eleves vises ni seances.
        expect(find.textContaining('Élèves concernés'), findsOneWidget);
      },
    );

    testWidgets(
      'une fermeture commencee ne se retire plus : la phrase le dit',
      (WidgetTester tester) async {
        await _monter(
          tester,
          calendrier: FauxCalendrierDirection(
            lignes: () => <Object?>[
              ligneCalendrier(
                id: 'f1',
                type: 'fermeture',
                categorie: 'autre',
                titre: 'Fermeture en cours',
                du: '2026-11-10',
                au: '2026-11-20',
                publie: true,
                elevesVises: 3,
                seancesNeutralisees: 0,
                commencee: true,
              ),
              ligneCalendrier(
                id: 'f2',
                type: 'fermeture',
                categorie: 'autre',
                titre: 'Fermeture a venir',
                du: '2027-01-10',
                au: '2027-01-20',
                publie: true,
                elevesVises: 3,
                seancesNeutralisees: 2,
              ),
            ],
          ),
        );
        await tester.tap(find.text('Fermeture en cours'));
        await _pause(tester);
        expect(find.text(t.calendrier.dates.commencee), findsOneWidget);
        expect(
          find.byKey(const ValueKey<String>('calendrier-retirer')),
          findsNothing,
        );
      },
    );

    testWidgets('une fermeture publiee a venir se retire avant son debut', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        calendrier: FauxCalendrierDirection(
          lignes: () => <Object?>[
            ligneCalendrier(
              id: 'f2',
              type: 'fermeture',
              categorie: 'autre',
              titre: 'Fermeture a venir',
              du: '2027-01-10',
              au: '2027-01-20',
              publie: true,
              elevesVises: 3,
              seancesNeutralisees: 2,
            ),
          ],
        ),
      );
      await tester.tap(find.text('Fermeture a venir'));
      await _pause(tester);
      expect(find.text(t.calendrier.dates.commencee), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('calendrier-retirer')),
        findsOneWidget,
      );
    });

    testWidgets('un seul bouton plein', (WidgetTester tester) async {
      await _monter(tester);
      expect(
        find.byKey(const ValueKey<String>('calendrier-ajouter')),
        findsOne,
      );
      verifierUnSeulBoutonPlein(tester);
    });

    testWidgets('publier une date non publiee', (WidgetTester tester) async {
      final FauxCalendrierDirection port = FauxCalendrierDirection();
      await _monter(tester, calendrier: port);
      await tester.tap(find.text('Rencontre de récitation de printemps'));
      await _pause(tester);
      await _toucher(
        tester,
        find.byKey(const ValueKey<String>('calendrier-publier')),
      );
      await _pause(tester);
      expect(port.publications, <(String, bool)>[('c2', true)]);
    });

    testWidgets('retirer de la publication une date publiee', (
      WidgetTester tester,
    ) async {
      final FauxCalendrierDirection port = FauxCalendrierDirection();
      await _monter(tester, calendrier: port);
      await tester.tap(find.text("Fermeture de l'Aïd al-Adha"));
      await _pause(tester);
      expect(find.text(t.calendrier.dates.retirer), findsOneWidget);
      await _toucher(
        tester,
        find.byKey(const ValueKey<String>('calendrier-retirer')),
      );
      await _pause(tester);
      expect(port.publications, <(String, bool)>[('c1', false)]);
    });

    testWidgets('publier une fermeture dit sa consequence avant le geste', (
      WidgetTester tester,
    ) async {
      final FauxCalendrierDirection port = FauxCalendrierDirection(
        lignes: () => <Object?>[
          ligneCalendrier(
            id: 'f9',
            type: 'fermeture',
            categorie: 'autre',
            titre: 'Fermeture libre',
            du: '2027-07-01',
            au: '2027-07-05',
            elevesVises: 3,
            seancesNeutralisees: 0,
          ),
        ],
      );
      await _monter(tester, calendrier: port);
      await tester.tap(find.text('Fermeture libre'));
      await _pause(tester);
      expect(find.text(t.calendrier.dates.publication.phrase), findsOneWidget);
      expect(find.text(t.calendrier.dates.aucuneSeance), findsWidgets);
      await _toucher(
        tester,
        find.byKey(const ValueKey<String>('calendrier-publier')),
      );
      await _pause(tester);
      expect(port.publications, <(String, bool)>[('f9', true)]);
    });

    testWidgets('modifier une date : la saisie est preremplie et se renvoie', (
      WidgetTester tester,
    ) async {
      final FauxCalendrierDirection port = FauxCalendrierDirection();
      await _monter(tester, calendrier: port);
      await tester.tap(find.text('Rencontre de récitation de printemps'));
      await _pause(tester);
      await tester.tap(find.text(t.calendrier.dates.modifier));
      await _pause(tester);
      expect(find.text(t.calendrier.dates.feuille.titreModif), findsWidgets);
      await tester.enterText(
        find.byType(TextField).first,
        'Rencontre de récitation du printemps',
      );
      await _toucher(
        tester,
        find.byKey(const ValueKey<String>('calendrier-enregistrer')),
      );
      await _pause(tester);
      expect(port.enregistrements.length, 1);
      final Map<String, Object?> e = port.enregistrements.single;
      expect(e['id'], 'c2');
      expect(e['type'], TypeEvenement.rencontre);
      expect(e['titre'], 'Rencontre de récitation du printemps');
      expect(e['du'], DateTime(2027, 4, 10));
      expect(e['au'], DateTime(2027, 4, 10));
      expect(e['portee'], PorteeEvenement.ecole);
    });

    testWidgets(
      'le serveur refuse une fermeture trop longue : dit en mots simples',
      (WidgetTester tester) async {
        final FauxCalendrierDirection port = FauxCalendrierDirection(
          refus: const CalendrierRefuse(
            MotifRefusCalendrier.fermetureTropLongue,
          ),
        );
        await _monter(tester, calendrier: port);
        await tester.tap(find.text("Fermeture de l'Aïd al-Adha"));
        await _pause(tester);
        await tester.tap(find.text(t.calendrier.dates.modifier));
        await _pause(tester);
        await _toucher(
          tester,
          find.byKey(const ValueKey<String>('calendrier-enregistrer')),
        );
        await _pause(tester);
        expect(
          find.text(t.calendrier.dates.refus.fermetureTropLongue),
          findsOneWidget,
        );
        expect(port.enregistrements, isEmpty);
      },
    );

    testWidgets(
      'ajouter sans titre ni dates : ce qui manque, rien n est envoye',
      (WidgetTester tester) async {
        final FauxCalendrierDirection port = FauxCalendrierDirection();
        await _monter(tester, calendrier: port);
        await tester.tap(
          find.byKey(const ValueKey<String>('calendrier-ajouter')),
        );
        await _pause(tester);
        expect(find.text(t.calendrier.dates.feuille.titreAjout), findsWidgets);
        await _toucher(
          tester,
          find.byKey(const ValueKey<String>('calendrier-enregistrer')),
        );
        await _pause(tester);
        expect(
          find.text(t.calendrier.dates.refus.evenementInvalide),
          findsOneWidget,
        );
        expect(port.enregistrements, isEmpty);
      },
    );

    testWidgets(
      'ajouter une date : titre et deux jours choisis au calendrier',
      (WidgetTester tester) async {
        final FauxCalendrierDirection port = FauxCalendrierDirection();
        await _monter(tester, calendrier: port);
        await tester.tap(
          find.byKey(const ValueKey<String>('calendrier-ajouter')),
        );
        await _pause(tester);
        await tester.enterText(
          find.byType(TextField).first,
          'Fermeture de Noël',
        );
        // Le genre « Fermeture » est le premier choix ; la categorie « Autre
        // fermeture » est retenue par defaut.
        final Finder champs = find.byKey(const ValueKey<String>('champ-date'));
        await tester.ensureVisible(champs.first);
        await tester.tap(champs.first);
        await _pause(tester);
        await tester.tap(find.byType(TextButton).last);
        await _pause(tester);
        await tester.ensureVisible(champs.last);
        await tester.tap(champs.last);
        await _pause(tester);
        await tester.tap(find.byType(TextButton).last);
        await _pause(tester);
        final Finder envoyer = find.byKey(
          const ValueKey<String>('calendrier-enregistrer'),
        );
        await tester.ensureVisible(envoyer);
        await tester.tap(envoyer);
        await _pause(tester);
        expect(port.enregistrements.length, 1);
        final Map<String, Object?> e = port.enregistrements.single;
        expect(e['id'], isNull);
        expect(e['titre'], 'Fermeture de Noël');
        expect(e['type'], TypeEvenement.fermeture);
        expect(e['categorie'], CategorieFermeture.autre);
        expect(e['portee'], PorteeEvenement.ecole);
        expect(e['du'], isA<DateTime>());
      },
    );

    testWidgets('chargement : un squelette, puis la liste', (
      WidgetTester tester,
    ) async {
      final Completer<void> attente = Completer<void>();
      await _monter(
        tester,
        calendrier: FauxCalendrierDirection(attente: attente),
      );
      expect(find.byType(Skeleton), findsWidgets);
      expect(find.text("Fermeture de l'Aïd al-Adha"), findsNothing);
      attente.complete();
      await _pause(tester);
      expect(find.text("Fermeture de l'Aïd al-Adha"), findsOneWidget);
    });

    testWidgets('vide : aucune date, une invitation', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        calendrier: FauxCalendrierDirection(lignes: () => <Object?>[]),
      );
      expect(find.text(t.calendrier.dates.videTitre), findsOneWidget);
      expect(find.text(t.calendrier.dates.videDetail), findsOneWidget);
    });

    testWidgets('erreur : la phrase et Reessayer, qui relit', (
      WidgetTester tester,
    ) async {
      final FauxCalendrierDirection port = FauxCalendrierDirection(
        erreur: StateError('reseau'),
      );
      await _monter(tester, calendrier: port);
      expect(find.text(t.calendrier.dates.erreur), findsWidgets);
      expect(find.text(t.commun.reessayer), findsOneWidget);
      port.erreur = null;
      await tester.tap(find.text(t.commun.reessayer));
      await _pause(tester);
      expect(find.text("Fermeture de l'Aïd al-Adha"), findsOneWidget);
    });

    testWidgets('hors ligne : le bandeau le dit, le bloc dit ce qui manque', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        calendrier: FauxCalendrierDirection(erreur: StateError('reseau')),
        horsLigne: true,
      );
      expect(find.text(t.calendrier.dates.erreur), findsWidgets);
      expect(find.byType(OfflineBanner), findsWidgets);
    });

    testWidgets('sans port : le calendrier est indisponible, sans bouton', (
      WidgetTester tester,
    ) async {
      await _monter(tester, sansPort: true);
      expect(find.text(t.calendrier.indisponible), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('calendrier-ajouter')),
        findsNothing,
      );
    });
  });

  group('Pauses', () {
    testWidgets('les demandes a traiter et les decisions recentes', (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      await _versPauses(tester);
      expect(find.text(t.calendrier.pauses.aTraiter), findsOneWidget);
      expect(find.text('Mariam Benali'), findsOneWidget);
      // Une demande a traiter et une decision recente portent ce nom.
      expect(find.text('Yasmine Haddad'), findsNWidgets(2));
      expect(find.text(t.calendrier.pauses.enRetard), findsOneWidget);
      expect(
        find.textContaining(
          t.calendrier.pauses.ligneDescription(mois: 'février 2027', n: 2),
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          t.calendrier.pauses.repondreAvant(date: '15 novembre 2026'),
        ),
        findsOneWidget,
      );
      expect(find.text(t.calendrier.pauses.decisionsRecentes), findsOneWidget);
      expect(find.text('Omar Saidi'), findsOneWidget);
      expect(
        find.textContaining(
          t.calendrier.pauses.accordeePar(nom: 'Direction Rewayah'),
        ),
        findsNWidgets(2),
      );
      expect(find.textContaining('Maladie soudaine'), findsOneWidget);
      verifierUnSeulBoutonPlein(tester, maximum: 0);
    });

    testWidgets('accepter une demande', (WidgetTester tester) async {
      final FausPauses port = FausPauses();
      await _monter(tester, pauses: port);
      await _versPauses(tester);
      await tester.tap(find.text('Mariam Benali'));
      await _pause(tester);
      await _toucher(
        tester,
        find.byKey(const ValueKey<String>('pause-accepter')),
      );
      await _pause(tester);
      expect(port.decisions, <(String, bool, String?)>[('p1', true, null)]);
    });

    testWidgets('refuser exige un motif, puis l envoie', (
      WidgetTester tester,
    ) async {
      final FausPauses port = FausPauses();
      await _monter(tester, pauses: port);
      await _versPauses(tester);
      await tester.tap(find.text('Mariam Benali'));
      await _pause(tester);
      await _toucher(
        tester,
        find.byKey(const ValueKey<String>('pause-refuser')),
      );
      await _pause(tester);
      expect(find.text(t.calendrier.pauses.refus.motifRequis), findsOneWidget);
      expect(port.decisions, isEmpty);
      await tester.enterText(
        find.byType(TextField).first,
        'Le programme s etire deja',
      );
      await _toucher(
        tester,
        find.byKey(const ValueKey<String>('pause-refuser')),
      );
      await _pause(tester);
      expect(port.decisions, <(String, bool, String?)>[
        ('p1', false, 'Le programme s etire deja'),
      ]);
    });

    testWidgets(
      'le serveur refuse une decision tardive : dit en mots simples',
      (WidgetTester tester) async {
        final FausPauses port = FausPauses(
          refusDecision: const PauseRefusee(MotifRefusPause.debutPasse),
        );
        await _monter(tester, pauses: port);
        await _versPauses(tester);
        await tester.tap(find.text('Mariam Benali'));
        await _pause(tester);
        await _toucher(
          tester,
          find.byKey(const ValueKey<String>('pause-accepter')),
        );
        await _pause(tester);
        expect(find.text(t.calendrier.pauses.refus.debutPasse), findsOneWidget);
      },
    );

    testWidgets('pause d exception : chercher l eleve, motif, dernier jour', (
      WidgetTester tester,
    ) async {
      final FausPauses port = FausPauses();
      await _monter(tester, pauses: port);
      await _versPauses(tester);
      await tester.tap(find.byKey(const ValueKey<String>('pause-exception')));
      await _pause(tester);
      expect(find.text(t.calendrier.pauses.exceptionPhrase), findsOneWidget);
      // La duree au plus vient du serveur (3 mois), jamais ecrite en dur.
      expect(
        find.text(t.calendrier.pauses.exceptionDuree(mois: 3)),
        findsOneWidget,
      );
      await tester.enterText(find.byType(TextField).first, 'Om');
      await _pause(tester);
      expect(port.recherches, <String>['Om']);
      await tester.tap(find.text('Omar Saidi').last);
      await _pause(tester);
      expect(
        find.text(t.calendrier.pauses.exceptionEleve(nom: 'Omar Saidi')),
        findsOneWidget,
      );
      // L'aide du motif : un mot suffit, aucun detail de sante.
      expect(find.text(t.calendrier.pauses.exceptionMotifAide), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'Maladie soudaine');
      final Finder champ = find.byKey(const ValueKey<String>('champ-date'));
      await tester.ensureVisible(champ);
      await tester.tap(champ);
      await _pause(tester);
      await tester.tap(find.byType(TextButton).last);
      await _pause(tester);
      final Finder accorder = find.byKey(
        const ValueKey<String>('pause-exception-accorder'),
      );
      await tester.ensureVisible(accorder);
      await tester.tap(accorder);
      await _pause(tester);
      expect(port.exceptions.length, 1);
      expect(port.exceptions.single.$1, 'eleve-omar');
      expect(port.exceptions.single.$3, 'Maladie soudaine');
    });

    testWidgets(
      'les decisions recentes disent la fin d origine et qui a termine',
      (WidgetTester tester) async {
        await _monter(tester);
        await _versPauses(tester);
        expect(
          find.textContaining(
            t.calendrier.pauses.finInitiale(
              date: jourEnMots(DateTime(2026, 10, 31)),
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.textContaining(
            t.calendrier.pauses.termineePar(nom: 'Direction Rewayah'),
          ),
          findsOneWidget,
        );
        // Seule la pause d'exception en cours se termine : une seule ligne le propose.
        expect(find.text(t.calendrier.pauses.terminerAction), findsNothing);
        expect(
          find.textContaining(t.calendrier.pauses.terminerAction),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'terminer une pause d exception : le dernier jour part au serveur',
      (WidgetTester tester) async {
        final FausPauses port = FausPauses();
        await _monter(
          tester,
          pauses: port,
          extra: <Override>[
            horlogeFormulairesProvider.overrideWithValue(
              () => DateTime(2026, 11, 12),
            ),
          ],
        );
        await _versPauses(tester);
        await tester.tap(find.text('Omar Saidi'));
        await _pause(tester);
        expect(find.text(t.calendrier.pauses.terminerPhrase), findsOneWidget);
        final Finder champ = find.byKey(const ValueKey<String>('champ-date'));
        await tester.ensureVisible(champ);
        await tester.tap(champ);
        await _pause(tester);
        await tester.tap(find.byType(TextButton).last);
        await _pause(tester);
        await _toucher(
          tester,
          find.byKey(const ValueKey<String>('pause-terminer-envoyer')),
        );
        await _pause(tester);
        expect(port.terminees.length, 1);
        expect(port.terminees.single.$1, 'r1');
        expect(
          port.terminees.single.$2.isBefore(DateTime(2026, 11, 20)),
          isTrue,
        );
      },
    );

    testWidgets('le serveur refuse : la duree permise se dit avec son nombre', (
      WidgetTester tester,
    ) async {
      expect(
        messageRefusDecisionPause(
          MotifRefusPause.exceptionTropLongue,
          moisMax: 3,
        ),
        t.calendrier.pauses.refus.exceptionTropLongue(mois: 3),
      );
      expect(
        messageRefusDecisionPause(MotifRefusPause.nonTerminable),
        t.calendrier.pauses.refus.nonTerminable,
      );
      expect(
        messageRefusCalendrier(MotifRefusCalendrier.fermetureCommencee),
        t.calendrier.dates.refus.fermetureCommencee,
      );
    });

    testWidgets('chargement : un squelette, puis la file', (
      WidgetTester tester,
    ) async {
      final Completer<void> attente = Completer<void>();
      await _monter(tester, pauses: FausPauses(attente: attente));
      await _versPauses(tester);
      expect(find.byType(Skeleton), findsWidgets);
      attente.complete();
      await _pause(tester);
      expect(find.text('Mariam Benali'), findsOneWidget);
    });

    testWidgets('vide : aucune demande en attente', (
      WidgetTester tester,
    ) async {
      await _monter(tester, pauses: FausPauses(file: fileServeur(vide: true)));
      await _versPauses(tester);
      expect(find.text(t.calendrier.pauses.videTitre), findsOneWidget);
      expect(find.text(t.calendrier.pauses.decisionsVide), findsOneWidget);
    });

    testWidgets('erreur et hors ligne', (WidgetTester tester) async {
      final FausPauses port = FausPauses(erreurLecture: StateError('reseau'));
      await _monter(tester, pauses: port, horsLigne: true);
      await _versPauses(tester);
      expect(find.text(t.calendrier.pauses.erreur), findsWidgets);
      expect(find.byType(OfflineBanner), findsWidgets);
      port.erreurLecture = null;
      await tester.tap(find.text(t.commun.reessayer));
      await _pause(tester);
      expect(find.text('Mariam Benali'), findsOneWidget);
    });
  });

  group('au telephone', () {
    testWidgets(
      '390 : la liste et les deux sections tiennent, sans exception',
      (WidgetTester tester) async {
        await _monter(tester, taille: const Size(390, 2400));
        expect(find.text("Fermeture de l'Aïd al-Adha"), findsOneWidget);
        await _versPauses(tester);
        expect(find.text('Mariam Benali'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
