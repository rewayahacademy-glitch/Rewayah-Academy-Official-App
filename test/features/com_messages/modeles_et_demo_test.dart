// COM-MSG-1 : fonctions pures (recherche, mises en mots), port de
// demonstration et fixtures (spec section 3.2 et section 26), et la
// demonstration rendue sous son routeur (hors production).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` n'est pas exporte par l'entree principale de Riverpod 3.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/communications/lecture_fil_communication.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';
import 'package:rewayah_academy/features/com_messages/entete_fil_contexte.dart';
import 'package:rewayah_academy/features/com_messages/liste_fils.dart';
import 'package:rewayah_academy/features/com_messages/port_messages_metier.dart';
import 'package:rewayah_academy/features/com_messages/recherche_fils.dart';
import 'package:rewayah_academy/features/demo/communications/com_messages_demo.dart';
import 'package:rewayah_academy/features/demo/communications/demo_communications_page.dart';

import '../../support/harnais.dart';
import 'support_messages.dart';

final RegExp _coordonnee = RegExp(r'@|\+?\d[\d .-]{7,}\d');

ResumeFil _resume(String id, String nom, String objet, {String? apercu}) =>
    ResumeFil(
      id: id,
      objet: ObjetLie(type: TypeObjetLie.classe, id: 'o-$id', libelle: objet),
      interlocuteurs: <Participant>[
        Participant(id: 'p-$id', nomAffiche: nom, fonction: 'Parent'),
      ],
      apercu: apercu,
    );

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  group('Recherche locale', () {
    final List<ResumeFil> fils = <ResumeFil>[
      _resume('a', 'Ahmed', 'Classe An-Nour', apercu: 'Séance réussie'),
      _resume('b', 'Fatima', 'Classe Al-Fajr'),
    ];

    test('sans accents ni majuscules, tous les mots', () {
      expect(filtrerFils(fils, 'seance'), <ResumeFil>[fils[0]]);
      expect(filtrerFils(fils, 'FAJR fatima'), <ResumeFil>[fils[1]]);
      expect(filtrerFils(fils, 'classe'), fils);
      expect(filtrerFils(fils, 'ahmed fajr'), isEmpty);
    });

    test('un texte vide rend la liste telle quelle', () {
      expect(filtrerFils(fils, '   '), same(fils));
    });

    test('jamais plus que les fils autorises', () {
      expect(filtrerFils(fils, 'a').length, lessThanOrEqualTo(fils.length));
    });
  });

  group('Mises en mots', () {
    const Participant a = Participant(id: 'a', nomAffiche: 'Ahmed');
    const Participant b = Participant(
      id: 'b',
      nomAffiche: 'Sayyida Mariam',
      fonction: 'Enseignante',
    );
    const Participant c = Participant(id: 'c', nomAffiche: 'Fatima');

    test('noms des interlocuteurs', () {
      expect(nomsInterlocuteurs(const <Participant>[]), '');
      expect(
        nomsInterlocuteurs(const <Participant>[b]),
        'Sayyida Mariam, Enseignante',
      );
      expect(
        nomsInterlocuteurs(const <Participant>[a, b]),
        'Ahmed et Sayyida Mariam',
      );
      expect(
        nomsInterlocuteurs(const <Participant>[a, b, c]),
        'Ahmed et 2 autres personnes',
      );
    });

    test('objets et natures', () {
      expect(
        libelleObjets(<ObjetLie>[
          ObjetLie(
            type: TypeObjetLie.classe,
            id: 'c',
            libelle: 'Classe An-Nour',
          ),
          ObjetLie(type: TypeObjetLie.eleve, id: 'e', libelle: 'Adam'),
        ]),
        'Classe An-Nour · Adam',
      );
      expect(libelleTypeObjet(TypeObjetLie.mission), 'Mission de contrôle');
      expect(libelleTypeObjet(TypeObjetLie.annonce), 'Autre sujet');
    });

    test('le moment : l heure du jour, sinon le jour et le mois', () {
      final DateTime ici = DateTime(2026, 10, 4, 15);
      expect(momentCourt(DateTime(2026, 10, 4, 9, 5), ici), '09:05');
      expect(momentCourt(DateTime(2026, 9, 12, 9, 5), ici), '12 septembre');
    });

    test('le texte d un message dit ses pieces, jamais leur reference', () {
      final MessageCommunication m = MessageCommunication(
        id: 'm',
        auteur: a,
        texte: 'Voici',
        envoyeLe: maintenantTest,
        piecesJointes: <PieceJointe>[
          PieceJointe(
            reference: ReferencePieceJointe('ref-secrete-1'),
            nom: 'dossier/sous/Devoir.pdf',
            nature: NaturePieceJointe.document,
            typeLisible: 'PDF',
          ),
          PieceJointe(
            reference: ReferencePieceJointe('ref-secrete-2'),
            nom: 'v.m4a',
            nature: NaturePieceJointe.vocal,
            typeLisible: 'Audio',
            duree: const Duration(minutes: 1, seconds: 5),
          ),
        ],
      );
      final String texte = texteDuMessage(m);
      expect(texte, 'Voici\nPièce jointe : Devoir.pdf\nMessage vocal de 1:05');
      expect(texte.contains('ref-secrete'), isFalse);
    });

    test('les objets de fil metier, pas une annonce ni un canal', () {
      expect(estFilMetier(_resume('x', 'A', 'Classe')), isTrue);
      for (final TypeObjetLie type in <TypeObjetLie>[
        TypeObjetLie.annonce,
        TypeObjetLie.canal,
        TypeObjetLie.publication,
        TypeObjetLie.message,
      ]) {
        expect(
          estFilMetier(
            ResumeFil(
              id: 'x',
              objet: ObjetLie(type: type, id: 'x', libelle: 'x'),
              interlocuteurs: const <Participant>[],
            ),
          ),
          isFalse,
          reason: type.name,
        );
      }
    });

    test('une capacite absente ferme l action', () {
      expect(filSimple(ecrire: false).peut(CapaciteFil.ecrire), isFalse);
      expect(filSimple().peut(CapaciteFil.ecrire), isTrue);
    });
  });

  group('Fixtures de demonstration (spec section 26, paires section 3.2)', () {
    test('parent/enseignant, administration/famille, controleur/'
        'administration, un vocal, une piece jointe', () {
      final List<FilMetier> tuteur = fixturesMessagesDemo(
        RoleDemoCommunications.tuteur,
        maintenantTest,
      );
      final List<FilMetier> admin = fixturesMessagesDemo(
        RoleDemoCommunications.admin,
        maintenantTest,
      );
      expect(tuteur.map((FilMetier f) => f.id), contains('fil-adam'));
      expect(tuteur.map((FilMetier f) => f.id), contains('fil-dossier-adam'));
      expect(admin.map((FilMetier f) => f.id), contains('fil-mission'));
      final List<PieceJointe> pieces = <PieceJointe>[
        for (final FilMetier f in tuteur) ...f.piecesJointes,
      ];
      expect(
        pieces.where((PieceJointe p) => p.nature == NaturePieceJointe.vocal),
        hasLength(1),
      );
      expect(
        pieces.where((PieceJointe p) => p.nature == NaturePieceJointe.document),
        isNotEmpty,
      );
    });

    test('chaque role : un seul « soi », jamais deux familles dans un fil, '
        'jamais une coordonnee, toujours un objet de fil metier', () {
      for (final RoleDemoCommunications role in RoleDemoCommunications.values) {
        for (final FilMetier f in fixturesMessagesDemo(role, maintenantTest)) {
          expect(
            f.participants.where((Participant p) => p.estSoi),
            hasLength(1),
            reason: '${role.name} ${f.id}',
          );
          expect(
            f.participants
                .where(
                  (Participant p) => (p.fonction ?? '').startsWith('Parent'),
                )
                .length,
            lessThanOrEqualTo(1),
            reason: 'Famille A / Famille B : jamais (${f.id})',
          );
          expect(typesObjetsFilMetier.contains(f.objet.type), isTrue);
          for (final MessageCommunication m in f.messages) {
            expect(_coordonnee.hasMatch(m.texte), isFalse, reason: m.texte);
          }
          for (final Participant p in f.participants) {
            expect(_coordonnee.hasMatch(p.nomAffiche), isFalse);
          }
        }
      }
    });

    test('le controleur ne voit que son fil de mission, sans prenom '
        'd eleve', () {
      final List<FilMetier> fils = fixturesMessagesDemo(
        RoleDemoCommunications.controleur,
        maintenantTest,
      );
      expect(fils.single.objet.type, TypeObjetLie.mission);
      expect(fils.single.contexte, hasLength(1));
    });
  });

  group('Port de demonstration', () {
    test('le fil d une autre famille est refuse, jamais vide', () async {
      final MessagesMetierDemo port = portDemo(RoleDemoCommunications.tuteur);
      expect(await port.fil(filAutreFamilleDemo), isNull);
      final List<ResumeFil> fils = await port.fils();
      expect(
        fils.map((ResumeFil f) => f.id),
        isNot(contains(filAutreFamilleDemo)),
      );
    });

    test('le plus recent d abord, marquer lu fait tomber le badge', () async {
      final MessagesMetierDemo port = portDemo(RoleDemoCommunications.tuteur);
      final List<ResumeFil> avant = await port.fils();
      expect(avant.first.id, 'fil-adam');
      expect(avant.first.attention.estVisible, isTrue);
      await port.marquerLu('fil-adam');
      final List<ResumeFil> apres = await port.fils();
      expect(apres.first.attention.estVisible, isFalse);
    });

    test('filPourObjet rend le fil canonique de l objet', () async {
      final MessagesMetierDemo port = portDemo(RoleDemoCommunications.tuteur);
      final FilMetier? fil = await port.filPourObjet(
        TypeObjetLie.eleve,
        'eleve-adam',
      );
      expect(fil?.id, 'fil-adam');
      expect(
        await port.filPourObjet(TypeObjetLie.eleve, 'eleve-inconnu'),
        isNull,
      );
    });

    test('echec puis succes sur la meme cle ; hors ligne, jamais', () async {
      final MessagesMetierDemo echec = portDemo(
        RoleDemoCommunications.enseignant,
        situation: SituationDemoMessages.echecEnvoi,
      );
      await expectLater(
        echec.envoyer('fil-adam', 'Bonjour', 'k1'),
        throwsA(isA<StateError>()),
      );
      await echec.envoyer('fil-adam', 'Bonjour', 'k1');
      expect(echec.filEnMemoire('fil-adam')!.messages.last.texte, 'Bonjour');

      final MessagesMetierDemo horsLigne = portDemo(
        RoleDemoCommunications.tuteur,
        situation: SituationDemoMessages.horsLigne,
      );
      await expectLater(
        horsLigne.envoyer('fil-adam', 'Bonjour', 'k1'),
        throwsA(isA<StateError>()),
      );
      await expectLater(
        horsLigne.envoyer('fil-adam', 'Bonjour', 'k1'),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('La demonstration rendue (hors production)', () {
    Future<GoRouter> monterDemo(WidgetTester tester, String depart) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final GoRouter routeur = GoRouter(
        initialLocation: depart,
        routes: routesDemoCommunications('dev'),
      );
      addTearDown(routeur.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
          ],
          child: TranslationProvider(
            child: MaterialApp.router(
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              routerConfig: routeur,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return routeur;
    }

    test('aucune route de demonstration en production', () {
      expect(routesDemoCommunications('production'), isEmpty);
    });

    testWidgets('sans role : le choix du point de vue et des situations', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await monterDemo(
        tester,
        adresseDemoCommunications(VoieDemoCommunications.messages),
      );
      for (final RoleDemoCommunications r in RoleDemoCommunications.values) {
        expect(
          find.byKey(ValueKey<String>('demo-messages-role-${r.name}')),
          findsOneWidget,
        );
      }
      await tester.tap(
        find.byKey(const ValueKey<String>('demo-messages-role-controleur')),
      );
      await tester.pumpAndSettle();
      expect(
        routeur.routerDelegate.currentConfiguration.uri.queryParameters['role'],
        'controleur',
      );
      expect(find.byKey(ListeFils.cleLigne('fil-mission')), findsOneWidget);
      // Le controleur n'a qu'un fil : celui de sa mission.
      expect(find.byKey(ListeFils.cleLigne('fil-adam')), findsNothing);
    });

    testWidgets('situation « fil refuse » : rien de l autre famille', (
      WidgetTester tester,
    ) async {
      await monterDemo(
        tester,
        adresseDemoMessages(
          RoleDemoCommunications.tuteur,
          situation: SituationDemoMessages.filRefuse,
        ),
      );
      expect(
        find.text(t.com.socle.composants.etats.permissionRefusee),
        findsOneWidget,
      );
      expect(find.byType(FilDiscussion), findsNothing);
    });

    testWidgets('direction : le fil famille et le fil de mission, l ouvrir '
        'montre son contexte', (WidgetTester tester) async {
      await monterDemo(
        tester,
        adresseDemoMessages(RoleDemoCommunications.admin),
      );
      expect(
        find.byKey(ListeFils.cleLigne('fil-dossier-adam')),
        findsOneWidget,
      );
      expect(find.byKey(ListeFils.cleLigne('fil-mission')), findsOneWidget);
      await tester.tap(find.byKey(ListeFils.cleLigne('fil-mission')));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(EnteteFilContexte),
          matching: find.text('Visite de contrôle, Classe An-Nour'),
        ),
        findsOneWidget,
      );
      expect(find.byType(FilDiscussion), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
