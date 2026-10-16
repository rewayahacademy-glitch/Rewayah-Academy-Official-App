// Captures de recette PED-APRES-1 (spec V1 du 11/10/2026, etape 4) :
//
// - TUT-PED-APR-01 : le detail de seance du tuteur sur le VRAI routeur et la
//   vraie coquille (390x844), clair et sombre, dans ses etats : compte rendu
//   partage, partage desactive, cahier en attente, source indisponible
//   (production), hors ligne ;
// - ADM-PED-APR-02 : l'inspecteur de la fiche de classe a 1440x900 avec le
//   groupe de partage, la feuille des exceptions ;
// - ADM-PED-APR-03 : l'apercu familial et le partage manuel (1440x900), dans
//   trois etats.
//
// Saute sans CAPTURE_DIR. Donnees : le simulateur de test, jamais une donnee
// reelle. Mode d'emploi : `test/capture/LISEZ-MOI.md`.
//
//   CAPTURE_DIR=docs/current/captures/PED-APRES-1 \
//     flutter test test/capture/ped_apres_1_capture_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/admin/service_groupes.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/port_partage_pedagogique.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart'
    show Creneau;
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/features/admin_groupes/apercu_familial.dart';
import 'package:rewayah_academy/features/admin_groupes/groupes_page.dart';

import '../features/historique/support_historique.dart';
import '../fixtures/ped_apres/faux_partage_pedagogique.dart';
import '../router/support_routeur.dart' show stabiliser;
import '../support/harnais.dart' show sansPersonneConnectee;
import 'outil_capture.dart'
    show
        cadreCapture,
        capturer,
        chargerPolicesDuDepot,
        fixerVueCapture,
        hoteCapture,
        sautSansCapture;

const String _a1 = 'foyer-a-eleve-1';

FauxPartagePedagogique _serveur() => FauxPartagePedagogique()
  ..rapports[('s-presente', _a1)] = RapportSim()
  ..rapports[('s1', 'e1')] = RapportSim()
  ..rapports[('s2', 'e1')] = RapportSim(autoPartage: false)
  ..regles['e2'] = ReglePartageEleve.toujours
  ..regles['e3'] = ReglePartageEleve.jamais;

Future<void> _tuteur(
  WidgetTester tester,
  String nom, {
  required ThemeMode mode,
  required PortPartagePedagogique? port,
  bool horsLigne = false,
}) async {
  fixerVueCapture(tester, const Size(390, 1500), 2);
  final GoRouter routeur = await monterHistorique(
    tester,
    taille: null,
    mode: mode,
    horsLigne: horsLigne,
    cadre: cadreCapture,
    autres: <Override>[
      if (port != null) portPartagePedagogiqueProvider.overrideWithValue(port),
    ],
  );
  routeur.go('${Routes.seancePour('s-presente')}?eleve=$_a1');
  await stabiliser(tester);
  debugPrint('PNG ${await capturer(tester, nom)}');
}

class _Groupes implements ServiceGroupes {
  GroupeAdmin _g(String id, String libelle) => GroupeAdmin(
    id: id,
    libelle: libelle,
    type: TypePublicGroupe.enfant,
    seuilMax: 5,
    teacherId: 't-$id',
    teacherIdentifiant: 'TEACHER-$id',
    teacherPrenom: 'Amina',
    teacherNom: 'Diallo',
    creneau: const Creneau(jour: 2, heure: 17, fuseau: 'Europe/Paris'),
    nombreMembres: 3,
    actif: true,
  );

  @override
  Future<List<GroupeAdmin>> groupes() async => <GroupeAdmin>[
    _g('a', 'Classe An-Nour'),
    _g('b', 'Classe Al-Furqan'),
  ];

  @override
  Future<List<MembreGroupe>> membres(String groupeId) async => <MembreGroupe>[
    for (final (String, String, String) m in <(String, String, String)>[
      ('e1', 'Yusuf', 'Ahmad'),
      ('e2', 'Mariam', 'Ali'),
      ('e3', 'Adam', 'Hassan'),
    ])
      MembreGroupe(
        studentId: m.$1,
        identifiant: 'STUDENT-${m.$1}',
        prenom: m.$2,
        nom: m.$3,
        rejointLe: DateTime(2026, 9, 1),
      ),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

List<Override> _surchargesAdmin(PortPartagePedagogique port) => <Override>[
  portPartagePedagogiqueProvider.overrideWithValue(port),
  serviceGroupesProvider.overrideWithValue(_Groupes()),
  sansPersonneConnectee(),
];

Future<void> _admin(
  WidgetTester tester,
  String nom, {
  required ThemeMode mode,
  required FauxPartagePedagogique serveur,
  bool exceptions = false,
}) async {
  fixerVueCapture(tester, const Size(1440, 1500), 1);
  await tester.pumpWidget(
    hoteCapture(
      const GroupesPage(),
      surcharges: _surchargesAdmin(serveur),
      themeMode: mode,
    ),
  );
  await stabiliser(tester);
  await tester.tap(find.text('Classe An-Nour').first);
  await stabiliser(tester);
  if (exceptions) {
    await tester.ensureVisible(
      find.text(t.admin.groupes.partage.gererExceptions),
    );
    await tester.tap(find.text(t.admin.groupes.partage.gererExceptions));
    await stabiliser(tester);
  }
  debugPrint('PNG ${await capturer(tester, nom)}');
}

Future<void> _apercu(
  WidgetTester tester,
  String nom, {
  required ThemeMode mode,
  required FauxPartagePedagogique serveur,
}) async {
  fixerVueCapture(tester, const Size(1440, 1000), 1);
  await tester.pumpWidget(
    hoteCapture(
      Builder(
        builder: (BuildContext c) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ouvrirApercuFamilial(c, seanceId: 's1', eleveId: 'e1');
          });
          return const Scaffold(body: SizedBox.expand());
        },
      ),
      surcharges: <Override>[
        portPartagePedagogiqueProvider.overrideWithValue(serveur),
        sansPersonneConnectee(),
      ],
      themeMode: mode,
    ),
  );
  await stabiliser(tester);
  await stabiliser(tester);
  debugPrint('PNG ${await capturer(tester, nom)}');
}

void main() {
  group('Capture : PED-APRES-1', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      final String m = mode == ThemeMode.light ? 'clair' : 'sombre';

      testWidgets('tuteur mobile : partage ($m)', (WidgetTester tester) async {
        await _tuteur(
          tester,
          'tuteur_mobile_partage_$m',
          mode: mode,
          port: _serveur(),
        );
      });
      testWidgets('tuteur mobile : partage desactive ($m)', (
        WidgetTester tester,
      ) async {
        await _tuteur(
          tester,
          'tuteur_mobile_desactive_$m',
          mode: mode,
          port: _serveur()..regles[_a1] = ReglePartageEleve.jamais,
        );
      });
      testWidgets('tuteur mobile : cahier en attente ($m)', (
        WidgetTester tester,
      ) async {
        await _tuteur(
          tester,
          'tuteur_mobile_attente_$m',
          mode: mode,
          port: _serveur()..rapports[('s-presente', _a1)]!.confirme = false,
        );
      });
      testWidgets('tuteur mobile : source indisponible, production ($m)', (
        WidgetTester tester,
      ) async {
        await _tuteur(
          tester,
          'tuteur_mobile_indisponible_$m',
          mode: mode,
          port: null,
        );
      });
      testWidgets('tuteur mobile : hors ligne ($m)', (
        WidgetTester tester,
      ) async {
        await _tuteur(
          tester,
          'tuteur_mobile_horsligne_$m',
          mode: mode,
          port: _serveur(),
          horsLigne: true,
        );
      });

      testWidgets('web politique : inspecteur ($m)', (
        WidgetTester tester,
      ) async {
        await _admin(
          tester,
          'web_politique_$m',
          mode: mode,
          serveur: _serveur(),
        );
      });
      testWidgets('web politique : classe desactivee ($m)', (
        WidgetTester tester,
      ) async {
        await _admin(
          tester,
          'web_politique_desactivee_$m',
          mode: mode,
          serveur: _serveur()..classeActive = false,
        );
      });
      testWidgets('web politique : sans source, production ($m)', (
        WidgetTester tester,
      ) async {
        await _admin(
          tester,
          'web_politique_indisponible_$m',
          mode: mode,
          serveur: _SansSource(),
        );
      });
      testWidgets('web politique : exceptions ($m)', (
        WidgetTester tester,
      ) async {
        await _admin(
          tester,
          'web_exceptions_$m',
          mode: mode,
          serveur: _serveur(),
          exceptions: true,
        );
      });

      testWidgets('web apercu : confirme non partage ($m)', (
        WidgetTester tester,
      ) async {
        await _apercu(
          tester,
          'web_apercu_nonpartage_$m',
          mode: mode,
          serveur: _serveur()..classeActive = false,
        );
      });
      testWidgets('web apercu : partage automatiquement ($m)', (
        WidgetTester tester,
      ) async {
        await _apercu(
          tester,
          'web_apercu_partage_$m',
          mode: mode,
          serveur: _serveur(),
        );
      });
      testWidgets('web apercu : cahier non valide ($m)', (
        WidgetTester tester,
      ) async {
        await _apercu(
          tester,
          'web_apercu_nonvalide_$m',
          mode: mode,
          serveur: _serveur()..rapports[('s1', 'e1')]!.confirme = false,
        );
      });
    }
  });
}

/// Un serveur sans aucune source : la production.
class _SansSource extends FauxPartagePedagogique {
  _SansSource() {
    erreurs['partageClasse'] = const CapaciteIndisponible('PED-APRES-BACK');
  }
}
