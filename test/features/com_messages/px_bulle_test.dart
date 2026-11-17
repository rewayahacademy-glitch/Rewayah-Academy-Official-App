// PX-BULLE (directeur, 17/11/2026) : CHAQUE bulle de Praxis porte son avatar et
// le nom « #Ra_Praxis » (la regle de `nom_officiel.dart`), meme dans une
// conversation a deux ; le toucher du nom ou de l'avatar ouvre le panneau de
// contexte (le profil existant) ; aucune bulle humaine ne change. Seul le code
// serveur `praxis` donne l'avatar : un autre compte officiel n'a pas d'image.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/communications/image_praxis.dart';
import 'package:rewayah_academy/core/communications/lecture_fil_communication.dart';
import 'package:rewayah_academy/core/communications/nom_officiel.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart'
    show MessageFil;
import 'package:rewayah_academy/features/com_messages/panneau_contexte_fil.dart';
import 'package:rewayah_academy/features/com_messages/port_messages_metier.dart';

import 'support_messages.dart';

const Participant _praxis = Participant(
  id: 'praxis',
  nomAffiche: 'Praxis',
  officiel: true,
  compteOfficiel: codeComptePraxis,
);
const Participant _autreOfficiel = Participant(
  id: 'autre',
  nomAffiche: 'Autre',
  officiel: true,
  compteOfficiel: 'autre_compte',
);
const Participant _mariam = Participant(
  id: 'mariam',
  nomAffiche: 'Sayyida Mariam',
  fonction: 'Enseignante',
);
const Participant _soi = Participant(
  id: 'soi',
  nomAffiche: 'Ahmed',
  estSoi: true,
);

MessageCommunication _msg(String id, Participant auteur, String texte, int h) =>
    MessageCommunication(
      id: id,
      auteur: auteur,
      texte: texte,
      envoyeLe: maintenantTest.subtract(Duration(hours: h)),
    );

/// Une conversation a deux : soi et [autre].
FilMetier _fil(Participant autre) => FilMetier(
  id: 'fil-${autre.id}',
  contexte: <ElementContexteFil>[
    ElementContexteFil(
      objet: ObjetLie(
        type: TypeObjetLie.classe,
        id: 'c',
        libelle: 'Classe An-Nour',
      ),
    ),
  ],
  participants: <Participant>[_soi, autre],
  messages: <MessageCommunication>[
    _msg('m1-${autre.id}', autre, 'Bonjour, voici votre rappel.', 3),
    _msg('m2-${autre.id}', _soi, 'Merci.', 2),
    _msg('m3-${autre.id}', autre, 'Avec plaisir.', 1),
  ],
  capacites: const <CapaciteFil>{CapaciteFil.ecrire},
);

Finder _bulle(String id) => find.byKey(ValueKey<String>('message-$id'));

void main() {
  group('messageFilDe : qui porte un avatar', () {
    test('seul le code serveur `praxis`, jamais un nom ni un autre compte', () {
      expect(
        messageFilDe(_msg('a', _praxis, 'x', 1)).avatarAuteur,
        isA<ImagePraxis>(),
      );
      expect(
        messageFilDe(_msg('b', _autreOfficiel, 'x', 1)).avatarAuteur,
        isNull,
        reason: 'un autre compte officiel : pas d\'image de Praxis',
      );
      expect(
        messageFilDe(_msg('c', _mariam, 'x', 1)).avatarAuteur,
        isNull,
        reason: 'une bulle humaine ne change pas',
      );
      const Participant nomPraxisSansCode = Participant(
        id: 'z',
        nomAffiche: 'Praxis',
        officiel: true,
      );
      expect(
        messageFilDe(_msg('d', nomPraxisSansCode, 'x', 1)).avatarAuteur,
        isNull,
        reason: 'serveur plus ancien : pas de code, jamais invente',
      );
    });

    test('mes propres messages n\'en portent jamais', () {
      final MessageFil m = messageFilDe(_msg('e', _soi, 'x', 1));
      expect(m.avatarAuteur, isNull);
    });
  });

  for (final (Size taille, double echelle) cas in <(Size, double)>[
    (const Size(390, 844), 1),
    (const Size(320, 800), 2),
    (const Size(1440, 900), 1),
  ]) {
    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      testWidgets(
        'conversation a deux avec Praxis : avatar + nom sur chacune de ses '
        'bulles (${cas.$1.width.toInt()}, x${cas.$2.toInt()}, '
        '${langue.languageCode})',
        (WidgetTester tester) async {
          await monterMessages(
            tester,
            port: FauxMessagesMetier(fils: <FilMetier>[_fil(_praxis)]),
            depart: cheminFilTest('fil-praxis'),
            taille: cas.$1,
            echelleTexte: cas.$2,
            langue: langue,
          );
          await tester.pumpAndSettle();
          for (final String id in <String>['m1-praxis', 'm3-praxis']) {
            expect(
              find.descendant(
                of: _bulle(id),
                matching: find.byType(ImagePraxis),
              ),
              findsOneWidget,
              reason: 'l\'avatar de Praxis sur $id',
            );
            expect(
              find.descendant(
                of: _bulle(id),
                matching: find.text(nomOfficielMarque()),
              ),
              findsOneWidget,
              reason: 'le nom #Ra_Praxis sur $id',
            );
          }
          // Mon message : ni avatar ni nom.
          expect(
            find.descendant(
              of: _bulle('m2-praxis'),
              matching: find.byType(ImagePraxis),
            ),
            findsNothing,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('une bulle humaine dans une conversation a deux : inchangee', (
    WidgetTester tester,
  ) async {
    await monterMessages(
      tester,
      port: FauxMessagesMetier(fils: <FilMetier>[_fil(_mariam)]),
      depart: cheminFilTest('fil-mariam'),
      taille: const Size(390, 844),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: _bulle('m1-mariam'),
        matching: find.byType(ImagePraxis),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: _bulle('m1-mariam'),
        matching: find.text('Sayyida Mariam'),
      ),
      findsNothing,
      reason: 'sans groupe, une bulle humaine ne porte pas de nom',
    );
    expect(find.byType(ImagePraxis), findsNothing);
  });

  testWidgets('un autre compte officiel : le nom oui, aucune image', (
    WidgetTester tester,
  ) async {
    await monterMessages(
      tester,
      port: FauxMessagesMetier(fils: <FilMetier>[_fil(_autreOfficiel)]),
      depart: cheminFilTest('fil-autre'),
      taille: const Size(390, 844),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ImagePraxis), findsNothing);
  });

  testWidgets('toucher l\'avatar ouvre le profil (le panneau de contexte)', (
    WidgetTester tester,
  ) async {
    await monterMessages(
      tester,
      port: FauxMessagesMetier(fils: <FilMetier>[_fil(_praxis)]),
      depart: cheminFilTest('fil-praxis'),
      taille: const Size(390, 844),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PanneauContexteFil), findsNothing);
    await tester.tap(
      find
          .descendant(
            of: _bulle('m1-praxis'),
            matching: find.byType(ImagePraxis),
          )
          .first,
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    expect(find.byType(PanneauContexteFil), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('fiche-officiel-praxis')),
      findsOneWidget,
    );
  });

  testWidgets('toucher le nom ouvre aussi le profil', (
    WidgetTester tester,
  ) async {
    await monterMessages(
      tester,
      port: FauxMessagesMetier(fils: <FilMetier>[_fil(_praxis)]),
      depart: cheminFilTest('fil-praxis'),
      taille: const Size(390, 844),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PanneauContexteFil), findsNothing);
    await tester.tap(
      find
          .descendant(
            of: _bulle('m1-praxis'),
            matching: find.text(nomOfficielMarque()),
          )
          .first,
      warnIfMissed: false,
    );
    // La bulle ecoute aussi le double toucher (le coeur) : le toucher simple
    // part a la fin du delai de double toucher.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.byType(PanneauContexteFil), findsOneWidget);
  });
}
