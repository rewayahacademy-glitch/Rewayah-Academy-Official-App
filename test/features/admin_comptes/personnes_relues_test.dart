// Dette D2 (directeur, 07/11/2026) : « Dans l'admin, un profil retire reste
// affiche jusqu'a la deconnexion. » Les listes de personnes de
// l'administration sont gardees pour toute la session ; seule celle des
// comptes etait relue apres une suppression. Ce test supprime un compte
// depuis Comptes, puis verifie que chaque autre liste est relue. Sans le
// signal `personnesModifieesProvider`, chaque compteur reste a 1 (ROUGE).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/personnes_modifiees.dart';
import 'package:rewayah_academy/core/admin/service_admin.dart';
import 'package:rewayah_academy/core/admin/service_comptes.dart';
import 'package:rewayah_academy/core/admin/service_diagnostics.dart';
import 'package:rewayah_academy/core/admin/service_groupes.dart';
import 'package:rewayah_academy/core/admin/service_progression.dart';
import 'package:rewayah_academy/core/capacites/port_paiements_saisis.dart';
import 'package:rewayah_academy/core/capacites/port_remboursements_direction.dart';
import 'package:rewayah_academy/core/capacites/port_retraits_comptes.dart';
import 'package:rewayah_academy/core/capacites/port_revue_dossiers.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/widgets/menu_actions.dart';
import 'package:rewayah_academy/features/admin_comptes/comptes_page.dart';
import 'package:rewayah_academy/features/admin_dossiers/etat_file_dossiers.dart';
import 'package:rewayah_academy/features/admin_finance/paiements/paiements_page.dart'
    show elevesPourPaiementProvider;
import 'package:rewayah_academy/features/admin_finance/paiements/remboursement_direction.dart'
    show elevesRemboursablesProvider;
import 'package:rewayah_academy/features/admin_invitations/familles_importees.dart';

import '../../support/harnais.dart';

/// Compte les lectures ; la reponse n'arrive jamais (seule la relecture
/// compte ici).
class _Lectures {
  final Map<String, int> n = <String, int>{};

  Future<T> lire<T>(String quoi) {
    n[quoi] = (n[quoi] ?? 0) + 1;
    return Completer<T>().future;
  }
}

class _Comptes implements ServiceComptes {
  @override
  Future<List<CompteAdmin>> comptes() async => <CompteAdmin>[
    CompteAdmin(
      profilId: 'p-1',
      identifiant: 'STUDENT-AA-000001',
      prenom: 'Lina',
      nom: 'Diallo',
      role: AppRole.student,
      etat: AccountStatus.active,
      inscritLe: DateTime.now().subtract(const Duration(days: 10)),
      accesJusquAu: null,
      foyerId: null,
      piece: EtatPiece.aucune,
      contrats: 0,
      aEnseignant: false,
      enfantsDuFoyer: 0,
      detailsServis: true,
    ),
  ];
}

class _Retraits implements PortRetraitsComptes {
  @override
  Future<List<ResultatRetrait>> retirer(
    List<String> ids, {
    String? motif,
    bool anonymiserMaintenant = false,
  }) async => <ResultatRetrait>[
    for (final String id in ids) ResultatRetrait(id: id, retire: true),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Admin implements ServiceAdmin {
  _Admin(this.l);
  final _Lectures l;
  @override
  Future<IndicateursAdmin> indicateurs() => l.lire('indicateurs');
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Progression implements ServiceProgression {
  _Progression(this.l);
  final _Lectures l;
  @override
  Future<List<EleveProgression>> tous() => l.lire('progression');
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Diagnostics implements ServiceDiagnostics {
  _Diagnostics(this.l);
  final _Lectures l;
  @override
  Future<List<EleveADiagnostiquer>> aTraiter() => l.lire('diagnostics');
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Groupes implements ServiceGroupes {
  _Groupes(this.l);
  final _Lectures l;
  @override
  Future<List<MembreGroupe>> membres(String groupeId) => l.lire('membres');
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Paiements implements PortPaiementsSaisis {
  _Paiements(this.l);
  final _Lectures l;
  @override
  Future<List<ElevePourPaiement>> eleves() => l.lire('paiements');
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Remboursements implements PortRemboursementsDirection {
  _Remboursements(this.l);
  final _Lectures l;
  @override
  Future<Set<String>> elevesRemboursables() => l.lire('remboursements');
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Familles implements PortFamillesImportees {
  _Familles(this.l);
  final _Lectures l;
  @override
  Future<FamillesImportees> lister() => l.lire('familles');
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Dossiers implements PortRevueDossiers {
  _Dossiers(this.l);
  final _Lectures l;
  @override
  Future<PageDossiers> listerDossiers({
    String? curseur,
    int limite = 20,
    AppRole? role,
  }) => l.lire('dossiers');
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Direction extends SessionControleur {
  @override
  SessionState build() => const SessionState(
    resolue: true,
    role: AppRole.admin,
    profileId: 'p-direction',
    accountStatus: AccountStatus.active,
    lectureProfil: LectureProfil.presente,
  );
}

List<Override> _sources(_Lectures l) => <Override>[
  sessionProvider.overrideWith(_Direction.new),
  portRevueDossiersProvider.overrideWithValue(_Dossiers(l)),
  serviceAdminProvider.overrideWithValue(_Admin(l)),
  serviceProgressionProvider.overrideWithValue(_Progression(l)),
  serviceDiagnosticsProvider.overrideWithValue(_Diagnostics(l)),
  serviceGroupesProvider.overrideWithValue(_Groupes(l)),
  portPaiementsSaisisProvider.overrideWithValue(_Paiements(l)),
  portRemboursementsDirectionProvider.overrideWithValue(_Remboursements(l)),
  portFamillesImporteesProvider.overrideWithValue(_Familles(l)),
];

/// Lit chaque liste gardee pour la session.
void _lireTout(ProviderContainer c) {
  c
    ..read(indicateursProvider)
    ..read(progressionProvider)
    ..read(diagnosticsATraiterProvider)
    ..read(membresGroupeProvider('classe-1'))
    ..read(elevesPourPaiementProvider)
    ..read(elevesRemboursablesProvider)
    ..read(famillesImporteesProvider)
    ..read(fileDossiersProvider);
}

const List<String> _listes = <String>[
  'indicateurs',
  'progression',
  'diagnostics',
  'membres',
  'paiements',
  'remboursements',
  'familles',
  'dossiers',
];

void main() {
  test('le signal relit chaque liste de personnes gardee pour la session', () {
    final _Lectures l = _Lectures();
    final ProviderContainer c = ProviderContainer(overrides: _sources(l));
    addTearDown(c.dispose);
    _lireTout(c);
    expect(l.n, <String, int>{for (final String x in _listes) x: 1});

    c.read(personnesModifieesProvider.notifier).signaler();
    _lireTout(c);
    expect(l.n, <String, int>{for (final String x in _listes) x: 2});
  });

  testWidgets('D2 : apres une suppression dans Comptes, les autres listes '
      'sont relues, sans deconnexion', (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 900);
    addTearDown(tester.view.reset);
    final _Lectures l = _Lectures();
    await tester.pumpWidget(
      hote(
        const MediaQuery(
          data: MediaQueryData(size: Size(1440, 900)),
          child: ComptesPage(requete: <String, String>{'vue': 'eleves'}),
        ),
        surcharges: <Override>[
          serviceComptesProvider.overrideWithValue(_Comptes()),
          portRetraitsComptesProvider.overrideWithValue(_Retraits()),
          serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
          ..._sources(l),
        ],
      ),
    );
    await tester.pumpAndSettle();
    final ProviderContainer c = ProviderScope.containerOf(
      tester.element(find.byType(ComptesPage)),
    );
    _lireTout(c);
    expect(l.n, <String, int>{for (final String x in _listes) x: 1});

    await tester.tap(find.byType(MenuActions).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer ce compte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer le compte').last);
    await tester.pumpAndSettle();

    _lireTout(c);
    expect(l.n, <String, int>{for (final String x in _listes) x: 2});
  });
}
