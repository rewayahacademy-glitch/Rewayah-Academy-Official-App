// DUREE-INSECABLE-4 : reserves de la relecture de DUREE-INSECABLE-3.
//
// 1. Aucune ancre de sens (U+200E) au milieu d'un libelle, meme quand la
//    valeur ancree passe par une variable ou une fonction avant d'etre
//    inseree ailleurs (test/support/garde_ancres.dart).
// 2. Les unites hors duree (« 18 ans », « 8 Mo », « 150 % ») sont
//    insecables, et la garde de source les connait.
// 3. Le message de rappel en attente (« A nouveau dans 30 s ») est verifie
//    sur l'ecran reel : la fiche de seance, rendue et pressee.
// 4. CarteSession : en interface de droite a gauche, un libelle francais
//    garde sa ponctuation a sa place (isole dans son sens) ; a 1440 px, la
//    carte garde une largeur de lecture.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/accessibilite/sens_du_contenu.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/presence/vue_presence.dart';
import 'package:rewayah_academy/core/tc_classe/port_rappel_discret.dart';
import 'package:rewayah_academy/core/tc_classe/teacher_student_projection.dart';
import 'package:rewayah_academy/core/tc_groupe/libelles_tc_groupe.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/app_card.dart';
import 'package:rewayah_academy/core/widgets/ligne_presence.dart';
import 'package:rewayah_academy/core/widgets/local_feedback.dart';
import 'package:rewayah_academy/features/demo/accessibilite_demo.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/barre_support.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';
import 'package:rewayah_academy/features/tc_classe_live/fiche_seance.dart';
import 'package:rewayah_academy/features/tc_espace_groupe/carte_session.dart';

import '../support/garde_ancres.dart';
import '../support/garde_durees.dart';
import '../teaching_core/e/faux/faux_classe.dart';
import '../teaching_core/e/support/hote_classe.dart';

const String _nbsp = '\u00A0';
const String _lrm = '\u200E';

/// Les textes rendus sous [racine].
List<String> _textes(WidgetTester tester, Finder racine) => <String>[
  for (final Element e
      in find.descendant(of: racine, matching: find.byType(Text)).evaluate())
    if ((e.widget as Text).data case final String d) d,
];

Widget _hote(Widget enfant, {TextDirection sens = TextDirection.ltr}) =>
    TranslationProvider(
      child: MaterialApp(
        theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
        builder: (BuildContext _, Widget? app) =>
            Directionality(textDirection: sens, child: app!),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: enfant,
          ),
        ),
      ),
    );

PresenceParticipant _retard(DateTime debut) => PresenceParticipant(
  seanceId: 's1',
  profilId: 'enf-1',
  role: 'student',
  prenom: 'Sofia',
  identifiantImmuable: 'STUD-000001',
  etat: EtatPresence.enRetard,
  consolide: false,
  entreLe: debut.add(const Duration(minutes: 7)),
  debutSeance: debut,
);

void main() {
  group('1. Ancre de sens : jamais au milieu d un libelle', () {
    test('lib/ : aucune valeur ancree inseree dans un autre libelle', () {
      final List<AncreGlissee> fautes = ancresGlissees();
      expect(
        fautes,
        isEmpty,
        reason: fautes
            .map((AncreGlissee f) => '${f.fichier}:${f.ligne} ${f.raison}')
            .join('\n'),
      );
    });

    test('la garde suit variables, fonctions, listes et chaines', () {
      final Directory dossier = Directory.systemTemp.createTempSync('ancres');
      addTearDown(() => dossier.deleteSync(recursive: true));
      final File f = File('${dossier.path}/x.dart')
        ..writeAsStringSync(r'''
String variable(int n) {
  final h = t.controleur.historique;
  final String duree = LibellesGroupe.valeurSeule(h.duree(minutes: n));
  return h.meta(heure: '18:00', duree: duree);
}
String _depuis(int j) => switch (j) {
  0 => t.a.aujourdhui,
  _ => LibellesGroupe.valeurSeule(t.a.depuisJours(jours: '$j')),
};
String fonction(int j) => t.b.phrase(depuis: _depuis(j));
String liste(String role, int n) {
  final String? dit = LibellesGroupe.dureeSeule(Duration(minutes: n));
  return <String>[role, ?dit].join(' · ');
}
String chaine(int n) {
  final String d = LibellesGroupe.dureeSeule(Duration(minutes: n));
  return 'Duree $d';
}
String concat(int n) => 'Duree ' + LibellesGroupe.dureeSeule(Duration(minutes: n));
// Ce qui est permis : la valeur commence le libelle, ou s'affiche seule.
String enTete(int n) {
  final String d = LibellesGroupe.dureeSeule(Duration(minutes: n));
  return '$d de cours';
}
Widget seule(int n) => Text(LibellesGroupe.dureeSeule(Duration(minutes: n)));
''');
      final List<int> lignes = <int>[
        for (final AncreGlissee a in ancresGlissees(<File>[f])) a.ligne,
      ];
      expect(lignes, <int>[4, 10, 13, 17, 19]);
    });

    test('salle, enseignant : « Classe · 32 min restantes » sans ancre', () {
      final VueSeance base = DonneesSeanceDemo.vue(
        RoleSeance.enseignant,
        EtatDemoSalle.visite,
      );
      final VueSeance avecClasse = base.copyWith(
        horloge: const HorlogeRestante(32),
      );
      expect(avecClasse.nomClasse, isNotEmpty);
      final String ligne = avecClasse.ligneEtat!;
      expect(ligne, contains('32${_nbsp}min'));
      expect(ligne, isNot(contains(_lrm)));
    });

    testWidgets('LignePresence : role puis retard, sans ancre au milieu', (
      WidgetTester tester,
    ) async {
      final DateTime debut = DateTime.utc(2026, 10, 5, 18);
      final VuePresence vue = VuePresence.depuis(
        ligne: _retard(debut),
        maintenant: debut.add(const Duration(minutes: 20)),
      );
      await tester.pumpWidget(
        _hote(
          Column(
            children: <Widget>[
              LignePresence(nom: 'Sofia', vue: vue, role: 'Élève'),
              LignePresence(nom: 'Nour', vue: vue),
            ],
          ),
        ),
      );
      final List<String> textes = _textes(tester, find.byType(LignePresence));
      final String avecRole = textes.firstWhere(
        (String s) => s.startsWith('Élève'),
      );
      expect(avecRole, contains('7${_nbsp}min'));
      expect(avecRole, isNot(contains(_lrm)));
      // Seule, la duree commence la ligne : ancree.
      expect(textes, contains(startsWith('${_lrm}7${_nbsp}min')));
    });
  });

  group('2. Unites hors duree : insecables', () {
    test('la garde connait les ages, tailles et pourcentages', () {
      expect(
        libellesAUnite(),
        containsAll(<String>[
          'foyer.ajout.erreurs.ageHorsBornes',
          'kyc.tropVolumineux',
          'ficheEleve.informations.tropLourde',
          'salle.seance.zoomValeur',
          'classe.entree.progressionValeur',
        ]),
      );
    });

    testWidgets('zoom de la salle : « 150 % » insecable et ancre', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_hote(const ZoomLocal(zoom: 1.5)));
      final List<String> textes = _textes(tester, find.byType(ZoomLocal));
      expect(textes, contains('${_lrm}150$_nbsp%'));
      expect(textes.where((String s) => s.contains('150 %')), isEmpty);
    });
  });

  group('3. Rappel discret en attente, sur la fiche reelle', () {
    testWidgets('« A nouveau dans 30 s » ne se coupe pas', (
      WidgetTester tester,
    ) async {
      const TeacherStudentProjection eleve = TeacherStudentProjection(
        firstName: 'Amina',
        academyId: 'RA-AB0012',
        liveStatus: EtatPresenceProjete.present,
        interfaceGuidee: false,
      );
      await tester.pumpWidget(
        hoteClasse(
          const FicheSeance(eleve: eleve, sessionId: 's1'),
          surcharges: surchargesClasse(
            moteur: FauxMoteurClasse(),
            video: FauxServiceVideoClasse(),
            preVol: FauxPreVolClasse(),
            rappel: FauxRappelDiscret(
              echec: const EchecRappel(MotifEchecRappel.cooldown),
              restant: const Duration(seconds: 30),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text(t.tc.classe.action.rappel));
      await tester.pump();
      await tester.pump();

      final List<String> textes = _textes(tester, find.byType(FicheSeance));
      final String message = textes.firstWhere(
        (String s) => s.contains('30'),
        orElse: () => fail('aucun message de rappel rendu : $textes'),
      );
      expect(message, endsWith('30${_nbsp}s'));
      expect(message, isNot(contains('30 s')));
      await tester.pump(const Duration(seconds: 5));
    });
  });

  group('4. CarteSession : sens du contenu et largeur de lecture', () {
    test('sensDuContenu lit la premiere lettre forte', () {
      expect(sensDuContenu('Déjà appelé.'), TextDirection.ltr);
      expect(sensDuContenu('$_lrm 45 min'), TextDirection.ltr);
      expect(sensDuContenu('45 دقيقة'), TextDirection.rtl);
      expect(sensDuContenu('18:00 · 45'), isNull);
    });

    testWidgets('RTL : chaque libelle francais ponctue est isole dans son '
        'sens', (WidgetTester tester) async {
      int ponctues = 0;
      for (final MomentDemoAccessibilite moment
          in MomentDemoAccessibilite.values) {
        await tester.pumpWidget(
          _hote(
            CarteSession(
              key: ValueKey<MomentDemoAccessibilite>(moment),
              espace: DonneesAccessibiliteDemo.espaceAccueil(moment),
              onRejoindre: () {},
            ),
            sens: TextDirection.rtl,
          ),
        );
        await tester.pump();
        for (final Element e
            in find
                .descendant(
                  of: find.byType(CarteSession),
                  matching: find.byType(Text),
                )
                .evaluate()) {
          final String? d = (e.widget as Text).data;
          if (d == null || !RegExp(r'[.,;:!?\u2026]').hasMatch(d)) continue;
          if (sensDuContenu(d) != TextDirection.ltr) continue;
          // Les heures (« 18:00 Paris ») sont ancrees par U+200E, elles.
          if (d.startsWith(_lrm)) continue;
          ponctues++;
          expect(
            Directionality.of(e),
            TextDirection.ltr,
            reason: '${moment.name} : « $d » suit le sens de l interface',
          );
        }
      }
      expect(ponctues, greaterThan(0));
    });

    testWidgets('RTL : le message du rappel garde son point a sa place', (
      WidgetTester tester,
    ) async {
      final String message = LibellesGroupe.insecable(
        t.tc.classe.rappel.cooldown(secondes: 30),
      );
      await tester.pumpWidget(
        _hote(LocalFeedback(message: message), sens: TextDirection.rtl),
      );
      await tester.pump();
      final Element texte = find.text(message).evaluate().single;
      expect(Directionality.of(texte), TextDirection.ltr);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('1440 px : la carte ne depasse pas la largeur de lecture', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _hote(
          CarteSession(
            espace: DonneesAccessibiliteDemo.espaceAccueil(
              MomentDemoAccessibilite.avant,
            ),
            onRejoindre: () {},
          ),
        ),
      );
      await tester.pump();
      final Finder carte = find.descendant(
        of: find.byType(CarteSession),
        matching: find.byType(AppCard),
      );
      expect(
        tester.getSize(carte).width,
        lessThanOrEqualTo(AppPage.largeurLecture),
      );
      // Au bord de debut de la page, pas au centre.
      expect(tester.getTopLeft(carte).dx, AppSpacing.lg);
    });
  });
}
