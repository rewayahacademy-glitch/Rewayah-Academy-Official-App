// COMPTE-OFFICIEL : captures R3 (sautees sans CAPTURE_DIR). Liste et fil
// d'une conversation avec Praxis, 390 et 1440, francais et arabe, clair et
// sombre ; la fiche du profil (panneau de contexte) a 1440.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/espace_travail_adaptatif.dart';
import 'package:rewayah_academy/features/com_messages/port_messages_metier.dart';

import '../../capture/outil_capture.dart';
import 'support_messages.dart';

const Participant _praxis = Participant(
  id: 'praxis',
  nomAffiche: 'Praxis',
  officiel: true,
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
  participants: const <Participant>[_soi, _praxis],
  messages: <MessageCommunication>[
    MessageCommunication(
      id: 'm1',
      auteur: _praxis,
      texte: 'Bonjour. Votre demande est transmise à l\'équipe.',
      envoyeLe: maintenantTest.subtract(const Duration(hours: 1)),
    ),
  ],
  capacites: const <CapaciteFil>{CapaciteFil.ecrire},
);

void main() {
  group('captures', () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);
    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      for (final Brightness lum in <Brightness>[
        Brightness.light,
        Brightness.dark,
      ]) {
        for (final Size taille in const <Size>[
          Size(390, 844),
          Size(1440, 900),
        ]) {
          final String nom =
              '${taille.width.toInt()}-${langue.languageCode}-'
              '${lum == Brightness.dark ? 'sombre' : 'clair'}';
          testWidgets('liste-$nom', (WidgetTester tester) async {
            await monterMessages(
              tester,
              port: FauxMessagesMetier(
                fils: <FilMetier>[_fil()],
                resumesEnPlus: <ResumeFil>[
                  ResumeFil(
                    id: 'fil-praxis',
                    objet: ObjetLie(
                      type: TypeObjetLie.classe,
                      id: 'c',
                      libelle: 'Classe An-Nour',
                    ),
                    interlocuteurs: const <Participant>[_praxis],
                    apercu: 'Bonjour. Votre demande est transmise.',
                    dernierMessageLe: maintenantTest.subtract(
                      const Duration(hours: 1),
                    ),
                  ),
                ],
              ),
              taille: taille,
              langue: langue,
              luminosite: lum,
            );
            await tester.pumpAndSettle();
            await capturerVue(tester, 'COMPTE-OFFICIEL/liste-$nom');
          });
          testWidgets('fil-$nom', (WidgetTester tester) async {
            await monterMessages(
              tester,
              port: FauxMessagesMetier(fils: <FilMetier>[_fil()]),
              depart: cheminFilTest('fil-praxis'),
              taille: taille,
              langue: langue,
              luminosite: lum,
            );
            await tester.pumpAndSettle();
            await capturerVue(tester, 'COMPTE-OFFICIEL/fil-$nom');
            if (taille.width > 1000) {
              await tester.tap(
                find.byKey(EspaceTravailAdaptatif.cleOuvrirContexte).first,
              );
              await tester.pumpAndSettle();
              await capturerVue(tester, 'COMPTE-OFFICIEL/fiche-$nom');
            }
          });
        }
      }
    }
  }, skip: sautSansCapture);
}
