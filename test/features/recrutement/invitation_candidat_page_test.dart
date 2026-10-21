// RECRUT-ECRANS (2/5) : le code d'invitation du candidat enseignant.
//
// Ce que le test prouve : les quatre issues du serveur (valide, expiree, deja
// utilisee, inconnue) avec leurs mots et leurs sorties ; le code valide est
// retenu pour l'inscription, un code refuse est oublie ; saisie vide, hors
// ligne, panne, port absent ; un lien avec `code` verifie des l'ouverture ;
// 320 px texte x2 en LTR et RTL.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/recrutement/ouvreur_lien.dart';
import 'package:rewayah_academy/core/recrutement/port_invitations_comptable.dart';
import 'package:rewayah_academy/core/recrutement/port_invitations_enseignant.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/features/demo/recrutement_demo.dart';
import 'package:rewayah_academy/features/inscription/brouillon_inscription.dart';
import 'package:rewayah_academy/features/inscription/code_comptable_retenu.dart';
import 'package:rewayah_academy/features/recrutement/invitation_candidat_page.dart';

import '../../support/aucun_mot_coupe.dart';
import '../../support/garde_interface.dart';
import '../../support/monter_recrutement.dart';

class _Verification implements PortVerificationInvitation {
  _Verification(this.reponse);
  final Future<ResultatInvitation> Function(String) reponse;
  @override
  Future<ResultatInvitation> verifierInvitation(String code) => reponse(code);
}

Future<void> _monter(
  WidgetTester tester, {
  PortVerificationInvitation? port,
  bool horsLigne = false,
  double largeur = 390,
  double echelle = 1,
  TextDirection? direction,
  String? depart,
  Uri? Function(Uri)? surLien,
}) => monterRecrutement(
  tester,
  chemin: Routes.inscriptionInvitation,
  depart: depart,
  autres: <String>[
    Routes.inscriptionIdentite,
    Routes.inscriptionUsage,
    Routes.connexion,
  ],
  ecran: (state) =>
      InvitationCandidatPage(codeInitial: state.uri.queryParameters['code']),
  surcharges: <Override>[
    portVerificationInvitationProvider.overrideWithValue(port),
    if (surLien != null)
      ouvreurLienProvider.overrideWithValue((Uri u) async {
        surLien(u);
        return ResultatOuverture.copie;
      }),
  ],
  horsLigne: horsLigne,
  largeur: largeur,
  echelle: echelle,
  direction: direction,
);

Future<void> _saisir(WidgetTester tester, String code) async {
  await tester.enterText(
    find.byKey(const ValueKey<String>('candidat-code')),
    code,
  );
  await tester.tap(find.byKey(const ValueKey<String>('candidat-verifier')));
  await laisser(tester);
}

void main() {
  final r = t.recrutement.candidat;

  testWidgets('port absent : une phrase, aucun champ', (tester) async {
    await _monter(tester);
    expect(
      find.byKey(const ValueKey<String>('candidat-indisponible')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey<String>('candidat-code')), findsNothing);
  });

  testWidgets('saisie vide : erreur de champ, rien n\'est envoye', (
    tester,
  ) async {
    await _monter(tester, port: InvitationsDemo());
    await tester.tap(find.byKey(const ValueKey<String>('candidat-verifier')));
    await laisser(tester);
    expect(find.text(r.champVide), findsOneWidget);
  });

  testWidgets('valide : la date, « Creer mon profil », le code est retenu', (
    tester,
  ) async {
    await _monter(tester, port: InvitationsDemo());
    await _saisir(tester, 'demo-valide');
    expect(
      find.byKey(const ValueKey<String>('candidat-valide')),
      findsOneWidget,
    );
    final ProviderContainer conteneur = ProviderScope.containerOf(
      tester.element(find.byKey(const ValueKey<String>('candidat-valide'))),
    );
    expect(conteneur.read(codeInvitationRetenuProvider), 'demo-valide');
    await tester.tap(find.text(r.creerProfil));
    await laisser(tester);
    expect(find.text('temoin:${Routes.inscriptionIdentite}'), findsOneWidget);
  });

  testWidgets('expiree : aucun champ, demande de nouvelle invitation', (
    tester,
  ) async {
    Uri? ouvert;
    await _monter(
      tester,
      port: InvitationsDemo(),
      surLien: (Uri u) {
        ouvert = u;
        return u;
      },
    );
    await _saisir(tester, CodesInvitationDemo.expire);
    expect(find.text(r.expiree), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('candidat-code')), findsNothing);
    await tester.tap(find.text(r.demanderNouvelle));
    await laisser(tester);
    expect(ouvert?.scheme, 'mailto');
    expect(find.text(r.contactCopie), findsOneWidget);
    await tester.tap(find.text(r.ressaisir));
    await laisser(tester);
    expect(find.byKey(const ValueKey<String>('candidat-code')), findsOneWidget);
  });

  testWidgets('deja utilisee : « Me connecter »', (tester) async {
    await _monter(tester, port: InvitationsDemo());
    await _saisir(tester, CodesInvitationDemo.utilise);
    expect(find.text(r.dejaUtilisee), findsOneWidget);
    await tester.tap(find.text(r.seConnecter));
    await laisser(tester);
    expect(find.text('temoin:${Routes.connexion}'), findsOneWidget);
  });

  testWidgets('inconnue : ressaisie possible, code oublie', (tester) async {
    await _monter(tester, port: InvitationsDemo());
    await _saisir(tester, 'NIMPORTE');
    expect(find.text(r.inconnue), findsOneWidget);
    final ProviderContainer conteneur = ProviderScope.containerOf(
      tester.element(find.byKey(const ValueKey<String>('candidat-inconnue'))),
    );
    expect(conteneur.read(codeInvitationRetenuProvider), isNull);
    await tester.tap(find.text(r.ressaisir));
    await laisser(tester);
    expect(find.byKey(const ValueKey<String>('candidat-code')), findsOneWidget);
  });

  testWidgets('hors ligne : le bouton n\'est pas actif', (tester) async {
    await _monter(tester, port: InvitationsDemo(), horsLigne: true);
    await tester.enterText(
      find.byKey(const ValueKey<String>('candidat-code')),
      'X',
    );
    await tester.tap(find.byKey(const ValueKey<String>('candidat-verifier')));
    await laisser(tester);
    expect(find.byKey(const ValueKey<String>('candidat-valide')), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('candidat-inconnue')),
      findsNothing,
    );
  });

  testWidgets('reseau coupe pendant la verification : message dit', (
    tester,
  ) async {
    await _monter(
      tester,
      port: _Verification((_) async => throw const HorsLigne()),
    );
    await _saisir(tester, 'X');
    expect(find.text(r.horsLigne), findsOneWidget);
  });

  testWidgets('panne : message dit, saisie conservee', (tester) async {
    await _monter(
      tester,
      port: _Verification((_) async => throw StateError('x')),
    );
    await _saisir(tester, 'X');
    expect(find.text(r.erreur), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('candidat-code')), findsOneWidget);
  });

  testWidgets('un lien avec code est verifie des l\'ouverture', (tester) async {
    await _monter(
      tester,
      port: InvitationsDemo(),
      depart: '${Routes.inscriptionInvitation}?code=DEMO-VALIDE',
    );
    expect(
      find.byKey(const ValueKey<String>('candidat-valide')),
      findsOneWidget,
    );
  });

  for (final TextDirection direction in <TextDirection>[
    TextDirection.ltr,
    TextDirection.rtl,
  ]) {
    testWidgets('320 px, texte x2, $direction : rien ne deborde', (
      tester,
    ) async {
      await _monter(
        tester,
        port: InvitationsDemo(),
        largeur: 320,
        echelle: 2,
        direction: direction,
      );
      await _saisir(tester, CodesInvitationDemo.expire);
      expect(tester.takeException(), isNull);
      verifierUnSeulBoutonPlein(tester);
      verifierEcranSansMotCoupe(tester);
    });
  }

  // Lot F2 : le candidat comptable, sur ses propres ports et son code.
  group('comptable', () {
    Future<void> monterComptable(
      WidgetTester tester, {
      PortVerificationInvitation? port,
      PortVerificationInvitation? enseignant,
    }) => monterRecrutement(
      tester,
      chemin: Routes.inscriptionInvitationComptable,
      autres: <String>[
        Routes.inscriptionIdentite,
        Routes.inscriptionUsage,
        Routes.connexion,
      ],
      ecran: (state) => InvitationCandidatPage(
        codeInitial: state.uri.queryParameters['code'],
        comptable: true,
      ),
      surcharges: <Override>[
        portVerificationInvitationProvider.overrideWithValue(enseignant),
        portVerificationInvitationComptableProvider.overrideWithValue(port),
      ],
    );

    testWidgets('port comptable absent : une phrase, aucun champ', (
      tester,
    ) async {
      // Le port enseignant servi ne suffit pas : les portes sont etanches.
      await monterComptable(tester, enseignant: InvitationsDemo());
      expect(find.text(r.comptable.indisponible), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('candidat-code')), findsNothing);
    });

    testWidgets('valide : code comptable retenu, usage comptable, identite', (
      tester,
    ) async {
      await monterComptable(tester, port: InvitationsDemo());
      expect(find.text(r.comptable.intro), findsOneWidget);
      await _saisir(tester, 'demo-valide');
      expect(find.text(r.comptable.valideDetail), findsOneWidget);
      final ProviderContainer conteneur = ProviderScope.containerOf(
        tester.element(find.byKey(const ValueKey<String>('candidat-valide'))),
      );
      expect(conteneur.read(codeComptableRetenuProvider), 'demo-valide');
      expect(conteneur.read(codeInvitationRetenuProvider), isNull);
      await tester.tap(find.text(r.creerProfil));
      await laisser(tester);
      expect(
        conteneur.read(brouillonInscriptionProvider).usage,
        UsageInscription.comptable,
      );
      expect(find.text('temoin:${Routes.inscriptionIdentite}'), findsOneWidget);
    });
  });
}
