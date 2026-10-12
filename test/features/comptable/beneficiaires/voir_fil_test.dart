// W07 (COMPTA-RECON-1 §3.2, spec §35) : « Voir le fil » ouvre le fil « Profil
// de paiement » d'un beneficiaire SANS relancer : aucun message modele, aucun
// brouillon touche. Fil refuse ou lecture en echec : la phrase le dit et rien
// ne s'ouvre.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/port_beneficiaires_paiement.dart';
import 'package:rewayah_academy/core/communications/capacites_communication.dart';
import 'package:rewayah_academy/core/communications/port_brouillons.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/features/com_messages/port_messages_metier.dart';
import 'package:rewayah_academy/features/comptable/beneficiaires/fil_profil_paiement_page.dart';
import 'package:rewayah_academy/features/comptable/beneficiaires/profil_paiement_page.dart';
import 'package:rewayah_academy/features/demo/communications/com_messages_demo.dart';
import 'package:rewayah_academy/features/demo/comptable/beneficiaires_demo.dart';
import 'package:rewayah_academy/features/demo/comptable/socle_comptable_demo.dart';

import '../../../capture/outil_capture.dart' show fixerVueCapture, stabiliser;
import '../../../router/support_routeur.dart' show sessionActive;
import '../../../support/harnais.dart';

const String _ens01 = ProfilsBeneficiairesDemo.modifieRecemment;

class _Messages extends MessagesMetierDemo {
  _Messages({this.refuse = false})
    : super.surObjets(aOuvrir: conversationsProfilPaiementDemo());

  final bool refuse;
  int appels = 0;

  @override
  Future<FilMetier?> filPourObjet(TypeObjetLie type, String objetId) {
    appels++;
    return refuse
        ? Future<FilMetier?>.value()
        : super.filPourObjet(type, objetId);
  }
}

final List<RouteBase> _routes = <RouteBase>[
  GoRoute(
    path: Routes.comptableBeneficiairePour(':beneficiaireId'),
    builder: (BuildContext _, GoRouterState etat) => ProfilPaiementPage(
      beneficiaireId: etat.pathParameters['beneficiaireId']!,
    ),
    routes: <RouteBase>[
      GoRoute(
        path: 'fil',
        builder: (BuildContext _, GoRouterState etat) => FilProfilPaiementPage(
          beneficiaireId: etat.pathParameters['beneficiaireId']!,
        ),
      ),
    ],
  ),
];

Future<void> _monter(
  WidgetTester tester,
  _Messages messages,
  BrouillonsMemoire brouillons,
) async {
  fixerVueCapture(tester, const Size(390, 1800), 1);
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    hoteRoutant(
      depart: Routes.comptableBeneficiairePour(_ens01),
      routes: _routes,
      surcharges: <Override>[
        sourceSessionProvider.overrideWithValue(
          FausseSourceSession(sessionActive(AppRole.accountant)),
        ),
        horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(false)),
        portBeneficiairesPaiementProvider.overrideWithValue(
          const BeneficiairesPaiementDemo(),
        ),
        portMessagesMetierProvider.overrideWithValue(messages),
        portBrouillonsProvider.overrideWithValue(brouillons),
        capacitesCommunicationProvider.overrideWith(
          (Ref _) => const CapacitesCommunicationsFixes(<CapaciteCommunication>{
            CapaciteCommunication.ecrireDansFil,
          }).capacites(),
        ),
      ],
    ),
  );
  await stabiliser(tester);
}

void main() {
  final p = t.comptable.beneficiaires.profil;
  final String nom = SocleComptableDemo.enseignants.first.nom;

  testWidgets('« Voir le fil » ouvre le fil sans rien prerremplir', (
    WidgetTester tester,
  ) async {
    final _Messages messages = _Messages();
    final BrouillonsMemoire brouillons = BrouillonsMemoire();
    await _monter(tester, messages, brouillons);
    expect(find.text(p.voirFil(nom: nom)), findsOneWidget);
    await tester.ensureVisible(find.byKey(ProfilPaiementPage.voirFilKey));
    await tester.tap(find.byKey(ProfilPaiementPage.voirFilKey));
    await stabiliser(tester);
    expect(find.byType(FilProfilPaiementPage), findsOneWidget);
    // Aucun message modele n'a ete pose : le brouillon n'existe pas.
    expect(await brouillons.tous(), isEmpty);
  });

  testWidgets('fil refuse : la phrase le dit, rien ne s ouvre', (
    WidgetTester tester,
  ) async {
    final _Messages messages = _Messages(refuse: true);
    await _monter(tester, messages, BrouillonsMemoire());
    await tester.ensureVisible(find.byKey(ProfilPaiementPage.voirFilKey));
    await tester.tap(find.byKey(ProfilPaiementPage.voirFilKey));
    await stabiliser(tester);
    expect(messages.appels, 1);
    expect(find.byType(FilProfilPaiementPage), findsNothing);
    expect(find.text(p.voirFilRefuse(nom: nom)), findsOneWidget);
  });
}
