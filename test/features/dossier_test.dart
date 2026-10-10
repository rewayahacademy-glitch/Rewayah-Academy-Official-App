import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/etat_dossier.dart';
import 'package:rewayah_academy/core/dossier/resignature_contrat.dart';
import 'package:rewayah_academy/core/dossier/selecteur_fichier.dart';
import 'package:rewayah_academy/core/dossier/service_dossier.dart';
import 'package:rewayah_academy/core/dossier/versions_contrat.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart'
    show DisqueRetour;
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

      // Le texte A3 valide le 02/10/2026, paragraphe par paragraphe ; les
      // anciens points (version 2026-09) ne sont plus affiches.
      expect(find.text(t.contrat.a3.titre), findsWidgets);
      for (final ParagrapheTexte p in paragraphesA3()) {
        expect(find.text(p.titre), findsOneWidget);
        expect(find.text(p.corps!), findsOneWidget);
      }
      expect(find.text(t.contrat.pointEnregistrement), findsNothing);
      expect(find.text(t.contrat.pointControle), findsNothing);

      await tester.tap(find.text(t.contrat.a3.jaiLu));
      await tester.pumpAndSettle();

      expect(dossier.contratsAcceptes, <SorteContrat>[
        SorteContrat.accuseEnregistrementControle,
      ]);
      expect(dossier.versionsAcceptees, <String>[
        VersionsContrat.textesJuridiques,
      ]);
    });

    testWidgets('un enseignant accuse le texte E1, pas le texte A3', (
      WidgetTester tester,
    ) async {
      final FauxServiceDossier dossier = FauxServiceDossier()
        ..etatRendu = const EtatDossier(
          profilExiste: true,
          role: AppRole.teacher,
          statutCompte: AccountStatus.pendingKyc,
        );
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

      expect(find.text(t.contrat.e1.quoi), findsOneWidget);
      expect(find.text(t.contrat.e1.pourquoi), findsOneWidget);
      expect(find.text(t.contrat.e1.refus), findsOneWidget);
      expect(find.text(t.contrat.a3.quoi), findsNothing);
      expect(find.text(t.contrat.a3.desaccord), findsNothing);
    });
  });

  group('Le contrat depend du role, et lui seul', () {
    Future<FauxServiceDossier> monter(
      WidgetTester tester,
      AppRole role, {
      bool demonstration = false,
    }) async {
      final FauxServiceDossier dossier = FauxServiceDossier()
        ..demonstration = demonstration
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
            // La re-signature (JUR-LIEN-385-1) lit la session : elle a son
            // propre test, dossier_resignature_test.dart.
            resignatureContratEnseignantProvider.overrideWithValue(false),
          ],
        ),
      );
      await tester.pumpAndSettle();
      return dossier;
    }

    testWidgets('demonstration : un enseignant signe la version 2026-10-jur, '
        'avec la clause des visites et la case art. 9', (
      WidgetTester tester,
    ) async {
      final FauxServiceDossier dossier = await monter(
        tester,
        AppRole.teacher,
        demonstration: true,
      );

      // C'est le controle anti-pillage central de l'ADR-008 : il doit etre lu,
      // pas seulement signe.
      expect(find.text(t.contrat.pointCoordonnees), findsOneWidget);
      // La clause des visites de controle, en paragraphe separe (texte valide
      // le 02/10/2026, POLITIQUE_CONTROLE_ENSEIGNANTS.md partie A).
      expect(find.text(t.contrat.clauseControle.titre), findsOneWidget);
      expect(find.text(t.contrat.clauseControle.texte), findsOneWidget);
      expect(find.text(t.contrat.e1.quoi), findsOneWidget);

      // Case de l'article 9 jamais precochee : sans elle, rien n'est signe.
      await tester.tap(find.text(t.contrat.accepter));
      await tester.pumpAndSettle();
      expect(dossier.contratsAcceptes, isEmpty);

      final Finder caseReligion = find.text(
        t.contrat.clauseControle.caseReligion,
      );
      await tester.ensureVisible(caseReligion);
      await tester.tap(caseReligion);
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.contrat.accepter));
      await tester.pumpAndSettle();
      expect(dossier.contratsAcceptes, <SorteContrat>[
        SorteContrat.contratEnseignant,
      ]);
      expect(dossier.versionsAcceptees, <String>[
        VersionsContrat.textesJuridiques,
      ]);
    });

    testWidgets('hors demonstration, politique de controle publiee : un '
        'enseignant signe la version 2026-10-jur, avec la clause, son lien '
        'vers la politique et la case art. 9', (WidgetTester tester) async {
      final FauxServiceDossier dossier = await monter(tester, AppRole.teacher);

      // La version 2026-10-jur, comme en demonstration.
      expect(find.text(t.contrat.clauseControle.titre), findsOneWidget);
      expect(find.text(t.contrat.clauseControle.texte), findsOneWidget);
      expect(find.text(t.contrat.e1.quoi), findsOneWidget);
      expect(find.text(t.contrat.pointCoordonnees), findsOneWidget);
      // Rien des textes d'origine de la version 2026-09.
      expect(find.text(t.contrat.intro), findsNothing);
      expect(find.text(t.contrat.pointEnregistrement), findsNothing);
      expect(find.text(t.contrat.pointControle), findsNothing);

      // La politique que la clause fait « confirmer avoir recue » se lit
      // depuis la clause, avant la signature.
      final Finder lien = find.text(t.contrat.politique.lien);
      await tester.ensureVisible(lien);
      await tester.tap(lien);
      await tester.pumpAndSettle();
      expect(find.text(t.contrat.politique.titre), findsOneWidget);
      expect(find.text(t.contrat.politique.s1.titre), findsOneWidget);
      await tester.tap(find.byType(DisqueRetour).last);
      await tester.pumpAndSettle();
      expect(find.text(t.contrat.politique.titre), findsNothing);

      // Case de l'article 9 jamais precochee : sans elle, rien n'est signe.
      await tester.tap(find.text(t.contrat.accepter));
      await tester.pumpAndSettle();
      expect(dossier.contratsAcceptes, isEmpty);
      final Finder caseReligion = find.text(
        t.contrat.clauseControle.caseReligion,
      );
      await tester.ensureVisible(caseReligion);
      await tester.tap(caseReligion);
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.contrat.accepter));
      await tester.pumpAndSettle();
      expect(dossier.contratsAcceptes, <SorteContrat>[
        SorteContrat.contratEnseignant,
      ]);
      expect(dossier.versionsAcceptees, <String>[
        VersionsContrat.textesJuridiques,
      ]);
    });

    testWidgets('un tuteur signe les conditions, sans la clause enseignant', (
      WidgetTester tester,
    ) async {
      final FauxServiceDossier dossier = await monter(tester, AppRole.guardian);

      expect(find.text(t.contrat.pointCoordonnees), findsNothing);
      expect(find.text(t.contrat.clauseControle.texte), findsNothing);
      expect(find.text(t.contrat.clauseControle.caseReligion), findsNothing);
      expect(find.text(t.contrat.a3.quoi), findsOneWidget);
      expect(find.text(t.contrat.a3.desaccord), findsOneWidget);

      // Case d'observation jamais precochee : sans elle, rien n'est signe.
      await tester.tap(find.text(t.contrat.accepter));
      await tester.pumpAndSettle();
      expect(dossier.contratsAcceptes, isEmpty);

      final Finder caseAccord = find.text(t.consentement.texte.caseResponsable);
      await tester.ensureVisible(caseAccord);
      await tester.tap(caseAccord);
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.contrat.accepter));
      await tester.pumpAndSettle();
      expect(dossier.contratsAcceptes, <SorteContrat>[
        SorteContrat.conditionsTuteur,
      ]);
      expect(dossier.versionsAcceptees, <String>[
        VersionsContrat.avecObservation,
      ]);
    });
  });

  group('Le depot de la piece d identite', () {
    Future<(FauxServiceDossier, FauxSelecteurFichier)> monter(
      WidgetTester tester,
      PieceAEnvoyer? choisie,
    ) async {
      // Mesure sur un telephone reel, jamais sur la surface par defaut :
      // 390 x 844 est le gabarit de reference du produit.
      //
      // **Ces trois tests ont echoue longtemps, et le commentaire qui etait ici
      // accusait la fenetre de `flutter_test`. C'etait faux.** Passer a
      // 390 x 844 ne suffisait pas : `tap()` derivait toujours un
      // `Offset(195, 971)`, donc 127 points SOUS le bas de l'ecran. La cause
      // etait l'ecran lui-meme -- « Choisir la photo » etait pose en bas d'une
      // carte qui depasse la hauteur d'un telephone, sous la ligne de
      // flottaison, tandis que « Envoyer ma piece » occupait seul la zone collee
      // en bas, inerte. Le premier geste du depot etait donc invisible sans
      // defilement, et rien ne le signalait.
      //
      // Corrige dans `depot_piece_page.dart` en posant les deux gestes dans la
      // zone d'action collee, dans l'ordre ou on les fait. Le test ne fait
      // toujours aucun defilement, **et c'est ce qui le rend utile** : s'il
      // redevient rouge, c'est que le bouton est reparti sous la ligne de
      // flottaison.
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

    testWidgets('les deux gestes tiennent dans un telephone, sans defiler', (
      WidgetTester tester,
    ) async {
      // L'invariant que les trois echecs mesuraient sans le dire : sur le
      // gabarit ou le depot se fait vraiment, les deux boutons sont a l'ecran.
      // On mesure leur rectangle, pas leur presence dans l'arbre : un bouton
      // present et hors cadre est un bouton absent pour la personne qui tient
      // le telephone.
      await monter(tester, _piece());

      for (final String libelle in <String>[
        t.kyc.choisirFichier,
        t.kyc.envoyer,
      ]) {
        final Rect zone = tester.getRect(find.text(libelle));
        expect(
          zone.top,
          greaterThanOrEqualTo(0),
          reason: '$libelle sort par le haut du viewport 390 x 844.',
        );
        expect(
          zone.bottom,
          lessThanOrEqualTo(844),
          reason:
              '$libelle tombe sous la ligne de flottaison a 390 x 844 : c est '
              'le defaut mesure a Offset(195, 971).',
        );
      }
    });

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

    test('garde-fou : 2026-10-jur pour l enseignant seulement en '
        'demonstration ou une fois la politique publiee', () {
      // La politique est publiee (05/10/2026) : 2026-10-jur par defaut.
      expect(
        VersionsContrat.pour(SorteContrat.contratEnseignant),
        VersionsContrat.textesJuridiques,
      );
      // Si l'interrupteur repassait a faux, la version d'origine hors
      // demonstration.
      expect(
        VersionsContrat.pour(
          SorteContrat.contratEnseignant,
          politiquePubliee: false,
        ),
        VersionsContrat.courante,
      );
      expect(
        VersionsContrat.pour(
          SorteContrat.contratEnseignant,
          demonstration: true,
        ),
        VersionsContrat.textesJuridiques,
      );
      expect(
        VersionsContrat.pour(
          SorteContrat.contratEnseignant,
          politiquePubliee: true,
        ),
        VersionsContrat.textesJuridiques,
      );
      // Les autres sortes ne dependent pas de l interrupteur.
      for (final bool demo in <bool>[false, true]) {
        expect(
          VersionsContrat.pour(
            SorteContrat.accuseEnregistrementControle,
            demonstration: demo,
          ),
          VersionsContrat.textesJuridiques,
        );
        expect(
          VersionsContrat.pour(
            SorteContrat.conditionsTuteur,
            demonstration: demo,
          ),
          VersionsContrat.avecObservation,
        );
      }
    });
  });
}
