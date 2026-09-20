import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/content_position.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/library_resource.dart';
import 'package:rewayah_academy/features/tc_catalogue/carte_ressource.dart';
import 'package:rewayah_academy/features/tc_catalogue/class_library_picker.dart';
import 'package:rewayah_academy/features/tc_catalogue/libelles_tc_b.dart';

import 'faux/faux_ports_b.dart';
import 'support/hote_b.dart';

/// Les fichiers qui composent la surface ouverte en classe.
const List<String> _fichiersDeLaSurface = <String>[
  'lib/features/tc_catalogue/class_library_picker.dart',
  'lib/features/tc_catalogue/surface_bibliotheque.dart',
  'lib/features/tc_catalogue/carte_ressource.dart',
  'lib/features/tc_catalogue/vignette_ressource.dart',
  'lib/features/tc_catalogue/libelles_tc_b.dart',
  'lib/core/tc_bibliotheque/vue_catalogue.dart',
  'lib/core/tc_bibliotheque/donnees_catalogue.dart',
  'lib/core/tc_bibliotheque/catalogue_local.dart',
  'lib/core/tc_bibliotheque/port_catalogue.dart',
  'lib/core/tc_bibliotheque/recherche_catalogue.dart',
  'lib/core/tc_telechargement/port_etat_offline.dart',
];

/// Une ligne de code, sans son commentaire.
String _sansCommentaire(String ligne) {
  final int i = ligne.indexOf('//');
  return i == -1 ? ligne : ligne.substring(0, i);
}

void main() {
  group('Aucune dependance a la classe Live', () {
    test('rien de la surface n importe LiveKit ni le moteur de salle', () {
      // Mesure, et non promesse : c'est la seule facon de garantir que choisir
      // un support en classe ne peut pas toucher a la `Room`. Meme methode que
      // `test/appairage/code_local_test.dart`, qui relit les lignes d'appel
      // reseau pour prouver qu'un code ne quitte jamais l'appareil.
      final List<String> fautifs = <String>[];
      for (final String chemin in _fichiersDeLaSurface) {
        final File fichier = File(chemin);
        expect(fichier.existsSync(), isTrue, reason: '$chemin est introuvable');
        // Les commentaires sont retires avant la mesure : ce fichier-ci parle
        // de `disconnect` pour dire qu'il ne l'appelle pas, et une regle qui
        // se declencherait sur sa propre justification ne mesurerait rien.
        final String source = fichier
            .readAsLinesSync()
            .map(_sansCommentaire)
            .join('\n');
        for (final String interdit in <String>[
          'core/video/',
          'livekit_client',
          'moteurSalleProvider',
          'serviceVideoProvider',
          'preVolProvider',
          'disconnect',
        ]) {
          if (source.contains(interdit)) fautifs.add('$chemin : $interdit');
        }
      }

      expect(fautifs, isEmpty);
    });
  });

  group('ClassLibraryPicker : la meme bibliotheque, un autre ordre', () {
    testWidgets('les recents passent devant le groupe (spec 6.2)', (
      WidgetTester tester,
    ) async {
      fenetreHaute(tester);

      await tester.pumpWidget(
        hoteB(
          Scaffold(
            body: ClassLibraryPicker(
              groupeId: 'g1',
              onChoisir: (LibraryResource _, ContentPosition? _) {},
            ),
          ),
          surcharges: surchargesCatalogue(
            ressources: <LibraryResource>[
              ressource(id: 'r1'),
              ressource(id: 'r2'),
            ],
            assignations: <String, List<String>>{
              'g1': <String>['r1'],
            },
            recents: <String>['r2'],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final double yRecents = tester
          .getTopLeft(find.text(LibellesTcB.sectionRecents))
          .dy;
      final double yGroupe = tester
          .getTopLeft(find.text(LibellesTcB.sectionPourCeGroupe))
          .dy;

      expect(yRecents, lessThan(yGroupe));
    });

    testWidgets('choisir un support n appelle que le rappel de l hote', (
      WidgetTester tester,
    ) async {
      fenetreHaute(tester);
      final List<String> choisis = <String>[];

      await tester.pumpWidget(
        hoteB(
          Scaffold(
            body: ClassLibraryPicker(
              groupeId: 'g1',
              onChoisir: (LibraryResource r, ContentPosition? _) =>
                  choisis.add(r.id),
            ),
          ),
          surcharges: surchargesCatalogue(
            ressources: <LibraryResource>[ressource(id: 'r1')],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(CarteRessource));
      await tester.pumpAndSettle();

      // Le selecteur ne ferme rien et ne navigue nulle part : remplacer le
      // support actif est une decision de la Classe Live.
      expect(choisis, <String>['r1']);
      expect(find.byType(ClassLibraryPicker), findsOneWidget);
    });

    testWidgets('une feuille ouverte laisse la page de classe montee', (
      WidgetTester tester,
    ) async {
      fenetreHaute(tester);

      await tester.pumpWidget(
        hoteB(
          Scaffold(
            body: Builder(
              builder: (BuildContext context) => Column(
                children: <Widget>[
                  const Text('classe en cours'),
                  TextButton(
                    onPressed: () => ClassLibraryPicker.ouvrirEnFeuille(
                      context,
                      groupeId: 'g1',
                      onChoisir: (LibraryResource _, ContentPosition? _) {},
                    ),
                    child: const Text('ouvrir'),
                  ),
                ],
              ),
            ),
          ),
          surcharges: surchargesCatalogue(
            ressources: <LibraryResource>[ressource(id: 'r1')],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('ouvrir'));
      await tester.pumpAndSettle();

      // La feuille est une route modale posee par-dessus : la page de classe
      // reste montee, donc le moteur de salle reste connecte.
      expect(find.byType(ClassLibraryPicker), findsOneWidget);
      expect(find.text('classe en cours'), findsOneWidget);
    });

    testWidgets('le panneau dit ce que le choix change, et ce qu il ne change '
        'pas', (WidgetTester tester) async {
      fenetreHaute(tester);

      await tester.pumpWidget(
        hoteB(
          Scaffold(
            body: ClassLibraryPicker(
              groupeId: 'g1',
              onChoisir: (LibraryResource _, ContentPosition? _) {},
            ),
          ),
          surcharges: surchargesCatalogue(
            ressources: <LibraryResource>[ressource(id: 'r1')],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(LibellesTcB.classeSousTitre), findsOneWidget);
    });
  });
}
