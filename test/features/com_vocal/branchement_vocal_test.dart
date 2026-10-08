// COM-FUS : le composer vocal (COM-VOC) branche dans le fil contextuel des
// Messages et dans les canaux du Studio (Focus compris), et le lecteur des
// vocaux recus dans les bulles. Rendu dans les vraies pages, avec le faux
// enregistreur de la demonstration et une horloge fixe.
//
// Ce qui est verifie :
// - production (capacite `envoyerVocal` fermee, port neutre) : aucun
//   composer vocal, ni dans Messages, ni dans un canal du Studio ;
// - capacite ouverte : le composer est sous le champ ; arreter n'envoie
//   rien ; seul « Envoyer » envoie, une fois, vers le bon fil ou canal ;
// - un envoi non confirme puis « Reessayer » rejoue la meme cle ;
// - Studio : le composer reste en Focus (MinimalComposer) ;
// - un vocal recu se lit par `LecteurVocalRecu` dans la bulle, sans la
//   ligne « Message vocal de 0:28 » ;
// - les cles d'idempotence du texte suivent la bulle, pas le texte.

import 'dart:async';

import 'package:flutter/material.dart';
// `Override` n'est pas exporte par l'entree principale de Riverpod 3.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/communications/capacites_communication.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/carte_piece_jointe.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';
import 'package:rewayah_academy/features/com_messages/fil_contextuel.dart';
import 'package:rewayah_academy/features/com_messages/port_messages_metier.dart';
import 'package:rewayah_academy/features/com_studio/canal_page.dart';
import 'package:rewayah_academy/features/com_studio/port_studio.dart';
import 'package:rewayah_academy/features/com_studio/studio_page.dart';
import 'package:rewayah_academy/features/com_vocal/composer_vocal.dart';
import 'package:rewayah_academy/features/com_vocal/envoi_vocal.dart';
import 'package:rewayah_academy/features/com_vocal/lecteur_vocal.dart';
import 'package:rewayah_academy/features/com_vocal/port_enregistreur_vocal.dart';
import 'package:rewayah_academy/features/demo/communications/com_vocal_demo.dart';

import '../com_messages/support_messages.dart' as msg;
import '../com_studio/support_focus.dart' as focus;
import '../com_studio/support_studio.dart' as studio;
import 'support_vocal.dart';

/// Un envoi de vocaux qui compte ses appels et peut echouer.
class _EnvoiCompte implements PortEnvoiVocal {
  final List<(DestinationVocal, String)> envois =
      <(DestinationVocal, String)>[];
  int echecsRestants = 0;

  @override
  Future<void> envoyer({
    required DestinationVocal destination,
    required EnregistrementVocal vocal,
    required String cleIdempotence,
  }) async {
    envois.add((destination, cleIdempotence));
    if (echecsRestants > 0) {
      echecsRestants--;
      throw StateError('non confirme');
    }
  }
}

/// Les doubles du vocal et, avec [capacite], la capacite `envoyerVocal`
/// (avec `ecrireDansFil`, que les Messages demandent aussi).
List<Override> _vocal(
  HorlogeManuelle horloge,
  _EnvoiCompte envoi, {
  bool capacite = true,
}) => <Override>[
  portEnregistreurVocalProvider.overrideWithValue(
    EnregistreurVocalDemonstration(horloge: horloge.horloge),
  ),
  portLectureVocaleProvider.overrideWithValue(
    LecturesVocalesDemonstration(horloge: horloge.horloge),
  ),
  horlogeVocaleProvider.overrideWithValue(horloge.horloge),
  portEnvoiVocalProvider.overrideWithValue(envoi),
  portCapacitesCommunicationsProvider.overrideWithValue(
    CapacitesCommunicationsFixes(<CapaciteCommunication>{
      CapaciteCommunication.ecrireDansFil,
      if (capacite) CapaciteCommunication.envoyerVocal,
    }),
  ),
];

Future<void> _toucher(WidgetTester tester, Key cle) async {
  await tester.ensureVisible(find.byKey(cle));
  await tester.tap(find.byKey(cle));
  await tester.pump();
  await tester.pump();
}

/// Enregistre six secondes puis arrete : la pre-ecoute, sans envoi.
Future<void> _enregistrerPuisArreter(
  WidgetTester tester,
  HorlogeManuelle horloge,
) async {
  await _toucher(tester, FilDiscussion.cleMicro);
  await avancer(tester, horloge, const Duration(seconds: 6));
  await _toucher(tester, ComposerVocal.cleArreter);
}

/// Le vocal recu des tests : 0:28, lisible.
final PieceJointe _vocalRecu = PieceJointe(
  reference: ReferencePieceJointe('vocal_test_recu'),
  nom: 'message-vocal.m4a',
  nature: NaturePieceJointe.vocal,
  typeLisible: 'Audio',
  duree: const Duration(seconds: 28),
  peutOuvrir: true,
);

void main() {
  group('Messages : fil contextuel', () {
    testWidgets('production : capacite fermee, aucun composer vocal', (
      WidgetTester tester,
    ) async {
      final _EnvoiCompte envoi = _EnvoiCompte();
      await msg.monterMessages(
        tester,
        port: msg.FauxMessagesMetier(fils: <FilMetier>[msg.filSimple()]),
        depart: msg.cheminFilTest('fil-1'),
        // Les capacites viennent de `_vocal`, pas du support.
        ecritureOuverte: false,
        surcharges: _vocal(HorlogeManuelle(), envoi, capacite: false),
      );
      expect(find.byKey(FilDiscussion.champKey), findsOneWidget);
      expect(find.byType(ComposerVocal), findsNothing);
      expect(find.byKey(FilContextuel.cleComposerVocal), findsNothing);
    });

    testWidgets('production : ports neutres, aucun composer vocal', (
      WidgetTester tester,
    ) async {
      await msg.monterMessages(
        tester,
        port: msg.FauxMessagesMetier(fils: <FilMetier>[msg.filSimple()]),
        depart: msg.cheminFilTest('fil-1'),
      );
      expect(find.byKey(FilDiscussion.champKey), findsOneWidget);
      expect(find.byType(ComposerVocal), findsNothing);
    });

    testWidgets('capacite ouverte : sous le champ ; arreter n envoie rien, '
        '« Envoyer » envoie une fois vers le fil', (WidgetTester tester) async {
      final HorlogeManuelle horloge = HorlogeManuelle();
      final _EnvoiCompte envoi = _EnvoiCompte();
      await msg.monterMessages(
        tester,
        port: msg.FauxMessagesMetier(fils: <FilMetier>[msg.filSimple()]),
        depart: msg.cheminFilTest('fil-1'),
        // Les capacites viennent de `_vocal`, pas du support.
        ecritureOuverte: false,
        surcharges: _vocal(horloge, envoi),
      );
      expect(find.byKey(FilContextuel.cleComposerVocal), findsOneWidget);
      // Decision R-28 : le micro est a cote d'« Envoyer », plus un lien
      // sous le champ.
      expect(find.byKey(ComposerVocal.cleEnregistrer), findsNothing);
      expect(
        tester.getTopLeft(find.byKey(FilDiscussion.cleMicro)).dy,
        tester.getTopLeft(find.byKey(FilDiscussion.envoyerKey)).dy,
      );
      expect(
        tester.getTopRight(find.byKey(FilDiscussion.cleMicro)).dx,
        lessThanOrEqualTo(
          tester.getTopLeft(find.byKey(FilDiscussion.envoyerKey)).dx,
        ),
      );
      await _enregistrerPuisArreter(tester, horloge);
      expect(envoi.envois, isEmpty, reason: 'jamais d envoi a l arret');
      await _toucher(tester, ComposerVocal.cleEnvoyer);
      await tester.pump();
      expect(envoi.envois, hasLength(1));
      expect(envoi.envois.single.$1, const DestinationVocal.fil('fil-1'));
      expect(find.text(t.com.vocal.composer.envoye), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('revue COM-FUS : le vocal confirme entre dans le fil ouvert, '
        'sans relecture du fil', (WidgetTester tester) async {
      final HorlogeManuelle horloge = HorlogeManuelle();
      final _EnvoiCompte envoi = _EnvoiCompte();
      final msg.FauxMessagesMetier port = msg.FauxMessagesMetier(
        fils: <FilMetier>[msg.filSimple()],
      );
      await msg.monterMessages(
        tester,
        port: port,
        depart: msg.cheminFilTest('fil-1'),
        // Les capacites viennent de `_vocal`, pas du support.
        ecritureOuverte: false,
        surcharges: _vocal(horloge, envoi),
      );
      final String ligne = t.com.socle.composants.lecture.vocal(
        duree: CartePieceJointe.libelleDuree(const Duration(seconds: 6)),
      );
      final Finder bulle = find.descendant(
        of: find.byType(FilDiscussion),
        matching: find.text(ligne),
      );
      expect(bulle, findsNothing);
      await _enregistrerPuisArreter(tester, horloge);
      await _toucher(tester, ComposerVocal.cleEnvoyer);
      await tester.pump();
      expect(envoi.envois, hasLength(1));
      expect(bulle, findsOneWidget, reason: 'la bulle du vocal confirme');
      expect(
        find.descendant(
          of: find.byType(FilDiscussion),
          matching: find.text(t.com.socle.composants.composer.envoye),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('revue COM-FUS : un vocal non confirme n entre pas dans le '
        'fil', (WidgetTester tester) async {
      final HorlogeManuelle horloge = HorlogeManuelle();
      final _EnvoiCompte envoi = _EnvoiCompte()..echecsRestants = 1;
      await msg.monterMessages(
        tester,
        port: msg.FauxMessagesMetier(fils: <FilMetier>[msg.filSimple()]),
        depart: msg.cheminFilTest('fil-1'),
        // Les capacites viennent de `_vocal`, pas du support.
        ecritureOuverte: false,
        surcharges: _vocal(horloge, envoi),
      );
      await _enregistrerPuisArreter(tester, horloge);
      await _toucher(tester, ComposerVocal.cleEnvoyer);
      await tester.pump();
      expect(find.byKey(ComposerVocal.cleReessayer), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(FilDiscussion),
          matching: find.text(
            t.com.socle.composants.lecture.vocal(
              duree: CartePieceJointe.libelleDuree(const Duration(seconds: 6)),
            ),
          ),
        ),
        findsNothing,
      );
    });

    testWidgets('envoi non confirme puis « Reessayer » : la meme cle', (
      WidgetTester tester,
    ) async {
      final HorlogeManuelle horloge = HorlogeManuelle();
      final _EnvoiCompte envoi = _EnvoiCompte()..echecsRestants = 1;
      await msg.monterMessages(
        tester,
        port: msg.FauxMessagesMetier(fils: <FilMetier>[msg.filSimple()]),
        depart: msg.cheminFilTest('fil-1'),
        // Les capacites viennent de `_vocal`, pas du support.
        ecritureOuverte: false,
        surcharges: _vocal(horloge, envoi),
      );
      await _enregistrerPuisArreter(tester, horloge);
      await _toucher(tester, ComposerVocal.cleEnvoyer);
      await tester.pump();
      expect(find.byKey(ComposerVocal.cleReessayer), findsOneWidget);
      await _toucher(tester, ComposerVocal.cleReessayer);
      await tester.pump();
      expect(envoi.envois, hasLength(2));
      expect(envoi.envois.last.$2, envoi.envois.first.$2);
    });

    testWidgets('un vocal recu se lit dans la bulle, sans la ligne '
        '« Message vocal de 0:28 »', (WidgetTester tester) async {
      final FilMetier fil = msg.filAvec(
        id: 'fil-vocal',
        autre: const Participant(id: 'autre', nomAffiche: 'Sayyida Mariam'),
        objets: <ObjetLie>[
          ObjetLie(
            type: TypeObjetLie.classe,
            id: 'an-nour',
            libelle: 'Classe An-Nour',
          ),
        ],
        pieces: <PieceJointe>[_vocalRecu],
      );
      await msg.monterMessages(
        tester,
        port: msg.FauxMessagesMetier(fils: <FilMetier>[fil]),
        depart: msg.cheminFilTest('fil-vocal'),
      );
      final Finder dansFil = find.descendant(
        of: find.byType(FilDiscussion),
        matching: find.byType(LecteurVocalRecu),
      );
      expect(dansFil, findsOneWidget);
      final String ligne = t.com.socle.composants.lecture.vocal(
        duree: CartePieceJointe.libelleDuree(const Duration(seconds: 28)),
      );
      expect(
        find.descendant(
          of: find.byType(FilDiscussion),
          matching: find.textContaining(ligne),
        ),
        findsNothing,
      );
      // Le texte du message reste dans la bulle.
      expect(
        find.descendant(
          of: find.byType(FilDiscussion),
          matching: find.text('Bonjour, une question sur la séance de jeudi.'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('texte : un nouveau message identique a un message en echec '
        'part sous une cle neuve ; « Reessayer » rejoue la sienne', (
      WidgetTester tester,
    ) async {
      final _MessagesRetenus port = _MessagesRetenus();
      await msg.monterMessages(
        tester,
        port: port,
        depart: msg.cheminFilTest('fil-1'),
      );
      final x = t.com.socle.composants.composer;
      await _ecrire(tester, 'Merci');
      port.attentes.single.completeError(Exception('reseau'));
      await tester.pumpAndSettle();
      await _ecrire(tester, 'Merci');
      expect(port.envois, hasLength(2));
      expect(
        port.envois.last.$3,
        isNot(port.envois.first.$3),
        reason: 'une autre bulle, une autre cle, meme texte',
      );
      await tester.tap(find.text(x.reessayer));
      await tester.pump();
      expect(port.envois, hasLength(3));
      expect(port.envois.last.$3, port.envois.first.$3);
      for (final Completer<void> a in port.attentes.skip(1)) {
        a.complete();
      }
      await tester.pumpAndSettle();
    });
  });

  group('Studio : canal', () {
    testWidgets('production : capacite fermee, aucun composer vocal', (
      WidgetTester tester,
    ) async {
      await studio.monterStudio(
        tester,
        port: studio.FauxStudio(canaux: <Canal>[studio.canalSimple()]),
        depart: cheminCanalStudio('c1'),
      );
      expect(find.byKey(FilDiscussion.champKey), findsOneWidget);
      expect(find.byType(ComposerVocal), findsNothing);
      expect(find.byKey(CanalStudio.cleComposerVocal), findsNothing);
    });

    testWidgets('capacite ouverte : le composer, en Focus aussi ; '
        '« Envoyer » envoie vers le canal', (WidgetTester tester) async {
      final HorlogeManuelle horloge = HorlogeManuelle();
      final _EnvoiCompte envoi = _EnvoiCompte();
      await studio.monterStudio(
        tester,
        port: studio.FauxStudio(canaux: <Canal>[studio.canalSimple()]),
        depart: cheminCanalStudio('c1'),
        surcharges: _vocal(horloge, envoi),
      );
      expect(find.byKey(CanalStudio.cleComposerVocal), findsOneWidget);
      await focus.entrer(tester);
      expect(focus.quitterFocus, findsOneWidget);
      expect(find.byKey(CanalStudio.cleComposerVocal), findsOneWidget);
      await _enregistrerPuisArreter(tester, horloge);
      expect(envoi.envois, isEmpty);
      await _toucher(tester, ComposerVocal.cleEnvoyer);
      await tester.pump();
      expect(envoi.envois, hasLength(1));
      expect(envoi.envois.single.$1, const DestinationVocal.canal('c1'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('revue COM-FUS : le vocal confirme entre dans le canal '
        'ouvert', (WidgetTester tester) async {
      final HorlogeManuelle horloge = HorlogeManuelle();
      final _EnvoiCompte envoi = _EnvoiCompte();
      await studio.monterStudio(
        tester,
        port: studio.FauxStudio(canaux: <Canal>[studio.canalSimple()]),
        depart: cheminCanalStudio('c1'),
        surcharges: _vocal(horloge, envoi),
      );
      final Finder bulle = find.descendant(
        of: find.byType(FilDiscussion),
        matching: find.text(
          t.com.socle.composants.lecture.vocal(
            duree: CartePieceJointe.libelleDuree(const Duration(seconds: 6)),
          ),
        ),
      );
      expect(bulle, findsNothing);
      await _enregistrerPuisArreter(tester, horloge);
      await _toucher(tester, ComposerVocal.cleEnvoyer);
      await tester.pump();
      expect(envoi.envois, hasLength(1));
      expect(bulle, findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    for (final (Size taille, AppLocale langue) in <(Size, AppLocale)>[
      (const Size(390, 844), AppLocale.fr),
      (const Size(390, 844), AppLocale.ar),
      (const Size(1440, 900), AppLocale.fr),
      (const Size(1440, 900), AppLocale.ar),
    ]) {
      testWidgets('revue COM-FUS : une bulle qui ne porte qu un vocal, '
          '${taille.width.toInt()} ${langue.languageCode} : le lecteur, sans '
          'ligne de texte vide', (WidgetTester tester) async {
        final Canal base = studio.canalSimple();
        await studio.monterStudio(
          tester,
          port: studio.FauxStudio(
            canaux: <Canal>[
              Canal(
                resume: base.resume,
                membres: base.membres,
                messages: <MessageCommunication>[
                  MessageCommunication(
                    id: 'c1-vocal',
                    auteur: base.membres.last,
                    texte: '',
                    envoyeLe: studio.maintenantTest,
                    piecesJointes: <PieceJointe>[_vocalRecu],
                  ),
                ],
                capacites: base.capacites,
              ),
            ],
          ),
          depart: cheminCanalStudio('c1'),
          taille: taille,
          langue: langue,
        );
        final Finder lecteur = find.descendant(
          of: find.byType(FilDiscussion),
          matching: find.byType(LecteurVocalRecu),
        );
        expect(lecteur, findsOneWidget);
        // Aucun texte vide dans le fil : la bulle va de l'auteur au lecteur.
        expect(
          find.descendant(
            of: find.byType(FilDiscussion),
            matching: find.byWidgetPredicate(
              (Widget w) => w is Text && (w.data?.isEmpty ?? false),
            ),
          ),
          findsNothing,
        );
        final Rect cadre = tester.getRect(lecteur);
        expect(cadre.width, greaterThan(0));
        expect(cadre.right, lessThanOrEqualTo(taille.width));
        expect(cadre.left, greaterThanOrEqualTo(0));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('un vocal recu se lit dans la bulle du canal', (
      WidgetTester tester,
    ) async {
      final Canal base = studio.canalSimple();
      final Canal canal = Canal(
        resume: base.resume,
        membres: base.membres,
        messages: <MessageCommunication>[
          MessageCommunication(
            id: 'c1-vocal',
            auteur: base.membres.last,
            texte: '',
            envoyeLe: studio.maintenantTest,
            piecesJointes: <PieceJointe>[_vocalRecu],
          ),
        ],
        capacites: base.capacites,
      );
      await studio.monterStudio(
        tester,
        port: studio.FauxStudio(canaux: <Canal>[canal]),
        depart: cheminCanalStudio('c1'),
      );
      expect(
        find.descendant(
          of: find.byType(FilDiscussion),
          matching: find.byType(LecteurVocalRecu),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(FilDiscussion),
          matching: find.textContaining(
            t.com.socle.composants.lecture.vocal(
              duree: CartePieceJointe.libelleDuree(const Duration(seconds: 28)),
            ),
          ),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('texte : deux messages identiques en attente, deux cles', (
      WidgetTester tester,
    ) async {
      final studio.FauxStudio port = studio.FauxStudio(
        canaux: <Canal>[studio.canalSimple()],
      )..attenteEnvoi = Completer<void>();
      await studio.monterStudio(
        tester,
        port: port,
        depart: cheminCanalStudio('c1'),
      );
      await _ecrire(tester, 'Bien reçu');
      await _ecrire(tester, 'Bien reçu');
      expect(port.envois, hasLength(2));
      expect(port.envois.last.$3, isNot(port.envois.first.$3));
      port.attenteEnvoi!.complete();
      await tester.pumpAndSettle();
    });
  });
}

Future<void> _ecrire(WidgetTester tester, String texte) async {
  await tester.enterText(find.byKey(FilDiscussion.champKey), texte);
  await tester.pump();
  await tester.tap(find.byKey(FilDiscussion.envoyerKey));
  await tester.pump();
}

/// Un port de messages dont chaque envoi attend sa completion.
class _MessagesRetenus extends msg.FauxMessagesMetier {
  _MessagesRetenus() : super(fils: <FilMetier>[msg.filSimple()]);

  final List<Completer<void>> attentes = <Completer<void>>[];

  @override
  Future<void> envoyer(String filId, String texte, String cle) {
    envois.add((filId, texte, cle));
    final Completer<void> a = Completer<void>();
    attentes.add(a);
    return a.future;
  }
}
