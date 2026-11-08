// Tolere n° 1 et 18 (08/11/2026) : « Mon espace » de l'Interface guidee,
// branche sur `/compte`, et la demande de presentation standard du mineur sur
// le serveur (`demander_presentation_standard`, migration 0080).
// Chaque test ci-dessous est ROUGE sans ce lot.

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/accessibilite/demande_presentation_supabase.dart';
import 'package:rewayah_academy/core/accessibilite/mode_accessibilite.dart';
import 'package:rewayah_academy/core/accessibilite/port_demande_presentation.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/features/accueil_eleve/mon_espace_accessibilite.dart';
import 'package:rewayah_academy/features/compte/compte_page.dart';

import '../../support/harnais.dart';

class _Port implements PortDemandePresentation {
  _Port({this.echoue = false});
  final bool echoue;
  int envois = 0;

  @override
  Future<void> demanderPresentationStandard() async {
    envois++;
    if (echoue) throw StateError('refus du serveur');
  }
}

class _Session extends SessionControleur {
  _Session({required this.autonome});
  final bool autonome;

  @override
  SessionState build() => SessionState(
    resolue: true,
    role: AppRole.student,
    profileId: 'p-eleve',
    accountStatus: AccountStatus.active,
    lectureProfil: LectureProfil.presente,
    eleveAutonome: autonome,
  );
}

Future<void> _monter(
  WidgetTester tester, {
  required _Port? port,
  bool autonome = false,
  bool horsLigne = false,
  Future<String?> Function()? prenom,
}) async {
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hote(
      const MonEspaceAccessibiliteBranche(),
      surcharges: <Override>[
        sessionProvider.overrideWith(() => _Session(autonome: autonome)),
        prenomDuCompteProvider.overrideWith(
          (Ref _) => (prenom ?? () async => 'Yasmine')(),
        ),
        portDemandePresentationProvider.overrideWithValue(port),
        // `/compte` ne montre cette page qu'en Mode Accessibilite.
        modeAccessibiliteActifProvider.overrideWithValue(true),
        serviceReseauProvider.overrideWithValue(
          FauxServiceReseau(horsLigneRendu: horsLigne),
        ),
      ],
      mode: InterfaceMode.enfant,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _demander(WidgetTester tester) async {
  final Finder ligne = find.text(
    t.accessibilite.monEspace.presentationStandard,
  );
  await tester.ensureVisible(ligne);
  await tester.tap(ligne);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  testWidgets('mineur : la demande part au serveur et la page le dit', (
    WidgetTester tester,
  ) async {
    final _Port port = _Port();
    await _monter(tester, port: port);
    expect(find.text('Yasmine'), findsOneWidget);
    await _demander(tester);
    expect(port.envois, 1);
    expect(find.text(t.accessibilite.monEspace.demandeEnvoyee), findsOneWidget);
  });

  testWidgets('hors ligne : rien ne part, la phrase et « Reessayer »', (
    WidgetTester tester,
  ) async {
    final _Port port = _Port();
    await _monter(tester, port: port, horsLigne: true);
    await _demander(tester);
    expect(port.envois, 0);
    expect(
      find.text(t.accessibilite.monEspace.demandeHorsLigne),
      findsOneWidget,
    );
    expect(find.text(t.compte.reessayer), findsOneWidget);
  });

  testWidgets('refus du serveur : envoi non confirme, « Reessayer » relance', (
    WidgetTester tester,
  ) async {
    final _Port port = _Port(echoue: true);
    await _monter(tester, port: port);
    await _demander(tester);
    expect(
      find.text(t.accessibilite.monEspace.demandeNonConfirmee),
      findsOneWidget,
    );
    await _demander(tester);
    expect(port.envois, 2);
  });

  testWidgets('eleve autonome (adulte) : aucune demande a un tuteur', (
    WidgetTester tester,
  ) async {
    await _monter(tester, port: _Port(), autonome: true);
    expect(
      find.text(t.accessibilite.monEspace.presentationStandard),
      findsNothing,
    );
  });

  testWidgets('sans serveur : aucune ligne de demande, rien de simule', (
    WidgetTester tester,
  ) async {
    await _monter(tester, port: null);
    expect(
      find.text(t.accessibilite.monEspace.presentationStandard),
      findsNothing,
    );
  });

  testWidgets('prenom illisible : le libelle du role, jamais un vide', (
    WidgetTester tester,
  ) async {
    await _monter(tester, port: _Port(), prenom: () async => null);
    expect(find.text(libelleRoleCompte(AppRole.student)), findsWidgets);
  });

  testWidgets('pendant la lecture du prenom : la page dit qu elle charge', (
    WidgetTester tester,
  ) async {
    final Completer<String?> jamais = Completer<String?>();
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      hote(
        const MonEspaceAccessibiliteBranche(),
        surcharges: <Override>[
          sessionProvider.overrideWith(() => _Session(autonome: false)),
          prenomDuCompteProvider.overrideWith((Ref _) => jamais.future),
          serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
        ],
      ),
    );
    await tester.pump();
    expect(find.byKey(MonEspaceAccessibiliteBranche.chargementKey), findsOne);
  });

  test('/compte montre Mon espace guide en Mode Accessibilite', () {
    final String routeur = File('lib/core/router/app_router.dart')
        .readAsStringSync();
    expect(routeur, contains('child: _CompteSelonMode()'));
    expect(routeur, contains('? const MonEspaceAccessibiliteBranche()'));
  });

  test("l'application reelle monte l'adaptateur Supabase", () {
    final String main = File('lib/main.dart').readAsStringSync();
    expect(
      main,
      contains(
        'portDemandePresentationProvider.overrideWithValue(\n'
        '    DemandePresentationSupabase(Supabase.instance.client),',
      ),
    );
  });
}
