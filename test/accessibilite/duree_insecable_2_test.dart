// DUREE-INSECABLE-2 : reserves de la relecture de DUREE-INSECABLE-1.
//
// 1. Toutes les durees affichees passent par `LibellesGroupe.insecable` :
//    cahier, creneaux, historique et compte rendu du controleur, salle de
//    seance, indicateur d'observation, panneau post-cours, `LignePresence`,
//    `PageParcours`, pastille de retard de l'historique.
// 2. Une duree affichee seule, comme valeur, porte l'ancre de sens (U+200E) :
//    detail de seance, detail des observations, et les valeurs de la liste 1
//    qui commencent par un nombre. La carte de groupe (« Duree 45 min ») n'en
//    porte plus depuis DUREE-INSECABLE-3 : la valeur y suit un mot.
//
// Les gardes de source lisent `lib/` : un nouvel appel nu a l'un de ces
// libelles fait echouer le test.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/presence/vue_presence.dart';
import 'package:rewayah_academy/core/tc_groupe/libelles_tc_groupe.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/ligne_cle_valeur.dart';
import 'package:rewayah_academy/core/widgets/ligne_presence.dart';
import 'package:rewayah_academy/features/suivi_foyer/filtres_historique.dart'
    show dureeSeule;

import '../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../support/aucun_mot_coupe.dart';
import '../support/garde_durees.dart';

/// Les espaces ou une ligne peut se couper.
final RegExp _espaceSecable = RegExp('[ \t\n]');

/// Les libelles a duree dont chaque appel, dans `lib/`, doit passer par
/// `insecable` (ou `valeurSeule`, qui l'inclut). DUREE-INSECABLE-3 : chemins
/// complets, juges appel par appel (`test/support/garde_durees.dart`).
const List<String> _libellesADuree = <String>[
  'enseignant.cahier.duree',
  'enseignant.cahier.dureeEtInterruption',
  'commun.formats.minutes',
  'controleur.historique.duree',
  'controleur.compteRendu.debutRetard',
  'salle.seance.minutesRestantes',
  'tc.observation.annonce.restant',
  'tc.parcours.postCours.duree',
  'presence.entreeMinutes',
  'presence.retardMinutes',
  'presence.silenceMinutes',
  'presence.attenteMinutes',
  'inscription.tempsRestant',
  'historique.etat.retard',
];

/// Les fichiers qui affichent une duree seule et doivent l'ancrer.
const List<String> _valeursSeules = <String>[
  'lib/features/suivi_foyer/detail_seance_page.dart',
  'lib/features/suivi_foyer/detail_observations_page.dart',
];

PresenceParticipant _ligne(
  EtatPresence etat, {
  DateTime? entreLe,
  DateTime? debutSeance,
  DateTime? derniereTraceLe,
}) => PresenceParticipant(
  seanceId: 's1',
  profilId: 'enf-1',
  role: 'student',
  prenom: 'Sofia',
  identifiantImmuable: 'STUD-000001',
  etat: etat,
  consolide: false,
  entreLe: entreLe,
  debutSeance: debutSeance,
  derniereTraceLe: derniereTraceLe,
);

void main() {
  group('Garde de source : chaque libelle a duree passe par insecable', () {
    test('aucun appel nu dans lib/', () {
      final List<AppelLibelle> appels = appelsDe(
        _libellesADuree,
        sourcesDart(),
      );
      expect(appels.length, greaterThanOrEqualTo(_libellesADuree.length));
      final List<String> nus = <String>[
        for (final AppelLibelle a in appels)
          if (!estInsecable(a.enveloppe)) '${a.fichier}:${a.ligne} ${a.cle}',
      ];
      expect(nus, isEmpty, reason: 'Durees secables : $nus');
    });

    test('les durees isolees sont ancrees (dureeSeule)', () {
      for (final String chemin in _valeursSeules) {
        final String source = File(chemin).readAsStringSync();
        expect(
          source.contains('dureeLisible('),
          isFalse,
          reason: '$chemin affiche une duree seule sans ancre de sens',
        );
        expect(source.contains('dureeSeule('), isTrue, reason: chemin);
      }
    });
  });

  group('Valeurs rendues', () {
    test(
      'valeurSeule : insecable et ancree si elle commence par un nombre',
      () {
        expect(
          LibellesGroupe.valeurSeule('45 min de cours'),
          '‎45 min de cours',
        );
        expect(LibellesGroupe.valeurSeule('Environ 3 min'), 'Environ 3 min');
      },
    );

    test('historique : dureeSeule ancre la duree isolee', () {
      expect(dureeSeule(const Duration(minutes: 45)), '‎45 min');
      expect(dureeSeule(const Duration(seconds: 102)), '‎1 min 42 s');
    });

    // DUREE-INSECABLE-4 : le retard suit le role sur la ligne (« Eleve ·
    // 7 min apres l'heure ») ; la phrase est insecable, et l'ancre se pose
    // sur la ligne rendue, seulement quand la duree la commence
    // (test/accessibilite/duree_insecable_4_test.dart).
    test('LignePresence : retard et autres reperes insecables', () {
      final DateTime debut = DateTime.utc(2026, 10, 5, 18);
      final String? retard = LignePresence.contexte(
        VuePresence.depuis(
          ligne: _ligne(
            EtatPresence.enRetard,
            debutSeance: debut,
            entreLe: debut.add(const Duration(minutes: 7)),
          ),
          maintenant: debut.add(const Duration(minutes: 20)),
        ),
      );
      expect(
        retard,
        t.presence.retardMinutes(minutes: '7').replaceFirst(' ', ' '),
      );
      final String? entree = LignePresence.contexte(
        VuePresence.depuis(
          ligne: _ligne(EtatPresence.presente, entreLe: debut),
          maintenant: debut.add(const Duration(minutes: 12)),
        ),
      );
      expect(entree, isNotNull);
      expect(
        motifDuree.firstMatch(entree!)!.group(0)!.contains(_espaceSecable),
        isFalse,
        reason: entree,
      );
    });
  });

  group('Interface de droite a gauche : le nombre reste devant son mot', () {
    setUpAll(chargerPolicesDuDepot);

    double gauche(TextPainter p, String texte, String partie) {
      final int debut = texte.indexOf(partie);
      expect(debut, isNonNegative, reason: '« $partie » dans « $texte »');
      return p
          .getBoxesForSelection(
            TextSelection(
              baseOffset: debut,
              extentOffset: debut + partie.length,
            ),
          )
          .map((TextBox b) => b.left)
          .reduce((double a, double b) => a < b ? a : b);
    }

    for (final ({String nom, String texte}) cas
        in <({String nom, String texte})>[
          (
            nom: 'detail de seance, 45 min',
            texte: dureeSeule(const Duration(minutes: 45)),
          ),
          (
            nom: 'carte de groupe, 45 min',
            texte: LibellesGroupe.dureeCarte(const Duration(minutes: 45)),
          ),
          (
            nom: 'cahier, 45 min de cours',
            texte: LibellesGroupe.valeurSeule(
              t.enseignant.cahier.duree(minutes: '45'),
            ),
          ),
        ]) {
      test('${cas.nom} : « 45 » a gauche de « min »', () {
        final TextPainter p = TextPainter(
          text: TextSpan(
            text: cas.texte,
            style: const TextStyle(fontFamily: 'DMSans', fontSize: 16),
          ),
          textDirection: TextDirection.rtl,
        )..layout();
        expect(
          gauche(p, cas.texte, '45'),
          lessThan(gauche(p, cas.texte, 'min')),
          reason: '« ${cas.texte} » se lit a l envers en RTL',
        );
        p.dispose();
      });
    }
  });

  group('LigneCleValeur, 320 px texte x2 : la duree tient sur une ligne', () {
    setUpAll(chargerPolicesDuDepot);

    for (final TextDirection sens in TextDirection.values) {
      testWidgets('${sens.name} : detail de seance et cahier', (
        WidgetTester tester,
      ) async {
        tester.view.physicalSize = const Size(320, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          TranslationProvider(
            child: MediaQuery(
              data: const MediaQueryData(
                size: Size(320, 1200),
                textScaler: TextScaler.linear(2),
              ),
              child: MaterialApp(
                theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
                home: Directionality(
                  textDirection: sens,
                  child: Scaffold(
                    body: ListView(
                      children: <Widget>[
                        LigneCleValeur(
                          cle: t.historique.seance.dureePrevue,
                          valeur: dureeSeule(
                            const Duration(hours: 1, minutes: 5),
                          ),
                          chiffres: true,
                        ),
                        LigneCleValeur(
                          cle: t.controleur.historique.cleDuree,
                          valeur: LibellesGroupe.valeurSeule(
                            t.controleur.historique.duree(minutes: 45),
                          ),
                        ),
                        Text(
                          LibellesGroupe.valeurSeule(
                            t.enseignant.cahier.dureeEtInterruption(
                              minutes: '45',
                              interruption: '12',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        verifierDureesSurUneLigne(tester, find.byType(Scaffold));
        verifierAucunMotCoupe(tester, find.byType(Scaffold));
        expect(tester.takeException(), isNull);
      });
    }
  });
}
