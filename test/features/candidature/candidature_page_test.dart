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
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/candidature/choix_avec_recherche.dart';
import 'package:rewayah_academy/features/candidature/coquille_parcours.dart';
import 'package:rewayah_academy/features/candidature/fuseau_etape.dart';
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

Finder _texte(String t) => find.text(t);

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
      'contenu : la presentation, « 1 sur 20 », un seul bouton plein',
      (WidgetTester tester) async {
        await monterQuestionnaire(tester, port: FauxMaCandidature());
        expect(
          _texte(t.recrutement.parcours.presentation.p1.titre),
          findsOneWidget,
        );
        expect(_texte(t.commun.etape.sur(n: 1, total: 20)), findsOneWidget);
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
      expect(_texte(t.commun.etape.sur(n: 20, total: 20)), findsOneWidget);
      verifierUnSeulBoutonPlein(tester);
    });

    testWidgets('« Continuer » sans reponse dit quoi faire, et n avance pas', (
      WidgetTester tester,
    ) async {
      await monterQuestionnaire(tester, port: FauxMaCandidature());
      await passerLaPresentation(tester);
      await continuer(tester);
      expect(_texte(t.recrutement.parcours.choisir), findsOneWidget);
      expect(
        _texte(t.recrutement.parcours.q.langueMaternelle.titre),
        findsOneWidget,
      );
      // Une reponse efface l'indication, et le bouton avance.
      await toucherCle(tester, 'option-langueMaternelle-poular');
      expect(_texte(t.recrutement.parcours.choisir), findsNothing);
      await continuer(tester);
      expect(
        _texte(t.recrutement.parcours.q.languesExplication.titre),
        findsOneWidget,
      );
    });

    testWidgets('un choix multiple vide dit « au moins une reponse »', (
      WidgetTester tester,
    ) async {
      await monterQuestionnaire(tester, port: FauxMaCandidature());
      await repondreJusqua(tester, 1);
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

    testWidgets('chaque choix est decrit : description, explication, exemple', (
      WidgetTester tester,
    ) async {
      await monterQuestionnaire(tester, port: FauxMaCandidature());
      await repondreJusqua(tester, 9);
      // Heures par semaine : ce que cela fait en classes, avec un exemple.
      final o = t.recrutement.parcours.q.heuresParSemaine;
      expect(_texte(o.explication), findsOneWidget);
      expect(_texte(o.options.de_3_a_5.libelle), findsOneWidget);
      expect(_texte(o.options.de_3_a_5.description), findsOneWidget);
      expect(
        _texte(t.choix.exemple(texte: o.options.de_3_a_5.exemple)),
        findsOneWidget,
      );
    });

    testWidgets('l ijaza se montre pendant l entretien, et le dit', (
      WidgetTester tester,
    ) async {
      await monterQuestionnaire(tester, port: FauxMaCandidature());
      await repondreJusqua(tester, 5);
      final o = t.recrutement.parcours.q.ijazaPresentable.options.oui;
      expect(_texte(o.explication), findsOneWidget);
      expect(find.textContaining('entretien'), findsWidgets);
    });

    testWidgets('le compte bancaire dit ce que cela change pour le versement', (
      WidgetTester tester,
    ) async {
      await monterQuestionnaire(tester, port: FauxMaCandidature());
      await repondreJusqua(tester, 14);
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

  group('langues, pays : des cartes, puis une recherche', () {
    testWidgets(
      'la langue maternelle : trois cartes, les autres par « Une autre langue »',
      (WidgetTester tester) async {
        await monterQuestionnaire(tester, port: FauxMaCandidature());
        await passerLaPresentation(tester);
        final l = t.recrutement.parcours.langues;
        expect(_texte(l.poular), findsOneWidget);
        expect(_texte(l.francais), findsOneWidget);
        expect(_texte(l.english), findsOneWidget);
        // Une langue hors referentiel n'est pas une carte.
        expect(_texte(l.wo), findsNothing);
        // Dire quelles langues Rewayah enseigne n'a pas de sens ici.
        expect(_texte(l.dansReferentiel), findsNothing);
        await toucherCle(tester, 'choix-recherche-autre');
        await tester.enterText(find.byKey(ChoixAvecRecherche.champKey), 'wolo');
        await tester.pumpAndSettle();
        expect(find.byKey(ChoixAvecRecherche.ligneKey('wo')), findsOneWidget);
        expect(find.byKey(ChoixAvecRecherche.ligneKey('poular')), findsNothing);
        expect(_texte(l.horsReferentiel), findsNothing);
        await tester.tap(find.byKey(ChoixAvecRecherche.ligneKey('wo')));
        await tester.pumpAndSettle();
        // Elle devient une carte retenue.
        expect(_texte(l.wo), findsOneWidget);
        await continuer(tester);
        expect(
          _texte(t.recrutement.parcours.q.languesExplication.titre),
          findsOneWidget,
        );
        await toucherCle(tester, 'parcours-retour');
        expect(_texte(l.wo), findsOneWidget);
      },
    );

    testWidgets(
      'les langues d explication disent lesquelles Rewayah enseigne',
      (WidgetTester tester) async {
        await monterQuestionnaire(tester, port: FauxMaCandidature());
        await repondreJusqua(tester, 1);
        final l = t.recrutement.parcours.langues;
        expect(_texte(l.dansReferentiel), findsNWidgets(3));
        await toucherCle(tester, 'choix-recherche-autre');
        await tester.enterText(find.byKey(ChoixAvecRecherche.champKey), 'wolo');
        await tester.pumpAndSettle();
        expect(_texte(l.horsReferentiel), findsOneWidget);
        await tester.tap(find.byKey(ChoixAvecRecherche.ligneKey('wo')));
        await tester.pumpAndSettle();
        await continuer(tester);
        expect(
          _texte(t.recrutement.parcours.q.niveauMemorisationDeclare.titre),
          findsOneWidget,
        );
      },
    );

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
        await repondreJusqua(tester, 12);
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
      await repondreJusqua(tester, 7);
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
      expect(
        _texte(t.recrutement.parcours.q.disponibilitesDeclarees.titre),
        findsOneWidget,
      );
      expect(
        _texte(t.recrutement.parcours.creneaux.fuseauRappel(lieu: 'Paris')),
        findsOneWidget,
      );
    });

    testWidgets(
      '« Changer » ouvre la liste des villes, la recherche en trouve d autres',
      (WidgetTester tester) async {
        await monterQuestionnaire(tester, port: FauxMaCandidature());
        await repondreJusqua(tester, 7);
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
        await repondreJusqua(tester, 7);
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
      await repondreJusqua(tester, 7);
      expect(find.byKey(FuseauEtape.carteKey), findsNothing);
    });
  });

  group('la grille des disponibilites', () {
    testWidgets('un geste sur une cellule la retient, un second la retire', (
      WidgetTester tester,
    ) async {
      await monterQuestionnaire(tester, port: FauxMaCandidature());
      await repondreJusqua(tester, 8);
      expect(
        _texte(t.recrutement.parcours.creneaux.choisies(n: 0)),
        findsOneWidget,
      );
      await toucherCle(tester, 'creneau-2-3');
      expect(
        _texte(t.recrutement.parcours.creneaux.choisies(n: 1)),
        findsOneWidget,
      );
      await toucherCle(tester, 'creneau-2-4');
      expect(
        _texte(t.recrutement.parcours.creneaux.choisies(n: 2)),
        findsOneWidget,
      );
      await toucherCle(tester, 'creneau-2-3');
      expect(
        _texte(t.recrutement.parcours.creneaux.choisies(n: 1)),
        findsOneWidget,
      );
    });

    testWidgets('sans plage, « Continuer » demande d en choisir une', (
      WidgetTester tester,
    ) async {
      await monterQuestionnaire(tester, port: FauxMaCandidature());
      await repondreJusqua(tester, 8);
      await continuer(tester);
      expect(_texte(t.recrutement.parcours.choisirPlage), findsOneWidget);
    });

    testWidgets(
      'chaque cellule dit son jour, sa plage et son etat au lecteur d ecran',
      (WidgetTester tester) async {
        await monterQuestionnaire(tester, port: FauxMaCandidature());
        await repondreJusqua(tester, 8);
        await toucherCle(tester, 'creneau-1-4');
        final SemanticsHandle poignee = tester.ensureSemantics();
        final String attendu =
            '${t.recrutement.parcours.creneaux.jourCellule(jour: 'Lundi', plage: t.recrutement.parcours.creneaux.plage4)}, '
            '16:00 - 20:00, ${t.recrutement.parcours.creneaux.choisie}';
        final String lu = tester
            .getSemantics(find.byKey(const ValueKey<String>('creneau-1-4')))
            .label
            .replaceAll('\u2068', '')
            .replaceAll('\u2069', '');
        expect(lu, contains(attendu));
        poignee.dispose();
      },
    );

    testWidgets('a 1440 la grille est un tableau, a 390 des blocs par jour', (
      WidgetTester tester,
    ) async {
      await monterQuestionnaire(
        tester,
        port: FauxMaCandidature(),
        taille: const Size(1440, 900),
      );
      await repondreJusqua(tester, 8);
      final Rect a = tester.getRect(
        find.byKey(const ValueKey<String>('creneau-1-0')),
      );
      final Rect b = tester.getRect(
        find.byKey(const ValueKey<String>('creneau-1-5')),
      );
      // Tout une ligne : les six plages d'un jour sont cote a cote.
      expect(b.top, closeTo(a.top, 1));
      expect(b.left, greaterThan(a.right));
      expect(a.height, greaterThanOrEqualTo(48));
    });
  });

  group('les moyens de versement du pays', () {
    testWidgets('Guinee : les operateurs confirmes, par leur nom', (
      WidgetTester tester,
    ) async {
      final FauxMaCandidature port = FauxMaCandidature();
      await monterQuestionnaire(tester, port: port);
      await repondreJusqua(tester, 15);
      expect(_texte(t.recrutement.parcours.q.operateurs.titre), findsOneWidget);
      expect(_texte('Orange Money'), findsOneWidget);
      expect(_texte('Wave'), findsOneWidget);
      expect(port.moyensLus, contains('GN'));
      // Facultatif : sans choix, on continue.
      await continuer(tester);
      expect(_texte(t.recrutement.parcours.recap.titre), findsOneWidget);
    });

    testWidgets(
      'Arabie saoudite : le virement seul, une phrase, jamais une liste vide',
      (WidgetTester tester) async {
        final FauxMaCandidature port = FauxMaCandidature();
        await monterQuestionnaire(tester, port: port);
        await passerLaPresentation(tester);
        final List<(String, List<String>)> reponses = <(String, List<String>)>[
          ...parcoursComplet.take(12),
          ('paysResidence', <String>['option-paysResidence-SA']),
          ('paysVersement', <String>[]),
          ('compteBancaire', <String>['option-compteBancaire-oui']),
        ];
        for (final (String _, List<String> touches) in reponses) {
          for (final String cle in touches) {
            await toucherCle(tester, cle);
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
        final List<(String, List<String>)> reponses = <(String, List<String>)>[
          ...parcoursComplet.take(12),
          ('paysResidence', <String>['option-paysResidence-ML']),
          ('paysVersement', <String>[]),
          ('compteBancaire', <String>['option-compteBancaire-non']),
        ];
        for (final (String _, List<String> touches) in reponses) {
          for (final String cle in touches) {
            await toucherCle(tester, cle);
          }
          await continuer(tester);
        }
        expect(
          _texte(t.recrutement.parcours.versement.aucunMoyen),
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
  });
}
