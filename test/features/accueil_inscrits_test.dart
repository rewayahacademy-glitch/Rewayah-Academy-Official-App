// IMM-ACCUEIL-FRONT : une famille deja inscrite par la direction retrouve
// son compte sans tout ressaisir (DECISION-IMMATRICULATION-2026-10-12 §5).
// Vrai routeur, session et reclamation pilotees ; aucun reseau.

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/import_inscriptions/port_reclamation_preinscription.dart';
import 'package:rewayah_academy/core/router/redirection.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/features/accueil_inscrits/accueil_inscrits_page.dart';
import 'package:rewayah_academy/features/foyer/formulaire_profil_eleve.dart';
import 'package:rewayah_academy/features/inscription/etapes/usage_etape.dart';

import '../router/support_routeur.dart';
import '../support/garde_interface.dart';

const SessionState _sansProfil = SessionState(
  resolue: true,
  profileId: 'u1',
  lectureProfil: LectureProfil.absente,
);

const SessionState _tuteur = SessionState(
  resolue: true,
  role: AppRole.guardian,
  profileId: 'u1',
  householdId: 'h1',
  accountStatus: AccountStatus.active,
  lectureProfil: LectureProfil.presente,
);

/// La source dont le nouveau jeton porte le profil cree par le serveur.
class _SourceReprise extends SourcePilotee {
  _SourceReprise({this.profilCree = true}) : super(_sansProfil);

  final bool profilCree;

  @override
  Future<void> rafraichir() async {
    await super.rafraichir();
    if (profilCree) {
      emettre(_tuteur);
    }
  }
}

class _Port implements PortReclamationPreinscription {
  _Port(this.reponse);

  final Future<ReclamationPreinscription> Function() reponse;
  int appels = 0;

  @override
  bool get disponible => true;

  @override
  Future<ReclamationPreinscription> reclamer() {
    appels++;
    return reponse();
  }
}

const ReclamationPreinscription _famille = ReclamationPreinscription(
  connue: true,
  motAccueil: 'Mariam, bienvenue chez vous. La direction',
  personnes: <PersonneImportee>[
    PersonneImportee(
      id: 'p-tuteur',
      prenom: 'Mariam',
      nature: NaturePersonneImportee.tuteur,
    ),
    PersonneImportee(
      id: 'p-yasmine',
      prenom: 'Yasmine',
      nature: NaturePersonneImportee.eleve,
    ),
    PersonneImportee(
      id: 'p-adam',
      prenom: 'Adam',
      nature: NaturePersonneImportee.eleve,
    ),
  ],
);

Future<GoRouter> _monter(
  WidgetTester tester, {
  required SourcePilotee source,
  required _Port port,
  List<EleveDuFoyer> eleves = const <EleveDuFoyer>[],
  Size taille = const Size(390, 844),
}) {
  return monterRouteur(
    tester,
    null,
    source: source,
    taille: taille,
    surcharges: <Override>[
      elevesDuFoyerProvider.overrideWith((Ref _) async => eleves),
      portReclamationPreinscriptionProvider.overrideWithValue(port),
    ],
  );
}

String _chemin(GoRouter r) => r.routerDelegate.currentConfiguration.uri.path;

void main() {
  setUp(() => LocaleSettings.setLocale(AppLocale.fr));

  group('redirection', () {
    test('le tuteur qui quitte l inscription voit d abord son accueil', () {
      expect(
        deciderRedirection(
          session: _tuteur,
          cheminDemande: Routes.inscription,
          maintenant: DateTime(2026, 11),
          accueilInscrits: true,
        ),
        Routes.tuteurInscriptionReprise,
      );
      expect(
        deciderRedirection(
          session: _tuteur,
          cheminDemande: Routes.inscription,
          maintenant: DateTime(2026, 11),
        ),
        Routes.tuteurAccueil,
      );
    });

    test('hors de ce moment, la page ramene a l accueil', () {
      expect(
        deciderRedirection(
          session: _tuteur,
          cheminDemande: Routes.tuteurInscriptionReprise,
          maintenant: DateTime(2026, 11),
        ),
        Routes.tuteurAccueil,
      );
      expect(
        deciderRedirection(
          session: _tuteur,
          cheminDemande: Routes.tuteurInscriptionReprise,
          maintenant: DateTime(2026, 11),
          accueilInscrits: true,
        ),
        isNull,
      );
    });
  });

  group('famille deja inscrite', () {
    testWidgets('reprise : mot de la direction, profils eleves a ajouter, '
        'un seul appel', (WidgetTester tester) async {
      final _SourceReprise source = _SourceReprise();
      addTearDown(source.fermer);
      final _Port port = _Port(() async => _famille);
      final GoRouter routeur = await _monter(
        tester,
        source: source,
        port: port,
      );

      expect(_chemin(routeur), Routes.tuteurInscriptionReprise);
      expect(port.appels, 1);
      expect(source.rafraichissements, 1);
      expect(find.text(t.accueilInscrits.titre), findsWidgets);
      expect(find.text(_famille.motAccueil!), findsOneWidget);
      expect(
        find.text(t.accueilInscrits.ajouterProfil(dePrenom: 'de Yasmine')),
        findsOneWidget,
      );
      expect(
        find.text(t.accueilInscrits.ajouterProfil(dePrenom: "d'Adam")),
        findsOneWidget,
      );
      // Le tuteur lui-meme n'est pas un profil eleve a ajouter.
      expect(find.textContaining('Mariam,'), findsOneWidget);
      verifierUnSeulBoutonPlein(tester);

      await tester.tap(find.byKey(AccueilInscritsPage.continuerKey));
      await stabiliser(tester);
      expect(_chemin(routeur), Routes.tuteurAccueil);

      // Montre une fois : l'adresse ne rouvre plus rien.
      routeur.go(Routes.tuteurInscriptionReprise);
      await stabiliser(tester);
      expect(_chemin(routeur), Routes.tuteurAccueil);
      expect(port.appels, 1);
    });

    testWidgets('un profil deja ajoute est « a jour »', (
      WidgetTester tester,
    ) async {
      final _SourceReprise source = _SourceReprise();
      addTearDown(source.fermer);
      const List<EleveDuFoyer> foyer = <EleveDuFoyer>[
        EleveDuFoyer(
          id: 'e1',
          prenom: 'yasmine',
          identifiantImmuable: 'RA-26-0001',
          mode: InterfaceMode.standard,
          camera: CameraPolicy.allowed,
        ),
      ];
      await _monter(
        tester,
        source: source,
        port: _Port(() async => _famille),
        eleves: foyer,
      );
      expect(find.text('Yasmine'), findsOneWidget);
      expect(find.text(t.accueilInscrits.aJour), findsOneWidget);
      expect(
        find.text(t.accueilInscrits.ajouterProfil(dePrenom: "d'Adam")),
        findsOneWidget,
      );
    });

    testWidgets('ajouter le profil eleve reprend le prenom importe', (
      WidgetTester tester,
    ) async {
      final _SourceReprise source = _SourceReprise();
      addTearDown(source.fermer);
      final GoRouter routeur = await _monter(
        tester,
        source: source,
        port: _Port(() async => _famille),
      );
      final Finder ligne = find.text(
        t.accueilInscrits.ajouterProfil(dePrenom: 'de Yasmine'),
      );
      await tester.ensureVisible(ligne);
      await stabiliser(tester);
      await tester.tap(ligne);
      await stabiliser(tester);
      expect(_chemin(routeur), Routes.tuteurAjouterEnfant);
      final FormulaireProfilEleve formulaire = tester.widget(
        find.byType(FormulaireProfilEleve),
      );
      expect(formulaire.prenomInitial, 'Yasmine');
      // L'adresse ne porte jamais le prenom.
      expect(
        routeur.routerDelegate.currentConfiguration.uri.toString(),
        isNot(contains('Yasmine')),
      );
    });

    testWidgets('sans profil cree par le serveur : le mot, puis les questions '
        'habituelles', (WidgetTester tester) async {
      final _SourceReprise source = _SourceReprise(profilCree: false);
      addTearDown(source.fermer);
      final GoRouter routeur = await _monter(
        tester,
        source: source,
        port: _Port(() async => _famille),
      );
      expect(_chemin(routeur), Routes.inscription);
      expect(find.text(_famille.motAccueil!), findsOneWidget);
      expect(find.text(t.accueilInscrits.finirCompte), findsOneWidget);
      expect(find.byType(UsageEtape), findsNothing);
      verifierUnSeulBoutonPlein(tester);

      await tester.tap(find.byKey(AccueilInscritsPage.continuerKey));
      await stabiliser(tester);
      expect(find.byType(UsageEtape), findsOneWidget);
    });
  });

  group('aucune pre-inscription', () {
    testWidgets('le parcours habituel, inchange', (WidgetTester tester) async {
      final _SourceReprise source = _SourceReprise();
      addTearDown(source.fermer);
      final _Port port = _Port(
        () async => const ReclamationPreinscription.inconnue(),
      );
      final GoRouter routeur = await _monter(
        tester,
        source: source,
        port: port,
      );
      expect(_chemin(routeur), Routes.inscription);
      expect(find.byType(UsageEtape), findsOneWidget);
      expect(port.appels, 1);
      expect(source.rafraichissements, 0);
    });
  });

  group('etats', () {
    testWidgets('verification en cours : rien ne s ouvre', (
      WidgetTester tester,
    ) async {
      final _SourceReprise source = _SourceReprise();
      addTearDown(source.fermer);
      final Completer<ReclamationPreinscription> attente =
          Completer<ReclamationPreinscription>();
      await _monter(tester, source: source, port: _Port(() => attente.future));
      expect(find.byKey(EtatReclamationVue.chargementKey), findsOneWidget);
      expect(find.byType(UsageEtape), findsNothing);
      attente.complete(const ReclamationPreinscription.inconnue());
      await stabiliser(tester);
      expect(find.byType(UsageEtape), findsOneWidget);
    });

    testWidgets('echec : la cause et Reessayer', (WidgetTester tester) async {
      final _SourceReprise source = _SourceReprise();
      addTearDown(source.fermer);
      int essais = 0;
      final _Port port = _Port(() async {
        essais++;
        if (essais == 1) {
          throw const ReclamationEnEchec();
        }
        return const ReclamationPreinscription.inconnue();
      });
      await _monter(tester, source: source, port: port);
      expect(find.byKey(EtatReclamationVue.echecKey), findsOneWidget);
      expect(find.text(t.accueilInscrits.echecTitre), findsOneWidget);
      expect(find.byType(UsageEtape), findsNothing);

      await tester.tap(find.text(t.commun.reessayer).first);
      await stabiliser(tester);
      expect(port.appels, 2);
      expect(find.byType(UsageEtape), findsOneWidget);
    });

    testWidgets('aucune reponse : dit ce qui manque', (
      WidgetTester tester,
    ) async {
      final _SourceReprise source = _SourceReprise();
      addTearDown(source.fermer);
      await _monter(
        tester,
        source: source,
        port: _Port(() async => throw const ReclamationInjoignable()),
      );
      expect(find.byKey(EtatReclamationVue.horsLigneKey), findsOneWidget);
      expect(find.byType(UsageEtape), findsNothing);
    });

    testWidgets('bureau 1440 et texte x2 : rien ne deborde', (
      WidgetTester tester,
    ) async {
      final _SourceReprise source = _SourceReprise();
      addTearDown(source.fermer);
      await _monter(
        tester,
        source: source,
        port: _Port(() async => _famille),
        taille: const Size(1440, 900),
      );
      expect(find.text(_famille.motAccueil!), findsOneWidget);
      expect(tester.takeException(), isNull);
      verifierUnSeulBoutonPlein(tester);
    });
  });
}
