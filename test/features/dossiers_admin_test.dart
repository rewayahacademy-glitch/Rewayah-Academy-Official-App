import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/revue_dossiers_depuis_validation.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/service_validation.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/admin_dossiers/dossiers_page.dart';
import 'package:rewayah_academy/features/admin_dossiers/visionneuse_piece.dart';

import '../support/dossiers_production.dart';
import '../support/harnais.dart';

DossierAValider _dossier({String id = 'doc1', String prenom = 'Moussa'}) =>
    DossierAValider(
      documentId: id,
      profilId: 'p1',
      type: TypePiece.carteIdentite,
      cleObjet: 'p1/piece.webp',
      deposeLe: DateTime(2026, 9, 4),
      prenom: prenom,
      nom: 'Barry',
      identifiantImmuable: 'TEACHER-MB-000001',
      role: AppRole.teacher,
    );

Future<FauxServiceValidation> _monter(
  WidgetTester tester,
  FauxServiceValidation service,
) async {
  await tester.pumpWidget(
    hote(
      const DossiersPage(),
      surcharges: <Override>[
        serviceValidationProvider.overrideWithValue(service),
        surchargeRevueDossiersProduction,
        imagePieceProvider.overrideWithValue(
          (Uri _) => MemoryImage(pngSynthetique),
        ),
      ],
    ),
  );
  await tester.pumpAndSettle();
  await ouvrirPremierDossier(tester);
  return service;
}

/// Fait defiler jusqu'a un libelle, comme l'administrateur le ferait.
///
/// Necessaire parce que `ListView` ne construit pas ce qui est hors champ : un
/// bouton plus bas que le pli n'existe pas encore dans l'arbre.
///
/// **`scrollUntilVisible` ne suffit pas** : elle s'arrete des que le widget est
/// CONSTRUIT, pas des qu'il est visible. Le verdict pouvait ainsi se trouver
/// huit pixels sous la fenetre de 800x600, construit mais intouchable, et le
/// tap partait dans le vide. `ensureVisible` finit le travail.
Future<void> _allerA(WidgetTester tester, String libelle) async {
  final Finder cible = find.text(libelle);
  await tester.scrollUntilVisible(
    cible,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
}

/// Tape sur un libelle apres s'etre assure qu'il est bien a l'ecran.
///
/// C'est le geste reel de l'administrateur : il ne peut pas appuyer sur ce
/// qu'il ne voit pas, et un test qui appuie quand meme ne prouve rien.
Future<void> _taper(WidgetTester tester, String libelle) async {
  await _allerA(tester, libelle);
  await tester.tap(find.text(libelle));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('la premiere lecture montre un squelette', (
    WidgetTester tester,
  ) async {
    final Completer<List<DossierAValider>> reponse =
        Completer<List<DossierAValider>>();

    await tester.pumpWidget(
      hote(
        const DossiersPage(),
        surcharges: <Override>[
          serviceValidationProvider.overrideWithValue(FauxServiceValidation()),
          dossiersEnAttenteProvider.overrideWith((_) => reponse.future),
          surchargeRevueDossiersProduction,
        ],
      ),
    );
    await tester.pump();

    // AD-5 : la file a son squelette (quatre lignes) et son texte visible.
    expect(find.byType(Skeleton), findsWidgets);
    expect(find.text(t.dossiers.file.chargement), findsOneWidget);
    expect(find.text(t.commun.chargement), findsNothing);

    reponse.complete(const <DossierAValider>[]);
    await tester.pumpAndSettle();
  });

  group('ADM-02 : un dossier a la fois, constat puis jugement', () {
    testWidgets('un seul dossier est presente, jamais une grille', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        FauxServiceValidation()
          ..file = <DossierAValider>[
            _dossier(),
            _dossier(id: 'doc2', prenom: 'Aissatou'),
          ],
      );

      // Le detail ouvert (titre « Dossier de Moussa Barry » et constat) : une
      // personne, une revue. Les deux pieces d'une meme personne ne font
      // qu'une ligne (AD-BR-01), la plus ancienne gardee.
      expect(find.text('Dossier de Moussa Barry'), findsOneWidget);
      expect(find.textContaining('Aissatou'), findsNothing);
      // En production, le total n'est pas garanti : aucun compteur (Q16).
      expect(find.text(t.dossiers.restants(n: 2)), findsNothing);
    });

    testWidgets(
      'le constat precede le jugement, a l ecran comme dans l ordre',
      (WidgetTester tester) async {
        await _monter(
          tester,
          FauxServiceValidation()..file = <DossierAValider>[_dossier()],
        );

        // AD-6 : identite, piece, verifications, puis la decision.
        final double yIdentite = tester
            .getTopLeft(find.text(t.dossiers.revue.identite))
            .dy;
        final double yPiece = tester
            .getTopLeft(find.text(t.dossiers.revue.piece))
            .dy;
        final double yChecklist = tester
            .getTopLeft(find.text(t.dossiers.verifications))
            .dy;
        final double yVerdict = tester
            .getTopLeft(find.text(t.dossiers.refuser))
            .dy;

        expect(yIdentite, lessThan(yPiece));
        expect(yPiece, lessThan(yChecklist));
        expect(yChecklist, lessThan(yVerdict));
      },
    );

    testWidgets('la validation attend que les trois constats soient poses', (
      WidgetTester tester,
    ) async {
      final FauxServiceValidation service = await _monter(
        tester,
        FauxServiceValidation()..file = <DossierAValider>[_dossier()],
      );

      await _taper(tester, t.dossiers.approuver);
      expect(service.verdicts, isEmpty);

      for (final String point in <String>[
        t.dossiers.pointLisible,
        t.dossiers.pointNom,
        t.dossiers.pointValidite,
      ]) {
        await _taper(tester, point);
      }

      await _taper(tester, t.dossiers.approuver);

      expect(service.verdicts, hasLength(1));
      expect(service.verdicts.single.approuve, isTrue);
      expect(service.verdicts.single.motif, isNull);
    });

    testWidgets('un refus sans motif ne part pas', (WidgetTester tester) async {
      final FauxServiceValidation service = await _monter(
        tester,
        FauxServiceValidation()..file = <DossierAValider>[_dossier()],
      );

      await _allerA(tester, t.dossiers.refuser);
      await tester.tap(find.text(t.dossiers.refuser));
      await tester.pumpAndSettle();

      // La base refuse aussi un verdict negatif sans motif : l ecran ne fait
      // que l annoncer plus tot.
      await _allerA(tester, t.dossiers.motifRequis);
      expect(find.text(t.dossiers.motifRequis), findsOneWidget);
      // La confirmation du refus en ligne (transitoire jusqu'a AD-8) est le
      // second « Refuser le dossier », sous le motif.
      await tester.ensureVisible(find.text(t.dossiers.refuser).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.dossiers.refuser).last);
      await tester.pumpAndSettle();
      expect(service.verdicts, isEmpty);

      await tester.enterText(find.byType(TextField), 'Photo illisible.');
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.dossiers.refuser).last);
      await tester.pumpAndSettle();

      expect(service.verdicts.single.approuve, isFalse);
      expect(service.verdicts.single.motif, 'Photo illisible.');
    });

    testWidgets('AD-7 : ni journalisation ni URL dans le detail ; « Voir la '
        'piece » signe par le mecanisme existant et la validation se rouvre', (
      WidgetTester tester,
    ) async {
      final FauxServiceValidation service = await _monter(
        tester,
        FauxServiceValidation()..file = <DossierAValider>[_dossier()],
      );

      expect(find.text(t.dossiers.journalisation), findsNothing);
      expect(find.text(t.dossiers.apercu), findsNothing);
      expect(find.textContaining('piece.webp'), findsNothing);
      expect(service.apercus, isEmpty);

      await _taper(tester, t.dossiers.revue.voirPiece);
      expect(find.byType(VisionneusePiece), findsOneWidget);
      expect(service.apercus, <String>['p1/piece.webp']);
      expect(find.textContaining('http'), findsNothing);
      expect(find.textContaining('piece.webp'), findsNothing);

      await tester.tap(
        find.descendant(
          of: find.byType(VisionneusePiece),
          matching: find.text(t.commun.fermer),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(VisionneusePiece), findsNothing);
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        'adm02b-voir-piece',
      );

      await _taper(tester, t.dossiers.pointLisible);
      await _taper(tester, t.dossiers.pointNom);
      await _taper(tester, t.dossiers.pointValidite);
      await _taper(tester, t.dossiers.approuver);
      expect(service.verdicts.single.approuve, isTrue);
    });

    testWidgets('AD-7 : une piece pdf ne s affiche pas, validation fermee, '
        'refus ouvert, rien n est signe', (WidgetTester tester) async {
      final FauxServiceValidation service = await _monter(
        tester,
        FauxServiceValidation()
          ..file = <DossierAValider>[
            DossierAValider(
              documentId: 'doc1',
              profilId: 'p1',
              type: TypePiece.carteIdentite,
              cleObjet: 'p1/piece.pdf',
              deposeLe: DateTime(2026, 9, 4),
              prenom: 'Moussa',
              nom: 'Barry',
              identifiantImmuable: 'TEACHER-MB-000001',
              role: AppRole.teacher,
            ),
          ],
      );
      await _taper(tester, t.dossiers.revue.voirPiece);
      expect(
        find.text(t.dossiers.visionneuse.formatNonPrisEnCharge),
        findsOneWidget,
      );
      expect(service.apercus, isEmpty);
      await tester.tap(
        find.descendant(
          of: find.byType(VisionneusePiece),
          matching: find.text(t.commun.fermer),
        ),
      );
      await tester.pumpAndSettle();
      await _allerA(tester, t.dossiers.approuver);
      final Finder valider = find.ancestor(
        of: find.text(t.dossiers.approuver),
        matching: find.byType(ActionPrincipale),
      );
      expect(tester.widget<ActionPrincipale>(valider).onPress, isNull);
      final Finder refuser = find.ancestor(
        of: find.text(t.dossiers.refuser).first,
        matching: find.byType(ActionPrincipale),
      );
      expect(tester.widget<ActionPrincipale>(refuser.first).onPress, isNotNull);
    });

    testWidgets('une file vide est une invitation, pas un ecran mort', (
      WidgetTester tester,
    ) async {
      await _monter(tester, FauxServiceValidation());
      expect(find.text(t.dossiers.aucun), findsOneWidget);
      expect(find.text(t.dossiers.aucunDetail), findsOneWidget);
    });

    testWidgets('un genre de lecteur inconnu se dit precisement', (
      WidgetTester tester,
    ) async {
      // La base ferme plutot que de rendre la moitie des dossiers en silence.
      // A l ecran, ce n est pas une panne : c est une information manquante que
      // l administrateur peut fournir, donc pas de bouton « reessayer ».
      await _monter(
        tester,
        FauxServiceValidation()..erreurFile = const GenreLecteurInconnu(),
      );

      expect(find.text(t.dossiers.genreManquant), findsOneWidget);
      expect(find.text(t.commun.reessayer), findsNothing);
    });

    testWidgets('une panne ordinaire laisse reessayer', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        FauxServiceValidation()..erreurFile = StateError('reseau'),
      );

      expect(find.text(t.commun.reessayer), findsOneWidget);
      expect(find.text(t.dossiers.genreManquant), findsNothing);
    });
  });
}
