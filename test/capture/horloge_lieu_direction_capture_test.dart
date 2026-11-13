// HORLOGE-ET-LIEU (R3, directeur, 01/11/2026 : pas de capture, pas de fusion) :
// les ecrans de la DIRECTION touches par le lot, rendus par le VRAI routeur de
// l'application (`routeurProvider`), avec des fixtures :
//
//   - la feuille « Ajouter un creneau » (legende « Heure de Paris » et
//     equivalent a La Mecque avant l'envoi) ;
//   - la feuille des reglages d'une Classe (etat normal, puis refus du serveur
//     « Rechargez l'application pour modifier un horaire. ») ;
//   - la fiche de la Classe (l'heure de la personne, puis La Mecque) ;
//   - le pilotage ;
//   - les regroupements ;
//   - les Comptes des enseignants : colonne Ville, « Verifier la ville », bloc
//     des changements d'heure a venir.
//
// 390 et 1440 de large, clair et sombre, francais et arabe. Prefixe des PNG :
// `horloge_lieu_`. Saute sans CAPTURE_DIR (test/capture/LISEZ-MOI.md).
//
//   CAPTURE_DIR=docs/current/captures/E2E/horloge-lieu \
//     flutter test test/capture/horloge_lieu_direction_capture_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/creneaux_classe.dart';
import 'package:rewayah_academy/core/admin/port_classes_admin.dart';
import 'package:rewayah_academy/core/admin/port_pilotage.dart';
import 'package:rewayah_academy/core/admin/service_groupes.dart';
import 'package:rewayah_academy/core/capacites/port_creation_classe.dart';
import 'package:rewayah_academy/core/capacites/port_enseignants_classe.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/enseignant/modeles_enseignant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/lieu/lieu_direction.dart';
import 'package:rewayah_academy/core/offres/page_regroupements.dart'
    show portRegroupementsPagesProvider;
import 'package:rewayah_academy/core/offres/port_regroupements_admin.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_horloge/apercu_creneau.dart';
import 'package:rewayah_academy/core/tc_horloge/creneau_chez_moi.dart';
import 'package:rewayah_academy/core/tc_horloge/fuseaux_interlocuteurs.dart';
import 'package:rewayah_academy/core/tc_horloge/mon_horloge.dart';
import 'package:rewayah_academy/core/widgets/menu_actions.dart';
import 'package:rewayah_academy/features/admin_groupes/feuille_reglages_classe.dart';

import '../features/support_form_l2.dart';
import '../router/support_routeur.dart' hide stabiliser;
import '../support/demo/classes_admin_demo.dart';
import '../support/demo/pilotage_demo.dart';
import '../support/demo/regroupements_demo.dart';
import '../support/harnais.dart';
import 'outil_capture.dart';

const Map<String, Object?> _paris = <String, Object?>{
  'fuseau': 'Europe/Paris',
  'decalage_secondes': 3600,
  'prochain_changement': '2027-03-28T01:00:00Z',
  'decalage_apres': 7200,
  'changement_suivant': '2027-10-31T01:00:00Z',
};
const Map<String, Object?> _riyad = <String, Object?>{
  'fuseau': 'Asia/Riyadh',
  'decalage_secondes': 10800,
  'prochain_changement': null,
};

// Jeudi 12/11/2026, 22:00 UTC (l'hiver) : une classe du mercredi 21 h a La
// Mecque est a 19 h a Paris.
final DateTime _maintenant = DateTime.utc(2026, 11, 12, 22);

final MonHorloge _lecture = MonHorloge.lire(<String, Object?>{
  'maintenant': '2026-11-12T22:00:00Z',
  'moi': _paris,
  'academie': _riyad,
});

class _PortFuseaux implements PortFuseauVu {
  const _PortFuseaux();

  @override
  Future<FuseauVu?> lire(String fuseau) async => FuseauVu.lire(
    <String, Map<String, Object?>>{
      'Asia/Riyadh': _riyad,
      'Europe/Paris': _paris,
    }[fuseau],
  );
}

class _PortApercu implements PortApercuCreneau {
  @override
  Future<ApercuCreneau?> lire({
    required String fuseau,
    required int jour,
    required int heure,
    String? fuseauCreneau,
  }) async {
    // L'equivalent a La Mecque d'un mercredi 19:00 a Paris : 21:00.
    if (fuseau == 'Asia/Riyadh') {
      return ApercuCreneau.lire(<String, Object?>{
        'jour_maintenant': 3,
        'maintenant': '21:00',
        'meme': true,
      });
    }
    return ApercuCreneau.lire(<String, Object?>{
      'jour_maintenant': 3,
      'maintenant': '19:00',
      'meme': false,
      'date_changement': '2027-03-28',
      'jour_apres': 3,
      'heure_apres': '20:00',
    });
  }
}

class _FauxCreneaux implements ServiceCreneauxClasse {
  _FauxCreneaux({this.refus});

  /// Le refus que `modifier` leve quand il est pose.
  final CreneauRefuse? refus;

  @override
  Future<int> ajouter({
    required String groupeId,
    required int jour,
    required int heure,
    String? fuseau,
    String? fuseauClasse,
  }) async => 2;

  @override
  Future<List<CreneauClasse>> lister(String groupeId) async => <CreneauClasse>[
    (jour: 3, heure: 21, duree: null),
  ];

  @override
  Future<int> modifier({
    required String groupeId,
    required CreneauClasse ancien,
    required CreneauClasse nouveau,
    required String motif,
    String? fuseau,
    String? fuseauClasse,
  }) async {
    if (refus case final CreneauRefuse r) throw r;
    return 0;
  }

  @override
  Future<int> retirer({
    required String groupeId,
    required CreneauClasse creneau,
    required String motif,
  }) async => 0;

  @override
  Future<void> reglerGenre({
    required String groupeId,
    required GenreClasse genre,
    required String motif,
  }) async {}
}

class _GroupesAdmin extends FauxGroupesFormL2 {
  @override
  Future<List<GroupeAdmin>> groupes() async => const <GroupeAdmin>[
    GroupeAdmin(
      id: 'g1',
      libelle: 'An-Nour',
      type: TypePublicGroupe.enfant,
      seuilMax: 5,
      teacherId: 't-amina',
      teacherIdentifiant: 'ENS-AD-001',
      teacherPrenom: 'Amina',
      teacherNom: 'Diallo',
      creneau: Creneau(jour: 3, heure: 21, fuseau: 'Asia/Riyadh'),
      nombreMembres: 2,
      actif: true,
    ),
  ];
}

class _Direction implements PortLieuDirection {
  @override
  Future<List<ChangementHeureAVenir>> changementsHeure({
    int jours = 60,
  }) async => <ChangementHeureAVenir>[
    ChangementHeureAVenir(
      fuseau: 'Europe/Paris',
      transition: DateTime.utc(2027, 3, 28, 1),
      decalageAvant: const Duration(hours: 1),
      decalageApres: const Duration(hours: 2),
      familles: 12,
      enseignants: 3,
    ),
  ];

  @override
  Future<List<LieuEnseignantDirection>> lieux() async =>
      const <LieuEnseignantDirection>[
        LieuEnseignantDirection(
          profilId: 't-amina',
          ville: 'Conakry',
          paysCode: 'GN',
          verifie: false,
        ),
        LieuEnseignantDirection(
          profilId: 't-yacine',
          ville: 'Paris',
          paysCode: 'FR',
          verifie: true,
        ),
      ];

  @override
  Future<List<IncoherenceLieu>> incoherences() async => const <IncoherenceLieu>[
    IncoherenceLieu(
      profilId: 't-attente',
      enseignant: 'Karim Ouali',
      type: TypeIncoherenceLieu.sansVille,
    ),
  ];

  @override
  Future<void> verifier(String profilId) async {}
}

List<Override> _horloges() {
  poserMonHorlogePourTest(_lecture);
  poserHorlogeCreneauxPourTest(() => _maintenant);
  return <Override>[
    // Hors Supabase, la vraie lecture rendrait null et viderait la lecture posee.
    monHorlogeProvider.overrideWith((Ref ref) async => _lecture),
    portFuseauVuProvider.overrideWithValue(const _PortFuseaux()),
    portApercuCreneauProvider.overrideWithValue(_PortApercu()),
  ];
}

/// Tout ce qu'un montage a besoin de savoir pour une capture.
typedef _Montage = ({ThemeMode theme, TextDirection direction, Size taille});

Future<void> _presser(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

/// L'ecran Classes de la direction, la Classe « An-Nour » a La Mecque.
Future<void> _monterClasses(
  WidgetTester tester,
  _Montage m, {
  CreneauRefuse? refus,
}) async {
  await monterRouteur(
    tester,
    Routes.adminOperationsGroupes,
    source: FausseSourceSession(sessionActive(AppRole.admin)),
    taille: m.taille,
    themeMode: m.theme,
    direction: m.direction,
    surcharges: <Override>[
      ...surchargesFormL2(
        comptes: FauxComptesFormL2(comptesFormL2),
        groupes: _GroupesAdmin(),
      ),
      portEnseignantsClasseProvider.overrideWithValue(
        FauxEnseignantsClasse(const []),
      ),
      portCreationClasseProvider.overrideWithValue(FauxCreationClasse()),
      serviceCreneauxClasseProvider.overrideWithValue(
        _FauxCreneaux(refus: refus),
      ),
      ..._horloges(),
    ],
  );
  await tester.pumpAndSettle();
}

Future<void> _ouvrirReglages(WidgetTester tester) async {
  await _presser(
    tester,
    find.byWidgetPredicate(
      (Widget w) => w is MenuActions && (w.objet ?? '').contains('An-Nour'),
    ),
  );
  await _presser(tester, find.text(t.admin.groupes.reglagesClasse.action).last);
}

Future<void> _feuilleCreneau(WidgetTester tester, _Montage m) async {
  await _monterClasses(tester, m);
  await _ouvrirReglages(tester);
  await _presser(
    tester,
    find.byKey(const ValueKey<String>('reglages-ajouter-creneau')),
  );
  await _presser(tester, find.byKey(const ValueKey<String>('creneau-jour-3')));
  await _presser(tester, find.byKey(const ValueKey<String>('creneau-heure')));
  await _presser(
    tester,
    find.text(t.admin.groupes.formulaire.heureValeur(heure: '19')).last,
  );
}

Future<void> _feuilleReglages(WidgetTester tester, _Montage m) async {
  await _monterClasses(tester, m);
  await _ouvrirReglages(tester);
}

Future<void> _feuilleReglagesRefus(WidgetTester tester, _Montage m) async {
  await _monterClasses(
    tester,
    m,
    refus: const CreneauRefuse(MotifRefusCreneau.rechargerApplication),
  );
  await _ouvrirReglages(tester);
  await _presser(
    tester,
    find
        .descendant(
          of: find.byType(FeuilleReglagesClasse),
          matching: find.byType(MenuActions),
        )
        .first,
  );
  final r = t.admin.groupes.reglagesClasse;
  await _presser(tester, find.text(r.modifierCreneau).last);
  // Le serveur refuse le geste complet : un jour, une heure, un motif.
  await _presser(tester, find.byKey(const ValueKey<String>('reglages-jour-3')));
  await _presser(tester, find.byKey(const ValueKey<String>('reglages-heure')));
  await _presser(
    tester,
    find.text(t.admin.groupes.formulaire.heureValeur(heure: '19')).last,
  );
  await tester.enterText(
    find.byKey(const ValueKey<String>('reglages-motif')),
    m.direction == TextDirection.rtl ? 'تغيير الوقت' : 'Changement de créneau',
  );
  await tester.pumpAndSettle();
  await _presser(tester, find.text(r.envoyerModifier).last);
}

Future<void> _ficheClasse(WidgetTester tester, _Montage m) async {
  await monterRouteur(
    tester,
    Routes.groupePour('g1'),
    source: FausseSourceSession(sessionActive(AppRole.teacher)),
    taille: m.taille,
    themeMode: m.theme,
    direction: m.direction,
    enseignant: FauxServiceEnseignant()
      ..groupesRendus = <GroupeEnseignant>[
        GroupeEnseignant(
          id: 'g1',
          libelle: 'An-Nour',
          type: TypePublicGroupe.enfant,
          seuilMax: 5,
          creneau: const Creneau(jour: 3, heure: 21, fuseau: 'Asia/Riyadh'),
          nbMembres: 2,
          creeLe: DateTime(2026, 9),
        ),
      ],
    surcharges: _horloges(),
  );
  await tester.pumpAndSettle();
}

/// Les trois ports de la demonstration d'administration, sans grand volume.
({
  RegroupementsDemo regroupements,
  ClassesAdminDemo classes,
  PilotageDemo pilotage,
})
_demos() {
  final RegroupementsDemo regroupements = RegroupementsDemo();
  final ClassesAdminDemo classes = ClassesAdminDemo(
    classes: familleDemo(),
    enseignantAffecte: (String id) => regroupements.enseignantDe[id],
  );
  final PilotageDemo pilotage = PilotageDemo(
    classes: classes.toutes,
    regroupements: regroupements.regroupements,
  );
  return (regroupements: regroupements, classes: classes, pilotage: pilotage);
}

Future<void> _monterAdminDemo(
  WidgetTester tester,
  _Montage m,
  String route,
) async {
  final d = _demos();
  await monterRouteur(
    tester,
    route,
    source: FausseSourceSession(sessionActive(AppRole.admin)),
    taille: m.taille,
    themeMode: m.theme,
    direction: m.direction,
    surcharges: <Override>[
      portPilotageProvider.overrideWithValue(d.pilotage),
      portClassesAdminProvider.overrideWithValue(d.classes),
      portRegroupementsAdminProvider.overrideWithValue(d.regroupements),
      portRegroupementsPagesProvider.overrideWithValue(d.regroupements),
      ..._horloges(),
    ],
  );
  await tester.pumpAndSettle();
}

Future<void> _pilotage(WidgetTester tester, _Montage m) =>
    _monterAdminDemo(tester, m, Routes.adminOperationsPilotage);

Future<void> _regroupements(WidgetTester tester, _Montage m) =>
    _monterAdminDemo(tester, m, Routes.adminOperationsRegroupements);

Future<void> _monterComptes(WidgetTester tester, _Montage m) async {
  await monterRouteur(
    tester,
    '${Routes.adminPersonnesComptes}?vue=enseignants',
    source: FausseSourceSession(sessionActive(AppRole.admin)),
    taille: m.taille,
    themeMode: m.theme,
    direction: m.direction,
    surcharges: <Override>[
      ...surchargesFormL2(comptes: FauxComptesFormL2(comptesFormL2)),
      portLieuDirectionProvider.overrideWithValue(_Direction()),
    ],
  );
  await tester.pumpAndSettle();
}

Future<void> _comptesVilles(WidgetTester tester, _Montage m) =>
    _monterComptes(tester, m);

Future<void> _comptesVerifierVille(WidgetTester tester, _Montage m) async {
  await _monterComptes(tester, m);
  await _presser(
    tester,
    find.byWidgetPredicate(
      (Widget w) => w is MenuActions && w.objet == 'Amina Diallo',
    ),
  );
}

void main() {
  group(
    'Capture : HORLOGE-ET-LIEU, ecrans de la direction',
    skip: sautSansCapture,
    () {
      setUpAll(() async {
        await chargerPolicesDuDepot();
        await LocaleSettings.setLocale(AppLocale.ar);
        await LocaleSettings.setLocale(AppLocale.fr);
      });
      tearDown(() {
        poserMonHorlogePourTest(null);
        poserHorlogeCreneauxPourTest(null);
        viderFuseauxLusPourTest();
      });

      // (nom, hauteur a 390, hauteur a 1440, montage)
      final List<
        (String, double, double, Future<void> Function(WidgetTester, _Montage))
      >
      ecrans =
          <
            (
              String,
              double,
              double,
              Future<void> Function(WidgetTester, _Montage),
            )
          >[
            ('feuille_creneau', 1100, 900, _feuilleCreneau),
            ('feuille_reglages', 1000, 900, _feuilleReglages),
            ('feuille_reglages_refus', 1100, 1000, _feuilleReglagesRefus),
            ('fiche_classe', 1100, 900, _ficheClasse),
            ('pilotage', 1500, 1100, _pilotage),
            ('regroupements', 1500, 1100, _regroupements),
            ('comptes_villes', 1500, 1000, _comptesVilles),
            ('comptes_verifier_ville', 1300, 900, _comptesVerifierVille),
          ];

      for (final (
            String nom,
            double h390,
            double h1440,
            Future<void> Function(WidgetTester, _Montage) monter,
          )
          in ecrans) {
        for (final double largeur in <double>[390, 1440]) {
          for (final bool clair in <bool>[true, false]) {
            for (final bool arabe in <bool>[false, true]) {
              final String fichier =
                  'horloge_lieu_${nom}_${largeur.toInt()}_'
                  '${clair ? 'clair' : 'sombre'}_${arabe ? 'ar' : 'fr'}';
              testWidgets(fichier, (WidgetTester tester) async {
                LocaleSettings.setLocaleSync(
                  arabe ? AppLocale.ar : AppLocale.fr,
                );
                addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
                masquerRubanDebug();
                await monter(tester, (
                  theme: clair ? ThemeMode.light : ThemeMode.dark,
                  direction: arabe ? TextDirection.rtl : TextDirection.ltr,
                  taille: Size(largeur, largeur > 600 ? h1440 : h390),
                ));
                await stabiliser(tester);
                debugPrint('PNG ${await capturerVue(tester, fichier)}');
              });
            }
          }
        }
      }
    },
  );
}
