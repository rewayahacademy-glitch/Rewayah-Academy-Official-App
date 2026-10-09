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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/service_comptes.dart';
import 'package:rewayah_academy/core/admin/service_progression.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/isolat_bidi.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/presence/vue_presence.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/tc_classe/port_rappel_discret.dart';
import 'package:rewayah_academy/core/tc_classe/teacher_student_projection.dart';
import 'package:rewayah_academy/core/tc_groupe/group_home_vm.dart';
import 'package:rewayah_academy/core/tc_groupe/group_summary_vm.dart';
import 'package:rewayah_academy/core/tc_groupe/libelles_tc_groupe.dart';
import 'package:rewayah_academy/core/tc_horloge/session_clock_vm.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/app_card.dart';
import 'package:rewayah_academy/core/widgets/ligne_presence.dart';
import 'package:rewayah_academy/features/admin_comptes/comptes_page.dart';
import 'package:rewayah_academy/features/admin_pedagogie_progression/progression_page.dart';
import 'package:rewayah_academy/features/demo/accessibilite_demo.dart';
import 'package:rewayah_academy/features/demo/classe_demo.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/barre_support.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';
import 'package:rewayah_academy/features/tc_classe_live/fiche_seance.dart';
import 'package:rewayah_academy/features/tc_espace_groupe/carte_session.dart';

import '../support/garde_ancres.dart';
import '../support/garde_durees.dart';
import '../support/harnais.dart';
import '../teaching_core/e/faux/faux_classe.dart';
import '../teaching_core/e/support/hote_classe.dart';

const String _nbsp = '\u00A0';
const String _lrm = '\u200E';
const String _fsi = '\u2068';
const String _pdi = '\u2069';

/// Une lettre latine : le libelle est en francais.
final RegExp _latin = RegExp('[A-Za-z\u00C0-\u024F]');

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

/// Aucun texte rendu ne porte d'ancre de sens ailleurs qu'en tete, et la
/// valeur [attendue] est bien rendue au milieu d'une ligne jointe.
void _sansAncreAuMilieu(WidgetTester tester, String attendue) {
  final List<String> textes = _textes(tester, find.byType(Scaffold));
  final String ligne = textes.firstWhere(
    (String s) => s.contains(' · ') && s.contains(attendue),
    orElse: () => fail('aucune ligne jointe avec « $attendue » : $textes'),
  );
  expect(ligne.indexOf(attendue), greaterThan(0));
  for (final String s in textes) {
    expect(
      s.lastIndexOf(_lrm),
      lessThanOrEqualTo(0),
      reason: 'ancre de sens au milieu de « $s »',
    );
  }
}

class _FauxServiceComptes implements ServiceComptes {
  _FauxServiceComptes(this._comptes);

  final List<CompteAdmin> _comptes;

  @override
  Future<List<CompteAdmin>> comptes() async => _comptes;
}

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

    test('la garde suit une valeur ancree jusqu a une colonne jointe', () {
      final Directory dossier = Directory.systemTemp.createTempSync('joints');
      addTearDown(() => dossier.deleteSync(recursive: true));
      // Une colonne dont le `texte:` est joint par `.join` ailleurs : la
      // valeur ancree qu'on y range finit au milieu de la ligne repliee.
      const String colonne = r'''
class Col<T> {
  const Col({required this.texte});
  final String Function(T ligne) texte;
}
String _attente(int j) => switch (j) {
  0 => t.a.aujourdhui,
  _ => LibellesGroupe.valeurSeule(t.a.attendJours(jours: '$j')),
};
List<Col<int>> colonnes() => <Col<int>>[
  Col<int>(texte: (int j) => _attente(j)),
  Col<int>(texte: (int j) => LibellesGroupe.dureeSeule(Duration(days: j))),
];
''';
      File('${dossier.path}/colonne.dart').writeAsStringSync(colonne);
      final File carte = File('${dossier.path}/carte.dart')
        ..writeAsStringSync(r'''
String resume(List<Col<int>> cs, int l) => cs
    .map((Col<int> c) => c.texte(l))
    .where((String v) => v.isNotEmpty)
    .join(' · ');
''');
      List<int> lignes() => <int>[
        for (final AncreGlissee a in ancresGlissees(
          dossier.listSync().whereType<File>(),
        ))
          a.ligne,
      ]..sort();
      expect(lignes(), <int>[10, 11]);
      // Jointe par `enchainer` (ancre gardee en tete seulement) : permis.
      carte.writeAsStringSync(r'''
String resume(List<Col<int>> cs, int l) =>
    enchainer(cs.map((Col<int> c) => c.texte(l)), ' · ');
''');
      expect(lignes(), isEmpty);
    });

    test('la garde suit une valeur ancree rangee dans un champ d objet '
        '(reprise 2)', () {
      final Directory dossier = Directory.systemTemp.createTempSync('champs');
      addTearDown(() => dossier.deleteSync(recursive: true));
      // Le cas releve par la relecture : `AffichageSeance.depuis` range
      // `dureeSeule(...)` dans le champ `duree`, que la page Planning relit
      // pour l'inserer dans « {heure} · {duree} ».
      File('${dossier.path}/affichage.dart').writeAsStringSync(r'''
class Affichage {
  const Affichage._({required this.duree, required this.seule});
  factory Affichage.depuis(int n) => Affichage._(
    duree: LibellesGroupe.dureeSeule(Duration(minutes: n)),
    seule: LibellesGroupe.dureeSeule(Duration(minutes: n)),
  );
  final String duree;
  final String seule;
  String get phrase => 'Duree $duree';
}
''');
      File('${dossier.path}/page.dart').writeAsStringSync(r'''
class Ligne extends StatelessWidget {
  const Ligne({required this.affichage});
  final Affichage affichage;
  Widget build(BuildContext context) => Column(children: <Widget>[
    Text(t.planning.ligne(heure: '18:10', duree: affichage.duree)),
    Text(affichage.seule),
  ]);
}
class Etat extends State<Carte> {
  Widget build(BuildContext context) =>
      Text(t.carte.valeur(v: widget.valeur));
}
class Carte extends StatefulWidget {
  const Carte({required this.valeur});
  final String valeur;
}
Widget carte(int n) => Carte(valeur: LibellesGroupe.dureeSeule(Duration(minutes: n)));
String lu(String libelle, String? d) => <String>[libelle, ?d].join('. ');
String premier(int n) => lu(LibellesGroupe.dureeSeule(Duration(minutes: n)), null);
''');
      List<String> fautes() => <String>[
        for (final AncreGlissee a in ancresGlissees(
          dossier.listSync().whereType<File>(),
        ))
          '${a.fichier.split('/').last}:${a.ligne}',
      ]..sort();
      // Le champ interpole dans le getter de la classe, le champ relu dans
      // un libelle, et `widget.valeur` d'un `State<Carte>`. Le champ affiche
      // seul (`seule`) et la valeur en tete d'une liste jointe sont permis.
      expect(fautes(), <String>[
        'affichage.dart:9',
        'page.dart:11',
        'page.dart:5',
      ]);
    });

    test('enchainer ne garde l ancre qu en tete de ligne', () {
      expect(
        enchainer(<String>['${_lrm}12 jours', '', 'Enseignant'], ' · '),
        '${_lrm}12 jours · Enseignant',
      );
      expect(
        enchainer(<String>['Enseignant', '${_lrm}12 jours', '2'], ' · '),
        'Enseignant · 12 jours · 2',
      );
    });

    testWidgets('Comptes, replie en cartes : « … · 12 jours » sans ancre', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        hote(
          const ComptesPage(),
          surcharges: <Override>[
            serviceComptesProvider.overrideWithValue(
              _FauxServiceComptes(<CompteAdmin>[
                CompteAdmin(
                  profilId: 'p1',
                  identifiant: 'TEACHER-AS-000001',
                  prenom: 'Aicha',
                  nom: 'Sow',
                  role: AppRole.teacher,
                  etat: AccountStatus.pendingKyc,
                  inscritLe: DateTime.now().subtract(const Duration(days: 12)),
                  accesJusquAu: null,
                  foyerId: null,
                  piece: EtatPiece.aucune,
                  contrats: 2,
                  aEnseignant: false,
                  enfantsDuFoyer: 0,
                ),
              ]),
            ),
            serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
          ],
        ),
      );
      await tester.pumpAndSettle();
      _sansAncreAuMilieu(tester, '12${_nbsp}jours');
    });

    testWidgets('Progression, repliee en cartes : « … · 9 jours » sans ancre', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        hote(
          const ProgressionPage(),
          surcharges: <Override>[
            progressionProvider.overrideWith(
              (Ref ref) async => <EleveProgression>[
                EleveProgression(
                  studentId: 's1',
                  identifiant: 'STUD-000001',
                  prenom: 'Sofia',
                  nom: 'B.',
                  groupeId: 'g1',
                  groupeLibelle: 'Groupe du soir',
                  niveauId: 'n1',
                  niveauNomHumain: 'Niveau 2',
                  niveauCycle: 'tajwid',
                  niveauDepuis: DateTime.now().subtract(
                    const Duration(days: 9, hours: 1),
                  ),
                  exceptionActiveId: null,
                  exceptionActiveType: null,
                ),
              ],
            ),
            serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
          ],
        ),
      );
      await tester.pumpAndSettle();
      _sansAncreAuMilieu(tester, '9${_nbsp}jours');
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
          'salle.seance.zoomValeur',
          'tc.coran.zoom.valeur',
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
          if (!_latin.hasMatch(d)) continue;
          // Les heures (« 18:00 Paris ») sont ancrees par U+200E, elles.
          if (d.startsWith(_lrm)) continue;
          ponctues++;
          expect(
            d,
            allOf(startsWith(_fsi), endsWith(_pdi)),
            reason: '${moment.name} : « $d » suit le sens de l interface',
          );
        }
      }
      expect(ponctues, greaterThan(0));
    });

    testWidgets('RTL : sur la fiche reelle, le message du rappel garde son '
        'point a sa place', (WidgetTester tester) async {
      const TeacherStudentProjection eleve = TeacherStudentProjection(
        firstName: 'Amina',
        academyId: 'RA-AB0012',
        liveStatus: EtatPresenceProjete.present,
        interfaceGuidee: false,
      );
      await tester.pumpWidget(
        hoteClasse(
          const Directionality(
            textDirection: TextDirection.rtl,
            child: FicheSeance(eleve: eleve, sessionId: 's1'),
          ),
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
      // Isole dans son sens : le point final reste apres « 30 s ».
      expect(message, allOf(startsWith(_fsi), endsWith(_pdi)));
      expect(message, contains('30${_nbsp}s'));
      expect(message, isNot(contains('30 s')));
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('RTL : attente, changement d heure, conseil d appareil et '
        'intitules des heures sont isoles (reprise 2)', (
      WidgetTester tester,
    ) async {
      const HorlogeAffichee contrepartie = HorlogeAffichee(
        fuseauIana: 'Africa/Conakry',
        libelleVille: 'Conakry',
        heureLocaleRendue: '16:00',
        dateLocaleRendue: 'Lundi 28 septembre',
      );
      final GroupSummaryVM identite = DonneesClasseDemo.groupe(
        EtatDemoClasse.attente,
      );
      final GroupHomeVM espace = GroupHomeVM(
        identite: identite,
        role: RoleEspaceGroupe.eleve,
        // Entre avant l'heure, avec un changement d'heure annonce.
        horloge: SessionClockVM.depuisFenetre(
          fenetre: DonneesClasseDemo.fenetre,
          maintenantServeurUtc: DonneesClasseDemo.instant(
            EtatDemoClasse.attente,
          ),
          horlogeUtilisateur: DonneesClasseDemo.horlogeUtilisateur,
          horlogeContrepartie: contrepartie,
          connecte: true,
          noticeDst: DonneesClasseDemo.noticeDst,
        ),
        avantProchainCours: DonneesClasseDemo.actions,
        bibliotheque: SlotBibliotheque(groupeId: identite.groupeId),
      );
      expect(espace.horloge!.phase, PhaseSeance.attenteAvantT0);
      for (final bool tutoiement in <bool>[false, true]) {
        await tester.pumpWidget(
          _hote(
            CarteSession(
              key: ValueKey<bool>(tutoiement),
              espace: espace,
              tutoiement: tutoiement,
              onRejoindre: () {},
            ),
            sens: TextDirection.rtl,
          ),
        );
        await tester.pump();
        final List<String> textes = _textes(tester, find.byType(CarteSession));
        final List<String> attendus = <String>[
          // `attenteDetail`
          if (tutoiement)
            t.accessibilite.tutoiement.attenteDetail
          else
            LibellesGroupe.attenteAvantDebutDetail,
          // NoticeChangementHeure
          t.classe.entree.dst(avant: '18:00', apres: '17:00'),
          // Le conseil d'appareil
          LibellesGroupe.conseilAppareil,
          // Les intitules de _LigneValeur
          if (tutoiement)
            t.accessibilite.tutoiement.tonHeure
          else
            LibellesGroupe.votreHeure,
          LibellesGroupe.dureeLibelle,
        ];
        for (final String libelle in attendus) {
          expect(
            textes,
            contains('$_fsi$libelle$_pdi'),
            reason:
                '« $libelle » non isole (tutoiement : $tutoiement) : '
                '$textes',
          );
          expect(textes, isNot(contains(libelle)));
        }
      }
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
