// Captures de recette FILTERPILL-ETAT-1 : l'etat retenu d'une `FilterPill`
// porte une coche en plus de la couleur. Deux ecrans reels : la feuille
// « Ajouter une plage » de `CreneauxPage` (raccourci « Week-end » touche :
// Samedi et Dimanche retenus, puis Lundi) et la page admin `ComptesPage`
// (« Tous » retenu, puis « En attente »). 320 x2, 390, 1440, clair et sombre ;
// une capture RTL de la page admin (la feuille de plage s'ouvre dans une
// route modale que l'enveloppe `Directionality` n'atteint pas : son RTL est
// prouve par `test/core/widgets/filter_pill_test.dart`). Service en memoire, vraies polices.
//
// Saute sans CAPTURE_DIR (voir `test/capture/LISEZ-MOI.md`). Nommage :
// filterpill_<ecran>_<largeur>_x<echelle>_<mode>[_rtl].png.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/service_comptes.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/matching/service_matching.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/regles/service_regles.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/features/admin_comptes/comptes_page.dart';
import 'package:rewayah_academy/features/creneaux/creneaux_page.dart';

import '../support/harnais.dart';
import 'outil_capture.dart';

const String _monId = 't1';

List<Creneau> _plage(int jour, int de, int a) => <Creneau>[
  for (int h = de; h < a; h++)
    Creneau(jour: jour, heure: h, fuseau: 'Europe/Paris'),
];

List<Override> _surcharges() => <Override>[
  sourceSessionProvider.overrideWithValue(
    FausseSourceSession(
      const SessionState(
        resolue: true,
        role: AppRole.teacher,
        profileId: _monId,
        accountStatus: AccountStatus.active,
        lectureProfil: LectureProfil.presente,
      ),
    ),
  ),
  serviceMatchingProvider.overrideWithValue(FauxServiceMatching()),
  servicePlanningProvider.overrideWithValue(
    FauxServicePlanning()
      ..creneaux[_monId] = <Creneau>[
        ..._plage(1, 17, 23),
        ..._plage(3, 9, 12),
        ..._plage(3, 18, 21),
        ..._plage(4, 9, 11),
        ..._plage(6, 8, 12),
        ..._plage(7, 8, 12),
      ],
  ),
  serviceReglesProvider.overrideWithValue(FauxServiceRegles()),
  serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
];

class _Comptes implements ServiceComptes {
  const _Comptes(this._l);
  final List<CompteAdmin> _l;
  @override
  Future<List<CompteAdmin>> comptes() async => _l;
}

CompteAdmin _c(String id, AppRole role, AccountStatus etat, String prenom) =>
    CompteAdmin(
      profilId: id,
      identifiant: id,
      prenom: prenom,
      nom: 'Sow',
      role: role,
      etat: etat,
      inscritLe: DateTime(2026, 10, 1),
      accesJusquAu: null,
      foyerId: null,
      piece: EtatPiece.aucune,
      contrats: 2,
      aEnseignant: false,
      enfantsDuFoyer: 0,
    );

List<Override> _surchargesComptes() => <Override>[
  serviceComptesProvider.overrideWithValue(
    _Comptes(<CompteAdmin>[
      _c(
        'GUARDIAN-MS-000003',
        AppRole.guardian,
        AccountStatus.pendingKyc,
        'Mariam',
      ),
      _c('STUDENT-LS-000001', AppRole.student, AccountStatus.active, 'Lina'),
      _c(
        'TEACHER-AS-000001',
        AppRole.teacher,
        AccountStatus.pendingKyc,
        'Aicha',
      ),
      _c('TEACHER-OB-000002', AppRole.teacher, AccountStatus.active, 'Omar'),
    ]),
  ),
  serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
];

const List<(Size, double, double, String)> _cadres =
    <(Size, double, double, String)>[
      (Size(320, 2600), 2, 2, '320_x2'),
      (Size(390, 844), 2, 1, '390_x1'),
      (Size(1440, 900), 1, 1, '1440_x1'),
    ];

void main() {
  group('Capture : FILTERPILL-ETAT-1', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
    });

    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      for (final (Size taille, double densite, double echelle, String nom)
          in _cadres) {
        final String suffixe = '${nom}_${mode.name}';

        testWidgets('plage $suffixe', (WidgetTester tester) async {
          fixerVueCapture(tester, taille, densite);
          await tester.pumpWidget(
            hoteCapture(
              const CreneauxPage(),
              themeMode: mode,
              echelleTexte: echelle,
              surcharges: _surcharges(),
            ),
          );
          await stabiliser(tester);
          final Finder ajouter = find.text(t.enseignant.creneaux.ajouterPlage);
          await tester.ensureVisible(ajouter);
          await stabiliser(tester);
          await tester.tap(ajouter);
          await stabiliser(tester);
          await tester.tap(find.text(t.enseignant.creneaux.raccourciWeekEnd));
          await stabiliser(tester);
          await tester.tap(find.text('Lundi').last);
          await stabiliser(tester);
          expect(tester.takeException(), isNull);
          // ignore: avoid_print
          print('PNG ${await capturer(tester, 'filterpill_plage_$suffixe')}');
        });

        testWidgets('comptes $suffixe', (WidgetTester tester) async {
          fixerVueCapture(tester, taille, densite);
          await tester.pumpWidget(
            hoteCapture(
              const ComptesPage(),
              themeMode: mode,
              echelleTexte: echelle,
              surcharges: _surchargesComptes(),
            ),
          );
          await stabiliser(tester);
          expect(tester.takeException(), isNull);
          // ignore: avoid_print
          print('PNG ${await capturer(tester, 'filterpill_comptes_$suffixe')}');
        });
      }
    }

    testWidgets('comptes 390_x1 light rtl', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(390, 844), 2);
      await tester.pumpWidget(
        hoteCapture(
          const Directionality(
            textDirection: TextDirection.rtl,
            child: ComptesPage(),
          ),
          surcharges: _surchargesComptes(),
        ),
      );
      await stabiliser(tester);
      expect(tester.takeException(), isNull);
      // ignore: avoid_print
      print(
        'PNG ${await capturer(tester, 'filterpill_comptes_390_x1_light_rtl')}',
      );
    });
  });
}
