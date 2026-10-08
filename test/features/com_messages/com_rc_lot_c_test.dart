// COM-RC, lot C (revue COM-R) : contre-preuves cote Messages et socle.
//
// - R-07 : une seule lecture de fil (adaptateur du socle, mode lecture seule
//   de `FilDiscussion`) et une seule recherche (`ChampRecherche`,
//   `SurfaceRecherche` du core) ;
// - R-23 : `VueEtatCommunication.depuisErreur`, une vue « choisir »
//   partagee qui defile, un seul provider des capacites de moderation ;
// - R-10 : liste d'au moins 320 a 1440, ecart de 24 entre colonnes, retrait
//   de 16 apres le filet, portes par `EspaceTravailAdaptatif`.
//
// Chaque test echouait avant le lot C.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/communications/lecture_fil_communication.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/espace_travail_adaptatif.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';
import 'package:rewayah_academy/core/widgets/vue_etat_communication.dart';
import 'package:rewayah_academy/features/com_messages/fil_contextuel.dart';
import 'package:rewayah_academy/features/com_messages/messages_page.dart';
import 'package:rewayah_academy/features/com_messages/port_messages_metier.dart';
import 'package:rewayah_academy/features/com_messages/recherche_fils.dart';
import 'package:rewayah_academy/features/demo/communications/demo_communications_page.dart';

import '../../support/hote_theme.dart';
import 'support_messages.dart';

/// Les fichiers Dart de [dossier], recursivement.
List<File> _fichiers(String dossier) =>
    Directory(dossier)
        .listSync(recursive: true)
        .whereType<File>()
        .where((File f) => f.path.endsWith('.dart'))
        .toList();

/// Le nombre d'occurrences de [motif] dans les fichiers de [dossiers].
int _occurrences(List<String> dossiers, Pattern motif) {
  int n = 0;
  for (final String d in dossiers) {
    for (final File f in _fichiers(d)) {
      n += motif.allMatches(f.readAsStringSync()).length;
    }
  }
  return n;
}

const List<String> _dossiersCom = <String>[
  'lib/features/com_messages',
  'lib/features/com_studio',
  'lib/features/com_communaute',
  'lib/features/com_annonces',
];

/// Un fil en lecture seule, sans aucun message.
FilMetier _filVideEnLecture() {
  final FilMetier base = filSimple(ecrire: false);
  return FilMetier(
    id: base.id,
    contexte: base.contexte,
    participants: base.participants,
    messages: const <MessageCommunication>[],
    capacites: const <CapaciteFil>{},
  );
}

void main() {
  group('R-07 : une seule lecture de fil', () {
    test('aucune copie du texte ni de la date d un message dans les voies', () {
      // Avant : texteDuMessage / horodatageMessage (Messages) et
      // texteMessageCanal / horodatageCanal (Studio), deux copies.
      expect(_occurrences(_dossiersCom, 'texteMessageCanal'), 0);
      expect(_occurrences(_dossiersCom, 'horodatageCanal'), 0);
      expect(_occurrences(_dossiersCom, RegExp(r'String texteDuMessage\(')), 0);
      expect(
        _occurrences(_dossiersCom, RegExp(r'String horodatageMessage\(')),
        0,
      );
      // Ni deux vues de lecture seule recopiees.
      expect(_occurrences(_dossiersCom, '_FilEnLecture'), 0);
      expect(_occurrences(_dossiersCom, '_CanalEnLecture'), 0);
    });

    test('l adaptateur du socle dit le texte, les pieces et la date', () {
      final FilMetier fil = filSimple();
      final MessageCommunication m = fil.messages.single;
      final MessageFil bulle = messageFilDe(m);
      expect(bulle.texte, texteDuMessage(m, avecVocaux: false));
      expect(bulle.horodatage, horodatageMessage(m.envoyeLe));
      expect(bulle.auteur, 'Sayyida Mariam');
      expect(bulle.deSoi, isFalse);
    });

    testWidgets('un fil en lecture seule est le fil partage, sans champ', (
      WidgetTester tester,
    ) async {
      await monterMessages(
        tester,
        port: FauxMessagesMetier(fils: <FilMetier>[filSimple(ecrire: false)]),
        depart: cheminFilTest('fil-1'),
      );
      expect(find.byType(FilDiscussion), findsOneWidget);
      expect(find.byKey(FilDiscussion.cleLectureSeule), findsOneWidget);
      expect(find.byKey(FilContextuel.cleLectureSeule), findsOneWidget);
      expect(find.byKey(FilDiscussion.champKey), findsNothing);
      expect(find.byKey(FilDiscussion.envoyerKey), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('un fil en lecture seule sans message dit son etat vide '
        '(le canal le disait, le fil non)', (WidgetTester tester) async {
      await monterMessages(
        tester,
        port: FauxMessagesMetier(fils: <FilMetier>[_filVideEnLecture()]),
        depart: cheminFilTest('fil-1'),
      );
      expect(find.byKey(FilDiscussion.cleAucunMessage), findsOneWidget);
      expect(find.byKey(FilContextuel.cleLectureSeule), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('320, texte x2 : la lecture seule ne deborde pas', (
      WidgetTester tester,
    ) async {
      await monterMessages(
        tester,
        port: FauxMessagesMetier(fils: <FilMetier>[filSimple(ecrire: false)]),
        depart: cheminFilTest('fil-1'),
        taille: const Size(320, 640),
        echelleTexte: 2,
      );
      expect(find.byKey(FilContextuel.cleLectureSeule), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('R-07 : une seule recherche', () {
    test('aucune voie ne recompose un champ de recherche', () {
      // Avant : ChampRechercheFils, ChampRechercheStudio et
      // ChampRechercheCommunaute, trois champs (le dernier sans Effacer).
      expect(
        _occurrences(_dossiersCom, 'TextInputAction.search'),
        0,
        reason: 'le champ de recherche est ChampRecherche, dans le core',
      );
      expect(_occurrences(_dossiersCom, 'class ChampRecherche'), 0);
      expect(_occurrences(_dossiersCom, 'class SurfaceRecherche'), 0);
      expect(
        File('lib/core/widgets/champ_recherche.dart').existsSync(),
        isTrue,
      );
      expect(
        File('lib/core/widgets/surface_recherche.dart').existsSync(),
        isTrue,
      );
    });

    testWidgets('Messages, 1440 : « Effacer la recherche » du champ partage', (
      WidgetTester tester,
    ) async {
      await monterMessages(
        tester,
        port: portDemo(RoleDemoCommunications.tuteur),
      );
      await tester.enterText(find.byKey(ClesRechercheFils.champ), 'zzz');
      await tester.pumpAndSettle();
      expect(find.byKey(ClesRechercheFils.effacer), findsOneWidget);
      expect(find.bySemanticsLabel(t.commun.recherche.effacer), findsOneWidget);
      await tester.tap(find.byKey(ClesRechercheFils.effacer));
      await tester.pumpAndSettle();
      expect(find.byKey(ClesRechercheFils.effacer), findsNothing);
    });
  });

  group('R-23 : etats partages', () {
    testWidgets('depuisErreur : capacite absente sans Reessayer, hors ligne '
        'et echec avec', (WidgetTester tester) async {
      int relances = 0;
      Future<void> rendre(Widget vue) async {
        await tester.pumpWidget(hoteTheme(vue));
        await tester.pump();
      }

      await rendre(
        VueEtatCommunication.depuisErreur(
          const CapaciteIndisponible('COM-BR-01'),
          onReessayer: () => relances++,
        ),
      );
      final EtatSysteme indisponible = tester.widget<EtatSysteme>(
        find.byType(EtatSysteme),
      );
      expect(indisponible.nature, NatureEtat.indisponible);
      expect(indisponible.dependance, 'COM-BR-01');
      expect(find.text(t.com.socle.composants.etats.reessayer), findsNothing);

      await rendre(
        VueEtatCommunication.depuisErreur(
          Exception('reseau'),
          horsLigne: true,
          onReessayer: () => relances++,
        ),
      );
      expect(
        tester.widget<EtatSysteme>(find.byType(EtatSysteme)).nature,
        NatureEtat.horsLigne,
      );
      await tester.tap(find.text(t.com.socle.composants.etats.reessayer));
      expect(relances, 1);

      await rendre(VueEtatCommunication.depuisErreur(Exception('serveur')));
      expect(
        tester.widget<EtatSysteme>(find.byType(EtatSysteme)).nature,
        NatureEtat.echecServeur,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('« Choisissez une conversation » defile (comme le Studio), '
        'texte x2 sur une colonne basse', (WidgetTester tester) async {
      await monterMessages(
        tester,
        port: portDemo(RoleDemoCommunications.tuteur),
        taille: const Size(1024, 420),
        echelleTexte: 2,
      );
      final Finder choisir = find.byKey(EspaceMessagesMetier.cleChoisir);
      expect(choisir, findsOneWidget);
      expect(find.byType(VueChoisirCommunication), findsWidgets);
      expect(
        find.descendant(
          of: choisir,
          matching: find.byType(SingleChildScrollView),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    test('un seul provider lit les capacites de moderation', () {
      // Avant : capacitesModerationFileProvider (file) et
      // capacitesModerationCommunauteProvider (publication).
      expect(
        _occurrences(<String>['lib'], 'portModerationProvider).capacites()'),
        1,
        reason: 'capacitesModerationProvider, dans core/communications',
      );
      expect(
        _occurrences(<String>['lib'], 'capacitesModerationFileProvider'),
        0,
      );
      expect(
        _occurrences(<String>['lib'], 'capacitesModerationCommunauteProvider'),
        0,
      );
    });
  });

  group('R-10 : colonnes de l espace adaptatif', () {
    Future<void> monter(WidgetTester tester, Size taille) async {
      fixerVue(tester, taille);
      await tester.pumpWidget(
        hoteTheme(
          const EspaceTravailAdaptatif(
            liste: Center(child: Text('Liste')),
            principal: Center(child: Text('Fil')),
            contexte: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[Text('Contexte')],
            ),
          ),
          defilant: false,
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('1440 : liste d au moins 320, ecart de 24, retrait de 16 '
        'apres le filet', (WidgetTester tester) async {
      await monter(tester, const Size(1440, 900));
      final Rect liste = tester.getRect(
        find.byKey(EspaceTravailAdaptatif.cleListe),
      );
      final Rect colonne = tester.getRect(
        find.byKey(EspaceTravailAdaptatif.cleColonnePrincipale),
      );
      final Rect contenu = tester.getRect(
        find.byKey(EspaceTravailAdaptatif.clePrincipal),
      );
      final Rect contexte = tester.getRect(
        find.byKey(EspaceTravailAdaptatif.cleContexte),
      );
      expect(liste.width, greaterThanOrEqualTo(320));
      expect(colonne.left - liste.right, 24);
      expect(contenu.left - colonne.left, 16);
      expect(contexte.left - colonne.right, 24);
    });

    testWidgets('840 : le contexte ne prend pas une colonne qui laisserait '
        'moins de 320 au contenu ; il s ouvre en feuille', (
      WidgetTester tester,
    ) async {
      await monter(tester, const Size(840, 900));
      expect(find.byKey(EspaceTravailAdaptatif.cleContexte), findsNothing);
      expect(
        find.byKey(EspaceTravailAdaptatif.cleOuvrirContexte),
        findsOneWidget,
      );
      expect(
        tester.getSize(find.byKey(EspaceTravailAdaptatif.clePrincipal)).width,
        greaterThanOrEqualTo(320),
      );
    });

    testWidgets('Messages, 1440 : la recherche tient dans la liste', (
      WidgetTester tester,
    ) async {
      await monterMessages(
        tester,
        port: portDemo(RoleDemoCommunications.enseignant),
        depart: cheminFilTest('fil-adam'),
      );
      expect(
        tester.getSize(find.byKey(EspaceTravailAdaptatif.cleListe)).width,
        greaterThanOrEqualTo(320),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
