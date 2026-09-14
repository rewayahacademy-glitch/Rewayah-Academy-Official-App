import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/etat_dossier.dart';
import 'package:rewayah_academy/core/dossier/selecteur_fichier.dart';
import 'package:rewayah_academy/core/dossier/service_dossier.dart';
import 'package:rewayah_academy/core/dossier/versions_contrat.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/dossier/attente_page.dart';
import 'package:rewayah_academy/features/dossier/depot_piece_page.dart';
import 'package:rewayah_academy/features/dossier/signature_page.dart';

import '../support/harnais.dart';

/// Une destination de retour, pour que le `go` de fin de page aboutisse.
GoRoute _portail() => GoRoute(
  path: Routes.attente,
  builder: (BuildContext _, GoRouterState _) =>
      const Scaffold(body: Text('portail')),
);

PieceAEnvoyer _piece({int octets = 1024}) => PieceAEnvoyer(
  octets: Uint8List(octets),
  nomFichier: 'piece.WEBP',
  type: TypePiece.carteIdentite,
);

void main() {
  testWidgets('le portail montre un squelette pendant sa premiere lecture', (
    WidgetTester tester,
  ) async {
    final Completer<EtatDossier> reponse = Completer<EtatDossier>();

    await tester.pumpWidget(
      hote(
        const AttentePage(),
        surcharges: <Override>[
          etatDossierProvider.overrideWith((_) => reponse.future),
        ],
      ),
    );
    await tester.pump();

    expect(find.byType(Skeleton), findsOneWidget);
    expect(find.text(t.commun.chargement), findsNothing);

    reponse.complete(const EtatDossier.sansProfil());
    await tester.pumpAndSettle();
  });

  group('ADR-011 : la carte a accuser une fois', () {
    testWidgets('elle nomme les deux dispositifs, en clair', (
      WidgetTester tester,
    ) async {
      final FauxServiceDossier dossier = FauxServiceDossier();
      await tester.pumpWidget(
        hoteRoutant(
          depart: Routes.attenteAccuse,
          routes: <RouteBase>[
            GoRoute(
              path: Routes.attenteAccuse,
              builder: (BuildContext _, GoRouterState _) => const AccusePage(),
            ),
            _portail(),
          ],
          surcharges: <Override>[
            serviceDossierProvider.overrideWithValue(dossier),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(t.contrat.pointEnregistrement), findsOneWidget);
      expect(find.text(t.contrat.pointControle), findsOneWidget);

      await tester.tap(find.text(t.accuse.compris));
      await tester.pumpAndSettle();

      expect(dossier.contratsAcceptes, <SorteContrat>[
        SorteContrat.accuseEnregistrementControle,
      ]);
    });
  });

  group('Le contrat depend du role, et lui seul', () {
    Future<FauxServiceDossier> monter(WidgetTester tester, AppRole role) async {
      final FauxServiceDossier dossier = FauxServiceDossier()
        ..etatRendu = EtatDossier(
          profilExiste: true,
          role: role,
          statutCompte: AccountStatus.pendingKyc,
          accuseSigne: true,
        );
      await tester.pumpWidget(
        hoteRoutant(
          depart: Routes.attenteContrat,
          routes: <RouteBase>[
            GoRoute(
              path: Routes.attenteContrat,
              builder: (BuildContext _, GoRouterState _) => const ContratPage(),
            ),
            _portail(),
          ],
          surcharges: <Override>[
            serviceDossierProvider.overrideWithValue(dossier),
          ],
        ),
      );
      await tester.pumpAndSettle();
      return dossier;
    }

    testWidgets('un enseignant signe son contrat, avec la clause coordonnees', (
      WidgetTester tester,
    ) async {
      final FauxServiceDossier dossier = await monter(tester, AppRole.teacher);

      // C'est le controle anti-pillage central de l'ADR-008 : il doit etre lu,
      // pas seulement signe.
      expect(find.text(t.contrat.pointCoordonnees), findsOneWidget);

      await tester.tap(find.text(t.contrat.accepter));
      await tester.pumpAndSettle();
      expect(dossier.contratsAcceptes, <SorteContrat>[
        SorteContrat.contratEnseignant,
      ]);
    });

    testWidgets('un tuteur signe les conditions, sans la clause enseignant', (
      WidgetTester tester,
    ) async {
      final FauxServiceDossier dossier = await monter(tester, AppRole.guardian);

      expect(find.text(t.contrat.pointCoordonnees), findsNothing);

      await tester.tap(find.text(t.contrat.accepter));
      await tester.pumpAndSettle();
      expect(dossier.contratsAcceptes, <SorteContrat>[
        SorteContrat.conditionsTuteur,
      ]);
    });
  });

  group('Le depot de la piece d identite', () {
    Future<(FauxServiceDossier, FauxSelecteurFichier)> monter(
      WidgetTester tester,
      PieceAEnvoyer? choisie,
    ) async {
      // Mesure sur un telephone reel, jamais sur la surface par defaut.
      // `flutter_test` monte tout sur 800 x 600, plus court que n'importe quel
      // telephone : `TUT-00c/c` porte la marque, une carte, trois choix et
      // deux boutons, et son bouton « Choisir le fichier » tombait donc sous
      // la ligne de flottaison de cette fenetre-la. Les `tap` atteignaient la
      // zone d'action collee au lieu du bouton, et les trois tests echouaient
      // en accusant l'ecran. 390 x 844 est le gabarit de reference du produit.
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final FauxServiceDossier dossier = FauxServiceDossier();
      final FauxSelecteurFichier selecteur = FauxSelecteurFichier(choisie);
      await tester.pumpWidget(
        hoteRoutant(
          depart: Routes.attentePiece,
          routes: <RouteBase>[
            GoRoute(
              path: Routes.attentePiece,
              builder: (BuildContext _, GoRouterState _) =>
                  const DepotPiecePage(),
            ),
            _portail(),
          ],
          surcharges: <Override>[
            serviceDossierProvider.overrideWithValue(dossier),
            selecteurFichierProvider.overrideWithValue(selecteur),
          ],
        ),
      );
      await tester.pumpAndSettle();
      return (dossier, selecteur);
    }

    testWidgets('rien ne part tant que le type de piece n est pas choisi', (
      WidgetTester tester,
    ) async {
      final (FauxServiceDossier dossier, _) = await monter(tester, _piece());

      await tester.tap(find.text(t.kyc.choisirFichier));
      await tester.pumpAndSettle();
      expect(dossier.depots, isEmpty);
    });

    testWidgets('un depot complet transmet la piece', (
      WidgetTester tester,
    ) async {
      final (FauxServiceDossier dossier, _) = await monter(tester, _piece());

      await tester.tap(find.text(t.kyc.carteIdentite));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.kyc.choisirFichier));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.kyc.envoyer));
      await tester.pumpAndSettle();

      expect(dossier.depots, hasLength(1));
      expect(dossier.depots.single.type, TypePiece.carteIdentite);
      expect(find.text('portail'), findsOneWidget);
    });

    testWidgets('une photo trop lourde est refusee avant l envoi', (
      WidgetTester tester,
    ) async {
      // Refuser apres trois minutes de televersement sur un reseau lent serait
      // une facon de perdre la famille.
      final (FauxServiceDossier dossier, _) = await monter(
        tester,
        _piece(octets: ServiceDossier.tailleMaximaleOctets + 1),
      );

      await tester.tap(find.text(t.kyc.carteIdentite));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.kyc.choisirFichier));
      await tester.pumpAndSettle();

      expect(dossier.depots, isEmpty);
      expect(find.textContaining('Mo'), findsOneWidget);
    });

    testWidgets('un abandon du selecteur ne casse rien', (
      WidgetTester tester,
    ) async {
      final (FauxServiceDossier dossier, _) = await monter(tester, null);

      await tester.tap(find.text(t.kyc.carteIdentite));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.kyc.choisirFichier));
      await tester.pumpAndSettle();

      expect(dossier.depots, isEmpty);
      expect(find.text(t.kyc.choisirFichier), findsOneWidget);
    });

    testWidgets('un echec d envoi se dit et ne quitte pas l ecran', (
      WidgetTester tester,
    ) async {
      final (FauxServiceDossier dossier, _) = await monter(tester, _piece());
      dossier.erreurAJeter = StateError('reseau');

      await tester.tap(find.text(t.kyc.carteIdentite));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.kyc.choisirFichier));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.kyc.envoyer));
      await tester.pumpAndSettle();

      expect(find.text(t.kyc.erreur), findsOneWidget);
      expect(find.text('portail'), findsNothing);
    });
  });

  group('PieceAEnvoyer', () {
    test('l extension est normalisee, et seulement elle est conservee', () {
      expect(_piece().extension, 'webp');
      expect(
        PieceAEnvoyer(
          octets: Uint8List(0),
          nomFichier: 'sans_extension',
          type: TypePiece.autre,
        ).extension,
        'bin',
      );
      expect(
        PieceAEnvoyer(
          octets: Uint8List(0),
          nomFichier: 'photo.',
          type: TypePiece.autre,
        ).extension,
        'bin',
      );
    });
  });

  group('La version signee est celle du texte affiche', () {
    test('une seule version pour toutes les sortes de contrat', () {
      // L unicite en base porte sur profil, sorte et version : faire bouger
      // cette valeur redemande la signature a tout le monde, ce qui est voulu.
      expect(VersionsContrat.courante, isNotEmpty);
    });
  });
}
