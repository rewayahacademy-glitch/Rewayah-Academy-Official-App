// COMPTE-OFFICIEL (PRAXIS-AFFICHAGE, 17/11/2026) : le nom d'un compte officiel
// s'affiche « #Ra_Praxis » sans italique, rendus par UNE regle de
// `lib/core/communications/nom_officiel.dart` a partir de l'indicateur `officiel` du
// serveur (absent = faux) ; la mention IA se lit dans la fiche du profil.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/communications/communications_supabase.dart';
import 'package:rewayah_academy/core/communications/lecture_fil_communication.dart';
import 'package:rewayah_academy/core/communications/libelles_communication_slang.dart';
import 'package:rewayah_academy/core/communications/nom_officiel.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/espace_travail_adaptatif.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart'
    show MessageFil;
import 'package:rewayah_academy/features/com_messages/panneau_contexte_fil.dart';
import 'package:rewayah_academy/features/com_messages/port_messages_metier.dart';

import 'support_messages.dart';

const Participant _praxis = Participant(
  id: 'praxis',
  nomAffiche: 'Praxis',
  officiel: true,
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
    MessageCommunication(
      id: 'm-${autre.id}',
      auteur: autre,
      texte: 'Bonjour.',
      envoyeLe: maintenantTest.subtract(const Duration(hours: 1)),
    ),
  ],
  capacites: const <CapaciteFil>{CapaciteFil.ecrire},
);

ResumeFil _resume(Participant autre) => ResumeFil(
  id: 'fil-${autre.id}',
  objet: ObjetLie(
    type: TypeObjetLie.classe,
    id: 'c',
    libelle: 'Classe An-Nour',
  ),
  interlocuteurs: <Participant>[autre],
  apercu: 'Bonjour.',
  dernierMessageLe: maintenantTest.subtract(const Duration(hours: 1)),
);

TextStyle? _styleDe(WidgetTester tester, String contient) {
  final Finder f = find.byWidgetPredicate(
    (Widget w) => w is Text && (w.data ?? '').contains(contient),
  );
  expect(f, findsWidgets, reason: 'un texte contenant « $contient »');
  return tester.widget<Text>(f.first).style;
}

void main() {
  group('la regle du nom officiel', () {
    test('le « # » est devant le nom, isole pour le sens de lecture', () {
      expect(nomOfficielMarque(), '\u2066#Ra_Praxis\u2069');
      expect(nomAvecMarque('Mariam', officiel: false), 'Mariam');
    });

    test('le serveur dit officiel ; une cle absente vaut faux', () {
      const LibellesCommunication l = LibellesCommunicationSlang();
      Participant lire(Map<String, dynamic> m) => participantJson(m, l);
      expect(
        lire(<String, dynamic>{
          'id': 'a',
          'nature': 'profil',
          'prenom': 'Praxis',
          'officiel': true,
        }).officiel,
        isTrue,
      );
      expect(
        lire(<String, dynamic>{
          'id': 'b',
          'nature': 'profil',
          'prenom': 'Mariam',
          'officiel': false,
        }).officiel,
        isFalse,
      );
      expect(
        lire(<String, dynamic>{
          'id': 'c',
          'nature': 'profil',
          'prenom': 'Mariam',
        }).officiel,
        isFalse,
        reason: 'une cle manquante ne casse rien',
      );
      Participant avecCode(String? code) => lire(<String, dynamic>{
        'id': 'p',
        'nature': 'profil',
        'prenom': 'Praxis',
        'officiel': true,
        'compte_officiel': ?code,
      });
      expect(avecCode('praxis').compteOfficiel, 'praxis');
      expect(avecCode('staff').compteOfficiel, 'staff');
      expect(
        avecCode(null).compteOfficiel,
        isNull,
        reason: 'serveur plus ancien : pas de code, jamais invente',
      );
      expect(
        lire(<String, dynamic>{
          'id': 'a',
          'nature': 'profil',
          'prenom': 'Praxis',
          'officiel': true,
        }).nomMarque,
        '\u2066#Ra_Praxis\u2069',
      );
    });

    test(
      'la bulle d\'un compte officiel porte la marque, jamais celle de soi',
      () {
        final MessageFil m = messageFilDe(_fil(_praxis).messages.first);
        expect(m.auteur, '\u2066#Ra_Praxis\u2069');
        final MessageFil autre = messageFilDe(_fil(_mariam).messages.first);
        expect(autre.auteur, 'Sayyida Mariam');
      },
    );
  });

  for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
    testWidgets('ligne de conversation (${langue.languageCode})', (
      WidgetTester tester,
    ) async {
      await monterMessages(
        tester,
        port: FauxMessagesMetier(
          resumesEnPlus: <ResumeFil>[_resume(_praxis), _resume(_mariam)],
        ),
        taille: const Size(1440, 900),
        langue: langue,
      );
      await tester.pumpAndSettle();
      _styleDe(tester, '#Ra_Praxis');
      expect(_styleDe(tester, 'Mariam')?.fontStyle, isNot(FontStyle.italic));
      expect(
        _styleDe(tester, '#Ra_Praxis')?.fontStyle,
        isNot(FontStyle.italic),
        reason: 'plus d\'italique (directeur, 17/11/2026)',
      );
    });
  }

  testWidgets(
    'la fiche du profil : mention IA et phrase, sans bouton inventé',
    (WidgetTester tester) async {
      await monterMessages(
        tester,
        port: FauxMessagesMetier(fils: <FilMetier>[_fil(_praxis)]),
        depart: cheminFilTest('fil-praxis'),
        taille: const Size(1440, 900),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(EspaceTravailAdaptatif.cleOuvrirContexte).first,
      );
      await tester.pumpAndSettle();
      expect(find.byType(PanneauContexteFil), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('fiche-officiel-praxis')),
        findsOneWidget,
      );
      final p = t.com.messages.panneau.officiel;
      expect(find.text(p.phrase), findsOneWidget);
      expect(find.text(p.mention), findsOneWidget);
    },
  );

  testWidgets('pas de fiche officielle pour une personne ordinaire', (
    WidgetTester tester,
  ) async {
    await monterMessages(
      tester,
      port: FauxMessagesMetier(fils: <FilMetier>[_fil(_mariam)]),
      depart: cheminFilTest('fil-mariam'),
      taille: const Size(1440, 900),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(EspaceTravailAdaptatif.cleOuvrirContexte).first,
    );
    await tester.pumpAndSettle();
    expect(find.byType(PanneauContexteFil), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('fiche-officiel-mariam')),
      findsNothing,
    );
    expect(find.text(t.com.messages.panneau.officiel.phrase), findsNothing);
  });

  testWidgets('la barre du fil au telephone porte la marque', (
    WidgetTester tester,
  ) async {
    await monterMessages(
      tester,
      port: FauxMessagesMetier(fils: <FilMetier>[_fil(_praxis)]),
      depart: cheminFilTest('fil-praxis'),
      taille: const Size(390, 844),
    );
    await tester.pumpAndSettle();
    expect(_styleDe(tester, '#Ra_Praxis')?.fontStyle, isNot(FontStyle.italic));
  });
}
