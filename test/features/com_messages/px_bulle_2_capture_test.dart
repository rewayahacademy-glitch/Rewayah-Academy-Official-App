// PX-BULLE-2 : captures R3 du cote de la direction : dans le fil de l'academie,
// les messages ecrits par Praxis (de soi) portent son image et « #Ra_Praxis » ;
// ceux de l'administrateur restent sans marque (390 et 1440, fr et ar, clair et
// sombre). Sautees sans CAPTURE_DIR :
//   CAPTURE_DIR=docs/current/captures/E2E flutter test \
//     test/features/com_messages/px_bulle_2_capture_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/communications/image_praxis.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/com_messages/port_messages_metier.dart';

import '../../capture/outil_capture.dart';
import 'support_messages.dart';

const Participant _praxis = Participant(
  id: 'praxis-soi',
  nomAffiche: 'Praxis',
  officiel: true,
  compteOfficiel: codeComptePraxis,
  estSoi: true,
);
const Participant _famille = Participant(
  id: 'famille',
  nomAffiche: 'Sayyida Mariam',
);
const Participant _soi = Participant(
  id: 'soi',
  nomAffiche: 'Ahmed',
  estSoi: true,
);

FilMetier _fil() => FilMetier(
  id: 'fil-praxis',
  contexte: <ElementContexteFil>[
    ElementContexteFil(
      objet: ObjetLie(
        type: TypeObjetLie.classe,
        id: 'c',
        libelle: 'Classe An-Nour',
      ),
    ),
  ],
  participants: const <Participant>[_famille, _praxis],
  messages: <MessageCommunication>[
    MessageCommunication(
      id: 'm1',
      auteur: _praxis,
      texte: 'Bonjour, voici le rappel de votre prochaine séance.',
      envoyeLe: maintenantTest.subtract(const Duration(hours: 3)),
    ),
    MessageCommunication(
      id: 'm2',
      auteur: _famille,
      texte: 'Merci, c\'est noté.',
      envoyeLe: maintenantTest.subtract(const Duration(hours: 2)),
    ),
    MessageCommunication(
      id: 'm3',
      auteur: _praxis,
      texte: 'Avec plaisir. Je reste là pour toute question.',
      envoyeLe: maintenantTest.subtract(const Duration(hours: 1)),
    ),
    MessageCommunication(
      id: 'm4',
      auteur: _soi,
      texte: 'La direction confirme l\'horaire.',
      envoyeLe: maintenantTest.subtract(const Duration(minutes: 30)),
    ),
  ],
  capacites: const <CapaciteFil>{CapaciteFil.ecrire},
);

void main() {
  group('captures PX-BULLE-2', () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);
    for (final Size taille in const <Size>[Size(390, 844), Size(1440, 900)]) {
      for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
        for (final Brightness lum in <Brightness>[
          Brightness.light,
          Brightness.dark,
        ]) {
          final String nom =
              'bulle-praxis-soi-${taille.width.toInt()}-${langue.languageCode}'
              '-${lum == Brightness.dark ? 'sombre' : 'clair'}';
          testWidgets(nom, (WidgetTester tester) async {
            await monterMessages(
              tester,
              port: FauxMessagesMetier(fils: <FilMetier>[_fil()]),
              depart: cheminFilTest('fil-praxis'),
              taille: taille,
              langue: langue,
              luminosite: lum,
            );
            await tester.pumpAndSettle();
            // L'image de Praxis se decode hors du temps simule : on lui laisse
            // le temps avant la capture.
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 300)),
            );
            await tester.pumpAndSettle();
            await capturerVue(tester, 'PX-BULLE-2/$nom');
          });
        }
      }
    }
  }, skip: sautSansCapture);
}
