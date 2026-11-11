// LISTES-1 : le menu « ... » d'une ligne de la file, et les gestes qu'il lance.
//
// Ce que le test prouve :
// - le menu propose « Ouvrir le dossier », puis les gestes que l'ETAT de la
//   ligne permet (la table de `gestes_proposes.dart`, pas une copie), les
//   destructifs a la suite ; jamais « Choisir le responsable » (liste non
//   servie) ; hors ligne ou sans le droit de decider, seulement le dossier ;
// - un geste lu depuis la ligne LIT LE DOSSIER (la ligne n'a pas la version),
//   recalcule ce qui est permis, puis ouvre la MEME feuille que la fiche, avec
//   la version du dossier ;
// - un geste qui n'est plus permis, ou un dossier illisible : un message en
//   mots, aucune feuille, rien d'ecrit ;
// - apres un succes, la liste se relit en gardant filtres, tri et page.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/gestes_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature_detail.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidatures_direction.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/admin_candidature/feuille_geste.dart';
import 'package:rewayah_academy/features/admin_candidatures/candidatures_page.dart';
import 'package:rewayah_academy/features/admin_candidatures/ligne_candidature.dart';
import 'package:rewayah_academy/features/admin_candidatures/menu_ligne_candidature.dart';

import '../../fixtures/candidature/faux_candidatures_direction.dart';
import '../../support/monter_recrutement.dart';
import '../../support/rangee_plus.dart';
import 'hote_candidatures.dart';

Finder _cle(String cle) => find.byKey(ValueKey<String>(cle));

final gestes = t.admin.candidatures.gestes;

/// Les entrees du menu ouvert, dans l'ordre ou elles s'affichent.
Future<List<String>> _entrees(WidgetTester tester, String id) async {
  final Finder menu = find.byKey(MenuLigneCandidature.cle(id));
  await tester.ensureVisible(menu);
  await tester.pump();
  await tester.tap(menu);
  await tester.pumpAndSettle();
  return <String>[
    for (final Element e
        in find
            .descendant(
              of: find.byType(PopupMenuItem<int>),
              matching: find.byType(Text),
            )
            .evaluate())
      (e.widget as Text).data!,
  ];
}

Future<void> _choisir(WidgetTester tester, String id, String entree) async {
  await _entrees(tester, id);
  await tester.tap(find.text(entree).last);
  await laisser(tester);
}

/// Une page ouverte sur [lignes], dont le dossier de `a1` est [dossier].
Future<FauxCandidaturesDirection> _monter(
  WidgetTester tester, {
  List<LigneCandidature>? lignes,
  DetailCandidature? dossier,
  CapacitesCandidatures caps = capacitesGestes,
  bool horsLigne = false,
  bool ouvrir = true,
  Completer<void>? attenteLire,
  Object? Function(int)? erreurLire,
  double largeur = 390,
}) async {
  final FauxCandidaturesDirection port = FauxCandidaturesDirection(
    lignes:
        lignes ??
        <LigneCandidature>[
          ligneTest(id: 'a1', nom: 'Amina Diallo'),
          ligneTest(
            id: 'b2',
            nom: 'Bilal Haddad',
            etat: EtatCandidature.aCompleter,
            enPause: true,
          ),
        ],
    capacitesRendues: caps,
    details: <DetailCandidature>[
      dossier ?? detailTest(id: 'a1', nom: 'Amina Diallo', version: 3),
    ],
    attenteLire: attenteLire,
    erreurLire: erreurLire,
  );
  await monterCandidatures(
    tester,
    port: port,
    horsLigne: horsLigne,
    largeur: largeur,
    ouvrir: ouvrir ? (LigneCandidature _) {} : null,
  );
  return port;
}

void main() {
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('le menu d\'une ligne', () {
    testWidgets(
      'en examen, versement confirme : le dossier, les gestes, les destructifs a la fin',
      (tester) async {
        await _monter(tester);
        expect(await _entrees(tester, 'a1'), <String>[
          t.admin.candidatures.liste.ouvrirDossier,
          gestes.admettre,
          gestes.demanderComplement,
          gestes.mettreEnPause,
          gestes.ecarterMoyen,
          gestes.refuser,
          gestes.retrait,
        ]);
        // Jamais « Choisir le responsable » : la liste n'est pas servie.
        expect(find.text(gestes.responsable), findsNothing);
      },
    );

    testWidgets('en pause : lever la pause, jamais mettre en pause', (
      tester,
    ) async {
      await _monter(tester);
      final List<String> entrees = await _entrees(tester, 'b2');
      expect(entrees.first, t.admin.candidatures.liste.ouvrirDossier);
      expect(entrees, contains(gestes.leverPause));
      expect(entrees, isNot(contains(gestes.mettreEnPause)));
      // Refuser reste permis en pause ; il est a la fin avec le retrait.
      expect(entrees.sublist(entrees.length - 2), <String>[
        gestes.refuser,
        gestes.retrait,
      ]);
    });

    testWidgets('une candidature refusee : rouvrir seulement', (tester) async {
      await _monter(
        tester,
        lignes: <LigneCandidature>[
          ligneTest(id: 'a1', issue: IssueCandidature.refusee),
        ],
      );
      expect(await _entrees(tester, 'a1'), <String>[
        t.admin.candidatures.liste.ouvrirDossier,
        gestes.rouvrir,
      ]);
    });

    testWidgets('sans destination, pas de « Ouvrir le dossier »', (
      tester,
    ) async {
      await _monter(tester, ouvrir: false);
      final List<String> entrees = await _entrees(tester, 'a1');
      expect(
        entrees,
        isNot(contains(t.admin.candidatures.liste.ouvrirDossier)),
      );
      expect(entrees, isNotEmpty);
    });

    testWidgets('hors ligne : seulement le dossier', (tester) async {
      await _monter(tester, horsLigne: true);
      expect(await _entrees(tester, 'a1'), <String>[
        t.admin.candidatures.liste.ouvrirDossier,
      ]);
    });

    testWidgets('sans le droit de decider : seulement le dossier', (
      tester,
    ) async {
      await _monter(tester, caps: capacitesQuiLit);
      expect(await _entrees(tester, 'a1'), <String>[
        t.admin.candidatures.liste.ouvrirDossier,
      ]);
    });

    testWidgets('un geste que le serveur n\'ouvre pas n\'est pas propose', (
      tester,
    ) async {
      await _monter(
        tester,
        caps: CapacitesCandidatures(
          peutLire: true,
          genreLecteurConnu: true,
          peutDecider: true,
          gestes: <String, bool>{...capacitesGestes.gestes, 'refuser': false},
          listes: capacitesGestes.listes,
        ),
      );
      expect(await _entrees(tester, 'a1'), isNot(contains(gestes.refuser)));
    });

    testWidgets('« Ouvrir le dossier » ouvre la candidature de la ligne', (
      tester,
    ) async {
      LigneCandidature? ouverte;
      final FauxCandidaturesDirection port = FauxCandidaturesDirection(
        lignes: <LigneCandidature>[ligneTest(id: 'a1')],
        capacitesRendues: capacitesGestes,
      );
      await monterCandidatures(
        tester,
        port: port,
        ouvrir: (LigneCandidature l) => ouverte = l,
      );
      await _choisir(tester, 'a1', t.admin.candidatures.liste.ouvrirDossier);
      expect(ouverte?.id, 'a1');
      // Le menu n'a pas ouvert la ligne deux fois, et n'a lu aucun dossier.
      expect(port.appelsLire, isEmpty);
    });

    testWidgets('un seul menu ouvert a la fois', (tester) async {
      await _monter(tester);
      await _entrees(tester, 'a1');
      expect(find.byType(PopupMenuItem<int>), findsWidgets);
      // Echap ferme le menu.
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(PopupMenuItem<int>), findsNothing);
    });
  });

  group('un geste depuis la ligne', () {
    testWidgets(
      'lit le dossier, ouvre la meme feuille, envoie la version du dossier',
      (tester) async {
        final FauxCandidaturesDirection port = await _monter(tester);
        final int lectures = port.appels.length;
        await _choisir(tester, 'a1', gestes.mettreEnPause);
        // Le dossier est lu, par l'identifiant de la ligne.
        expect(port.appelsLire, <String>['a1']);
        // La meme feuille que la fiche.
        expect(find.byKey(FeuilleGeste.cle), findsOneWidget);
        await tester.tap(
          find.byKey(const ValueKey<String>('modele-pause_general')),
        );
        await laisser(tester);
        await tester.enterText(
          find.byKey(FeuilleGeste.cleMotif),
          'Attente des pieces.',
        );
        await tester.pump();
        await tester.tap(find.byKey(FeuilleGeste.cleValider));
        await laisser(tester, fois: 12);
        // La version attendue est celle du dossier lu (3), jamais inventee.
        expect(port.appelsGeste, hasLength(1));
        expect(
          port.appelsGeste.single.demande.geste,
          GesteCandidature.mettreEnPause,
        );
        expect(port.appelsGeste.single.demande.versionAttendue, 3);
        expect(port.appelsGeste.single.demande.candidatureId, 'a1');
        // Le succes se dit apres la reponse, avec le nom ; la liste se relit.
        expect(
          find.text(
            t.admin.candidatures.liste.retourLigne(
              nom: 'Amina Diallo',
              retour: t.admin.candidatures.retours.mettreEnPause,
            ),
          ),
          findsOneWidget,
        );
        expect(port.appels.length, greaterThan(lectures));
      },
    );

    testWidgets('un indicateur dit que le dossier se lit', (tester) async {
      final Completer<void> attente = Completer<void>();
      final FauxCandidaturesDirection port = await _monter(
        tester,
        attenteLire: attente,
      );
      await _entrees(tester, 'a1');
      await tester.tap(find.text(gestes.mettreEnPause).last);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(CandidaturesPage.cleOuverture), findsOneWidget);
      expect(
        find.text(t.admin.candidatures.liste.ouverture(nom: 'Amina Diallo')),
        findsOneWidget,
      );
      expect(find.byKey(FeuilleGeste.cle), findsNothing);
      expect(port.appelsGeste, isEmpty);
      attente.complete();
      await laisser(tester, fois: 12);
      expect(find.byKey(CandidaturesPage.cleOuverture), findsNothing);
      expect(find.byKey(FeuilleGeste.cle), findsOneWidget);
    });

    testWidgets(
      'un geste qui n\'est plus permis : un message, aucune feuille, rien d\'ecrit',
      (tester) async {
        // La ligne (liste) dit « pas en pause » ; le dossier lu, lui, l'est deja.
        final FauxCandidaturesDirection port = await _monter(
          tester,
          dossier: detailTest(id: 'a1', nom: 'Amina Diallo', enPause: true),
        );
        final int lectures = port.appels.length;
        await _choisir(tester, 'a1', gestes.mettreEnPause);
        expect(find.byKey(FeuilleGeste.cle), findsNothing);
        expect(
          find.text(
            t.admin.candidatures.liste.gestePlusPossible(
              etat: t.admin.candidatures.etats.enPause,
            ),
          ),
          findsOneWidget,
        );
        expect(port.appelsGeste, isEmpty);
        // La liste est relue : la ligne a change.
        expect(port.appels.length, greaterThan(lectures));
      },
    );

    testWidgets('un dossier illisible : un message, aucune feuille', (
      tester,
    ) async {
      final FauxCandidaturesDirection port = await _monter(
        tester,
        erreurLire: (int _) => StateError('panne'),
      );
      await _choisir(tester, 'a1', gestes.refuser);
      expect(find.byKey(FeuilleGeste.cle), findsNothing);
      expect(
        find.text(t.admin.candidatures.liste.dossierIllisible),
        findsOneWidget,
      );
      expect(port.appelsGeste, isEmpty);
    });

    testWidgets(
      'refuser garde ses confirmations : motif et message exiges, bouton d\'alerte',
      (tester) async {
        final FauxCandidaturesDirection port = await _monter(tester);
        await _choisir(tester, 'a1', gestes.refuser);
        expect(find.byKey(FeuilleGeste.cle), findsOneWidget);
        // Sans motif ni modele, rien ne part.
        await tester.tap(find.byKey(FeuilleGeste.cleValider));
        await laisser(tester);
        expect(port.appelsGeste, isEmpty);
        expect(
          find.text(t.admin.candidatures.feuille.motifManquant),
          findsWidgets,
        );
      },
    );

    testWidgets(
      '1440 : le menu de la ligne ne l\'ouvre pas, la ligne ne lit aucun dossier',
      (tester) async {
        LigneCandidature? ouverte;
        final FauxCandidaturesDirection port = FauxCandidaturesDirection(
          lignes: <LigneCandidature>[ligneTest(id: 'a1', nom: 'Amina Diallo')],
          capacitesRendues: capacitesGestes,
        );
        await monterCandidatures(
          tester,
          port: port,
          largeur: 1440,
          hauteur: 1800,
          ouvrir: (LigneCandidature l) => ouverte = l,
        );
        await tester.tap(find.byKey(MenuLigneCandidature.cle('a1')));
        await tester.pumpAndSettle();
        expect(
          ouverte,
          isNull,
          reason: 'le menu est hors de la cible de la ligne',
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(cleCandidature('a1')));
        await laisser(tester);
        expect(ouverte?.id, 'a1');
        expect(port.appelsLire, isEmpty);
      },
    );
  });

  group('apres un geste : filtres, tri et page sont gardes', () {
    testWidgets(
      'la relecture part avec le meme filtre, le meme tri, la meme page',
      (tester) async {
        final FauxCandidaturesDirection port = FauxCandidaturesDirection(
          lignes: <LigneCandidature>[
            for (int i = 0; i < 70; i++)
              ligneTest(
                id: i == 55 ? 'a1' : 'p$i',
                nom: i == 55
                    ? 'Amina Diallo'
                    : 'Personne ${i.toString().padLeft(2, '0')}',
                derniereActivite: DateTime.utc(
                  2026,
                  10,
                  20,
                ).subtract(Duration(minutes: i)),
              ),
          ],
          capacitesRendues: capacitesGestes,
          details: <DetailCandidature>[
            detailTest(id: 'a1', nom: 'Amina Diallo', version: 3),
          ],
        );
        await monterCandidatures(tester, port: port, ouvrir: (_) {});
        await ouvrirMenuFiltre(tester, _cle('candidatures-filtre-etat'));
        await tester.tap(find.text(t.admin.candidatures.etats.enExamen).last);
        await tester.pumpAndSettle();
        await fermerPlus(tester);
        await laisser(tester);
        final Finder suivante = find.byKey(
          const ValueKey<String>('nav-suivant'),
        );
        await tester.ensureVisible(suivante);
        await tester.pump();
        await tester.tap(suivante);
        await laisser(tester);
        expect(port.appels.last.page, 2);
        final AppelLister avant = port.appels.last;

        await _choisir(tester, 'a1', gestes.mettreEnPause);
        await tester.tap(
          find.byKey(const ValueKey<String>('modele-pause_general')),
        );
        await laisser(tester);
        await tester.enterText(find.byKey(FeuilleGeste.cleMotif), 'Attente.');
        await tester.pump();
        await tester.tap(find.byKey(FeuilleGeste.cleValider));
        await laisser(tester, fois: 12);

        expect(port.appelsGeste, hasLength(1));
        final AppelLister apres = port.appels.last;
        expect(apres.filtre, avant.filtre);
        expect(apres.tri, avant.tri);
        expect(apres.page, 2);
      },
    );
  });
}
