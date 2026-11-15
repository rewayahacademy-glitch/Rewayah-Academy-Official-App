// COMPLEMENT-ET-FORMATS (directeur, 14/11/2026) : une piece deja deposee en
// HEIC ou en PDF ne s'affiche pas sur ordinateur. Le dossier le dit avant
// l'ouverture, et la nouvelle piece se demande en un geste (le complement
// « pièce d'identité » deja coche).

import 'dart:async';

import 'package:flutter/widgets.dart'
    show Offset, Rect, Size, TextDirection, ValueKey;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/gestes_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature_detail.dart';
import 'package:rewayah_academy/core/candidature/piece_candidature.dart';
import 'package:rewayah_academy/core/capacites/port_revue_dossiers.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/app_bottom_sheet.dart';
import 'package:rewayah_academy/core/widgets/choice_card_group.dart';
import 'package:rewayah_academy/features/admin_candidature/feuille_geste.dart';
import 'package:rewayah_academy/features/admin_candidature/piece_sur_place.dart';
import 'package:rewayah_academy/features/admin_dossiers/etat_file_dossiers.dart';

import '../../capture/outil_capture.dart';
import '../../fixtures/candidature/faux_candidatures_direction.dart';
import 'hote_candidature.dart';

DossierPourRevue _dossier({required bool illisible}) => DossierPourRevue(
  dossierId: 'p1',
  revision: 0,
  prenom: 'Essai',
  nom: 'Fictif',
  role: AppRole.teacher,
  soumisLeUtc: DateTime.utc(2026, 11, 10),
  statut: StatutRevue.aVerifier,
  exigencePiece: ExigencePiece.requise,
  etatPiece: EtatPieceRevue.disponible,
  typePiece: TypePiece.passeport,
  documentId: 'd1',
  verifications: const <VerificationRevue>[],
  accords: const <AccordSoumis>[],
  peutValider: false,
  peutRefuser: true,
  peutVoirPiece: true,
  blocagesValidation: const <BlocageRevue>[BlocageRevue.pieceNonConsultable],
  blocagesRefus: const <BlocageRevue>[],
  consequence: ConsequenceValidation.indeterminee,
  formatIllisible: illisible,
);

List<Override> _surcharges({required bool illisible}) => <Override>[
  lirePieceCandidatureProvider.overrideWithValue(
    (String _) async => const PieceCandidature(
      statut: StatutPieceCandidature.enAttente,
      profilId: 'p1',
      documentId: 'd1',
    ),
  ),
  dossierPourRevueProvider('p1')
      .overrideWith((_) async => _dossier(illisible: illisible)),
];

FauxCandidaturesDirection _port() => FauxCandidaturesDirection(
  details: <DetailCandidature>[detailTest()],
  capacitesRendues: capacitesGestes,
);

void main() {
  testWidgets('piece HEIC ou PDF : la phrase, puis la demande en un geste', (
    WidgetTester tester,
  ) async {
    await monterCandidature(
      tester,
      port: _port(),
      surcharges: _surcharges(illisible: true),
    );
    expect(find.byKey(PieceSurPlace.cleIllisible), findsOneWidget);
    expect(
      find.text(t.admin.candidatures.detail.pieceIllisible),
      findsOneWidget,
    );
    await tester.ensureVisible(find.byKey(PieceSurPlace.cleRedemander));
    await tester.tap(find.byKey(PieceSurPlace.cleRedemander));
    await tester.pumpAndSettle();
    expect(find.byKey(FeuilleGeste.cle), findsOneWidget);
    final ChoiceCardGroup groupe = tester.widget<ChoiceCardGroup>(
      find.ancestor(
        of: find.byKey(const ValueKey<String>('element-piece_identite')),
        matching: find.byType(ChoiceCardGroup),
      ),
    );
    expect(groupe.valeurInitiale?.valeurs, <String>{'piece_identite'});
  });

  testWidgets(
    'ordinateur : la feuille est un panneau lateral, groupes cote a cote, '
    'actions en ligne au bord de fin',
    (WidgetTester tester) async {
      await monterCandidature(
        tester,
        port: _port(),
        largeur: 1440,
        hauteur: 900,
        surcharges: _surcharges(illisible: true),
      );
      await tester.ensureVisible(find.byKey(PieceSurPlace.cleRedemander));
      await tester.tap(find.byKey(PieceSurPlace.cleRedemander));
      await tester.pumpAndSettle();
      final Rect panneau = tester.getRect(
        find.byKey(AppBottomSheet.clePanneau),
      );
      expect(panneau.right, 1440);
      expect(panneau.top, 0);
      expect(panneau.height, 900);
      expect(panneau.width, lessThan(1440 / 2));
      // Les deux groupes cote a cote.
      final Rect reponses = tester.getRect(
        find.byKey(FeuilleGeste.cleGroupeReponses),
      );
      final Rect documents = tester.getRect(
        find.byKey(FeuilleGeste.cleGroupeDocuments),
      );
      expect(reponses.top, documents.top);
      expect(reponses.left, lessThan(documents.left));
      // Les actions : sur la meme ligne, le geste en dernier, a la largeur de
      // son contenu.
      await tester.ensureVisible(find.byKey(FeuilleGeste.cleValider));
      await tester.pumpAndSettle();
      final Rect annuler = tester.getRect(find.byKey(FeuilleGeste.cleAnnuler));
      final Rect valider = tester.getRect(find.byKey(FeuilleGeste.cleValider));
      expect(annuler.center.dy, closeTo(valider.center.dy, 1));
      expect(valider.left, greaterThan(annuler.right));
      // A la largeur de son contenu, jamais celle du panneau.
      expect(valider.width + annuler.width, lessThan(panneau.width));
    },
  );

  testWidgets('piece lisible : aucune phrase de format', (
    WidgetTester tester,
  ) async {
    await monterCandidature(
      tester,
      port: _port(),
      surcharges: _surcharges(illisible: false),
    );
    expect(find.byType(PieceSurPlace), findsOneWidget);
    expect(find.byKey(PieceSurPlace.cleIllisible), findsNothing);
  });

  testWidgets('direction qui lit seulement : la phrase, sans geste', (
    WidgetTester tester,
  ) async {
    await monterCandidature(
      tester,
      port: FauxCandidaturesDirection(
        details: <DetailCandidature>[detailTest()],
        capacitesRendues: capacitesQuiLit,
      ),
      surcharges: _surcharges(illisible: true),
    );
    expect(find.byKey(PieceSurPlace.cleIllisible), findsOneWidget);
    expect(find.byKey(PieceSurPlace.cleRedemander), findsNothing);
  });

  // Captures R3 (sautees sans CAPTURE_DIR) : CAPTURE_DIR=docs/current/captures/E2E.
  group('captures complement et formats', () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);
    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      for (final Size taille in <Size>[
        const Size(1440, 900),
        const Size(390, 844),
      ]) {
        final String suffixe = '${taille.width.toInt()}-${langue.languageCode}';
        testWidgets('piece illisible et feuille du complement $suffixe', (
          WidgetTester tester,
        ) async {
          await tester.runAsync(() => LocaleSettings.setLocale(langue));
          await monterCandidature(
            tester,
            port: _port(),
            largeur: taille.width,
            hauteur: taille.height,
            direction: langue == AppLocale.ar ? TextDirection.rtl : null,
            surcharges: _surcharges(illisible: true),
          );
          await tester.ensureVisible(find.byKey(PieceSurPlace.cleIllisible));
          await tester.drag(
            find.byKey(PieceSurPlace.cleIllisible),
            const Offset(0, 160),
          );
          await stabiliser(tester);
          await capturerVue(
            tester,
            'complement-et-formats/piece-illisible-$suffixe',
          );
          await tester.tap(find.byKey(PieceSurPlace.cleRedemander));
          await tester.pumpAndSettle();
          await stabiliser(tester);
          await capturerVue(
            tester,
            'complement-et-formats/feuille-complement-$suffixe',
          );
          await tester.ensureVisible(
            find.byKey(FeuilleGeste.cleGroupeDocuments),
          );
          await stabiliser(tester);
          await capturerVue(
            tester,
            'complement-et-formats/feuille-complement-documents-$suffixe',
          );
        });
      }
    }
  }, skip: sautSansCapture);

  // Captures R3 a 1440 de chaque geste de la direction : le panneau lateral.
  group('captures des gestes au panneau lateral', () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);
    for (final GesteCandidature geste in <GesteCandidature>[
      GesteCandidature.demanderComplement,
      GesteCandidature.cloreComplement,
      GesteCandidature.admettreVerifications,
      GesteCandidature.confirmerMoyenPaiement,
      GesteCandidature.infirmerMoyenPaiement,
      GesteCandidature.mettreEnPause,
      GesteCandidature.leverPause,
      GesteCandidature.refuser,
      GesteCandidature.consignerRetrait,
      GesteCandidature.rouvrir,
      GesteCandidature.definirResponsable,
    ]) {
      testWidgets('geste ${geste.name} 1440 fr', (WidgetTester tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.fr));
        await monterCandidature(
          tester,
          port: _port(),
          largeur: 1440,
          hauteur: 900,
          surcharges: _surcharges(illisible: true),
        );
        unawaited(
          ouvrirFeuilleGeste(
            tester.element(find.byKey(PieceSurPlace.cleIllisible)),
            geste: geste,
            detail: detailTest(),
            capacites: capacitesGestes,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(AppBottomSheet.clePanneau), findsOneWidget);
        await stabiliser(tester);
        await capturerVue(
          tester,
          'complement-et-formats/geste-${geste.name}-1440-fr',
        );
      });
    }
  }, skip: sautSansCapture);
}
