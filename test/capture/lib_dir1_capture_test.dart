// Captures de recette de LIB-DIR-1 (decisions du 05/10, par delegation du
// directeur) : vraies polices, vrai theme, clair.
//
// - Journee enseignant a 320 x2 : la carte « A terminer » (pastille
//   « Obligatoire »), avec 1 et 4 cahiers ; la journee de la demonstration
//   (ruban compris) ; la page « A terminer » vide (« cahier de
//   transmission ») ; le cahier (titre « Cahier de transmission »).
//   Aucun mot coupe, aucun debordement.
// - Administration a 390 et 1440 : Comptes (pastille « En attente » des
//   seuls enseignants) et Classes (titre de la page).
//
// Saute sans CAPTURE_DIR (voir `test/capture/LISEZ-MOI.md`). Donnees
// synthetiques.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/service_comptes.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/enseignant/depot_cahiers.dart';
import 'package:rewayah_academy/core/enseignant/modeles_enseignant.dart';
import 'package:rewayah_academy/core/enseignant/service_enseignant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/matching/service_matching.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/priere/service_priere.dart';
import 'package:rewayah_academy/core/regles/service_regles.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/video/pre_vol.dart';
import 'package:rewayah_academy/features/admin_comptes/comptes_page.dart';
import 'package:rewayah_academy/features/admin_groupes/groupes_page.dart';
import 'package:rewayah_academy/features/cahier/cahier_page.dart';
import 'package:rewayah_academy/features/cahier/vue_cahier.dart';
import 'package:rewayah_academy/features/demo/demo_enseignant_page.dart';
import 'package:rewayah_academy/features/demo/enseignant_demo.dart';
import 'package:rewayah_academy/features/journee/journee_page.dart';

import '../features/support_form_l2.dart';
import '../support/aucun_mot_coupe.dart';
import '../support/harnais.dart';
import 'outil_capture.dart';

const SessionState _session = SessionState(
  resolue: true,
  role: AppRole.teacher,
  profileId: 't1',
  accountStatus: AccountStatus.active,
  lectureProfil: LectureProfil.presente,
);

CahierEnRetard _cahier(String id, String classe, int jour) => CahierEnRetard(
  seanceId: id,
  debut: DateTime(2026, 9, jour, 17),
  fin: DateTime(2026, 9, jour, 17, 45),
  nbParticipants: 3,
  heuresDeRetard: 30,
  groupeId: 'g-$id',
  groupeLibelle: classe,
);

final List<CahierEnRetard> _quatre = <CahierEnRetard>[
  _cahier('a', 'Al-Badr', 26),
  _cahier('b', 'As-Salam', 25),
  _cahier('c', 'Al-Fatiha', 23),
  _cahier('d', 'Al-Ikhlas', 22),
];

List<Override> _surchargesJournee(List<CahierEnRetard> retards) => <Override>[
  sourceSessionProvider.overrideWithValue(FausseSourceSession(_session)),
  serviceEnseignantProvider.overrideWithValue(
    FauxServiceEnseignant()
      ..seancesRendues = <SeanceEnseignant>[
        seanceDeTest(
          id: 'an-nour',
          debut: DateTime(2026, 9, 28, 17, 30),
          nbParticipants: 4,
          groupeId: 'g-an-nour',
          groupeLibelle: 'An-Nour',
        ),
      ]
      ..retardsRendus = retards,
  ),
  serviceMatchingProvider.overrideWithValue(FauxServiceMatching()),
  serviceReglesProvider.overrideWithValue(FauxServiceRegles()),
  servicePriereProvider.overrideWithValue(FauxServicePriere()),
  servicePreVolProvider.overrideWithValue(FauxServicePreVol()),
  servicePresenceProvider.overrideWithValue(FauxServicePresence()),
  serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
  maintenantJourneeProvider.overrideWithValue(() => DateTime(2026, 9, 28, 16)),
];

class _Comptes implements ServiceComptes {
  const _Comptes(this._l);
  final List<CompteAdmin> _l;
  @override
  Future<List<CompteAdmin>> comptes() async => _l;
}

CompteAdmin _compte(String id, AppRole? role, AccountStatus etat, String? p) =>
    CompteAdmin(
      profilId: id,
      identifiant: id,
      prenom: p,
      nom: p == null ? null : 'Sow',
      role: role,
      etat: etat,
      inscritLe: DateTime.now().subtract(const Duration(days: 4)),
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
      _compte(
        'TEACHER-AS-000001',
        AppRole.teacher,
        AccountStatus.pendingKyc,
        'Aicha',
      ),
      _compte(
        'TEACHER-IB-000002',
        AppRole.teacher,
        AccountStatus.pendingKyc,
        'Ibrahim',
      ),
      _compte(
        'GUARDIAN-MS-000003',
        AppRole.guardian,
        AccountStatus.pendingKyc,
        'Mariam',
      ),
      _compte(
        'GUARDIAN-YB-000004',
        AppRole.guardian,
        AccountStatus.pendingKyc,
        'Youssef',
      ),
      _compte(
        'STUDENT-LS-000001',
        AppRole.student,
        AccountStatus.active,
        'Lina',
      ),
    ]),
  ),
  serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
];

/// Echoue en nommant les mots coupes sous [ou] (traits d'union permis :
/// « Al- / Badr »).
void _sansCoupure(WidgetTester tester, Finder ou) {
  final List<String> fautes = motsCoupes(tester, ou, traitDUnionPermis: true);
  if (fautes.isNotEmpty) {
    debugPrint('FAUTES ${fautes.toSet().join(' | ')}');
  }
  expect(fautes, isEmpty, reason: 'Un mot coupe ou tronque');
}

void main() {
  group('Capture : LIB-DIR-1', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final int nombre in const <int>[1, 4]) {
      testWidgets('journee, A terminer, $nombre cahier(s), 320 x2', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, const Size(320, 900), 1);
        await tester.pumpWidget(
          hoteCapture(
            const JourneePage(),
            surcharges: _surchargesJournee(_quatre.take(nombre).toList()),
            echelleTexte: 2,
          ),
        );
        await stabiliser(tester);
        expect(tester.takeException(), isNull);
        final Finder titre = find.text(t.enseignant.journee.aTerminer);
        await tester.ensureVisible(titre);
        await stabiliser(tester);
        final Finder bloc = find
            .ancestor(of: titre, matching: find.byType(Column))
            .first;
        expect(
          find.descendant(
            of: bloc,
            matching: find.text(t.enseignant.cahier.obligatoire),
          ),
          findsOneWidget,
        );
        _sansCoupure(tester, bloc);
        debugPrint(
          'PNG ${await capturer(tester, 'journee_a_terminer_${nombre}_320x2')}',
        );
      });
    }

    testWidgets('journee de la demonstration (ruban), 320 x2', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, const Size(320, 900), 1);
      await tester.pumpWidget(
        hoteCapture(
          const CoquilleEnseignantDemo(
            ecran: EcranDemoEnseignant.aujourdhui,
            etat: EtatDemoEnseignant.nominal,
          ),
          echelleTexte: 2,
        ),
      );
      await stabiliser(tester);
      expect(tester.takeException(), isNull);
      final Finder titre = find.text(t.enseignant.journee.aTerminer);
      await tester.ensureVisible(titre);
      await stabiliser(tester);
      expect(tester.takeException(), isNull);
      _sansCoupure(
        tester,
        find.ancestor(of: titre, matching: find.byType(Column)).first,
      );
      debugPrint('PNG ${await capturer(tester, 'journee_demo_320x2')}');
    });

    testWidgets('page A terminer vide, 320 x2', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(320, 900), 1);
      await tester.pumpWidget(
        hoteCapture(
          const ListeATerminerPage(),
          surcharges: <Override>[
            ..._surchargesJournee(const <CahierEnRetard>[]),
            cahiersEnRetardProvider.overrideWith(
              (Ref _) async => const <CahierEnRetard>[],
            ),
          ],
          echelleTexte: 2,
        ),
      );
      await stabiliser(tester);
      expect(
        find.text('Tous vos cahiers de transmission sont terminés.'),
        findsOneWidget,
      );
      _sansCoupure(tester, find.byKey(cadreCapture));
      debugPrint('PNG ${await capturer(tester, 'a_terminer_vide_320x2')}');
    });

    testWidgets('cahier de transmission, titre, 320 x2', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, const Size(320, 900), 1);
      await tester.pumpWidget(
        hoteCapture(
          const CahierPage(seanceId: DonneesEnseignantDemo.cahierDemoSeanceId),
          surcharges: <Override>[
            ...surchargesCoquilleEnseignantDemo(EtatDemoEnseignant.nominal),
            soumissionCahierProvider.overrideWithValue(
              const SoumissionCahierDemo(),
            ),
            horlogeCahierProvider.overrideWithValue(
              () => DonneesEnseignantDemo.maintenant,
            ),
            depotRapportsProvider.overrideWithValue(FauxDepotRapports()),
          ],
          echelleTexte: 2,
        ),
      );
      await stabiliser(tester);
      expect(tester.takeException(), isNull);
      final Finder titre = find.text(t.enseignant.cahier.titre);
      expect(titre, findsWidgets);
      _sansCoupure(tester, titre.first);
      debugPrint('PNG ${await capturer(tester, 'cahier_titre_320x2')}');
    });

    for (final (String, Size) vue in const <(String, Size)>[
      ('390', Size(390, 900)),
      ('1440', Size(1440, 900)),
    ]) {
      testWidgets('comptes, ${vue.$1}', (WidgetTester tester) async {
        fixerVueCapture(tester, vue.$2, 1);
        await tester.pumpWidget(
          hoteCapture(const ComptesPage(), surcharges: _surchargesComptes()),
        );
        await stabiliser(tester);
        expect(tester.takeException(), isNull);
        debugPrint('PNG ${await capturer(tester, 'comptes_${vue.$1}')}');
      });

      testWidgets('classes, ${vue.$1}', (WidgetTester tester) async {
        fixerVueCapture(tester, vue.$2, 1);
        await tester.pumpWidget(
          hoteCapture(
            const GroupesPage(),
            surcharges: surchargesFormL2(
              comptes: FauxComptesFormL2(comptesFormL2),
            ),
          ),
        );
        await stabiliser(tester);
        expect(tester.takeException(), isNull);
        expect(find.text('Classes'), findsWidgets);
        debugPrint('PNG ${await capturer(tester, 'classes_${vue.$1}')}');
      });
    }
  });
}
