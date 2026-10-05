// Contre-preuves de la revue COM-MSG-1 :
//
// 1. Ordinateur, VRAI routeur : la recherche survit a l'ouverture d'un fil
//    (`/messages` vers `/messages/:filId` pose une nouvelle page), et la
//    liste ne repasse pas par le squelette.
// 2. Telephone : le retour du systeme, puis celui de la page, referment la
//    recherche plein ecran au lieu de quitter les Messages.
// 3. Un fil sans autre participant que soi n'a jamais un libelle vide, ni
//    dans la liste, ni dans l'en-tete, ni pour le lecteur d'ecran.
// 4. Deux messages identiques envoyes coup sur coup partent sous deux cles
//    d'idempotence ; un nouvel essai rejoue la cle de l'echec.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` n'est pas exporte par l'entree principale de Riverpod 3.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/port_classes_foyer.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';
import 'package:rewayah_academy/features/com_messages/entete_fil_contexte.dart';
import 'package:rewayah_academy/features/com_messages/liste_fils.dart';
import 'package:rewayah_academy/features/com_messages/messages_page.dart';
import 'package:rewayah_academy/features/com_messages/port_messages_metier.dart';
import 'package:rewayah_academy/features/com_messages/recherche_fils.dart';
import 'package:rewayah_academy/features/demo/communications/demo_communications_page.dart';

import '../../router/support_routeur.dart';
import '../../support/harnais.dart';
import 'support_messages.dart';

const Size _mobile = Size(390, 844);

/// Monte l'application sur le vrai routeur, au role et a la taille donnes.
Future<GoRouter> _monterRouteur(
  WidgetTester tester,
  String depart,
  AppRole role,
  PortMessagesMetier port, {
  Size taille = const Size(1440, 900),
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...surchargesRouteur(FausseSourceSession(sessionActive(role))),
        portClassesFoyerProvider.overrideWithValue(
          const ClassesFoyerIndisponible(),
        ),
        portMessagesMetierProvider.overrideWithValue(port),
        capaciteEcrireOuverteTest,
      ],
      child: TranslationProvider(
        child: Consumer(
          builder: (BuildContext _, WidgetRef ref, Widget? _) {
            routeur = ref.read(routeurProvider);
            return MaterialApp.router(
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              routerConfig: routeur,
            );
          },
        ),
      ),
    ),
  );
  await stabiliser(tester);
  routeur.go(depart);
  await stabiliser(tester);
  return routeur;
}

/// Un participant qui est soi : le seul du fil.
const Participant _soi = Participant(
  id: 'soi',
  nomAffiche: 'Ahmed',
  estSoi: true,
);

/// Un fil ou personne d'autre que soi n'est nomme (une equipe non
/// nominative, par exemple).
FilMetier _filSansInterlocuteur() => FilMetier(
  id: 'fil-equipe',
  contexte: <ElementContexteFil>[
    ElementContexteFil(
      objet: ObjetLie(
        type: TypeObjetLie.dossier,
        id: 'dossier-adam',
        libelle: "Dossier d'inscription d'Adam",
      ),
    ),
  ],
  participants: const <Participant>[_soi],
  messages: <MessageCommunication>[
    MessageCommunication(
      id: 'fil-equipe-m1',
      auteur: _soi,
      texte: 'Voici la pièce demandée.',
      envoyeLe: maintenantTest.subtract(const Duration(hours: 2)),
    ),
  ],
  capacites: const <CapaciteFil>{CapaciteFil.ecrire},
);

/// Un port dont chaque envoi attend sa completion, dans l'ordre.
class _EnvoisRetenus extends FauxMessagesMetier {
  _EnvoisRetenus() : super(fils: <FilMetier>[filSimple()]);

  final List<Completer<void>> attentes = <Completer<void>>[];

  @override
  Future<void> envoyer(String filId, String texte, String cle) async {
    envois.add((filId, texte, cle));
    final Completer<void> attente = Completer<void>();
    attentes.add(attente);
    await attente.future;
  }
}

/// Le port de demonstration, dont toute relecture de la liste apres la
/// premiere attend [relacher] : une page qui repartirait de zero resterait
/// sur son squelette.
class _ListeRetenue implements PortMessagesMetier {
  _ListeRetenue(this._source);

  final PortMessagesMetier _source;
  final Completer<void> relacher = Completer<void>();
  int _lectures = 0;

  @override
  Future<List<ResumeFil>> fils() async {
    if (_lectures++ > 0) await relacher.future;
    return _source.fils();
  }

  @override
  Future<FilMetier?> fil(String filId) => _source.fil(filId);

  @override
  Future<FilMetier?> filPourObjet(TypeObjetLie type, String objetId) =>
      _source.filPourObjet(type, objetId);

  @override
  Future<FilMetier?> ouvrirConversation(ConversationPossible c) =>
      _source.ouvrirConversation(c);

  @override
  Future<List<ConversationPossible>> conversationsPourObjet(
    TypeObjetLie type,
    String objetId,
  ) => _source.conversationsPourObjet(type, objetId);

  @override
  Future<void> marquerLu(String filId) => _source.marquerLu(filId);

  @override
  Future<void> envoyer(String filId, String texte, String cle) =>
      _source.envoyer(filId, texte, cle);
}

Finder _dansFil(Finder cible) =>
    find.descendant(of: find.byType(FilDiscussion), matching: cible);

Future<void> _envoyer(WidgetTester tester, String texte) async {
  await tester.enterText(find.byKey(FilDiscussion.champKey), texte);
  await tester.pump();
  await tester.tap(find.byKey(FilDiscussion.envoyerKey));
  await tester.pump();
}

void main() {
  group('1. la recherche survit a l ouverture d un fil (1440)', () {
    testWidgets('vrai routeur : rechercher, ouvrir un resultat, le filtre '
        'reste applique', (WidgetTester tester) async {
      final _ListeRetenue port = _ListeRetenue(
        portDemo(RoleDemoCommunications.tuteur),
      );
      final GoRouter routeur = await _monterRouteur(
        tester,
        Routes.tuteurMessages,
        AppRole.guardian,
        port,
      );
      expect(find.byKey(ListeFils.cleLigne('fil-adam')), findsOneWidget);
      await tester.enterText(find.byKey(ClesRechercheFils.champ), 'dossier');
      await stabiliser(tester);
      expect(find.byKey(ListeFils.cleLigne('fil-adam')), findsNothing);

      await tester.tap(find.byKey(ListeFils.cleLigne('fil-dossier-adam')));
      await stabiliser(tester);
      // La colonne de liste de la nouvelle page ne repart pas du squelette :
      // la liste deja lue s'affiche pendant que sa relecture attend.
      expect(
        find.descendant(
          of: find.byWidgetPredicate(
            (Widget w) => w is MessagesPage && w.filId == 'fil-dossier-adam',
          ),
          matching: find.byType(ListeFils),
        ),
        findsOneWidget,
      );

      expect(lieu(routeur), Routes.tuteurFilPour('fil-dossier-adam'));
      final TextField champ = tester.widget<TextField>(
        find.byKey(ClesRechercheFils.champ),
      );
      expect(champ.controller!.text, 'dossier');
      expect(
        find.byKey(ListeFils.cleLigne('fil-dossier-adam')),
        findsOneWidget,
      );
      expect(
        find.byKey(ListeFils.cleLigne('fil-adam')),
        findsNothing,
        reason: 'le filtre exclut toujours fil-adam',
      );
      port.relacher.complete();
      await stabiliser(tester);
      expect(find.byKey(ListeFils.cleLigne('fil-adam')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('2. telephone : le retour referme la recherche plein ecran', () {
    testWidgets('retour du systeme', (WidgetTester tester) async {
      final GoRouter routeur = await monterMessages(
        tester,
        port: portDemo(RoleDemoCommunications.enseignant),
        taille: _mobile,
      );
      await tester.tap(find.byKey(ListeFils.cleOuvrirRecherche));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(ClesRechercheFils.champ), 'direction');
      await tester.pumpAndSettle();
      expect(find.byKey(ClesRechercheFils.surface), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(cheminCourant(routeur), cheminListeTest);
      expect(find.byKey(ClesRechercheFils.surface), findsNothing);
      expect(find.byKey(ListeFils.cleLigne('fil-adam')), findsOneWidget);
      expect(find.byKey(ListeFils.cleLigne('fil-affectation')), findsOneWidget);
    });

    testWidgets('retour de la page : referme d abord, puis mene au role', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await monterMessages(
        tester,
        port: portDemo(RoleDemoCommunications.enseignant),
        taille: _mobile,
      );
      await tester.tap(find.byKey(ListeFils.cleOuvrirRecherche));
      await tester.pumpAndSettle();
      expect(find.byKey(ClesRechercheFils.surface), findsOneWidget);

      await tester.tap(find.byType(DisqueRetour));
      await tester.pumpAndSettle();
      expect(cheminCourant(routeur), cheminListeTest);
      expect(find.byKey(ClesRechercheFils.surface), findsNothing);
      expect(find.byKey(ListeFils.cleOuvrirRecherche), findsOneWidget);

      await tester.tap(find.byType(DisqueRetour));
      await tester.pumpAndSettle();
      expect(cheminCourant(routeur), cheminRacineTest);
    });
  });

  group('3. un fil sans interlocuteur nomme', () {
    test('le titre retombe sur l objet, jamais vide', () {
      final n = t.com.messages.noms;
      expect(
        titreFil(const <Participant>[], 'Classe An-Nour'),
        n.surObjet(objet: 'Classe An-Nour'),
      );
      expect(titreFil(const <Participant>[], ''), n.sansObjet);
      expect(
        titreFil(const <Participant>[
          Participant(id: 'b', nomAffiche: 'Mme Mariam'),
        ], 'Classe An-Nour'),
        'Mme Mariam',
      );
    });

    testWidgets('liste et en-tete : un libelle, et une phrase sans « avec »', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantique = tester.ensureSemantics();
      await monterMessages(
        tester,
        port: FauxMessagesMetier(fils: <FilMetier>[_filSansInterlocuteur()]),
        depart: cheminFilTest('fil-equipe'),
      );
      const String objet = "Dossier d'inscription d'Adam";
      final String titre = t.com.messages.noms.surObjet(objet: objet);
      expect(
        find.descendant(of: find.byType(ListeFils), matching: find.text(titre)),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(EnteteFilContexte),
          matching: find.text(titre),
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          t.com.messages.entete.semantiqueSansNoms(objets: objet),
        ),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel(RegExp('avec ,')), findsNothing);
      semantique.dispose();
    });
  });

  group('4. cles d idempotence (R-COM-13)', () {
    testWidgets('deux messages identiques en cours : deux cles distinctes', (
      WidgetTester tester,
    ) async {
      final _EnvoisRetenus port = _EnvoisRetenus();
      await monterMessages(tester, port: port, depart: cheminFilTest('fil-1'));
      await _envoyer(tester, 'Merci');
      await _envoyer(tester, 'Merci');
      expect(port.envois, hasLength(2));
      expect(
        port.envois.first.$3,
        isNot(port.envois.last.$3),
        reason: 'deux messages, deux cles : le serveur garde les deux',
      );
      for (final Completer<void> a in port.attentes) {
        a.complete();
      }
      await tester.pumpAndSettle();
      expect(
        _dansFil(find.text(t.com.socle.composants.composer.envoye)),
        findsNWidgets(2),
      );
    });

    testWidgets('un echec, puis « Reessayer » : la meme cle', (
      WidgetTester tester,
    ) async {
      final _EnvoisRetenus port = _EnvoisRetenus();
      await monterMessages(tester, port: port, depart: cheminFilTest('fil-1'));
      final x = t.com.socle.composants.composer;
      await _envoyer(tester, 'Merci');
      port.attentes.single.completeError(Exception('reseau'));
      await tester.pumpAndSettle();
      expect(find.text(x.reessayer), findsOneWidget);

      await tester.tap(find.text(x.reessayer));
      await tester.pump();
      expect(port.envois, hasLength(2));
      expect(port.envois.last.$3, port.envois.first.$3);
      port.attentes.last.complete();
      await tester.pumpAndSettle();
      expect(_dansFil(find.text(x.envoye)), findsOneWidget);
    });
  });
}
