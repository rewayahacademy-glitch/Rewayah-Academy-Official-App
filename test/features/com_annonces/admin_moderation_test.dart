// COM-ANN-2 : la file de moderation de l'Administration des communications
// (`ModerationQueue`, spec section 5.5). Les actions ne se montrent qu'avec
// la capacite du serveur, une decision n'est dite qu'apres l'accuse, les
// motifs et la regle visee viennent du socle et de COM-COMU-2. Rendu verifie
// a 390, 768 et 1440, et en arabe.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/communications/moderation.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/espace_travail_adaptatif.dart';
import 'package:rewayah_academy/features/com_annonces/administration_communications_page.dart';
import 'package:rewayah_academy/features/com_annonces/annonces_planifiees.dart';
import 'package:rewayah_academy/features/com_annonces/file_moderation.dart';
import 'package:rewayah_academy/features/com_communaute/regles_communaute.dart';
import 'package:rewayah_academy/features/demo/communications/com_annonces_demo.dart';

import '../../support/garde_interface.dart';
import 'admin_banc.dart';

Finder _ligne(String libelle) => find.text(libelle);

void main() {
  final m = t.com.annonces.administration.moderation;
  final d = t.com.annonces.demoPublication;

  group('Moderation : file, detail, decision', () {
    for (final Size taille in const <Size>[Size(768, 1024), Size(1440, 900)]) {
      testWidgets('${taille.width.toInt()} : masquer, accuse, puis restaurer', (
        WidgetTester tester,
      ) async {
        final ModerationAdministrationDemo moderation =
            ModerationAdministrationDemo(maintenant: maintenantBanc);
        await monterAdministration(
          tester,
          onglet: OngletCommunications.moderation,
          taille: taille,
          moderation: moderation,
        );
        expect(find.text(d.signalementAffilie), findsOneWidget);
        expect(find.text(d.signalementVente), findsOneWidget);
        expect(find.text(d.signalementHorsSujet), findsOneWidget);
        expect(find.byType(MarqueDemonstration), findsOneWidget);
        // Rien d'ouvert : la colonne du detail invite a choisir.
        expect(find.text(m.choisirTitre), findsOneWidget);

        await taper(tester, _ligne(d.signalementAffilie));
        expect(
          find.byKey(FileModeration.cleDetail('demo-sig-affilie')),
          findsOneWidget,
        );
        expect(find.text(d.extraitAffilie), findsOneWidget);
        // La regle visee est celle de COM-COMU-2.
        expect(find.text(t.com.communaute.garde.bloqueAffilie), findsOneWidget);
        expect(
          find.text(m.motif(motif: MotifSignalement.lienAffilie.libelle)),
          findsOneWidget,
        );
        for (final ActionModeration a in <ActionModeration>[
          ActionModeration.approuver,
          ActionModeration.masquer,
          ActionModeration.rejeter,
        ]) {
          expect(find.byKey(FileModeration.cleAction(a)), findsOneWidget);
        }
        expect(
          find.byKey(FileModeration.cleAction(ActionModeration.restaurer)),
          findsNothing,
        );
        verifierUnSeulBoutonPlein(tester, maximum: 0);

        await taper(
          tester,
          find.byKey(FileModeration.cleAction(ActionModeration.masquer)),
        );
        expect(moderation.decisions, <(String, ActionModeration)>[
          ('demo-sig-affilie', ActionModeration.masquer),
        ]);
        expect(find.text(m.enregistree), findsOneWidget);
        expect(find.text(m.masque), findsWidgets);
        expect(
          find.byKey(FileModeration.cleAction(ActionModeration.restaurer)),
          findsOneWidget,
        );
        expect(
          find.byKey(FileModeration.cleAction(ActionModeration.masquer)),
          findsNothing,
        );
        await taper(
          tester,
          find.byKey(FileModeration.cleAction(ActionModeration.restaurer)),
        );
        expect(find.text(m.restaure), findsWidgets);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('1440 : la politique anti-promotion en contexte', (
      WidgetTester tester,
    ) async {
      await monterAdministration(
        tester,
        onglet: OngletCommunications.moderation,
      );
      expect(find.byKey(EspaceTravailAdaptatif.cleContexte), findsOneWidget);
      expect(find.byType(ReglesCommunaute), findsOneWidget);
      expect(find.text(m.sansSanction), findsOneWidget);
    });

    testWidgets('390 : une surface a la fois, retour a la file', (
      WidgetTester tester,
    ) async {
      await monterAdministration(
        tester,
        onglet: OngletCommunications.moderation,
        taille: const Size(390, 844),
      );
      await taper(tester, _ligne(d.signalementVente));
      expect(find.text(d.extraitVente), findsOneWidget);
      expect(find.text(d.signalementAffilie), findsNothing);
      await taper(tester, find.byKey(EspaceTravailAdaptatif.cleRetourListe));
      expect(find.text(d.signalementAffilie), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ouvrir le contexte mene a la destination validee', (
      WidgetTester tester,
    ) async {
      await monterAdministration(
        tester,
        onglet: OngletCommunications.moderation,
      );
      await taper(tester, _ligne(d.signalementVente));
      await taper(tester, find.text(m.contexte));
      expect(find.text(texteContexte), findsOneWidget);
    });

    testWidgets('sans destination, pas de lien de contexte', (
      WidgetTester tester,
    ) async {
      await monterAdministration(
        tester,
        onglet: OngletCommunications.moderation,
      );
      await taper(tester, _ligne(d.signalementHorsSujet));
      expect(find.text(m.extraitAbsent), findsOneWidget);
      expect(find.text(m.contexte), findsNothing);
    });

    testWidgets('arabe, de droite a gauche, 1440', (WidgetTester tester) async {
      await monterAdministration(
        tester,
        onglet: OngletCommunications.moderation,
        arabe: true,
      );
      final String ligne = t.com.annonces.demoPublication.signalementVente;
      await taper(tester, find.text(ligne));
      expect(
        Directionality.of(tester.element(find.text(ligne).first)),
        TextDirection.rtl,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Moderation : capacites et etats', () {
    testWidgets('seulement rejeter : seule cette action est rendue', (
      WidgetTester tester,
    ) async {
      await monterAdministration(
        tester,
        onglet: OngletCommunications.moderation,
        moderation: ModerationAdministrationDemo(
          maintenant: maintenantBanc,
          actions: const <ActionModeration>{ActionModeration.rejeter},
        ),
      );
      await taper(tester, _ligne(d.signalementAffilie));
      expect(
        find.byKey(FileModeration.cleAction(ActionModeration.rejeter)),
        findsOneWidget,
      );
      for (final ActionModeration a in <ActionModeration>[
        ActionModeration.approuver,
        ActionModeration.masquer,
        ActionModeration.restaurer,
      ]) {
        expect(find.byKey(FileModeration.cleAction(a)), findsNothing);
      }
    });

    testWidgets('aucune capacite de moderer : la file n est pas montree', (
      WidgetTester tester,
    ) async {
      await monterAdministration(
        tester,
        onglet: OngletCommunications.moderation,
        moderation: ModerationAdministrationDemo(
          maintenant: maintenantBanc,
          actions: const <ActionModeration>{},
        ),
      );
      expect(find.text(m.refuseTitre), findsOneWidget);
      expect(find.text(d.signalementAffilie), findsNothing);
    });

    testWidgets('accuse perdu : pas encore confirmee, aucune decision dite', (
      WidgetTester tester,
    ) async {
      await monterAdministration(
        tester,
        onglet: OngletCommunications.moderation,
        moderation: ModerationAdministrationDemo(
          maintenant: maintenantBanc,
          nonConfirme: true,
        ),
      );
      await taper(tester, _ligne(d.signalementAffilie));
      await taper(
        tester,
        find.byKey(FileModeration.cleAction(ActionModeration.approuver)),
      );
      expect(find.byKey(FileModeration.cleErreur), findsOneWidget);
      expect(find.text(m.nonConfirmee), findsOneWidget);
      expect(find.text(m.enregistree), findsNothing);
      expect(find.text(m.approuve), findsNothing);
      // L'action reste offerte : on peut reessayer.
      expect(
        find.byKey(FileModeration.cleAction(ActionModeration.approuver)),
        findsOneWidget,
      );
    });

    testWidgets('decision sans contrat : pas encore disponible', (
      WidgetTester tester,
    ) async {
      await monterAdministration(
        tester,
        onglet: OngletCommunications.moderation,
        moderation: ModerationAdministrationDemo(
          maintenant: maintenantBanc,
          indisponible: true,
        ),
      );
      await taper(tester, _ligne(d.signalementAffilie));
      await taper(
        tester,
        find.byKey(FileModeration.cleAction(ActionModeration.rejeter)),
      );
      expect(find.text(m.indisponible), findsOneWidget);
    });

    testWidgets('file vide', (WidgetTester tester) async {
      await monterAdministration(
        tester,
        onglet: OngletCommunications.moderation,
        moderation: ModerationAdministrationDemo(
          maintenant: maintenantBanc,
          vide: true,
        ),
      );
      expect(find.text(m.videTitre), findsOneWidget);
    });

    testWidgets('production : port neutre, pas encore disponible', (
      WidgetTester tester,
    ) async {
      await monterAdministration(
        tester,
        onglet: OngletCommunications.moderation,
        neutre: true,
      );
      expect(find.text(m.indisponible), findsOneWidget);
      expect(find.byType(MarqueDemonstration), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('hors ligne : la phrase de la spec, avec Reessayer', (
      WidgetTester tester,
    ) async {
      await monterAdministration(
        tester,
        onglet: OngletCommunications.moderation,
        surcharges: surchargesDemoSansAnnonces(moderation: _FileEnPanne()),
        horsLigne: true,
      );
      expect(find.text(t.com.socle.composants.etats.horsLigne), findsOneWidget);
    });
  });
}

/// Une moderation dont la file ne se lit pas (reseau coupe).
class _FileEnPanne extends ModerationAdministrationDemo {
  _FileEnPanne() : super(maintenant: maintenantBanc);

  @override
  Future<List<ElementModeration>> file() =>
      Future<List<ElementModeration>>.error(Exception('reseau'));
}
