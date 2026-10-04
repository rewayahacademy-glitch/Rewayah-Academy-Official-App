// COM-MSG-1 : les Messages metier, rendus par la vraie `MessagesPage`
// (COM-M01, COM-W01 ; spec sections 3, 16, 17, 23, 25 ; R-COM-01, R-COM-02,
// R-COM-13, R-COM-15). Mesures a 390, 768 et 1440, en francais et en arabe
// (RTL), clair et sombre, texte x2.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/communications/badge_non_lu.dart';
import 'package:rewayah_academy/core/widgets/communications/carte_piece_jointe.dart';
import 'package:rewayah_academy/core/widgets/communications/espace_travail_adaptatif.dart';
import 'package:rewayah_academy/core/widgets/communications/etats_communication.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';
import 'package:rewayah_academy/features/com_messages/entete_fil_contexte.dart';
import 'package:rewayah_academy/features/com_messages/fil_contextuel.dart';
import 'package:rewayah_academy/features/com_messages/liste_fils.dart';
import 'package:rewayah_academy/features/com_messages/messages_page.dart';
import 'package:rewayah_academy/features/com_messages/panneau_contexte_fil.dart';
import 'package:rewayah_academy/features/com_messages/port_messages_metier.dart';
import 'package:rewayah_academy/features/com_messages/recherche_fils.dart';
import 'package:rewayah_academy/features/demo/communications/com_messages_demo.dart';
import 'package:rewayah_academy/features/demo/communications/demo_communications_page.dart';

import '../../support/garde_interface.dart';
import 'support_messages.dart';

const Size _mobile = Size(390, 844);
const Size _tablette = Size(768, 1024);
const Size _bureau = Size(1440, 900);

bool _present(Key cle) => find.byKey(cle).evaluate().isNotEmpty;

int _panneaux() => <Key>[
  EspaceTravailAdaptatif.cleListe,
  EspaceTravailAdaptatif.clePrincipal,
  EspaceTravailAdaptatif.cleContexte,
].where(_present).length;

Finder _dansListe(Finder cible) => find.descendant(
  of: find.byKey(EspaceTravailAdaptatif.cleListe),
  matching: cible,
);

Finder _dansPrincipal(Finder cible) => find.descendant(
  of: find.byKey(EspaceTravailAdaptatif.clePrincipal),
  matching: cible,
);

Finder _dansFil(Finder cible) =>
    find.descendant(of: find.byType(FilDiscussion), matching: cible);

final RegExp _coordonnee = RegExp(r'@|\+?\d[\d .-]{7,}\d');

void main() {
  group('Disposition (spec section 23)', () {
    testWidgets('1440, fil ouvert : Conversations | Fil | Contexte', (
      WidgetTester tester,
    ) async {
      await monterMessages(
        tester,
        port: portDemo(RoleDemoCommunications.enseignant),
        depart: cheminFilTest('fil-adam'),
      );
      expect(_panneaux(), 3);
      expect(
        tester.getSize(find.byKey(EspaceTravailAdaptatif.cleListe)).width,
        EspaceTravailAdaptatif.largeurListe,
      );
      expect(_dansListe(find.byType(ListeFils)), findsOneWidget);
      expect(_dansPrincipal(find.byType(FilDiscussion)), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(EspaceTravailAdaptatif.cleContexte),
          matching: find.byType(PanneauContexteFil),
        ),
        findsOneWidget,
      );
      // L'ordre : liste au debut, contexte a la fin.
      final double xListe = tester
          .getTopLeft(find.byKey(EspaceTravailAdaptatif.cleListe))
          .dx;
      final double xFil = tester
          .getTopLeft(find.byKey(EspaceTravailAdaptatif.clePrincipal))
          .dx;
      final double xContexte = tester
          .getTopLeft(find.byKey(EspaceTravailAdaptatif.cleContexte))
          .dx;
      expect(xListe < xFil && xFil < xContexte, isTrue);
      verifierUnSeulBoutonPlein(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('1440, sans fil : la liste et la phrase qui guide, '
        'aucune colonne de contexte vide', (WidgetTester tester) async {
      await monterMessages(
        tester,
        port: portDemo(RoleDemoCommunications.enseignant),
      );
      expect(_panneaux(), 2);
      expect(find.byKey(EspaceMessagesMetier.cleChoisir), findsOneWidget);
      expect(find.text(t.com.messages.choisirTitre), findsOneWidget);
      expect(find.byKey(EspaceTravailAdaptatif.cleContexte), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('768 : Conversations | Fil, le contexte en feuille', (
      WidgetTester tester,
    ) async {
      await monterMessages(
        tester,
        port: portDemo(RoleDemoCommunications.enseignant),
        depart: cheminFilTest('fil-adam'),
        taille: _tablette,
      );
      expect(_panneaux(), 2);
      expect(find.byKey(EspaceTravailAdaptatif.cleContexte), findsNothing);
      expect(find.byType(PanneauContexteFil), findsNothing);
      await tester.tap(find.byKey(EspaceTravailAdaptatif.cleOuvrirContexte));
      await tester.pumpAndSettle();
      expect(find.byType(PanneauContexteFil), findsOneWidget);
      expect(find.text(t.com.messages.panneau.participants), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('390 : une surface a la fois, la liste puis le fil', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await monterMessages(
        tester,
        port: portDemo(RoleDemoCommunications.enseignant),
        taille: _mobile,
      );
      expect(_panneaux(), 1);
      expect(find.byType(ListeFils), findsOneWidget);
      expect(find.byType(FilDiscussion), findsNothing);
      await tester.tap(find.byKey(ListeFils.cleLigne('fil-adam')));
      await tester.pumpAndSettle();
      expect(cheminCourant(routeur), cheminFilTest('fil-adam'));
      expect(_panneaux(), 1);
      expect(find.byType(ListeFils), findsNothing);
      expect(find.byType(FilDiscussion), findsOneWidget);
      // Le retour de la page ramene a la liste.
      await tester.tap(find.byType(DisqueRetour));
      await tester.pumpAndSettle();
      expect(cheminCourant(routeur), cheminListeTest);
      expect(find.byType(ListeFils), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('pas de bouton global « Nouveau message », ni annuaire', (
      WidgetTester tester,
    ) async {
      await monterMessages(
        tester,
        port: portDemo(RoleDemoCommunications.tuteur),
      );
      final String tout = textesRendus(tester).join(' ').toLowerCase();
      expect(tout.contains('nouveau message'), isFalse);
      expect(tout.contains('nouvelle conversation'), isFalse);
      expect(tout.contains('annuaire'), isFalse);
    });

    for (final Size taille in <Size>[_mobile, _tablette, _bureau]) {
      for (final Brightness lum in Brightness.values) {
        testWidgets('aucun debordement a ${taille.width.toInt()}, '
            '${lum.name}, texte x2', (WidgetTester tester) async {
          await monterMessages(
            tester,
            port: portDemo(RoleDemoCommunications.tuteur),
            depart: cheminFilTest('fil-adam'),
            taille: taille,
            luminosite: lum,
            echelleTexte: 2,
          );
          expect(find.byType(FilDiscussion), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  group('R-COM-01 : le fil contextuel', () {
    testWidgets('l enseignant touche une conversation : bon parent, '
        'bon eleve, contexte de Classe, aucune coordonnee', (
      WidgetTester tester,
    ) async {
      await monterMessages(
        tester,
        port: portDemo(RoleDemoCommunications.enseignant),
      );
      await tester.tap(find.byKey(ListeFils.cleLigne('fil-adam')));
      await tester.pumpAndSettle();

      final Finder entete = find.byKey(EnteteFilContexte.cle);
      expect(entete, findsOneWidget);
      expect(
        find.descendant(
          of: entete,
          matching: find.text("Ahmed, Parent d'Adam"),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: entete,
          matching: find.text('Classe An-Nour · Adam'),
        ),
        findsOneWidget,
      );
      // Le lecteur d'ecran entend l'en-tete d'un bloc.
      expect(
        tester.getSemantics(entete).label,
        contains("Conversation avec Ahmed, Parent d'Adam"),
      );
      // Le panneau : objets lies et participants.
      final Finder panneau = find.byType(PanneauContexteFil);
      expect(
        find.descendant(of: panneau, matching: find.text('Classe An-Nour')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: panneau, matching: find.text('Adam')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: panneau, matching: find.text('Ahmed')),
        findsOneWidget,
      );
      // Aucune coordonnee privee nulle part a l'ecran.
      for (final String texte in textesRendus(tester)) {
        expect(_coordonnee.hasMatch(texte), isFalse, reason: texte);
      }
    });

    testWidgets('le vocal et la piece jointe se disent dans le fil et '
        'se montrent dans le panneau, sans adresse', (
      WidgetTester tester,
    ) async {
      await monterMessages(
        tester,
        port: portDemo(RoleDemoCommunications.tuteur),
        depart: cheminFilTest('fil-adam'),
      );
      expect(
        _dansPrincipal(find.textContaining('Message vocal de 0:28')),
        findsOneWidget,
      );
      expect(
        _dansPrincipal(
          find.textContaining('Pièce jointe : Devoir_semaine_3.pdf'),
        ),
        findsOneWidget,
      );
      final Finder fichiers = find.byKey(PanneauContexteFil.cleFichiers);
      expect(
        find.descendant(of: fichiers, matching: find.byType(CartePieceJointe)),
        findsNWidgets(2),
      );
      // Ouvrir passe par un jeton ephemere absent : aucune action rendue.
      expect(find.byKey(CartePieceJointe.cleOuvrir), findsNothing);
      for (final String texte in textesRendus(tester)) {
        expect(texte.contains('pj-'), isFalse, reason: texte);
        expect(texte.contains('http'), isFalse, reason: texte);
      }
    });

    testWidgets('ouvrir un fil le marque lu : le badge de sa ligne tombe', (
      WidgetTester tester,
    ) async {
      await monterMessages(
        tester,
        port: portDemo(RoleDemoCommunications.tuteur),
      );
      Finder badgeDe(String id) => find.descendant(
        of: find.ancestor(
          of: find.byKey(ListeFils.cleLigne(id)),
          matching: find.byType(MergeSemantics),
        ),
        matching: find.byType(BadgeNonLu),
      );
      expect(find.byType(BadgeNonLu), findsNWidgets(2));
      await tester.tap(find.byKey(ListeFils.cleLigne('fil-adam')));
      await tester.pumpAndSettle();
      expect(
        _dansListe(find.byType(BadgeNonLu)),
        findsOneWidget,
        reason: 'seul le dossier attend encore',
      );
      expect(badgeDe('fil-adam'), findsNothing);
    });

    testWidgets('un objet lie ouvre son module ; un objet inaccessible est '
        'nomme sans geste', (WidgetTester tester) async {
      final GoRouter routeur = await monterMessages(
        tester,
        port: FauxMessagesMetier(
          fils: <FilMetier>[
            filSimple(destinationClasse: '/tuteur/classes/an-nour'),
            filSimple(id: 'fil-2', classeAccessible: false),
          ],
        ),
        depart: cheminFilTest('fil-1'),
      );
      await tester.tap(
        find.descendant(
          of: find.byType(PanneauContexteFil),
          matching: find.text('Classe An-Nour'),
        ),
      );
      await tester.pumpAndSettle();
      expect(cheminCourant(routeur), '/tuteur/classes/an-nour');

      routeur.go(cheminFilTest('fil-2'));
      await tester.pumpAndSettle();
      expect(find.text(t.com.messages.panneau.inaccessible), findsOneWidget);
      // Une ligne sans destination ne porte pas de geste.
      await tester.tap(
        find.descendant(
          of: find.byType(PanneauContexteFil),
          matching: find.text('Classe An-Nour'),
        ),
      );
      await tester.pumpAndSettle();
      expect(cheminCourant(routeur), cheminFilTest('fil-2'));
    });
  });

  group('R-COM-02 : jamais le fil d une autre famille', () {
    testWidgets('le port refuse : rien du fil n est rendu', (
      WidgetTester tester,
    ) async {
      await monterMessages(
        tester,
        port: portDemo(RoleDemoCommunications.tuteur),
        depart: cheminFilTest(filAutreFamilleDemo),
      );
      expect(
        find.text(t.com.socle.composants.etats.permissionRefusee),
        findsOneWidget,
      );
      expect(find.byType(FilDiscussion), findsNothing);
      expect(find.byType(EnteteFilContexte), findsNothing);
      expect(find.byType(PanneauContexteFil), findsNothing);
      expect(find.byKey(EspaceTravailAdaptatif.cleContexte), findsNothing);
    });

    testWidgets('un fil rendu sous un autre identifiant n est pas montre', (
      WidgetTester tester,
    ) async {
      final FauxMessagesMetier port =
          FauxMessagesMetier(fils: <FilMetier>[filSimple()])
            ..filSousUnAutreId = filSimple(
              id: 'fil-famille-b',
              texte: 'Message de la famille B',
            );
      await monterMessages(tester, port: port, depart: cheminFilTest('fil-1'));
      expect(find.textContaining('famille B'), findsNothing);
      expect(
        find.text(t.com.socle.composants.etats.permissionRefusee),
        findsOneWidget,
      );
    });

    testWidgets('une annonce ou un canal ne figurent pas dans la liste', (
      WidgetTester tester,
    ) async {
      await monterMessages(
        tester,
        port: FauxMessagesMetier(
          fils: <FilMetier>[filSimple()],
          resumesEnPlus: <ResumeFil>[
            ResumeFil(
              id: 'annonce-1',
              objet: ObjetLie(
                type: TypeObjetLie.annonce,
                id: 'a1',
                libelle: 'Rappel : sortie scolaire',
              ),
              interlocuteurs: const <Participant>[],
            ),
          ],
        ),
      );
      expect(find.byKey(ListeFils.cleLigne('fil-1')), findsOneWidget);
      expect(find.byKey(ListeFils.cleLigne('annonce-1')), findsNothing);
      expect(find.textContaining('sortie scolaire'), findsNothing);
    });
  });

  group('R-COM-13 : un echec n affiche jamais « Envoye »', () {
    testWidgets('echec puis nouvel essai avec la meme cle', (
      WidgetTester tester,
    ) async {
      final MessagesMetierDemo port = portDemo(
        RoleDemoCommunications.enseignant,
        situation: SituationDemoMessages.echecEnvoi,
      );
      await monterMessages(
        tester,
        port: port,
        depart: cheminFilTest('fil-adam'),
      );
      final x = t.com.socle.composants.composer;
      await tester.enterText(find.byKey(FilDiscussion.champKey), 'Merci !');
      await tester.pump();
      await tester.tap(find.byKey(FilDiscussion.envoyerKey));
      await tester.pumpAndSettle();
      expect(_dansFil(find.text(x.nonConfirme)), findsOneWidget);
      expect(_dansFil(find.text(x.envoye)), findsNothing);
      expect(find.text(x.reessayer), findsOneWidget);

      await tester.tap(find.text(x.reessayer));
      await tester.pumpAndSettle();
      expect(_dansFil(find.text(x.envoye)), findsOneWidget);
      expect(_dansFil(find.text(x.nonConfirme)), findsNothing);
      expect(port.clesRecues, hasLength(2));
      expect(port.clesRecues.first, port.clesRecues.last);
    });

    testWidgets('hors ligne : bandeau des communications, contenu garde, '
        'envoi non confirme', (WidgetTester tester) async {
      await monterMessages(
        tester,
        port: portDemo(
          RoleDemoCommunications.tuteur,
          situation: SituationDemoMessages.horsLigne,
        ),
        depart: cheminFilTest('fil-adam'),
        horsLigne: true,
      );
      expect(find.text(t.com.socle.composants.etats.horsLigne), findsOneWidget);
      expect(find.byType(FilDiscussion), findsOneWidget);
      await tester.enterText(find.byKey(FilDiscussion.champKey), 'Bonjour');
      await tester.pump();
      await tester.tap(find.byKey(FilDiscussion.envoyerKey));
      await tester.pumpAndSettle();
      expect(
        _dansFil(find.text(t.com.socle.composants.composer.nonConfirme)),
        findsOneWidget,
      );
      expect(
        _dansFil(find.text(t.com.socle.composants.composer.envoye)),
        findsNothing,
      );
    });
  });

  group('R-COM-15 : clavier logiciel', () {
    testWidgets('a 390 avec un clavier de 300, le champ reste visible et '
        'le dernier message aussi', (WidgetTester tester) async {
      await monterMessages(
        tester,
        port: portDemo(RoleDemoCommunications.tuteur),
        depart: cheminFilTest('fil-adam'),
        taille: _mobile,
      );
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.showKeyboard(find.byKey(FilDiscussion.champKey));
      await tester.pumpAndSettle();
      const double hautVisible = 844 - 300;
      final Rect champ = tester.getRect(find.byKey(FilDiscussion.champKey));
      expect(champ.bottom, lessThanOrEqualTo(hautVisible));
      final Rect envoyer = tester.getRect(find.byKey(FilDiscussion.envoyerKey));
      expect(envoyer.bottom, lessThanOrEqualTo(hautVisible));
      // Le dernier message reste lisible au-dessus du champ.
      final Rect dernier = tester.getRect(
        find.byKey(const ValueKey<String>('message-adam-4')),
      );
      expect(dernier.bottom, lessThanOrEqualTo(champ.top));
      expect(dernier.top, greaterThanOrEqualTo(0));
      expect(tester.takeException(), isNull);
    });
  });

  group('Etats (spec section 25)', () {
    testWidgets('chargement : squelette', (WidgetTester tester) async {
      final FauxMessagesMetier port = FauxMessagesMetier(
        fils: <FilMetier>[filSimple()],
      )..attenteListe = Completer<void>();
      await monterMessages(
        tester,
        port: port,
        taille: _mobile,
        stabiliser: false,
      );
      expect(find.byKey(VueEtatCommunication.cleChargement), findsOneWidget);
      port.attenteListe!.complete();
      await tester.pumpAndSettle();
      expect(find.byType(ListeFils), findsOneWidget);
    });

    testWidgets('vide : « Aucune conversation pour le moment. »', (
      WidgetTester tester,
    ) async {
      await monterMessages(tester, port: FauxMessagesMetier());
      expect(find.text(t.com.messages.vide), findsOneWidget);
      expect(find.text(t.com.messages.videDetail), findsOneWidget);
      // Rien a choisir : ni liste vide en colonne, ni phrase « Choisissez ».
      expect(find.byKey(EspaceTravailAdaptatif.cleListe), findsNothing);
      expect(find.byKey(EspaceMessagesMetier.cleChoisir), findsNothing);
    });

    testWidgets('erreur : « Reessayer » relit la liste', (
      WidgetTester tester,
    ) async {
      final FauxMessagesMetier port = FauxMessagesMetier(
        fils: <FilMetier>[filSimple()],
      )..erreurListe = Exception('reseau');
      await monterMessages(tester, port: port);
      expect(
        find.text(t.com.socle.composants.etats.erreurTitre),
        findsOneWidget,
      );
      port.erreurListe = null;
      await tester.tap(find.text(t.com.socle.composants.etats.reessayer));
      await tester.pumpAndSettle();
      expect(find.byType(ListeFils), findsOneWidget);
      expect(port.lecturesListe, 2);
    });

    testWidgets('hors ligne sans contenu : l etat hors ligne et '
        '« Reessayer »', (WidgetTester tester) async {
      await monterMessages(
        tester,
        port: FauxMessagesMetier()..erreurListe = Exception('reseau'),
        horsLigne: true,
      );
      expect(find.text(t.com.socle.composants.etats.reessayer), findsWidgets);
      expect(find.text(t.com.socle.composants.etats.horsLigne), findsWidgets);
    });

    testWidgets('port neutre : « pas encore disponible », sans Reessayer', (
      WidgetTester tester,
    ) async {
      await monterMessages(
        tester,
        port: const MessagesMetierIndisponibles(),
        depart: cheminFilTest('fil-1'),
      );
      expect(
        find.text(t.com.socle.composants.etats.indisponibleTitre),
        findsWidgets,
      );
      expect(find.text(t.com.socle.composants.etats.reessayer), findsNothing);
      expect(find.byType(FilDiscussion), findsNothing);
    });

    testWidgets('lecture seule : aucun champ, la limite est dite', (
      WidgetTester tester,
    ) async {
      await monterMessages(
        tester,
        port: FauxMessagesMetier(fils: <FilMetier>[filSimple(ecrire: false)]),
        depart: cheminFilTest('fil-1'),
      );
      expect(find.byType(FilDiscussion), findsNothing);
      expect(find.byKey(FilContextuel.cleLectureSeule), findsOneWidget);
      expect(
        _dansPrincipal(find.textContaining('Bonjour, voici une question')),
        findsOneWidget,
      );
      expect(find.byType(TextField), findsOneWidget, reason: 'la recherche');
    });

    testWidgets('envoi confirme : « Envoye » et la cle part au serveur', (
      WidgetTester tester,
    ) async {
      final FauxMessagesMetier port = FauxMessagesMetier(
        fils: <FilMetier>[filSimple()],
      );
      await monterMessages(tester, port: port, depart: cheminFilTest('fil-1'));
      await tester.enterText(find.byKey(FilDiscussion.champKey), 'Merci');
      await tester.pump();
      await tester.tap(find.byKey(FilDiscussion.envoyerKey));
      await tester.pumpAndSettle();
      expect(
        _dansFil(find.text(t.com.socle.composants.composer.envoye)),
        findsOneWidget,
      );
      expect(port.envois.single.$1, 'fil-1');
      expect(port.envois.single.$2, 'Merci');
      expect(port.envois.single.$3, startsWith('fil-1-'));
    });
  });

  group('Recherche (ThreadSearch)', () {
    testWidgets('1440 : le champ en tete de colonne filtre la liste', (
      WidgetTester tester,
    ) async {
      await monterMessages(
        tester,
        port: portDemo(RoleDemoCommunications.enseignant),
      );
      expect(find.byKey(ChampRechercheFils.cle), findsOneWidget);
      await tester.enterText(find.byKey(ChampRechercheFils.cle), 'yasmine');
      await tester.pumpAndSettle();
      expect(find.byKey(ListeFils.cleLigne('fil-yasmine')), findsOneWidget);
      expect(find.byKey(ListeFils.cleLigne('fil-adam')), findsNothing);
      expect(find.text(t.com.messages.recherche.resultatUn), findsOneWidget);

      await tester.enterText(find.byKey(ChampRechercheFils.cle), 'zzz');
      await tester.pumpAndSettle();
      expect(find.text(t.com.messages.recherche.aucunTitre), findsOneWidget);

      await tester.tap(find.byKey(ChampRechercheFils.cleEffacer));
      await tester.pumpAndSettle();
      expect(find.byKey(ListeFils.cleLigne('fil-adam')), findsOneWidget);
      expect(find.byKey(ListeFils.cleLigne('fil-yasmine')), findsOneWidget);
    });

    testWidgets('390 : surface plein ecran temporaire, le retour rend la '
        'liste', (WidgetTester tester) async {
      await monterMessages(
        tester,
        port: portDemo(RoleDemoCommunications.enseignant),
        taille: _mobile,
      );
      expect(find.byKey(ChampRechercheFils.cle), findsNothing);
      await tester.tap(find.byKey(ListeFils.cleOuvrirRecherche));
      await tester.pumpAndSettle();
      expect(find.byKey(SurfaceRechercheFils.cle), findsOneWidget);
      await tester.enterText(find.byKey(ChampRechercheFils.cle), 'direction');
      await tester.pumpAndSettle();
      expect(find.byKey(ListeFils.cleLigne('fil-affectation')), findsOneWidget);
      expect(find.byKey(ListeFils.cleLigne('fil-adam')), findsNothing);

      await tester.tap(find.byKey(SurfaceRechercheFils.cleFermer));
      await tester.pumpAndSettle();
      expect(find.byKey(SurfaceRechercheFils.cle), findsNothing);
      expect(find.byKey(ListeFils.cleLigne('fil-adam')), findsOneWidget);
      expect(find.byKey(ListeFils.cleLigne('fil-affectation')), findsOneWidget);
    });
  });

  group('RTL (arabe)', () {
    testWidgets('1440 : la liste au debut, a droite ; libelles arabes', (
      WidgetTester tester,
    ) async {
      await monterMessages(
        tester,
        port: portDemo(RoleDemoCommunications.enseignant),
        depart: cheminFilTest('fil-adam'),
        langue: AppLocale.ar,
      );
      final Finder page = find.byType(MessagesPage);
      expect(Directionality.of(tester.element(page)), TextDirection.rtl);
      final double xListe = tester
          .getCenter(find.byKey(EspaceTravailAdaptatif.cleListe))
          .dx;
      final double xContexte = tester
          .getCenter(find.byKey(EspaceTravailAdaptatif.cleContexte))
          .dx;
      expect(xListe, greaterThan(xContexte));
      expect(find.text('المشاركون'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('390 : le fil s ouvre sans debordement', (
      WidgetTester tester,
    ) async {
      await monterMessages(
        tester,
        port: portDemo(RoleDemoCommunications.tuteur),
        depart: cheminFilTest('fil-adam'),
        langue: AppLocale.ar,
        taille: _mobile,
      );
      expect(find.byType(FilDiscussion), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  test('le port neutre rend CapaciteIndisponible, jamais une liste vide', () {
    const MessagesMetierIndisponibles port = MessagesMetierIndisponibles();
    expect(
      port.fils(),
      throwsA(
        isA<CapaciteIndisponible>().having(
          (CapaciteIndisponible e) => e.dependance,
          'dependance',
          'COM-BR-01',
        ),
      ),
    );
    expect(port.fil('x'), throwsA(isA<CapaciteIndisponible>()));
    expect(
      port.filPourObjet(TypeObjetLie.classe, 'c'),
      throwsA(isA<CapaciteIndisponible>()),
    );
    expect(port.marquerLu('x'), throwsA(isA<CapaciteIndisponible>()));
    expect(
      port.envoyer('x', 'y', 'k'),
      throwsA(
        isA<CapaciteIndisponible>().having(
          (CapaciteIndisponible e) => e.dependance,
          'dependance',
          'COM-BR-02',
        ),
      ),
    );
  });
}
