// COM-F-b : les complements COM-0b du socle (02_DECOUPAGE, COM-F) et les
// mineurs de la revue COM-F-R.
//
// - Capacites Communications (COM-BR-16, COM-BR-A01) : une source unique,
//   fermee en production, ouverte seulement par surcharge ; aucun fichier des
//   Communications ne lit un role.
// - Icones des voies (02_DEC-01) : posees d'avance, distinctes, Le Studio a
//   la sienne.
// - m3 : « Ouvrir » et « Retirer » sans le nom a l'ecran, le nom pour le
//   lecteur d'ecran.
// - n1 : l'etat d'erreur ne repete pas son titre.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/communications/capacites_communication.dart';
import 'package:rewayah_academy/core/communications/port_pieces_jointes.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/widgets/carte_piece_jointe.dart';
import 'package:rewayah_academy/core/widgets/vue_etat_communication.dart';

import '../../support/hote_theme.dart';

/// Un port qui echoue autrement que par une capacite absente.
class _PortEnPanne implements PortCapacitesCommunications {
  @override
  Future<CapacitesCommunication> capacites() =>
      Future<CapacitesCommunication>.error(StateError('panne'));
}

PieceJointe _piece(EtatPieceJointe etat) => PieceJointe(
  reference: ReferencePieceJointe('pj_7f3a9c'),
  nom: 'devoir-sourate-al-mulk.pdf',
  nature: NaturePieceJointe.document,
  typeLisible: 'PDF',
  tailleOctets: 655360,
  etat: etat,
  peutOuvrir: true,
);

void main() {
  group('Capacites Communications (COM-BR-16)', () {
    test('le port de production leve CapaciteIndisponible(COM-BR-16)', () {
      expect(
        const CapacitesCommunicationsIndisponibles().capacites(),
        throwsA(
          isA<CapaciteIndisponible>().having(
            (CapaciteIndisponible c) => c.dependance,
            'dependance',
            'COM-BR-16',
          ),
        ),
      );
    });

    test('en production, tout est ferme : aucune capacite', () async {
      final ProviderContainer conteneur = ProviderContainer();
      addTearDown(conteneur.dispose);
      expect(
        conteneur.read(portCapacitesCommunicationsProvider),
        isA<CapacitesCommunicationsIndisponibles>(),
      );
      final CapacitesCommunication lues = await conteneur.read(
        capacitesCommunicationProvider.future,
      );
      expect(lues, CapacitesCommunication.aucune);
      for (final CapaciteCommunication c in CapaciteCommunication.values) {
        expect(lues.peut(c), isFalse, reason: c.name);
      }
    });

    test('ouvertes seulement par surcharge (demonstration, tests)', () async {
      final ProviderContainer conteneur = ProviderContainer(
        overrides: [
          portCapacitesCommunicationsProvider.overrideWithValue(
            const CapacitesCommunicationsFixes(<CapaciteCommunication>{}),
          ),
        ],
      );
      addTearDown(conteneur.dispose);
      expect(
        await conteneur.read(capacitesCommunicationProvider.future),
        CapacitesCommunication.aucune,
      );

      final ProviderContainer ouvert = ProviderContainer(
        overrides: [
          portCapacitesCommunicationsProvider.overrideWithValue(
            const CapacitesCommunicationsFixes(<CapaciteCommunication>{
              CapaciteCommunication.publierAnnonce,
              CapaciteCommunication.ecrireDansFil,
            }),
          ),
        ],
      );
      addTearDown(ouvert.dispose);
      final CapacitesCommunication lues = await ouvert.read(
        capacitesCommunicationProvider.future,
      );
      expect(lues.peut(CapaciteCommunication.publierAnnonce), isTrue);
      expect(lues.peut(CapaciteCommunication.ecrireDansFil), isTrue);
      expect(lues.peut(CapaciteCommunication.programmer), isFalse);
      expect(lues.peut(CapaciteCommunication.envoyerVocal), isFalse);
    });

    test(
      'une panne n est pas une capacite absente : elle reste une erreur',
      () {
        final ProviderContainer conteneur = ProviderContainer(
          overrides: [
            portCapacitesCommunicationsProvider.overrideWithValue(
              _PortEnPanne(),
            ),
          ],
        );
        addTearDown(conteneur.dispose);
        expect(
          conteneur.read(capacitesCommunicationProvider.future),
          throwsA(isA<StateError>()),
        );
      },
    );

    test('les quatre capacites de COM-BR-16, dans cet ordre (envoyerVocal '
        'ajoutee a COM-FUS ; moderer et parametresCanal retirees, sources '
        'uniques dans leur domaine, revue COM-R R-21)', () {
      expect(CapaciteCommunication.values, <CapaciteCommunication>[
        CapaciteCommunication.publierAnnonce,
        CapaciteCommunication.programmer,
        CapaciteCommunication.ecrireDansFil,
        CapaciteCommunication.envoyerVocal,
      ]);
    });

    test('aucun fichier des Communications ne lit un role', () {
      // CLAUDE.md : un widget lit une capacite, jamais un role. Le choix de
      // la cloche par role est fait par le routeur, hors de ces dossiers ;
      // la demonstration choisit une personne fictive, hors production, et
      // n'est pas lue ici.
      final List<String> fautifs = <String>[
        for (final String racine in <String>[
          'lib/core/communications',
          'lib/features/com_annonces',
          'lib/features/com_communaute',
          'lib/features/com_messages',
          'lib/features/com_studio',
          // COM-RC (R-26) : le vocal et le centre de notifications aussi.
          'lib/features/com_vocal',
          'lib/features/notifications',
        ])
          if (Directory(racine).existsSync())
            for (final File f
                in Directory(racine)
                    .listSync(recursive: true)
                    .whereType<File>()
                    .where((File f) => f.path.endsWith('.dart')))
              if (RegExp(r'\bAppRole\b|\.role\b')
                  .hasMatch(f.readAsStringSync()))
                f.path,
        for (final String fichier in <String>[
          'lib/core/widgets/badge_non_lu.dart',
          'lib/core/widgets/carte_piece_jointe.dart',
          'lib/core/widgets/espace_travail_adaptatif.dart',
          'lib/core/widgets/fil_discussion.dart',
          'lib/core/widgets/vue_etat_communication.dart',
        ])
          if (RegExp(r'\bAppRole\b|\.role\b')
              .hasMatch(File(fichier).readAsStringSync()))
            fichier,
      ];
      expect(fautifs, isEmpty);
    });
  });

  group('Icones des voies (02_DEC-01)', () {
    final Map<String, AppIcon> voies = <String, AppIcon>{
      'pieceJointe': AppIcons.pieceJointe,
      'epingle': AppIcons.epingle,
      'lien': AppIcons.lien,
      'telecharger': AppIcons.telecharger,
      'arret': AppIcons.arret,
      'annonce': AppIcons.annonce,
      'studio': AppIcons.studio,
    };

    test('chaque icone garde le meme glyphe dans ses deux graisses', () {
      for (final MapEntry<String, AppIcon> e in voies.entries) {
        expect(e.value.repos.codePoint, e.value.actif.codePoint, reason: e.key);
        expect(e.value.repos.fontFamily, 'Phosphor', reason: e.key);
        expect(e.value.actif.fontFamily, 'PhosphorFill', reason: e.key);
      }
    });

    test('sept glyphes distincts, aucun detourne d une icone existante', () {
      final Set<int> points = voies.values
          .map((AppIcon i) => i.repos.codePoint)
          .toSet();
      expect(points.length, voies.length);
      // Les glyphes deja employes ailleurs, qu'une voie aurait pu detourner.
      for (final AppIcon existante in <AppIcon>[
        AppIcons.discussion,
        AppIcons.envoyerMessage,
        AppIcons.ajouter,
        AppIcons.enAttenteEnvoi,
        AppIcons.pause,
        AppIcons.notifications,
        AppIcons.tableauDeBord,
      ]) {
        expect(points, isNot(contains(existante.repos.codePoint)));
      }
    });

    test('Le Studio n emprunte plus l icone des Echanges', () {
      expect(AppIcons.studio.repos, isNot(AppIcons.discussion.repos));
      final String coquille = File('lib/core/widgets/admin_shell.dart')
          .readAsStringSync();
      expect(coquille, isNot(contains('AppIcons.discussion')));
      expect(RegExp('AppIcons\\.studio').allMatches(coquille).length, 2);
    });
  });

  group('m3 : le verbe a l ecran, le nom pour le lecteur d ecran', () {
    final p = t.com.socle.composants.pieceJointe;

    testWidgets('Ouvrir', (WidgetTester tester) async {
      final SemanticsHandle semantique = tester.ensureSemantics();
      await tester.pumpWidget(
        hoteTheme(
          CartePieceJointe(
            piece: _piece(EtatPieceJointe.envoyee),
            onOuvrir: () {},
          ),
        ),
      );
      expect(find.text(p.ouvrir), findsOneWidget);
      expect(
        find.textContaining(p.ouvrirLecteur(nom: 'devoir-sourate-al-mulk.pdf')),
        findsNothing,
      );
      expect(
        find.bySemanticsLabel(
          p.ouvrirLecteur(nom: 'devoir-sourate-al-mulk.pdf'),
        ),
        findsOneWidget,
      );
      semantique.dispose();
    });

    testWidgets('Retirer', (WidgetTester tester) async {
      final SemanticsHandle semantique = tester.ensureSemantics();
      var retraits = 0;
      await tester.pumpWidget(
        hoteTheme(
          CartePieceJointe(
            piece: _piece(EtatPieceJointe.autorisee),
            onRetirer: () => retraits++,
          ),
        ),
      );
      expect(find.text(p.retirer), findsOneWidget);
      final Finder lu = find.bySemanticsLabel(
        p.retirerLecteur(nom: 'devoir-sourate-al-mulk.pdf'),
      );
      expect(lu, findsOneWidget);
      await tester.tap(find.byKey(CartePieceJointe.cleRetirer));
      expect(retraits, 1);
      semantique.dispose();
    });

    testWidgets('320 px, texte x2 : « Retirer » tient sur une ligne', (
      WidgetTester tester,
    ) async {
      fixerVue(tester, const Size(320, 900));
      await tester.pumpWidget(
        hoteTheme(
          CartePieceJointe(
            piece: _piece(EtatPieceJointe.echec),
            onRetirer: () {},
            onReessayer: () {},
          ),
          echelleTexte: 2,
        ),
      );
      expect(tester.takeException(), isNull);
      final double ligne = tester.getSize(find.text(p.retirer)).height;
      final double corps = tester
          .getSize(
            find.text(CartePieceJointe.libelleEtat(EtatPieceJointe.echec)),
          )
          .height;
      // Une seule ligne : pas plus haute qu'une ligne d'etiquette a x2.
      expect(ligne, lessThanOrEqualTo(corps * 1.5));
    });
  });

  testWidgets('n1 : l erreur dit son titre une fois, puis quoi faire', (
    WidgetTester tester,
  ) async {
    final e = t.com.socle.composants.etats;
    expect(e.erreur, isNot(contains(e.erreurTitre)));
    expect(e.erreur.toLowerCase(), contains('réessayez'));
    await tester.pumpWidget(
      hoteTheme(
        VueEtatCommunication(
          etat: EtatCommunication.erreur,
          onReessayer: () {},
        ),
      ),
    );
    expect(find.textContaining(e.erreurTitre), findsOneWidget);
    expect(find.text(e.erreur), findsOneWidget);
  });
}
