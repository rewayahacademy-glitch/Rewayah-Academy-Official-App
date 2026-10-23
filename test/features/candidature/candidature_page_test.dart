// CAND-01 : le parcours du candidat dans la Salle d'examen, de la presentation
// a l'envoi. Les etats de la fiche, chacun rendu : chargement, contenu, erreur,
// hors ligne, capacite indisponible, aucune candidature, lecture seule ; puis
// la presentation, une question par ecran, la grille, le fuseau, le
// recapitulatif, les conditions de remuneration (en pourcentage, jamais un
// montant), le cadre religieux, l'envoi et chacun de ses refus.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/port_ma_candidature.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/i18n/isolat_bidi.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/filter_pill.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/candidature/choix_avec_recherche.dart';
import 'package:rewayah_academy/features/candidature/coquille_parcours.dart';
import 'package:rewayah_academy/features/candidature/disponibilites_etape.dart';
import 'package:rewayah_academy/features/candidature/fuseau_etape.dart';
import 'package:rewayah_academy/features/candidature/libelles_parcours.dart';
import 'package:rewayah_academy/features/candidature/recapitulatif_etape.dart';

import '../../fixtures/candidature/faux_ma_candidature.dart';
import '../../support/garde_interface.dart';
import 'hote_candidature.dart';

/// Un double dont la lecture du questionnaire attend qu'on la libere.
class _Lent extends FauxMaCandidature {
  final Completer<void> libere = Completer<void>();

  @override
  Future<Questionnaire> questionnaire() async {
    await libere.future;
    return super.questionnaire();
  }
}

/// Le texte entier d'un `Text`. Un trait d'union d'un nom (« Al-Fatiha ») porte
/// un joint insecable (U+2060) que le texte du modele n'a pas : il est ignore.
Finder _texte(String t) => find.byWidgetPredicate(
  (Widget w) => w is Text && w.data?.replaceAll('\u2060', '') == t,
  description: 'texte « $t »',
);

void main() {
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('etats de la page', () {
    testWidgets('chargement : un squelette, aucune fausse donnee', (
      WidgetTester tester,
    ) async {
      final _Lent port = _Lent();
      await monterQuestionnaire(tester, port: port, attendre: false);
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(Skeleton), findsWidgets);
      expect(find.byKey(CoquilleParcours.actionKey), findsNothing);
      expect(
        _texte(t.recrutement.parcours.presentation.p1.titre),
        findsNothing,
      );
      port.libere.complete();
      await tester.pumpAndSettle();
      expect(
        _texte(t.recrutement.parcours.presentation.p1.titre),
        findsOneWidget,
      );
    });

    testWidgets(
      'contenu : la presentation, « 1 sur 23 », un seul bouton plein',
      (WidgetTester tester) async {
        await monterQuestionnaire(tester, port: FauxMaCandidature());
        expect(
          _texte(t.recrutement.parcours.presentation.p1.titre),
          findsOneWidget,
        );
        expect(_texte(t.commun.etape.sur(n: 1, total: 23)), findsOneWidget);
        verifierUnSeulBoutonPlein(tester);
        // « Retour » est en bas, avec « Continuer ».
        expect(find.byKey(CoquilleParcours.retourKey), findsOneWidget);
        expect(find.byKey(CoquilleParcours.actionKey), findsOneWidget);
      },
    );

    testWidgets(
      '« Continuer » ne parait jamais desactive : actif, en aplat violet plein '
      '(demande du directeur du 22/10), avant comme apres un choix',
      (WidgetTester tester) async {
        await monterQuestionnaire(tester, port: FauxMaCandidature());
        final Finder action = find.byKey(CoquilleParcours.actionKey);
        final ActionPrincipale bouton = tester.widget<ActionPrincipale>(action);
        expect(bouton.onPress, isNotNull);
        expect(bouton.enCours, isFalse);
        expect(bouton.affirmee, isTrue);
        // Le fond peint est l'aplat de marque, pas la lavande douce qui se
        // lisait comme un bouton inerte.
        final AppPalette palette = AppPalette.of(tester.element(action));
        final List<Color?> fonds = <Color?>[
          for (final DecoratedBox boite in tester.widgetList<DecoratedBox>(
            find.descendant(of: action, matching: find.byType(DecoratedBox)),
          ))
            if (boite.decoration is BoxDecoration)
              (boite.decoration as BoxDecoration).color,
        ];
        expect(fonds, contains(palette.surfacePrimary.background));
        expect(fonds, isNot(contains(palette.surfaceActionDouce.background)));
        // Une question, un choix fait : le bouton est le meme.
        await tester.tap(action);
        await tester.pumpAndSettle();
        await tester.tap(action);
        await tester.pumpAndSettle();
        final Finder suivante = find.byKey(CoquilleParcours.actionKey);
        expect(suivante, findsOneWidget);
        expect(tester.widget<ActionPrincipale>(suivante).affirmee, isTrue);
        expect(tester.widget<ActionPrincipale>(suivante).onPress, isNotNull);
      },
    );

    testWidgets('erreur : la phrase et « Reessayer », qui relit', (
      WidgetTester tester,
    ) async {
      final FauxMaCandidature port = FauxMaCandidature()
        ..erreurQuestionnaire = Exception('boum');
      await monterQuestionnaire(tester, port: port);
      expect(_texte(t.recrutement.questionnaire.nonCharge), findsOneWidget);
      expect(_texte(t.commun.reessayer), findsOneWidget);
      port.erreurQuestionnaire = null;
      await tester.tap(_texte(t.commun.reessayer));
      await tester.pumpAndSettle();
      expect(
        _texte(t.recrutement.parcours.presentation.p1.titre),
        findsOneWidget,
      );
    });

    testWidgets(
      'hors ligne sans rien de lu : ce qui manque, sans redire « hors ligne »',
      (WidgetTester tester) async {
        final FauxMaCandidature port = FauxMaCandidature()
          ..erreurQuestionnaire = const HorsLigneCandidature();
        await monterQuestionnaire(tester, port: port, horsLigne: true);
        expect(_texte(t.recrutement.questionnaire.nonCharge), findsOneWidget);
        // Le bandeau le dit une fois ; le bloc n'y revient pas.
        expect(_texte(t.reseau.horsLigne), findsOneWidget);
      },
    );

    testWidgets(
      'capacite indisponible : la phrase, sans « Reessayer », sans code',
      (WidgetTester tester) async {
        await monterQuestionnaire(
          tester,
          port: FauxMaCandidatureIndisponible(),
        );
        expect(_texte(t.recrutement.questionnaire.nonOuverte), findsOneWidget);
        expect(_texte(t.commun.reessayer), findsNothing);
        expect(find.textContaining('CAND-BR'), findsNothing);
        expect(find.byKey(CoquilleParcours.actionKey), findsNothing);
      },
    );

    testWidgets('des conditions indisponibles : la meme phrase, une fois', (
      WidgetTester tester,
    ) async {
      final FauxMaCandidature port = FauxMaCandidature()
        ..erreurConditions = const CapaciteIndisponible(
          dependanceConditionsRemuneration,
        );
      await monterQuestionnaire(tester, port: port);
      expect(_texte(t.recrutement.questionnaire.nonOuverte), findsOneWidget);
    });

    testWidgets(
      'un champ que cette version ne connait pas : etape non ouverte',
      (WidgetTester tester) async {
        final Map<String, dynamic> json = questionnaireJsonDeTest();
        (json['champs'] as List<Map<String, dynamic>>).add(<String, dynamic>{
          'code': 'nouveauChamp',
          'carte': 'langues',
          'type': 'choix',
          'requis': true,
          'options': <String>['a'],
        });
        await monterQuestionnaire(
          tester,
          port: FauxMaCandidature(questionnaireJson: json),
        );
        expect(_texte(t.recrutement.questionnaire.nonOuverte), findsOneWidget);
        expect(find.text('nouveauChamp'), findsNothing);
      },
    );

    testWidgets('aucune candidature pour ce compte : retour au portail', (
      WidgetTester tester,
    ) async {
      await monterQuestionnaire(
        tester,
        port: FauxMaCandidature(),
        etat: etatCandidat(candidature: CandidatureDossier.aucune),
      );
      expect(_texte(t.attente.titreDossier), findsOneWidget);
      expect(find.byKey(CoquilleParcours.actionKey), findsNothing);
    });

    testWidgets('une candidature retiree n ouvre plus le questionnaire', (
      WidgetTester tester,
    ) async {
      await monterQuestionnaire(
        tester,
        port: FauxMaCandidature(),
        etat: etatCandidat(
          candidature: const CandidatureDossier(
            existe: true,
            etape: EtapeCandidature.prequalification,
            issue: IssueCandidature.retiree,
          ),
        ),
      );
      expect(_texte(t.attente.titreDossier), findsOneWidget);
    });

    testWidgets('en pause : le questionnaire reste ferme', (
      WidgetTester tester,
    ) async {
      await monterQuestionnaire(
        tester,
        port: FauxMaCandidature(),
        etat: etatCandidat(candidature: candidatureAFaire(enPause: true)),
      );
      expect(_texte(t.attente.titreDossier), findsOneWidget);
    });
  });

  group('le parcours, une question par ecran', () {
    testWidgets('chaque ecran a un seul bouton plein, jusqu au recapitulatif', (
      WidgetTester tester,
    ) async {
      await monterQuestionnaire(tester, port: FauxMaCandidature());
      verifierUnSeulBoutonPlein(tester);
      await passerLaPresentation(tester);
      for (final (String champ, List<String> touches) in parcoursComplet) {
        verifierUnSeulBoutonPlein(tester);
        expect(
          _texte(t.recrutement.parcours.q.langueMaternelle.titre),
          champ == 'langueMaternelle' ? findsOneWidget : findsNothing,
        );
        for (final String cle in touches) {
          await toucherCle(tester, cle);
        }
        await continuer(tester);
      }
      expect(_texte(t.recrutement.parcours.recap.titre), findsOneWidget);
      // Trois jours : « memes heures ? » est pose, un ecran de plus.
      expect(_texte(t.commun.etape.sur(n: 24, total: 24)), findsOneWidget);
      verifierUnSeulBoutonPlein(tester);
    });

    testWidgets(
      'la langue maternelle est facultative : on continue sans elle, sans '
      'reproche',
      (WidgetTester tester) async {
        await monterQuestionnaire(tester, port: FauxMaCandidature());
        await passerLaPresentation(tester);
        expect(
          _texte(t.recrutement.parcours.q.langueMaternelle.titre),
          findsOneWidget,
        );
        expect(
          find.textContaining('facultative'),
          findsOneWidget,
          reason: 'la question dit qu elle est facultative',
        );
        await continuer(tester);
        expect(_texte(t.recrutement.parcours.choisir), findsNothing);
        expect(
          _texte(t.recrutement.parcours.q.languesExplication.titre),
          findsOneWidget,
        );
      },
    );

    testWidgets('« Continuer » sans reponse dit quoi faire, et n avance pas', (
      WidgetTester tester,
    ) async {
      await monterQuestionnaire(tester, port: FauxMaCandidature());
      await repondreAvant(tester, 'languesExplication');
      await continuer(tester);
      expect(_texte(t.recrutement.parcours.choisirPlusieurs), findsOneWidget);
      expect(
        _texte(t.recrutement.parcours.q.languesExplication.titre),
        findsOneWidget,
      );
      // Une reponse efface l'indication, et le bouton avance.
      await toucherCle(tester, 'option-languesExplication-poular');
      await continuer(tester);
      expect(
        _texte(t.recrutement.parcours.choisirPlusieurs),
        findsNothing,
      );
      expect(
        _texte(t.recrutement.parcours.q.niveauMemorisationDeclare.titre),
        findsOneWidget,
      );
    });

    testWidgets('un choix multiple vide dit « au moins une reponse »', (
      WidgetTester tester,
    ) async {
      await monterQuestionnaire(tester, port: FauxMaCandidature());
      await repondreAvant(tester, 'languesExplication');
      await continuer(tester);
      expect(_texte(t.recrutement.parcours.choisirPlusieurs), findsOneWidget);
    });

    testWidgets(
      'Retour revient d une etape ; a la premiere il sort au portail',
      (WidgetTester tester) async {
        await monterQuestionnaire(tester, port: FauxMaCandidature());
        await continuer(tester);
        expect(
          _texte(t.recrutement.parcours.presentation.p2.titre),
          findsOneWidget,
        );
        await toucherCle(tester, 'parcours-retour');
        expect(
          _texte(t.recrutement.parcours.presentation.p1.titre),
          findsOneWidget,
        );
        await toucherCle(tester, 'parcours-retour');
        expect(_texte(t.attente.titreDossier), findsOneWidget);
      },
    );

    testWidgets(
      'la memorisation : quatre cartes, de « aucun juz » a tout le Coran',
      (WidgetTester tester) async {
        await monterQuestionnaire(tester, port: FauxMaCandidature());
        await repondreAvant(tester, 'niveauMemorisationDeclare');
        final o = t.recrutement.parcours.q.niveauMemorisationDeclare;
        expect(_texte(o.titre), findsOneWidget);
        // Ce que la personne a memorise, pas ce qu'elle a recu : l'ijaza est
        // une autre question.
        expect(_texte(o.explication), findsOneWidget);
        for (final String code in <String>[
          'aucune',
          'moins_10_juz',
          'de_10_a_29_juz',
          'coran_entier',
        ]) {
          expect(
            find.byKey(ValueKey<String>('option-niveauMemorisationDeclare-$code')),
            findsOneWidget,
            reason: code,
          );
        }
        expect(_texte(o.options.de_10_a_29_juz.libelle), findsOneWidget);
        expect(_texte(o.options.de_10_a_29_juz.description), findsOneWidget);
        expect(
          _texte(t.choix.exemple(texte: o.options.de_10_a_29_juz.exemple)),
          findsOneWidget,
        );
        // L'ijaza n'est plus un niveau de memorisation.
        expect(find.textContaining('ijaza'), findsNWidgets(1));
      },
    );

    testWidgets(
      'l ijaza : oui, pret a un test, non ; elle se montre pendant l entretien',
      (WidgetTester tester) async {
        await monterQuestionnaire(tester, port: FauxMaCandidature());
        await repondreAvant(tester, 'ijazaPresentable');
        final o = t.recrutement.parcours.q.ijazaPresentable;
        expect(_texte(o.titre), findsOneWidget);
        for (final String code in <String>['oui', 'pret_test', 'non']) {
          expect(
            find.byKey(ValueKey<String>('option-ijazaPresentable-$code')),
            findsOneWidget,
            reason: code,
          );
        }
        expect(_texte(o.options.oui.explication), findsOneWidget);
        expect(_texte(o.options.pret_test.libelle), findsOneWidget);
        expect(_texte(o.options.pret_test.description), findsOneWidget);
        expect(find.textContaining('entretien'), findsWidgets);
        // Avoir memorise n'est pas avoir une ijaza : la question le dit.
        expect(_texte(o.explication), findsOneWidget);
        expect(o.explication, contains('à part'));
      },
    );

    testWidgets(
      'les publics : quatre tranches d age, chacune decrite (ce qu on y '
      'enseigne, ce que cela demande)',
      (WidgetTester tester) async {
        await monterQuestionnaire(tester, port: FauxMaCandidature());
        await repondreAvant(tester, 'publics');
        final o = t.recrutement.parcours.q.publics;
        expect(_texte(o.titre), findsOneWidget);
        for (final String code in <String>['6_9', '10_13', '14_17', 'adultes']) {
          expect(
            find.byKey(ValueKey<String>('option-publics-$code')),
            findsOneWidget,
            reason: code,
          );
        }
        for (final ({String libelle, String description, String explication, String exemple}) x
            in <({String libelle, String description, String explication, String exemple})>[
              (
                libelle: o.options.o_6_9.libelle,
                description: o.options.o_6_9.description,
                explication: o.options.o_6_9.explication,
                exemple: o.options.o_6_9.exemple,
              ),
              (
                libelle: o.options.o_10_13.libelle,
                description: o.options.o_10_13.description,
                explication: o.options.o_10_13.explication,
                exemple: o.options.o_10_13.exemple,
              ),
              (
                libelle: o.options.o_14_17.libelle,
                description: o.options.o_14_17.description,
                explication: o.options.o_14_17.explication,
                exemple: o.options.o_14_17.exemple,
              ),
              (
                libelle: o.options.adultes.libelle,
                description: o.options.adultes.description,
                explication: o.options.adultes.explication,
                exemple: o.options.adultes.exemple,
              ),
            ]) {
          expect(_texte(x.libelle), findsOneWidget, reason: x.libelle);
          expect(_texte(x.description), findsOneWidget, reason: x.libelle);
          expect(_texte(x.explication), findsOneWidget, reason: x.libelle);
          expect(
            _texte(t.choix.exemple(texte: x.exemple)),
            findsOneWidget,
            reason: x.libelle,
          );
        }
        // Aucune tranche n'est imposee : sans choix, on le dit.
        await continuer(tester);
        expect(_texte(t.recrutement.parcours.choisirPlusieurs), findsOneWidget);
        // Plusieurs tranches, au choix.
        await toucherCle(tester, 'option-publics-6_9');
        await toucherCle(tester, 'option-publics-adultes');
        await continuer(tester);
        expect(find.byKey(FuseauEtape.carteKey), findsOneWidget);
      },
    );

    testWidgets('le compte bancaire dit ce que cela change pour le versement', (
      WidgetTester tester,
    ) async {
      await monterQuestionnaire(tester, port: FauxMaCandidature());
      await repondreAvant(tester, 'compteBancaire');
      final o = t.recrutement.parcours.q.compteBancaire;
      expect(_texte(o.options.oui.explication), findsOneWidget);
      expect(_texte(o.options.non.explication), findsOneWidget);
    });

    testWidgets(
      'chaque reponse est gardee : le brouillon part a chaque etape',
      (WidgetTester tester) async {
        final FauxMaCandidature port = FauxMaCandidature();
        await monterQuestionnaire(tester, port: port);
        await repondreJusqua(tester, 2);
        expect(port.brouillons.length, 2);
        expect(port.brouillons.last['languesExplication'], <String>[
          'poular',
          'francais',
        ]);
        expect(port.versionsBrouillonRecues, <int>[0, 1]);
      },
    );

    testWidgets(
      'un brouillon se reprend sans la presentation, a la bonne question',
      (WidgetTester tester) async {
        final FauxMaCandidature port = FauxMaCandidature(
          questionnaireJson: questionnaireJsonDeTest(
            versionBrouillon: 2,
            dernieresReponses: <String, Object?>{
              'langueMaternelle': 'poular',
              'languesExplication': <String>['poular'],
            },
          ),
        );
        await monterQuestionnaire(tester, port: port);
        expect(
          _texte(t.recrutement.parcours.q.niveauMemorisationDeclare.titre),
          findsOneWidget,
        );
        expect(
          _texte(t.recrutement.parcours.presentation.p1.titre),
          findsNothing,
        );
        // Retour : la reponse deja donnee est retenue.
        await toucherCle(tester, 'parcours-retour');
        expect(
          _texte(t.recrutement.parcours.q.languesExplication.titre),
          findsOneWidget,
        );
      },
    );

    testWidgets('un complement demande ouvre la partie nommee, signalee', (
      WidgetTester tester,
    ) async {
      final FauxMaCandidature port = FauxMaCandidature(
        questionnaireJson: questionnaireJsonDeTest(
          dernieresReponses: reponsesCompletesDeTest(),
        ),
      );
      await monterQuestionnaire(
        tester,
        port: port,
        etat: etatCandidat(
          candidature: candidatureAFaire(complement: <String>['publics']),
        ),
      );
      expect(_texte(t.recrutement.parcours.q.publics.titre), findsOneWidget);
      expect(
        _texte(t.recrutement.questionnaire.complementCarte),
        findsOneWidget,
      );
    });

    testWidgets('un questionnaire change signale les reponses a relire', (
      WidgetTester tester,
    ) async {
      final FauxMaCandidature port = FauxMaCandidature(
        questionnaireJson: questionnaireJsonDeTest(
          dernieresReponses: <String, Object?>{'langueMaternelle': 'poular'},
          perime: true,
        ),
      );
      await monterQuestionnaire(tester, port: port);
      expect(_texte(t.recrutement.questionnaire.perime), findsOneWidget);
    });

    testWidgets(
      'une reponse du brouillon que le serveur refuserait est ecartee',
      (WidgetTester tester) async {
        final FauxMaCandidature port = FauxMaCandidature(
          questionnaireJson: questionnaireJsonDeTest(
            dernieresReponses: <String, Object?>{'langueMaternelle': 'klingon'},
          ),
        );
        await monterQuestionnaire(tester, port: port);
        // Aucune reponse valable : le parcours recommence a la presentation.
        expect(
          _texte(t.recrutement.parcours.presentation.p1.titre),
          findsOneWidget,
        );
      },
    );
  });

  group('les langues : les cartes du public, puis une recherche en cartes', () {
    testWidgets(
      'la langue maternelle : les langues du public en cartes, l arabe '
      'compris, les autres par la recherche',
      (WidgetTester tester) async {
        await monterQuestionnaire(tester, port: FauxMaCandidature());
        await passerLaPresentation(tester);
        final l = t.recrutement.parcours.langues;
        // Poular, peul et fulfulde sont une seule langue, en une carte.
        expect(_texte(l.poular), findsOneWidget);
        expect(l.poular, allOf(contains('peul'), contains('fulfulde')));
        for (final String nom in <String>[
          l.man,
          l.sus,
          l.sw,
          l.ha,
          l.wo,
          l.bm,
          l.snk,
          l.mnk,
          l.francais,
          l.english,
          l.ar,
          l.autre,
        ]) {
          expect(_texte(nom), findsOneWidget, reason: nom);
        }
        // Une langue hors de cette liste n'est pas une carte.
        expect(_texte(l.ps), findsNothing);
        // Dire quelles langues Rewayah enseigne n'a pas de sens ici.
        expect(_texte(l.dansReferentiel), findsNothing);
        expect(_texte(l.horsReferentiel), findsNothing);
        await toucherCle(tester, 'choix-recherche-autre');
        await tester.enterText(find.byKey(ChoixAvecRecherche.champKey), 'pacht');
        await tester.pumpAndSettle();
        // Les resultats sont des cartes, pas des lignes.
        expect(
          find.byKey(const ValueKey<String>('option-langueMaternelle-ps')),
          findsOneWidget,
        );
        expect(find.byKey(ChoixAvecRecherche.ligneKey('ps')), findsNothing);
        expect(_texte(l.poular), findsNothing);
        await toucherCle(tester, 'option-langueMaternelle-ps');
        await tester.tap(_texte(l.retour));
        await tester.pumpAndSettle();
        // Elle devient une carte retenue de la liste.
        expect(_texte(l.ps), findsOneWidget);
        await continuer(tester);
        expect(
          _texte(t.recrutement.parcours.q.languesExplication.titre),
          findsOneWidget,
        );
        await toucherCle(tester, 'parcours-retour');
        expect(_texte(l.ps), findsOneWidget);
      },
    );

    testWidgets('peul, fulfulde, poular : la recherche trouve la meme carte', (
      WidgetTester tester,
    ) async {
      await monterQuestionnaire(tester, port: FauxMaCandidature());
      await repondreAvant(tester, 'languesExplication');
      await toucherCle(tester, 'choix-recherche-autre');
      for (final String mot in <String>['peul', 'fulfulde', 'poular']) {
        await tester.enterText(find.byKey(ChoixAvecRecherche.champKey), mot);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey<String>('option-languesExplication-poular')),
          findsOneWidget,
          reason: mot,
        );
        expect(
          find.byKey(const ValueKey<String>('option-languesExplication-francais')),
          findsNothing,
          reason: mot,
        );
      }
    });

    testWidgets(
      'les langues d explication : sans l arabe, sans plafond, chacune dit '
      'si Rewayah y donne des cours',
      (WidgetTester tester) async {
        await monterQuestionnaire(tester, port: FauxMaCandidature());
        await repondreAvant(tester, 'languesExplication');
        final l = t.recrutement.parcours.langues;
        // L'arabe n'est pas une langue de cours : ni carte, ni resultat.
        expect(_texte(l.ar), findsNothing);
        expect(
          find.byKey(const ValueKey<String>('option-languesExplication-ar')),
          findsNothing,
        );
        expect(
          _texte(t.recrutement.parcours.q.languesExplication.explication),
          findsOneWidget,
        );
        // Poular, francais, anglais : des cours existent ; les autres du
        // public : pas encore ; « autre langue » a sa propre phrase.
        expect(_texte(l.dansReferentiel), findsNWidgets(3));
        expect(_texte(l.horsReferentiel), findsNWidgets(8));
        expect(_texte(l.autreDescription), findsOneWidget);
        await toucherCle(tester, 'choix-recherche-autre');
        await tester.enterText(find.byKey(ChoixAvecRecherche.champKey), 'arab');
        await tester.pumpAndSettle();
        expect(_texte(l.aucune), findsOneWidget);
      },
    );

    testWidgets('aucun plafond : douze langues, aucun « trop de reponses »', (
      WidgetTester tester,
    ) async {
      await monterQuestionnaire(tester, port: FauxMaCandidature());
      await repondreAvant(tester, 'languesExplication');
      for (final String code in <String>[
        'poular',
        'man',
        'sus',
        'sw',
        'ha',
        'wo',
        'bm',
        'snk',
        'mnk',
        'francais',
        'english',
        'autre',
      ]) {
        await toucherCle(tester, 'option-languesExplication-$code');
      }
      await continuer(tester);
      expect(find.textContaining('au plus'), findsNothing);
      expect(
        _texte(t.recrutement.parcours.q.niveauMemorisationDeclare.titre),
        findsOneWidget,
      );
    });

    testWidgets(
      'aucune langue ne correspond : une phrase, pas une liste vide',
      (WidgetTester tester) async {
        await monterQuestionnaire(tester, port: FauxMaCandidature());
        await passerLaPresentation(tester);
        await toucherCle(tester, 'choix-recherche-autre');
        await tester.enterText(find.byKey(ChoixAvecRecherche.champKey), 'zzzz');
        await tester.pumpAndSettle();
        expect(_texte(t.recrutement.parcours.langues.aucune), findsOneWidget);
      },
    );

    testWidgets(
      'les pays frequents en cartes ; « Un autre pays » ouvre la recherche',
      (WidgetTester tester) async {
        await monterQuestionnaire(tester, port: FauxMaCandidature());
        await repondreAvant(tester, 'paysResidence');
        expect(
          _texte(t.recrutement.parcours.q.paysResidence.titre),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey<String>('option-paysResidence-GN')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey<String>('option-paysResidence-SA')),
          findsOneWidget,
        );
        // Un pays rare passe par la recherche, en francais comme en arabe.
        await toucherCle(tester, 'choix-recherche-autre');
        await tester.enterText(
          find.byKey(ChoixAvecRecherche.champKey),
          'moldavie',
        );
        await tester.pumpAndSettle();
        expect(find.byKey(ChoixAvecRecherche.ligneKey('MD')), findsOneWidget);
        await tester.tap(find.byKey(ChoixAvecRecherche.ligneKey('MD')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey<String>('option-paysResidence-MD')),
          findsOneWidget,
        );
        await continuer(tester);
        // Le pays de versement repart de la residence, modifiable.
        expect(
          _texte(t.recrutement.parcours.q.paysVersement.titre),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey<String>('option-paysVersement-MD')),
          findsOneWidget,
        );
      },
    );
  });

  group('le fuseau : deduit de l appareil, confirme par une carte', () {
    testWidgets('« Chez vous, il est 14:05 ? » puis Oui retient le fuseau', (
      WidgetTester tester,
    ) async {
      final FauxMaCandidature port = FauxMaCandidature();
      await monterQuestionnaire(tester, port: port);
      await repondreAvant(tester, 'fuseauIana');
      expect(find.byKey(FuseauEtape.carteKey), findsOneWidget);
      expect(
        _texte(
          t.recrutement.parcours.fuseau.heureChezVous(
            heure: isolerSens('14:05'),
          ),
        ),
        findsOneWidget,
      );
      expect(
        _texte(t.recrutement.parcours.fuseau.lieuPropose(lieu: 'Paris')),
        findsOneWidget,
      );
      // Rien n'est retenu sans le geste.
      await continuer(tester);
      expect(_texte(t.recrutement.parcours.choisir), findsOneWidget);
      await toucherCle(tester, 'fuseau-oui');
      await continuer(tester);
      // Les disponibilites sont a l'heure de chez la personne, jamais a celle
      // de Paris par defaut : le fuseau retenu est celui de l'appareil confirme.
      expect(
        _texte(t.recrutement.parcours.q.disponibilitesDeclarees.titre),
        findsOneWidget,
      );
    });

    testWidgets(
      '« Changer » ouvre la liste des villes, la recherche en trouve d autres',
      (WidgetTester tester) async {
        await monterQuestionnaire(tester, port: FauxMaCandidature());
        await repondreAvant(tester, 'fuseauIana');
        await toucherCle(tester, 'fuseau-changer');
        expect(find.byKey(FuseauEtape.champKey), findsOneWidget);
        expect(
          find.byKey(FuseauEtape.ligneKey('Europe/Paris')),
          findsOneWidget,
        );
        await tester.enterText(find.byKey(FuseauEtape.champKey), 'dakar');
        await tester.pumpAndSettle();
        expect(
          find.byKey(FuseauEtape.ligneKey('Africa/Dakar')),
          findsOneWidget,
        );
        expect(find.byKey(FuseauEtape.ligneKey('Europe/Paris')), findsNothing);
        await tester.tap(find.byKey(FuseauEtape.ligneKey('Africa/Dakar')));
        await tester.pumpAndSettle();
        expect(
          _texte(t.recrutement.parcours.fuseau.retenu(lieu: 'Dakar')),
          findsOneWidget,
        );
        await continuer(tester);
        await toucherCle(tester, 'option-jour-1');
        await continuer(tester);
        // Les heures sont celles de Dakar, dites en toutes lettres.
        expect(
          _texte(t.recrutement.parcours.creneaux.fuseauRappel(lieu: 'Dakar')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'sans fuseau lisible sur l appareil : la liste, sans rien presumer',
      (WidgetTester tester) async {
        await monterQuestionnaire(
          tester,
          port: FauxMaCandidature(),
          fuseauAppareil: null,
        );
        await repondreAvant(tester, 'fuseauIana');
        expect(find.byKey(FuseauEtape.carteKey), findsNothing);
        expect(find.byKey(FuseauEtape.champKey), findsOneWidget);
        await continuer(tester);
        expect(_texte(t.recrutement.parcours.choisir), findsOneWidget);
      },
    );

    testWidgets('un fuseau que le serveur n accepte pas n est jamais propose', (
      WidgetTester tester,
    ) async {
      await monterQuestionnaire(
        tester,
        port: FauxMaCandidature(),
        fuseauAppareil: 'Mars/Olympus',
      );
      await repondreAvant(tester, 'fuseauIana');
      expect(find.byKey(FuseauEtape.carteKey), findsNothing);
    });
  });

  group('les disponibilites, heure par heure', () {
    /// Mene le parcours jusqu'a l'ecran des jours.
    Future<void> auxJours(
      WidgetTester tester, {
      Size taille = const Size(390, 844),
      FauxMaCandidature? port,
    }) async {
      await monterQuestionnaire(
        tester,
        port: port ?? FauxMaCandidature(),
        taille: taille,
      );
      await repondreAvant(tester, 'jours');
      expect(
        _texte(t.recrutement.parcours.q.disponibilitesDeclarees.titre),
        findsOneWidget,
      );
    }

    bool retenue(WidgetTester tester, Key cle) =>
        tester.widget<FilterPill>(find.byKey(cle)).retenue;

    testWidgets(
      'les jours : sept cartes et trois raccourcis, une question par ecran',
      (WidgetTester tester) async {
        await auxJours(tester);
        verifierUnSeulBoutonPlein(tester);
        for (int j = 1; j <= 7; j++) {
          expect(find.byKey(DisponibilitesEtape.carteJourKey(j)), findsOneWidget);
        }
        final r = t.recrutement.parcours.creneaux;
        for (final String raccourci in <String>[
          r.raccourciLmv,
          r.raccourciMjs,
          r.raccourciFinDeSemaine,
        ]) {
          expect(_texte(raccourci), findsOneWidget, reason: raccourci);
        }
        // Une Classe se tient trois fois par semaine : la question le dit.
        expect(
          _texte(t.recrutement.parcours.q.disponibilitesDeclarees.explication),
          findsOneWidget,
        );
      },
    );

    testWidgets('aucun jour : « Continuer » demande d en choisir un', (
      WidgetTester tester,
    ) async {
      await auxJours(tester);
      await continuer(tester);
      expect(_texte(t.recrutement.parcours.choisirJour), findsOneWidget);
      expect(find.byKey(DisponibilitesEtape.moinsDeTroisKey), findsNothing);
    });

    testWidgets('un raccourci choisit ses jours, qu on peut ensuite modifier', (
      WidgetTester tester,
    ) async {
      await auxJours(tester);
      await toucherCle(tester, 'dispo-raccourci-lmv');
      expect(retenue(tester, DisponibilitesEtape.raccourciKey('lmv')), isTrue);
      expect(retenue(tester, DisponibilitesEtape.raccourciKey('mjs')), isFalse);
      // Le mardi se rajoute : ce n'est plus le raccourci.
      await toucherCle(tester, 'option-jour-2');
      expect(retenue(tester, DisponibilitesEtape.raccourciKey('lmv')), isFalse);
      await toucherCle(tester, 'dispo-raccourci-finDeSemaine');
      expect(
        retenue(tester, DisponibilitesEtape.raccourciKey('finDeSemaine')),
        isTrue,
      );
      await continuer(tester);
      // Le premier jour choisi est le samedi.
      expect(
        _texte(
          t.recrutement.parcours.q.disponibilitesDeclarees.heures.titre(
            jour: 'samedi',
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('moins de trois jours : une phrase, jamais un blocage', (
      WidgetTester tester,
    ) async {
      await auxJours(tester);
      await toucherCle(tester, 'option-jour-1');
      expect(
        _texte(t.recrutement.parcours.creneaux.moinsDeTrois(n: 1)),
        findsOneWidget,
      );
      await toucherCle(tester, 'option-jour-3');
      expect(
        _texte(t.recrutement.parcours.creneaux.moinsDeTrois(n: 2)),
        findsOneWidget,
      );
      await toucherCle(tester, 'option-jour-5');
      expect(find.byKey(DisponibilitesEtape.moinsDeTroisKey), findsNothing);
      // Avec deux jours, on avance quand meme.
      await toucherCle(tester, 'option-jour-5');
      await continuer(tester);
      expect(_texte(t.recrutement.parcours.choisirJour), findsNothing);
    });

    testWidgets(
      'les heures de debut : quatre moments de la journee, vingt-quatre puces',
      (WidgetTester tester) async {
        await auxJours(tester);
        await toucherCle(tester, 'option-jour-1');
        await continuer(tester);
        verifierUnSeulBoutonPlein(tester);
        final r = t.recrutement.parcours.creneaux;
        for (final String moment in <String>[
          r.moments.nuit,
          r.moments.matin,
          r.moments.apresMidi,
          r.moments.soir,
        ]) {
          expect(_texte(moment), findsOneWidget, reason: moment);
        }
        for (int h = 0; h < 24; h++) {
          expect(
            find.byKey(DisponibilitesEtape.puceKey(1, h)),
            findsOneWidget,
            reason: 'heure $h',
          );
        }
        // L'heure de chez la personne, nommee.
        expect(_texte(r.fuseauRappel(lieu: 'Paris')), findsOneWidget);
        // La fin du cours se calcule : la question le dit.
        expect(
          find.textContaining('Un cours d\'enfants dure'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'une heure choisie dit quand on enseigne : de 18 h a 19 h pour des '
      'enfants',
      (WidgetTester tester) async {
        await auxJours(tester);
        await toucherCle(tester, 'option-jour-1');
        await continuer(tester);
        expect(
          find.byKey(DisponibilitesEtape.resumeKey),
          findsOneWidget,
        );
        expect(
          _texte(t.recrutement.parcours.creneaux.heuresChoisies(n: 0)),
          findsOneWidget,
        );
        await toucherCle(tester, 'heure-1-18');
        expect(retenue(tester, DisponibilitesEtape.puceKey(1, 18)), isTrue);
        expect(
          _texte(t.recrutement.parcours.creneaux.heuresChoisies(n: 1)),
          findsOneWidget,
        );
        expect(
          find.textContaining('vous enseignez de 18\u00a0h à 19\u00a0h.'),
          findsOneWidget,
        );
        // Une seconde heure qui suit prolonge la plage ; la touche une
        // seconde fois, elle la retire.
        await toucherCle(tester, 'heure-1-19');
        expect(
          find.textContaining('de 18\u00a0h à 20\u00a0h.'),
          findsOneWidget,
        );
        await toucherCle(tester, 'heure-1-19');
        expect(retenue(tester, DisponibilitesEtape.puceKey(1, 19)), isFalse);
      },
    );

    testWidgets(
      'pour des adultes : de 18 h a 19 h 30, et les deux phrases quand on '
      'enseigne les deux',
      (WidgetTester tester) async {
        final FauxMaCandidature port = FauxMaCandidature(
          questionnaireJson: questionnaireJsonDeTest(
            dernieresReponses: <String, Object?>{
              'langueMaternelle': 'poular',
              'languesExplication': <String>['poular'],
              'niveauMemorisationDeclare': 'coran_entier',
              'niveauLectureTajwid': 'tajwid_enseigne',
              'riwayat': <String>['hafs'],
              'ijazaPresentable': 'oui',
              'experienceDebutants': 'oui',
              'publics': <String>['adultes'],
              'fuseauIana': 'Africa/Conakry',
            },
          ),
        );
        await monterQuestionnaire(tester, port: port);
        // Le brouillon s'arrete aux jours : l'ecran des jours s'ouvre.
        expect(
          _texte(t.recrutement.parcours.q.disponibilitesDeclarees.titre),
          findsOneWidget,
        );
        await toucherCle(tester, 'option-jour-1');
        await continuer(tester);
        await toucherCle(tester, 'heure-1-18');
        expect(
          find.textContaining('vous enseignez de 18\u00a0h à 19\u00a0h\u00a030.'),
          findsOneWidget,
        );
        // Un cours d'enfants n'est pas dit : cette personne n'en enseigne pas.
        expect(find.textContaining('Cours d\'enfants'), findsNothing);
      },
    );

    testWidgets('sans heure de debut, « Continuer » demande d en choisir une', (
      WidgetTester tester,
    ) async {
      await auxJours(tester);
      await toucherCle(tester, 'option-jour-1');
      await continuer(tester);
      await continuer(tester);
      expect(_texte(t.recrutement.parcours.choisirHeure), findsOneWidget);
      await toucherCle(tester, 'heure-1-18');
      expect(_texte(t.recrutement.parcours.choisirHeure), findsNothing);
    });

    testWidgets(
      'un seul jour : pas de « memes heures ? », la semaine suit les heures',
      (WidgetTester tester) async {
        await auxJours(tester);
        await toucherCle(tester, 'option-jour-2');
        await continuer(tester);
        await toucherCle(tester, 'heure-2-9');
        await continuer(tester);
        expect(
          _texte(t.recrutement.parcours.q.disponibilitesDeclarees.semaine.titre),
          findsOneWidget,
        );
        expect(find.byKey(DisponibilitesEtape.jourKey(2)), findsOneWidget);
        // Moins de trois jours : la phrase le dit, sans bloquer.
        expect(
          _texte(t.recrutement.parcours.creneaux.moinsDeTrois(n: 1)),
          findsOneWidget,
        );
        await continuer(tester);
        expect(
          _texte(t.recrutement.parcours.q.classesSouhaitees.titre),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'plusieurs jours : « memes heures ? », oui garde les memes heures partout',
      (WidgetTester tester) async {
        await auxJours(tester);
        await toucherCle(tester, 'dispo-raccourci-lmv');
        await continuer(tester);
        await toucherCle(tester, 'heure-1-18');
        await toucherCle(tester, 'heure-1-19');
        await continuer(tester);
        final q = t.recrutement.parcours.q.disponibilitesDeclarees.memes;
        expect(_texte(q.titre), findsOneWidget);
        expect(
          _texte(q.explication(
            jours: 'lundi, mercredi et vendredi',
            premier: 'lundi',
            heures: '18\u00a0h, 19\u00a0h',
          )),
          findsOneWidget,
        );
        // Chaque carte est decrite.
        expect(_texte(q.oui.libelle), findsOneWidget);
        expect(_texte(q.oui.explication), findsOneWidget);
        expect(_texte(t.choix.exemple(texte: q.non.exemple)), findsOneWidget);
        // Sans reponse, on ne passe pas.
        await continuer(tester);
        expect(_texte(t.recrutement.parcours.choisir), findsOneWidget);
        await toucherCle(tester, 'option-memes-oui');
        await continuer(tester);
        expect(
          _texte(t.recrutement.parcours.q.disponibilitesDeclarees.semaine.titre),
          findsOneWidget,
        );
        for (final int j in <int>[1, 3, 5]) {
          expect(find.byKey(DisponibilitesEtape.jourKey(j)), findsOneWidget);
        }
        expect(find.byKey(DisponibilitesEtape.jourKey(2)), findsNothing);
        // Trois jours : plus de phrase « moins de trois jours ».
        expect(
          find.text(t.recrutement.parcours.creneaux.troisSeances),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '« non » : chaque jour se regle seul, et chaque jour exige une heure',
      (WidgetTester tester) async {
        await auxJours(tester);
        await toucherCle(tester, 'option-jour-1');
        await toucherCle(tester, 'option-jour-3');
        await continuer(tester);
        await toucherCle(tester, 'heure-1-18');
        await continuer(tester);
        await toucherCle(tester, 'option-memes-non');
        await continuer(tester);
        final q = t.recrutement.parcours.q.disponibilitesDeclarees.parJour;
        expect(_texte(q.titre), findsOneWidget);
        // Chaque jour porte ses puces ; le mercredi reprend les heures du lundi.
        expect(find.byKey(DisponibilitesEtape.jourKey(1)), findsOneWidget);
        expect(find.byKey(DisponibilitesEtape.jourKey(3)), findsOneWidget);
        expect(retenue(tester, DisponibilitesEtape.puceKey(3, 18)), isTrue);
        await toucherCle(tester, 'heure-3-18');
        await toucherCle(tester, 'heure-3-20');
        // Le lundi garde son heure.
        expect(retenue(tester, DisponibilitesEtape.puceKey(1, 18)), isTrue);
        expect(retenue(tester, DisponibilitesEtape.puceKey(1, 20)), isFalse);
        await toucherCle(tester, 'heure-3-20');
        await continuer(tester);
        expect(
          _texte(t.recrutement.parcours.choisirHeureJour(jour: 'mercredi')),
          findsOneWidget,
        );
        await toucherCle(tester, 'heure-3-20');
        await continuer(tester);
        final s = t.recrutement.parcours.q.disponibilitesDeclarees.semaine;
        expect(_texte(s.titre), findsOneWidget);
      },
    );

    testWidgets('a 1440 les moments se rangent sur deux colonnes', (
      WidgetTester tester,
    ) async {
      await auxJours(tester, taille: const Size(1440, 900));
      await toucherCle(tester, 'option-jour-1');
      await continuer(tester);
      final r = t.recrutement.parcours.creneaux;
      final Offset nuit = tester.getTopLeft(_texte(r.moments.nuit));
      final Offset matin = tester.getTopLeft(_texte(r.moments.matin));
      final Offset apresMidi = tester.getTopLeft(_texte(r.moments.apresMidi));
      final Offset soir = tester.getTopLeft(_texte(r.moments.soir));
      expect(apresMidi.dx, greaterThan(nuit.dx + 100));
      expect(nuit.dx, matin.dx);
      expect(apresMidi.dx, soir.dx);
      expect(matin.dy, greaterThan(nuit.dy));
      verifierUnSeulBoutonPlein(tester);
    });

    testWidgets('a 390 les moments s empilent, chaque puce fait 48 au moins', (
      WidgetTester tester,
    ) async {
      await auxJours(tester);
      await toucherCle(tester, 'option-jour-1');
      await continuer(tester);
      final r = t.recrutement.parcours.creneaux;
      expect(
        tester.getTopLeft(_texte(r.moments.nuit)).dx,
        tester.getTopLeft(_texte(r.moments.soir)).dx,
      );
      final Rect puce = tester.getRect(
        find.byKey(DisponibilitesEtape.puceKey(1, 18)),
      );
      expect(puce.height, greaterThanOrEqualTo(48));
    });

    testWidgets('chaque ecran des disponibilites enregistre le brouillon', (
      WidgetTester tester,
    ) async {
      final FauxMaCandidature port = FauxMaCandidature();
      await auxJours(tester, port: port);
      final int avant = port.brouillons.length;
      await toucherCle(tester, 'option-jour-1');
      await continuer(tester);
      await toucherCle(tester, 'heure-1-18');
      await continuer(tester);
      expect(port.brouillons.length, avant + 2);
      expect(port.brouillons.last['disponibilitesDeclarees'], <Object?>[
        <String, Object?>{'jour': 1, 'debut': '18:00', 'fin': '19:00'},
      ]);
    });
  });

  group('le nombre de Classes', () {
    Finder carte(String n) =>
        find.byKey(ValueKey<String>('option-classesSouhaitees-$n'));

    testWidgets(
      'de 1 a 3 : trois cartes, les heures par semaine pour des enfants',
      (WidgetTester tester) async {
        await monterQuestionnaire(tester, port: FauxMaCandidature());
        await repondreAvant(tester, 'classesSouhaitees');
        final q = t.recrutement.parcours.q.classesSouhaitees;
        final c = t.recrutement.parcours.classes;
        expect(_texte(q.titre), findsOneWidget);
        expect(_texte(q.explication), findsOneWidget);
        expect(carte('1'), findsOneWidget);
        expect(carte('2'), findsOneWidget);
        expect(carte('3'), findsOneWidget);
        expect(carte('4'), findsNothing);
        expect(_texte(c.libelle(n: 1)), findsOneWidget);
        expect(_texte(c.libelle(n: 2)), findsOneWidget);
        expect(_texte(c.libelle(n: 3)), findsOneWidget);
        // Des enfants : trois seances d'une heure par Classe.
        expect(
          find.textContaining(
            'Soit ${libelleDuree(180)} par semaine avec des enfants.',
          ),
          findsOneWidget,
        );
        expect(
          find.textContaining(
            'Soit ${libelleDuree(540)} par semaine avec des enfants.',
          ),
          findsOneWidget,
        );
        expect(find.textContaining('avec des adultes'), findsNothing);
        // Chaque carte est decrite, avec un exemple.
        expect(_texte(c.explication), findsNWidgets(3));
        expect(_texte(t.choix.exemple(texte: c.exemple1)), findsOneWidget);
        expect(_texte(t.choix.exemple(texte: c.exemple2)), findsOneWidget);
        // Sans choix, on le dit.
        await continuer(tester);
        expect(_texte(t.recrutement.parcours.choisir), findsOneWidget);
        await toucherCle(tester, 'option-classesSouhaitees-2');
        await continuer(tester);
        expect(
          _texte(t.recrutement.parcours.q.debutPossible.titre),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'des adultes : une Classe, c est trois seances d une heure et demie',
      (WidgetTester tester) async {
        final FauxMaCandidature port = FauxMaCandidature(
          questionnaireJson: questionnaireJsonDeTest(
            dernieresReponses: <String, Object?>{
              ...reponsesCompletesDeTest(),
              'publics': <String>['adultes'],
            },
          ),
        );
        await monterQuestionnaire(tester, port: port);
        await toucherCle(tester, 'recap-classesSouhaitees');
        expect(
          find.textContaining(
            'Soit ${libelleDuree(270)} par semaine avec des adultes.',
          ),
          findsOneWidget,
        );
        expect(
          find.textContaining(
            'Soit ${libelleDuree(810)} par semaine avec des adultes.',
          ),
          findsOneWidget,
        );
        expect(find.textContaining('avec des enfants'), findsNothing);
      },
    );

    testWidgets('les deux publics : les deux durees', (
      WidgetTester tester,
    ) async {
      final FauxMaCandidature port = FauxMaCandidature(
        questionnaireJson: questionnaireJsonDeTest(
          dernieresReponses: <String, Object?>{
            ...reponsesCompletesDeTest(),
            'publics': <String>['10_13', 'adultes'],
          },
        ),
      );
      await monterQuestionnaire(tester, port: port);
      await toucherCle(tester, 'recap-classesSouhaitees');
      expect(
        find.textContaining(
          'Soit ${libelleDuree(360)} par semaine avec des enfants, '
          'ou ${libelleDuree(540)} avec des adultes.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('le maximum de la direction borne les cartes', (
      WidgetTester tester,
    ) async {
      for (final int max in <int>[1, 5]) {
        final FauxMaCandidature port = FauxMaCandidature(
          questionnaireJson: questionnaireJsonDeTest(
            classesMax: max,
            dernieresReponses: reponsesCompletesDeTest(),
          ),
        );
        await monterQuestionnaire(tester, port: port);
        await toucherCle(tester, 'recap-classesSouhaitees');
        for (int n = 1; n <= 6; n++) {
          expect(carte('$n'), n <= max ? findsOneWidget : findsNothing);
        }
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });
  });

  group('les moyens de versement du pays', () {
    testWidgets('Guinee : les operateurs confirmes, par leur nom', (
      WidgetTester tester,
    ) async {
      final FauxMaCandidature port = FauxMaCandidature();
      await monterQuestionnaire(tester, port: port);
      await repondreAvant(tester, 'operateurs');
      expect(_texte(t.recrutement.parcours.q.operateurs.titre), findsOneWidget);
      expect(_texte('Orange Money'), findsOneWidget);
      expect(_texte('Wave'), findsOneWidget);
      expect(port.moyensLus, contains('GN'));
      // Facultatif : sans choix, on continue.
      await continuer(tester);
      expect(
        _texte(t.recrutement.parcours.q.moyensAccessibles.titre),
        findsOneWidget,
      );
    });

    testWidgets(
      'Arabie saoudite : le virement seul, une phrase, jamais une liste vide',
      (WidgetTester tester) async {
        final FauxMaCandidature port = FauxMaCandidature();
        await monterQuestionnaire(tester, port: port);
        await passerLaPresentation(tester);
        for (final (String nom, List<String> touches) in parcoursComplet) {
          if (nom == 'paysResidence') {
            await toucherCle(tester, 'option-paysResidence-SA');
          } else if (nom == 'compteBancaire') {
            await toucherCle(tester, 'option-compteBancaire-oui');
          } else if (nom == 'operateurs') {
            break;
          } else {
            for (final String cle in touches) {
              await toucherCle(tester, cle);
            }
          }
          await continuer(tester);
        }
        expect(
          _texte(t.recrutement.parcours.versement.virementSeul),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey<String>('option-operateurs-wave')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'un pays sans moyen confirme : la phrase, la candidature reste possible',
      (WidgetTester tester) async {
        await monterQuestionnaire(tester, port: FauxMaCandidature());
        await passerLaPresentation(tester);
        for (final (String nom, List<String> touches) in parcoursComplet) {
          if (nom == 'paysResidence') {
            await toucherCle(tester, 'option-paysResidence-ML');
          } else if (nom == 'operateurs') {
            break;
          } else {
            for (final String cle in touches) {
              await toucherCle(tester, cle);
            }
          }
          await continuer(tester);
        }
        expect(
          _texte(t.recrutement.parcours.versement.aucunMoyen),
          findsOneWidget,
        );
        await continuer(tester);
        expect(
          _texte(t.recrutement.parcours.q.moyensAccessibles.titre),
          findsOneWidget,
        );
        await continuer(tester);
        expect(_texte(t.recrutement.parcours.recap.titre), findsOneWidget);
      },
    );

    testWidgets(
      'changer de pays de versement vide les operateurs deja choisis',
      (WidgetTester tester) async {
        final FauxMaCandidature port = FauxMaCandidature();
        await monterQuestionnaire(tester, port: port);
        await repondreJusqua(tester, parcoursComplet.length);
        expect(
          find.byKey(CartesRecapitulatif.ligneKey('operateurs')),
          findsOneWidget,
        );
        await toucherCle(tester, 'recap-paysVersement');
        await toucherCle(tester, 'option-paysVersement-SA');
        await continuer(tester);
        expect(
          find.byKey(CartesRecapitulatif.ligneKey('operateurs')),
          findsOneWidget,
        );
        expect(find.textContaining('Orange Money'), findsNothing);
      },
    );

    testWidgets(
      'les moyens de paiement connus : facultatif, informatif, n elimine '
      'personne',
      (WidgetTester tester) async {
        await monterQuestionnaire(tester, port: FauxMaCandidature());
        await repondreAvant(tester, 'moyensAccessibles');
        final m = t.recrutement.parcours.moyens;
        expect(
          _texte(t.recrutement.parcours.q.moyensAccessibles.titre),
          findsOneWidget,
        );
        // Facultatif, et la phrase dit qu'elle n'elimine personne.
        expect(_texte(m.nonElimine), findsOneWidget);
        expect(m.nonElimine, contains('facultative'));
        expect(m.nonElimine, contains('n\'élimine personne'));
        // Tous les moyens connus, par leur nom propre ; jamais un code.
        for (final String nom in <String>['Wave', 'Orange Money', 'Moov Money']) {
          expect(_texte(nom), findsOneWidget, reason: nom);
        }
        expect(find.text('moov_money'), findsNothing);
        expect(_texte(m.mobile), findsNWidgets(3));
        verifierUnSeulBoutonPlein(tester);
        // Sans aucun choix, on continue : rien ne bloque.
        await continuer(tester);
        expect(_texte(t.recrutement.parcours.recap.titre), findsOneWidget);
        // Le recapitulatif le dit : « Aucune ».
        expect(
          find.descendant(
            of: find.byKey(CartesRecapitulatif.ligneKey('moyensAccessibles')),
            matching: _texte(t.recrutement.parcours.aucune),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('un moyen choisi est envoye et relu au recapitulatif', (
      WidgetTester tester,
    ) async {
      await monterQuestionnaire(tester, port: FauxMaCandidature());
      await repondreJusqua(tester, parcoursComplet.length);
      expect(
        find.descendant(
          of: find.byKey(CartesRecapitulatif.ligneKey('moyensAccessibles')),
          matching: _texte('Wave'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('sans moyen connu au catalogue, la question n est pas posee', (
      WidgetTester tester,
    ) async {
      final FauxMaCandidature port = FauxMaCandidature(
        questionnaireJson: questionnaireJsonDeTest(moyensConnus: false),
      );
      await monterQuestionnaire(tester, port: port);
      await repondreAvant(tester, 'moyensAccessibles');
      expect(_texte(t.recrutement.parcours.recap.titre), findsOneWidget);
      expect(
        _texte(t.recrutement.parcours.q.moyensAccessibles.titre),
        findsNothing,
      );
    });
  });
}
