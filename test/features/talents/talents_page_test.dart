// CAND-07 : la page « Vos autres talents » (`/attente/talents`), chaque etat et
// chaque geste, sur le double du port :
// - les etats : chargement, contenu, erreur (« Reessayer »), hors ligne,
//   capacite indisponible, pas encore ouvert, termine, aucune candidature ;
// - le parcours : introduction, competences par famille, niveaux, disponibilite
//   et accord, ce qui manque pour continuer (K-59), le choix qui revient quand on
//   recule, un seul bouton plein a chaque etape ;
// - l'enregistrement : ce qui part au serveur (version attendue, cle), le succes
//   dit apres la reponse, le conflit, la competence desactivee, la reponse a
//   revoir, l'issue incertaine rejouee avec la meme cle ;
// - la lecture : les reponses, « Modifier », « Retirer » avec confirmation,
//   candidature terminee (lire et retirer, plus modifier), hors ligne.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/modeles_autres_competences.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/port_autres_competences.dart';
import 'package:rewayah_academy/core/candidature/port_ma_candidature.dart'
    show HorsLigneCandidature;
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/permission_insuffisante.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/candidature/coquille_parcours.dart';
import 'package:rewayah_academy/features/candidature/lecture_page.dart';
import 'package:rewayah_academy/features/talents/etape_competences.dart';
import 'package:rewayah_academy/features/talents/etape_disponibilite.dart';
import 'package:rewayah_academy/features/talents/lecture_talents.dart';
import 'package:rewayah_academy/features/talents/parcours_talents.dart';
import 'package:rewayah_academy/features/talents/talents_page.dart';

import '../../fixtures/candidature/faux_autres_competences.dart';
import '../../support/garde_interface.dart';
import 'hote_talents.dart';

Finder _texte(String t) => find.text(t);

/// Les reponses d'un candidat qui a deja repondu : deux competences.
Map<String, dynamic> _lectureAvecReponses({
  int version = 2,
  bool ouvert = true,
  String? raison,
  Map<String, Object?>? reponses,
}) => autresCompetencesJsonDeTest(
  ouvert: ouvert,
  raison: raison,
  version: version,
  reponses:
      reponses ??
      reponsesJsonDeTest(
        domaines: const <String, String>{
          'comptabilite': 'metier',
          'reseaux_sociaux': 'experience',
        },
        disponibilite: 'mi_temps',
      ),
);

/// Choisit une competence, un niveau chacune, une disponibilite, puis arrive
/// sur le dernier ecran.
Future<void> _jusquALaDisponibilite(
  WidgetTester tester, {
  List<String> codes = const <String>['comptabilite'],
  NiveauCompetence niveau = NiveauCompetence.metier,
}) async {
  await passerLIntroduction(tester);
  for (final String code in codes) {
    await toucherTalents(tester, 'talent-$code');
  }
  await continuerTalents(tester);
  for (final String code in codes) {
    await tester.ensureVisible(cleTalents('talents-niveau-$code'));
    await tester.pump();
    await tester.tap(
      find.descendant(
        of: cleTalents('talents-niveau-$code'),
        matching: _texte(_libelleNiveau(niveau)),
      ),
    );
    await tester.pumpAndSettle();
  }
  await continuerTalents(tester);
}

String _libelleNiveau(NiveauCompetence n) => switch (n) {
  NiveauCompetence.debutant => t.recrutement.talents.niveaux.debutant.libelle,
  NiveauCompetence.experience =>
    t.recrutement.talents.niveaux.experience.libelle,
  NiveauCompetence.metier => t.recrutement.talents.niveaux.metier.libelle,
};

void main() {
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('les etats de la page', () {
    testWidgets('chargement : un squelette, rien d invente', (
      WidgetTester tester,
    ) async {
      final Completer<void> attente = Completer<void>();
      await monterTalents(
        tester,
        port: FauxAutresCompetences()..attente = attente,
        attendre: false,
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(Skeleton), findsWidgets);
      expect(_texte(t.recrutement.talents.intro.texte), findsNothing);
      attente.complete();
      await tester.pumpAndSettle();
      expect(_texte(t.recrutement.talents.intro.texte), findsOneWidget);
    });

    testWidgets('le bouton plein ne parait jamais desactive, a aucune etape '
        '(demande du directeur du 22/10)', (WidgetTester tester) async {
      await monterTalents(tester, port: FauxAutresCompetences());
      final AppPalette palette = AppPalette.of(
        tester.element(find.byKey(CoquilleParcours.actionKey)),
      );
      void verifier() {
        final Finder action = find.byKey(CoquilleParcours.actionKey);
        final ActionPrincipale bouton = tester.widget<ActionPrincipale>(action);
        expect(bouton.onPress, isNotNull);
        expect(bouton.affirmee, isTrue);
        final List<Color?> fonds = <Color?>[
          for (final DecoratedBox boite in tester.widgetList<DecoratedBox>(
            find.descendant(of: action, matching: find.byType(DecoratedBox)),
          ))
            if (boite.decoration is BoxDecoration)
              (boite.decoration as BoxDecoration).color,
        ];
        expect(fonds, contains(palette.surfacePrimary.background));
        expect(fonds, isNot(contains(palette.surfaceActionDouce.background)));
      }

      // L'introduction, les competences (avant tout choix), les niveaux, puis
      // la derniere etape, « Enregistrer mes reponses ».
      verifier();
      await passerLIntroduction(tester);
      verifier();
      await toucherTalents(tester, 'talent-comptabilite');
      await continuerTalents(tester);
      verifier();
      await tester.ensureVisible(cleTalents('talents-niveau-comptabilite'));
      await tester.pump();
      await tester.tap(
        find.descendant(
          of: cleTalents('talents-niveau-comptabilite'),
          matching: _texte(_libelleNiveau(NiveauCompetence.metier)),
        ),
      );
      await tester.pumpAndSettle();
      await continuerTalents(tester);
      verifier();
      expect(
        tester
            .widget<ActionPrincipale>(find.byKey(CoquilleParcours.actionKey))
            .libelle,
        t.recrutement.talents.disponibilite.enregistrer,
      );
    });

    testWidgets('contenu : le titre, l introduction, un seul bouton plein', (
      WidgetTester tester,
    ) async {
      await monterTalents(tester, port: FauxAutresCompetences());
      expect(_texte(t.recrutement.talents.titre), findsOneWidget);
      expect(_texte(t.recrutement.talents.intro.texte), findsOneWidget);
      expect(
        _texte(t.recrutement.talents.intro.facultatif.titre),
        findsOneWidget,
      );
      expect(_texte(t.recrutement.talents.intro.usage.titre), findsOneWidget);
      expect(_texte(t.commun.continuer), findsOneWidget);
      verifierUnSeulBoutonPlein(tester);
    });

    testWidgets('erreur : la phrase et « Reessayer », qui relit', (
      WidgetTester tester,
    ) async {
      final FauxAutresCompetences port = FauxAutresCompetences()
        ..erreurLecture = Exception('panne');
      await monterTalents(tester, port: port);
      expect(_texte(t.recrutement.talents.etats.nonCharge), findsOneWidget);
      expect(_texte(t.commun.reessayer), findsOneWidget);
      expect(_texte(t.recrutement.talents.intro.texte), findsNothing);
      await tester.tap(_texte(t.commun.reessayer));
      await tester.pumpAndSettle();
      expect(_texte(t.recrutement.talents.intro.texte), findsOneWidget);
      expect(port.lectures, 2);
    });

    testWidgets('capacite indisponible : « pas encore ouverte », sans '
        '« Reessayer »', (WidgetTester tester) async {
      await monterTalents(tester, port: null);
      expect(find.byKey(EtapeNonOuverte.blocKey), findsOneWidget);
      expect(_texte(t.commun.reessayer), findsNothing);
      // Le code du lot ne s'affiche jamais.
      expect(find.textContaining('CAND-BR'), findsNothing);
    });

    testWidgets('hors ligne : le bandeau le dit une fois, la page ne le redit '
        'pas', (WidgetTester tester) async {
      await monterTalents(
        tester,
        port: FauxAutresCompetences()
          ..erreurLectureDurable = const CapaciteIndisponible('x'),
        horsLigne: true,
      );
      expect(find.textContaining('hors ligne'), findsNothing);
      expect(find.textContaining('Pas de réseau'), findsOneWidget);
    });

    testWidgets('pas encore ouvert : la candidature n est pas envoyee', (
      WidgetTester tester,
    ) async {
      await monterTalents(
        tester,
        port: FauxAutresCompetences(
          lectureJson: autresCompetencesJsonDeTest(
            ouvert: false,
            raison: 'questionnaire_non_envoye',
          ),
        ),
      );
      expect(find.byKey(TalentsPage.nonEnvoyeKey), findsOneWidget);
      expect(
        _texte(t.recrutement.talents.etats.nonEnvoyeTitre),
        findsOneWidget,
      );
      expect(_texte(t.recrutement.talents.etats.nonEnvoye), findsOneWidget);
      expect(_texte(t.recrutement.talents.intro.texte), findsNothing);
      verifierUnSeulBoutonPlein(tester);
    });

    testWidgets('termine, sans reponse : rien a ajouter, retour au dossier', (
      WidgetTester tester,
    ) async {
      await monterTalents(
        tester,
        port: FauxAutresCompetences(
          lectureJson: autresCompetencesJsonDeTest(
            ouvert: false,
            raison: 'candidature_close',
          ),
        ),
      );
      expect(find.byKey(TalentsPage.closKey), findsOneWidget);
      expect(_texte(t.recrutement.talents.etats.clos), findsOneWidget);
      await tester.tap(_texte(t.recrutement.questionnaire.retourDossier));
      await tester.pumpAndSettle();
      expect(find.byKey(TalentsPage.closKey), findsNothing);
      expect(_texte(t.attente.titreDossier), findsOneWidget);
    });

    testWidgets('aucune candidature pour ce compte : retour au portail', (
      WidgetTester tester,
    ) async {
      await monterTalents(
        tester,
        port: FauxAutresCompetences(),
        etat: etatEnvoye(candidature: const CandidatureDossier()),
      );
      expect(find.byKey(TalentsPage.lectureKey), findsNothing);
      expect(_texte(t.recrutement.talents.intro.texte), findsNothing);
      expect(_texte(t.attente.titreDossier), findsOneWidget);
    });

    testWidgets('un compte que le serveur ne reconnait pas : retour au '
        'portail, sans phrase d erreur', (WidgetTester tester) async {
      await monterTalents(
        tester,
        port: FauxAutresCompetences()
          ..erreurLectureDurable = const PermissionInsuffisante('x'),
      );
      expect(_texte(t.recrutement.talents.etats.nonCharge), findsNothing);
      expect(_texte(t.attente.titreDossier), findsOneWidget);
    });
  });

  group('le parcours', () {
    testWidgets('introduction, puis les competences : cinq familles, des '
        'cartes decrites, une seule phrase « plusieurs reponses »', (
      WidgetTester tester,
    ) async {
      await monterTalents(tester, port: FauxAutresCompetences());
      await passerLIntroduction(tester);
      expect(_texte(t.recrutement.talents.competences.titre), findsOneWidget);
      expect(find.byKey(EtapeCompetences.plusieursKey), findsOneWidget);
      expect(_texte(t.choix.selectionMultiple), findsOneWidget);
      // Chaque competence du catalogue a sa carte (24 + « Autre domaine »).
      for (final (String, String, int, String, String) c
          in catalogueInitialDeTest) {
        expect(
          find.byKey(EtapeCompetences.carteKey(c.$1), skipOffstage: false),
          findsOneWidget,
          reason: c.$1,
        );
      }
      // Les cinq familles et leur titre ; « Autre domaine » n'a pas de titre de
      // famille (sa carte porte deja ce nom).
      final f = t.recrutement.talents.competences.familles;
      for (final String titre in <String>[
        f.communication,
        f.administration,
        f.financesDroit,
        f.pedagogie,
        f.technique,
      ]) {
        expect(find.text(titre, skipOffstage: false), findsOneWidget);
      }
      expect(find.text(f.autre, skipOffstage: false), findsOneWidget);
      verifierUnSeulBoutonPlein(tester);
    });

    testWidgets('aucune competence : on ne continue pas, la phrase dit quoi '
        'faire', (WidgetTester tester) async {
      await monterTalents(tester, port: FauxAutresCompetences());
      await passerLIntroduction(tester);
      await continuerTalents(tester);
      expect(
        find.descendant(
          of: find.byKey(ParcoursTalents.messageKey),
          matching: _texte(t.recrutement.talents.competences.manque),
        ),
        findsOneWidget,
      );
      expect(_texte(t.recrutement.talents.competences.titre), findsOneWidget);
      // Choisir une competence efface le message.
      await toucherTalents(tester, 'talent-comptabilite');
      expect(find.byKey(ParcoursTalents.messageKey), findsNothing);
    });

    testWidgets('le compteur dit combien de competences sont choisies', (
      WidgetTester tester,
    ) async {
      await monterTalents(tester, port: FauxAutresCompetences());
      await passerLIntroduction(tester);
      expect(
        find.descendant(
          of: find.byKey(ParcoursTalents.compteurKey),
          matching: _texte(t.recrutement.talents.competences.choisies(n: 0)),
        ),
        findsOneWidget,
      );
      await toucherTalents(tester, 'talent-comptabilite');
      await toucherTalents(tester, 'talent-reseaux_sociaux');
      expect(
        _texte(t.recrutement.talents.competences.choisies(n: 2)),
        findsOneWidget,
      );
      await toucherTalents(tester, 'talent-comptabilite');
      expect(
        _texte(t.recrutement.talents.competences.choisies(n: 1)),
        findsOneWidget,
      );
    });

    testWidgets(
      '« Autre domaine » : le seul champ au clavier, exige, nettoye',
      (WidgetTester tester) async {
        final FauxAutresCompetences port = FauxAutresCompetences();
        await monterTalents(tester, port: port);
        await passerLIntroduction(tester);
        expect(find.byKey(EtapeCompetences.autreChampKey), findsNothing);
        // Aucun autre champ de texte sur l'ecran.
        expect(find.byType(TextField), findsNothing);
        await toucherTalents(tester, 'talent-autre');
        expect(find.byKey(EtapeCompetences.autreChampKey), findsOneWidget);
        expect(find.byType(TextField), findsOneWidget);
        await continuerTalents(tester);
        expect(
          _texte(t.recrutement.talents.competences.autreVide),
          findsOneWidget,
        );
        await tester.enterText(
          find.byType(TextField),
          '  Secrétariat médical  ',
        );
        await tester.pump();
        expect(
          _texte(t.recrutement.talents.competences.autreVide),
          findsNothing,
        );
        await continuerTalents(tester);
        // Un niveau pour « Autre domaine », une disponibilite, l'envoi.
        await tester.tap(
          find.descendant(
            of: cleTalents('talents-niveau-autre'),
            matching: _texte(_libelleNiveau(NiveauCompetence.experience)),
          ),
        );
        await tester.pumpAndSettle();
        await continuerTalents(tester);
        await toucherTalents(tester, 'talents-dispo-mi_temps');
        await continuerTalents(tester);
        expect(port.enregistrements, hasLength(1));
        expect(port.enregistrements.single.autreTexte, 'Secrétariat médical');
        expect(port.enregistrements.single.domaines, <String, NiveauCompetence>{
          'autre': NiveauCompetence.experience,
        });
      },
    );

    testWidgets('un texte trop long est refuse avant l envoi, avec la borne', (
      WidgetTester tester,
    ) async {
      final FauxAutresCompetences port = FauxAutresCompetences();
      await monterTalents(tester, port: port);
      await passerLIntroduction(tester);
      await toucherTalents(tester, 'talent-autre');
      await tester.enterText(find.byType(TextField), 'a' * 201);
      await tester.pump();
      await continuerTalents(tester);
      expect(
        _texte(t.recrutement.talents.competences.autreTropLong(max: 200)),
        findsOneWidget,
      );
      expect(port.enregistrements, isEmpty);
    });

    testWidgets('un niveau manque : la phrase nomme la competence', (
      WidgetTester tester,
    ) async {
      await monterTalents(tester, port: FauxAutresCompetences());
      await passerLIntroduction(tester);
      await toucherTalents(tester, 'talent-comptabilite');
      await continuerTalents(tester);
      expect(_texte(t.recrutement.talents.niveaux.legende), findsOneWidget);
      // Aucun niveau n'est presume : rien n'est choisi d'avance.
      await continuerTalents(tester);
      expect(
        _texte(
          t.recrutement.talents.niveaux.manque(competence: 'Comptabilité'),
        ),
        findsOneWidget,
      );
      expect(_texte(t.recrutement.talents.niveaux.titre), findsOneWidget);
      verifierUnSeulBoutonPlein(tester);
    });

    testWidgets('la disponibilite manque : on ne l envoie pas', (
      WidgetTester tester,
    ) async {
      final FauxAutresCompetences port = FauxAutresCompetences();
      await monterTalents(tester, port: port);
      await _jusquALaDisponibilite(tester);
      await continuerTalents(tester);
      expect(
        _texte(t.recrutement.talents.disponibilite.manque),
        findsOneWidget,
      );
      expect(port.enregistrements, isEmpty);
    });

    testWidgets('« Retour » garde les choix ; a la premiere etape, il sort', (
      WidgetTester tester,
    ) async {
      await monterTalents(tester, port: FauxAutresCompetences());
      await passerLIntroduction(tester);
      await toucherTalents(tester, 'talent-comptabilite');
      await continuerTalents(tester);
      await tester.tap(
        find.descendant(
          of: cleTalents('talents-niveau-comptabilite'),
          matching: _texte(_libelleNiveau(NiveauCompetence.metier)),
        ),
      );
      await tester.pumpAndSettle();
      await toucherTalents(tester, 'parcours-retour');
      // La competence reste choisie (le compteur le dit).
      expect(
        _texte(t.recrutement.talents.competences.choisies(n: 1)),
        findsOneWidget,
      );
      await continuerTalents(tester);
      // Le niveau choisi reste.
      expect(
        _texte(
          t.recrutement.talents.niveaux.manque(competence: 'Comptabilité'),
        ),
        findsNothing,
      );
      await continuerTalents(tester);
      expect(_texte(t.recrutement.talents.disponibilite.titre), findsOneWidget);
      await toucherTalents(tester, 'parcours-retour');
      await toucherTalents(tester, 'parcours-retour');
      await toucherTalents(tester, 'parcours-retour');
      expect(_texte(t.recrutement.talents.intro.texte), findsOneWidget);
      await toucherTalents(tester, 'parcours-retour');
      // La premiere etape sort du parcours, vers le portail.
      expect(_texte(t.attente.titreDossier), findsOneWidget);
    });

    testWidgets('un seul bouton plein a chaque etape', (
      WidgetTester tester,
    ) async {
      await monterTalents(tester, port: FauxAutresCompetences());
      verifierUnSeulBoutonPlein(tester);
      await passerLIntroduction(tester);
      verifierUnSeulBoutonPlein(tester);
      await toucherTalents(tester, 'talent-comptabilite');
      await continuerTalents(tester);
      verifierUnSeulBoutonPlein(tester);
      await tester.tap(
        find.descendant(
          of: cleTalents('talents-niveau-comptabilite'),
          matching: _texte(_libelleNiveau(NiveauCompetence.metier)),
        ),
      );
      await tester.pumpAndSettle();
      await continuerTalents(tester);
      verifierUnSeulBoutonPlein(tester);
      expect(
        _texte(t.recrutement.talents.disponibilite.enregistrer),
        findsOneWidget,
      );
    });

    testWidgets('l accord est facultatif : sans la case, rien ne s efface et '
        'la phrase dit ce que cela change', (WidgetTester tester) async {
      final FauxAutresCompetences port = FauxAutresCompetences();
      await monterTalents(tester, port: port);
      await _jusquALaDisponibilite(tester);
      expect(find.byKey(EtapeDisponibilite.accordNoteKey), findsOneWidget);
      expect(
        _texte(t.recrutement.talents.disponibilite.accordNote),
        findsOneWidget,
      );
      await toucherTalents(tester, 'talents-dispo-pas_maintenant');
      await continuerTalents(tester);
      expect(port.enregistrements.single.accord, isFalse);
      expect(
        port.enregistrements.single.disponibilite,
        DisponibiliteMission.pasMaintenant,
      );
      expect(_texte(t.recrutement.talents.lecture.contactNon), findsOneWidget);
    });
  });

  group('l enregistrement', () {
    testWidgets('ce qui part : domaines, niveau, disponibilite, accord, '
        'version 0, une cle', (WidgetTester tester) async {
      final FauxAutresCompetences port = FauxAutresCompetences();
      await monterTalents(tester, port: port);
      await _jusquALaDisponibilite(
        tester,
        codes: <String>['comptabilite', 'reseaux_sociaux'],
        niveau: NiveauCompetence.experience,
      );
      await toucherTalents(tester, 'talents-dispo-quelques_heures');
      await toucherTalents(tester, 'talents-accord');
      await continuerTalents(tester);
      final EnregistrementTalents e = port.enregistrements.single;
      expect(e.domaines, <String, NiveauCompetence>{
        'comptabilite': NiveauCompetence.experience,
        'reseaux_sociaux': NiveauCompetence.experience,
      });
      expect(e.autreTexte, isNull);
      expect(e.disponibilite, DisponibiliteMission.quelquesHeures);
      expect(e.accord, isTrue);
      expect(e.versionAttendue, 0);
      expect(e.cleIdempotence.length, inInclusiveRange(8, 200));
    });

    testWidgets('le succes ne se dit qu apres la reponse : les reponses '
        'relues', (WidgetTester tester) async {
      final FauxAutresCompetences port = FauxAutresCompetences();
      port.attenteEnregistrement = Completer<void>();
      await monterTalents(tester, port: port);
      await _jusquALaDisponibilite(tester);
      await toucherTalents(tester, 'talents-dispo-mi_temps');
      await tester.tap(_texte(t.recrutement.talents.disponibilite.enregistrer));
      await tester.pump();
      // Pas de reponse encore : aucun succes.
      expect(_texte(t.recrutement.talents.lecture.enregistre), findsNothing);
      // Un second toucher n'envoie rien de plus.
      await tester.tap(cleTalents('parcours-action'), warnIfMissed: false);
      await tester.pump();
      expect(port.enregistrements, hasLength(1));
      port.attenteEnregistrement!.complete();
      await tester.pumpAndSettle();
      expect(_texte(t.recrutement.talents.lecture.enregistre), findsOneWidget);
      // L'ecran a relu : les reponses viennent du serveur.
      expect(port.lectures, 2);
      expect(_texte('Comptabilité'), findsOneWidget);
      expect(_texte(_libelleNiveau(NiveauCompetence.metier)), findsOneWidget);
    });

    testWidgets('conflit : l ecran relit, le dit, et montre ce qui est '
        'enregistre ailleurs', (WidgetTester tester) async {
      final FauxAutresCompetences port = FauxAutresCompetences();
      await monterTalents(tester, port: port);
      await _jusquALaDisponibilite(tester);
      await toucherTalents(tester, 'talents-dispo-mi_temps');
      // Entre-temps, un autre appareil a enregistre autre chose.
      port.lectureJson = _lectureAvecReponses(version: 3);
      port.erreurEnregistrement = const ConflitAutresCompetences(3);
      await continuerTalents(tester);
      expect(find.byKey(LectureTalents.messageKey), findsOneWidget);
      expect(_texte(t.recrutement.talents.erreurs.conflit), findsOneWidget);
      expect(_texte(t.recrutement.talents.lecture.enregistre), findsOneWidget);
      expect(_texte('Gestion des réseaux sociaux'), findsOneWidget);
    });

    testWidgets('une competence desactivee entre-temps : la liste est '
        'relue, le message dit quoi faire', (WidgetTester tester) async {
      final FauxAutresCompetences port = FauxAutresCompetences();
      await monterTalents(tester, port: port);
      await _jusquALaDisponibilite(tester);
      await toucherTalents(tester, 'talents-dispo-mi_temps');
      port.lectureJson = autresCompetencesJsonDeTest(
        desactivees: <String>{'comptabilite'},
      );
      port.erreurEnregistrement = const ReponsesAutresCompetencesInvalides(
        <String>['domaines'],
        motifs: <String, String>{'domaines': 'domaine_desactive'},
      );
      await continuerTalents(tester);
      expect(_texte(t.recrutement.talents.erreurs.desactivee), findsOneWidget);
      // La personne repart des competences, sans revoir l'introduction ; la
      // competence retiree du catalogue n'est plus proposee.
      expect(_texte(t.recrutement.talents.intro.texte), findsNothing);
      expect(_texte(t.recrutement.talents.competences.titre), findsOneWidget);
      expect(
        find.byKey(EtapeCompetences.carteKey('comptabilite')),
        findsNothing,
      );
    });

    testWidgets('une competence desactivee entre-temps : les autres choix sont '
        'gardes, rien n est a ressaisir', (WidgetTester tester) async {
      final FauxAutresCompetences port = FauxAutresCompetences();
      await monterTalents(tester, port: port);
      await _jusquALaDisponibilite(
        tester,
        codes: const <String>['comptabilite', 'reseaux_sociaux'],
        niveau: NiveauCompetence.experience,
      );
      await toucherTalents(tester, 'talents-dispo-mi_temps');
      // Entre-temps, la direction retire « Comptabilite » du catalogue : le
      // serveur refuse l'enregistrement (`domaine_desactive`) et la lecture ne
      // la propose plus.
      port.lectureJson = autresCompetencesJsonDeTest(
        desactivees: <String>{'comptabilite'},
      );
      port.erreurEnregistrement = const ReponsesAutresCompetencesInvalides(
        <String>['domaines'],
        motifs: <String, String>{'domaines': 'domaine_desactive'},
      );
      await continuerTalents(tester);
      expect(port.enregistrements, hasLength(1));
      // Le message dit ce qui s'est passe, et que le choix est deja corrige.
      expect(_texte(t.recrutement.talents.erreurs.desactivee), findsOneWidget);
      expect(
        find.byKey(EtapeCompetences.carteKey('comptabilite')),
        findsNothing,
      );
      // L'autre competence est toujours choisie, avec son niveau : l'etape
      // des niveaux n'a plus qu'une ligne, deja renseignee, et on la passe sans
      // rien ressaisir. La disponibilite est celle de tout a l'heure.
      await continuerTalents(tester);
      expect(cleTalents('talents-niveau-reseaux_sociaux'), findsOneWidget);
      expect(cleTalents('talents-niveau-comptabilite'), findsNothing);
      await continuerTalents(tester);
      final Finder dispo = cleTalents('talents-disponibilites');
      expect(dispo, findsOneWidget);
      await continuerTalents(tester);
      expect(port.enregistrements, hasLength(2));
      final EnregistrementTalents second = port.enregistrements[1];
      expect(second.domaines, <String, NiveauCompetence>{
        'reseaux_sociaux': NiveauCompetence.experience,
      });
      expect(second.disponibilite, DisponibiliteMission.miTemps);
      expect(
        second.cleIdempotence,
        isNot(port.enregistrements[0].cleIdempotence),
      );
    });

    testWidgets('une reponse a revoir : on reste sur l ecran, sans relire', (
      WidgetTester tester,
    ) async {
      final FauxAutresCompetences port = FauxAutresCompetences();
      await monterTalents(tester, port: port);
      await _jusquALaDisponibilite(tester);
      await toucherTalents(tester, 'talents-dispo-mi_temps');
      port.erreurEnregistrement = const ReponsesAutresCompetencesInvalides(
        <String>['disponibilite'],
        motifs: <String, String>{'disponibilite': 'disponibilite_inconnue'},
      );
      await continuerTalents(tester);
      expect(_texte(t.recrutement.talents.erreurs.invalides), findsOneWidget);
      expect(_texte(t.recrutement.talents.disponibilite.titre), findsOneWidget);
      expect(port.lectures, 1);
    });

    testWidgets('une issue incertaine se rejoue avec la meme cle ; une reponse '
        'changee prend une cle neuve', (WidgetTester tester) async {
      final FauxAutresCompetences port = FauxAutresCompetences();
      await monterTalents(tester, port: port);
      await _jusquALaDisponibilite(tester);
      await toucherTalents(tester, 'talents-dispo-mi_temps');
      port.erreurEnregistrement = const HorsLigneCandidature();
      await continuerTalents(tester);
      expect(_texte(t.recrutement.talents.erreurs.incertain), findsOneWidget);
      // Rien ne change : la meme demande rejoue la meme cle.
      await continuerTalents(tester);
      expect(port.enregistrements, hasLength(2));
      expect(
        port.enregistrements[1].cleIdempotence,
        port.enregistrements[0].cleIdempotence,
      );
      expect(_texte(t.recrutement.talents.lecture.enregistre), findsOneWidget);
    });

    testWidgets('une reponse changee apres un echec prend une cle neuve', (
      WidgetTester tester,
    ) async {
      final FauxAutresCompetences port = FauxAutresCompetences();
      await monterTalents(tester, port: port);
      await _jusquALaDisponibilite(tester);
      await toucherTalents(tester, 'talents-dispo-mi_temps');
      port.erreurEnregistrement = const HorsLigneCandidature();
      await continuerTalents(tester);
      await toucherTalents(tester, 'talents-dispo-plus');
      await continuerTalents(tester);
      expect(
        port.enregistrements[1].cleIdempotence,
        isNot(port.enregistrements[0].cleIdempotence),
      );
    });

    testWidgets('l envoi echoue sans reseau lisible : la phrase d echec, le '
        'bouton reste', (WidgetTester tester) async {
      final FauxAutresCompetences port = FauxAutresCompetences();
      await monterTalents(tester, port: port);
      await _jusquALaDisponibilite(tester);
      await toucherTalents(tester, 'talents-dispo-mi_temps');
      port.erreurEnregistrement = const CapaciteIndisponible('CAND-BR-19');
      await continuerTalents(tester);
      expect(_texte(t.recrutement.talents.erreurs.echec), findsOneWidget);
      // Le code ne s'affiche jamais.
      expect(find.textContaining('CAND-BR'), findsNothing);
      expect(
        _texte(t.recrutement.talents.disponibilite.enregistrer),
        findsOneWidget,
      );
    });

    testWidgets('la candidature est close entre-temps : la page le dit', (
      WidgetTester tester,
    ) async {
      final FauxAutresCompetences port = FauxAutresCompetences();
      await monterTalents(tester, port: port);
      await _jusquALaDisponibilite(tester);
      await toucherTalents(tester, 'talents-dispo-mi_temps');
      port.lectureJson = autresCompetencesJsonDeTest(
        ouvert: false,
        raison: 'candidature_close',
      );
      port.erreurEnregistrement = const CandidatureClose(null);
      await continuerTalents(tester);
      expect(find.byKey(TalentsPage.closKey), findsOneWidget);
    });

    testWidgets('hors ligne : pas de bouton d envoi, une phrase dit quand ce '
        'sera possible', (WidgetTester tester) async {
      final FauxAutresCompetences port = FauxAutresCompetences();
      await monterTalents(tester, port: port, horsLigne: true);
      await _jusquALaDisponibilite(tester);
      expect(
        _texte(t.recrutement.talents.disponibilite.enregistrer),
        findsNothing,
      );
      expect(find.byKey(ParcoursTalents.horsLigneKey), findsOneWidget);
      expect(_texte(t.recrutement.talents.erreurs.horsLigne), findsOneWidget);
      // La phrase ne redit pas « hors ligne » : le bandeau le dit.
      expect(find.textContaining('hors ligne'), findsNothing);
      expect(port.enregistrements, isEmpty);
      verifierUnSeulBoutonPlein(tester, maximum: 0);
    });
  });

  group('la lecture des reponses enregistrees', () {
    testWidgets('les competences, leur niveau, la disponibilite, l accord', (
      WidgetTester tester,
    ) async {
      await monterTalents(
        tester,
        port: FauxAutresCompetences(lectureJson: _lectureAvecReponses()),
      );
      expect(find.byKey(LectureTalents.enregistreKey), findsOneWidget);
      expect(
        _texte(
          t.recrutement.talents.lecture.misesAJour(
            date: jourTalents(DateTime.utc(2026, 10, 22, 14, 5)),
          ),
        ),
        findsOneWidget,
      );
      expect(_texte('Gestion des réseaux sociaux'), findsOneWidget);
      expect(_texte('Comptabilité'), findsOneWidget);
      expect(_texte(_libelleNiveau(NiveauCompetence.metier)), findsOneWidget);
      expect(
        _texte(_libelleNiveau(NiveauCompetence.experience)),
        findsOneWidget,
      );
      expect(_texte('Un mi-temps'), findsOneWidget);
      expect(_texte(t.recrutement.talents.lecture.contactOui), findsOneWidget);
      // Aucun code, aucune rubrique de l'introduction.
      expect(find.textContaining('comptabilite'), findsNothing);
      expect(find.textContaining('mi_temps'), findsNothing);
      expect(_texte(t.recrutement.talents.intro.texte), findsNothing);
      verifierUnSeulBoutonPlein(tester);
    });

    testWidgets('sans accord : la phrase dit qu aucune mission ne sera '
        'proposee', (WidgetTester tester) async {
      await monterTalents(
        tester,
        port: FauxAutresCompetences(
          lectureJson: _lectureAvecReponses(
            reponses: reponsesJsonDeTest(accord: false),
          ),
        ),
      );
      expect(_texte(t.recrutement.talents.lecture.contactNon), findsOneWidget);
      expect(_texte(t.recrutement.talents.lecture.contactOui), findsNothing);
    });

    testWidgets('« Autre domaine » se lit avec son texte', (
      WidgetTester tester,
    ) async {
      await monterTalents(
        tester,
        port: FauxAutresCompetences(
          lectureJson: _lectureAvecReponses(
            reponses: reponsesJsonDeTest(
              domaines: const <String, String>{'autre': 'experience'},
              autreTexte: 'Secrétariat médical',
            ),
          ),
        ),
      );
      expect(
        _texte(
          t.recrutement.talents.lecture.autreDomaine(
            texte: 'Secrétariat médical',
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('« Modifier » reprend les choix, enregistre avec la version '
        'lue, relit', (WidgetTester tester) async {
      final FauxAutresCompetences port = FauxAutresCompetences(
        lectureJson: _lectureAvecReponses(version: 2),
      );
      await monterTalents(tester, port: port);
      await toucherTalents(tester, 'talents-modifier');
      // Sans introduction : on repart des competences, deja choisies.
      expect(_texte(t.recrutement.talents.intro.texte), findsNothing);
      expect(
        _texte(t.recrutement.talents.competences.choisies(n: 2)),
        findsOneWidget,
      );
      await toucherTalents(tester, 'talent-assistanat');
      await continuerTalents(tester);
      await tester.tap(
        find.descendant(
          of: cleTalents('talents-niveau-assistanat'),
          matching: _texte(_libelleNiveau(NiveauCompetence.debutant)),
        ),
      );
      await tester.pumpAndSettle();
      await continuerTalents(tester);
      // La disponibilite lue est deja choisie.
      await continuerTalents(tester);
      final EnregistrementTalents e = port.enregistrements.single;
      expect(e.versionAttendue, 2);
      expect(e.domaines.keys.toSet(), <String>{
        'comptabilite',
        'reseaux_sociaux',
        'assistanat',
      });
      expect(e.domaines['comptabilite'], NiveauCompetence.metier);
      expect(e.disponibilite, DisponibiliteMission.miTemps);
      expect(_texte(t.recrutement.talents.lecture.enregistre), findsOneWidget);
      expect(
        _texte('Assistanat administratif ou de direction'),
        findsOneWidget,
      );
    });

    testWidgets('« Retirer » : la consequence se dit avant, annuler ne retire '
        'rien', (WidgetTester tester) async {
      final FauxAutresCompetences port = FauxAutresCompetences(
        lectureJson: _lectureAvecReponses(),
      );
      await monterTalents(tester, port: port);
      await toucherTalents(tester, 'talents-retirer');
      expect(
        _texte(t.recrutement.talents.lecture.retraitQuestion),
        findsOneWidget,
      );
      expect(
        _texte(t.recrutement.talents.lecture.retraitConsequence),
        findsOneWidget,
      );
      await tester.tap(_texte(t.commun.annuler));
      await tester.pumpAndSettle();
      expect(port.retraits, isEmpty);
      expect(find.byKey(LectureTalents.enregistreKey), findsOneWidget);
    });

    testWidgets('« Retirer » confirme : version attendue, cle, relecture, '
        'retrait dit apres la reponse', (WidgetTester tester) async {
      final FauxAutresCompetences port = FauxAutresCompetences(
        lectureJson: _lectureAvecReponses(version: 2),
      );
      await monterTalents(tester, port: port);
      await toucherTalents(tester, 'talents-retirer');
      await tester.tap(
        _texte(t.recrutement.talents.lecture.retraitConfirmer).last,
      );
      await tester.pumpAndSettle();
      expect(port.retraits.single.$1, 2);
      expect(port.retraits.single.$2.length, inInclusiveRange(8, 200));
      expect(port.lectures, 2);
      expect(find.byKey(TalentsPage.retireKey), findsOneWidget);
      expect(_texte(t.recrutement.talents.lecture.retire), findsOneWidget);
      verifierUnSeulBoutonPlein(tester);
      await tester.tap(_texte(t.recrutement.questionnaire.retourDossier));
      await tester.pumpAndSettle();
      expect(_texte(t.attente.titreDossier), findsOneWidget);
    });

    testWidgets('un retrait incertain se rejoue avec la meme cle', (
      WidgetTester tester,
    ) async {
      final FauxAutresCompetences port = FauxAutresCompetences(
        lectureJson: _lectureAvecReponses(version: 2),
      )..erreurRetrait = const HorsLigneCandidature();
      await monterTalents(tester, port: port);
      await toucherTalents(tester, 'talents-retirer');
      await tester.tap(
        _texte(t.recrutement.talents.lecture.retraitConfirmer).last,
      );
      await tester.pumpAndSettle();
      expect(
        _texte(t.recrutement.talents.erreurs.retraitIncertain),
        findsOneWidget,
      );
      await toucherTalents(tester, 'talents-retirer');
      await tester.tap(
        _texte(t.recrutement.talents.lecture.retraitConfirmer).last,
      );
      await tester.pumpAndSettle();
      expect(port.retraits, hasLength(2));
      expect(port.retraits[1].$2, port.retraits[0].$2);
      expect(find.byKey(TalentsPage.retireKey), findsOneWidget);
    });

    testWidgets('candidature terminee : lire et retirer, plus modifier', (
      WidgetTester tester,
    ) async {
      await monterTalents(
        tester,
        port: FauxAutresCompetences(
          lectureJson: _lectureAvecReponses(
            ouvert: false,
            raison: 'candidature_close',
          ),
        ),
      );
      expect(find.byKey(LectureTalents.closeKey), findsOneWidget);
      expect(_texte(t.recrutement.talents.lecture.close), findsOneWidget);
      expect(find.byKey(LectureTalents.modifierKey), findsNothing);
      expect(find.byKey(LectureTalents.retirerKey), findsOneWidget);
      expect(_texte('Comptabilité'), findsOneWidget);
      verifierUnSeulBoutonPlein(tester, maximum: 0);
    });

    testWidgets('hors ligne : rien ne se retire, une phrase dit quand ce sera '
        'possible', (WidgetTester tester) async {
      await monterTalents(
        tester,
        port: FauxAutresCompetences(lectureJson: _lectureAvecReponses()),
        horsLigne: true,
      );
      expect(find.byKey(LectureTalents.retirerKey), findsNothing);
      expect(find.byKey(LectureTalents.horsLigneKey), findsOneWidget);
      expect(
        _texte(t.recrutement.talents.erreurs.retraitHorsLigne),
        findsOneWidget,
      );
      expect(find.textContaining('hors ligne'), findsNothing);
    });

    testWidgets('une competence desactivee de sa reponse reste lisible', (
      WidgetTester tester,
    ) async {
      await monterTalents(
        tester,
        port: FauxAutresCompetences(
          lectureJson: autresCompetencesJsonDeTest(
            version: 1,
            reponses: reponsesJsonDeTest(
              domaines: const <String, String>{'tests_niveau': 'debutant'},
            ),
            desactivees: <String>{'tests_niveau'},
          ),
        ),
      );
      expect(_texte('Tests de niveau'), findsOneWidget);
    });

    testWidgets('modifier une reponse qui garde une competence desactivee : '
        'la phrase la dit, la personne la garde ou la decoche', (
      WidgetTester tester,
    ) async {
      final FauxAutresCompetences port = FauxAutresCompetences(
        lectureJson: autresCompetencesJsonDeTest(
          version: 1,
          reponses: reponsesJsonDeTest(
            domaines: const <String, String>{
              'tests_niveau': 'debutant',
              'comptabilite': 'metier',
            },
          ),
          desactivees: <String>{'tests_niveau'},
        ),
      );
      await monterTalents(tester, port: port);
      await toucherTalents(tester, 'talents-modifier');
      await tester.ensureVisible(
        find.byKey(EtapeCompetences.carteKey('tests_niveau')),
      );
      expect(
        _texte(t.recrutement.talents.competences.nonProposee),
        findsOneWidget,
      );
      // Elle reste choisie : la personne peut la decocher.
      await toucherTalents(tester, 'talent-tests_niveau');
      expect(
        _texte(t.recrutement.talents.competences.choisies(n: 1)),
        findsOneWidget,
      );
    });

    testWidgets('une competence que l application ne connait pas prend le '
        'libelle du catalogue, jamais son code', (WidgetTester tester) async {
      await monterTalents(
        tester,
        port: FauxAutresCompetences(
          lectureJson: autresCompetencesJsonDeTest(
            version: 1,
            reponses: reponsesJsonDeTest(
              domaines: const <String, String>{'moderation_forum': 'metier'},
            ),
            ajoutees: <Map<String, Object?>>[
              entreeJsonDeTest(
                'moderation_forum',
                famille: 'administration',
                ordre: 6,
                libelle: 'Modération du forum',
              ),
            ],
          ),
        ),
      );
      expect(_texte('Modération du forum'), findsOneWidget);
      expect(find.textContaining('moderation_forum'), findsNothing);
    });
  });

  group('l arabe, de droite a gauche', () {
    testWidgets('le parcours se lit et s enregistre', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      final FauxAutresCompetences port = FauxAutresCompetences();
      await monterTalents(tester, port: port, direction: TextDirection.rtl);
      expect(_texte(t.recrutement.talents.titre), findsOneWidget);
      expect(_texte('مواهبك الأخرى'), findsOneWidget);
      await _jusquALaDisponibilite(tester);
      await toucherTalents(tester, 'talents-dispo-mi_temps');
      await continuerTalents(tester);
      expect(port.enregistrements, hasLength(1));
      expect(_texte(t.recrutement.talents.lecture.enregistre), findsOneWidget);
      expect(_texte('المحاسبة'), findsOneWidget);
    });
  });

  test('la route existe dans le routeur unique', () {
    expect(Routes.attenteTalents, '/attente/talents');
    expect(Routes.attenteTalents.startsWith(Routes.attente), isTrue);
  });
}
