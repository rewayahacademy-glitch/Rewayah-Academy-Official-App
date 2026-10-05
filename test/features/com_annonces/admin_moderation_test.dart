// COM-ANN-2 : la file de moderation de l'Administration des communications
// (`ModerationQueue`, spec section 5.5). Les actions ne se montrent qu'avec
// la capacite du serveur, une decision n'est dite qu'apres l'accuse, les
// motifs viennent du socle, la regle visee reprend les textes de COM-COMU-2
// sans importer sa voie. Rendu verifie a 390, 768 et 1440, et en arabe.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/communications/moderation.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/espace_travail_adaptatif.dart';
import 'package:rewayah_academy/core/widgets/stat_tile.dart';
import 'package:rewayah_academy/core/widgets/status_pill.dart';
import 'package:rewayah_academy/features/com_annonces/administration_communications_page.dart';
import 'package:rewayah_academy/features/com_annonces/annonces_planifiees.dart';
import 'package:rewayah_academy/features/com_annonces/file_moderation.dart';
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
        // La regle visee : le texte de COM-COMU-2, repris dans la voie.
        expect(find.text(m.regleMotif.lienAffilie), findsOneWidget);
        expect(
          regleVisee(MotifSignalement.lienAffilie),
          m.regleMotif.lienAffilie,
        );
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
      expect(find.byKey(FileModeration.clePolitique), findsOneWidget);
      expect(find.text(m.regles.titre), findsOneWidget);
      expect(find.text(m.regles.pasAffilie), findsOneWidget);
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

  group('Moderation : revue COM-ANN-2', () {
    test('la voie COM-ANN n importe rien de la voie COM-COMU', () {
      final List<File> fichiers = <File>[
        ...Directory('lib/features/com_annonces')
            .listSync(recursive: true)
            .whereType<File>()
            .where((File f) => f.path.endsWith('.dart')),
        File('lib/features/demo/communications/com_annonces_demo.dart'),
        ...Directory('test/features/com_annonces')
            .listSync(recursive: true)
            .whereType<File>()
            .where((File f) => f.path.endsWith('.dart')),
      ];
      final RegExp importCommunaute = RegExp(
        r"^import\s+'[^']*(com_communaute/|com_communaute_demo\.dart)",
        multiLine: true,
      );
      for (final File f in fichiers) {
        expect(
          importCommunaute.hasMatch(f.readAsStringSync()),
          isFalse,
          reason: f.path,
        );
      }
    });

    test('regle visee : seulement les quatre motifs de la politique', () {
      for (final MotifSignalement motif in MotifSignalement.values) {
        final bool politique = <MotifSignalement>{
          MotifSignalement.publicite,
          MotifSignalement.lienAffilie,
          MotifSignalement.venteNonAutorisee,
          MotifSignalement.sollicitationCommerciale,
        }.contains(motif);
        expect(regleVisee(motif) != null, politique, reason: motif.name);
      }
    });

    testWidgets('apres l accuse, la file est relue : le traite en sort', (
      WidgetTester tester,
    ) async {
      final _FileQuiSuit moderation = _FileQuiSuit();
      await monterAdministration(
        tester,
        onglet: OngletCommunications.moderation,
        moderation: moderation,
      );
      expect(moderation.lectures, 1);
      await taper(tester, _ligne(d.signalementVente));
      await taper(
        tester,
        find.byKey(FileModeration.cleAction(ActionModeration.approuver)),
      );
      expect(find.text(m.enregistree), findsOneWidget);
      expect(moderation.lectures, 2);
      // Le serveur l'a sorti de la file : la ligne et le detail disparaissent.
      expect(find.text(d.signalementVente), findsNothing);
      expect(
        find.byKey(FileModeration.cleDetail('demo-sig-vente')),
        findsNothing,
      );
      expect(find.text(d.signalementAffilie), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('le compteur des Annonces suit la decision', (
      WidgetTester tester,
    ) async {
      final _FileQuiSuit moderation = _FileQuiSuit();
      final GoRouter router = await monterAdministration(
        tester,
        moderation: moderation,
      );
      int valeur() => tester
          .widget<StatTile>(
            find.byWidgetPredicate(
              (Widget w) =>
                  w is StatTile &&
                  w.libelle ==
                      t.com.annonces.administration.indicateurs.moderation,
            ),
          )
          .valeur;
      expect(valeur(), 3);
      await taper(
        tester,
        find.byWidgetPredicate(
          (Widget w) =>
              w is StatTile &&
              w.libelle == t.com.annonces.administration.indicateurs.moderation,
        ),
      );
      await taper(tester, _ligne(d.signalementVente));
      await taper(
        tester,
        find.byKey(FileModeration.cleAction(ActionModeration.rejeter)),
      );
      router.go(Routes.adminCommunicationsAnnonces);
      await tester.pumpAndSettle();
      expect(valeur(), 2);
    });

    for (final ActionModeration action in <ActionModeration>[
      ActionModeration.rejeter,
      ActionModeration.approuver,
      ActionModeration.masquer,
    ]) {
      testWidgets('${action.name} : meme ton de pastille, ligne et detail', (
        WidgetTester tester,
      ) async {
        await monterAdministration(
          tester,
          onglet: OngletCommunications.moderation,
        );
        await taper(tester, _ligne(d.signalementAffilie));
        await taper(tester, find.byKey(FileModeration.cleAction(action)));
        final StatusPill ligne = tester.widget<StatusPill>(
          find.byKey(
            FileModeration.clePastilleDecision(
              'demo-sig-affilie',
              detail: false,
            ),
          ),
        );
        final StatusPill detail = tester.widget<StatusPill>(
          find.byKey(
            FileModeration.clePastilleDecision(
              'demo-sig-affilie',
              detail: true,
            ),
          ),
        );
        expect(ligne.ton, detail.ton);
        expect(ligne.ton, tonDecision(action));
      });
    }
    test('signalement rejete : ton neutre, le contenu reste tel quel', () {
      expect(tonDecision(ActionModeration.rejeter), TonEtat.neutre);
      expect(tonDecision(ActionModeration.masquer), TonEtat.avertissement);
      expect(tonDecision(ActionModeration.approuver), TonEtat.succes);
      expect(tonDecision(ActionModeration.restaurer), TonEtat.succes);
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
      // D-FUS-3 : le bandeau des Communications (plus le generique).
      // COM-RC tour 6 (COM-R-4 8.3-2) : un seul message hors ligne, propre
      // a la moderation ; la file dit seulement ce qui n'est pas charge.
      // Contre-preuve : a a1a33222, la phrase des « nouveaux messages »
      // paraissait deux fois.
      final e = t.com.socle.composants.etats;
      expect(find.text(t.reseau.horsLigne), findsNothing);
      expect(find.text(e.horsLigne), findsNothing);
      expect(find.text(m.horsLigne), findsOneWidget);
      expect(find.textContaining('hors ligne'), findsOneWidget);
      expect(find.text(e.horsLigneBloc), findsOneWidget);
      expect(find.text(e.reessayer), findsOneWidget);
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

/// Une moderation dont la file suit les decisions comme le serveur : un
/// signalement approuve, rejete ou restaure en sort ; elle compte ses
/// lectures.
class _FileQuiSuit extends ModerationAdministrationDemo {
  _FileQuiSuit() : super(maintenant: maintenantBanc);

  int lectures = 0;

  @override
  Future<List<ElementModeration>> file() async {
    lectures++;
    final Set<String> traites = <String>{
      for (final (String id, ActionModeration a) in decisions)
        if (a != ActionModeration.masquer) id,
    };
    return <ElementModeration>[
      for (final ElementModeration e in await super.file())
        if (!traites.contains(e.id)) e,
    ];
  }
}
