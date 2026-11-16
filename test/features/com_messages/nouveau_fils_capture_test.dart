// NOUVEAU-FILS : captures R3 de la liste des conversations (sautees sans
// CAPTURE_DIR). Telephone 390 x 844 et ordinateur 1440 x 900, francais et
// arabe, clair et sombre, avec une conversation nouvelle (avec message, avec
// des non lus), une conversation nouvelle vide, et deux conversations qui ne
// le sont pas.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/communications/modeles_communication.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';

import '../../capture/outil_capture.dart';
import 'support_messages.dart';

ResumeFil _fil(
  String id,
  String nom,
  String dossier, {
  String? apercu,
  bool nouveau = false,
  int nonLus = 0,
  required int heures,
}) => ResumeFil(
  id: id,
  objet: ObjetLie(
    type: TypeObjetLie.candidature,
    id: 'cand-$id',
    libelle: dossier,
  ),
  interlocuteurs: <Participant>[
    Participant(id: 'p-$id', nomAffiche: nom, fonction: 'Candidat'),
  ],
  apercu: apercu,
  dernierMessageLe: apercu == null
      ? null
      : maintenantTest.subtract(Duration(hours: heures)),
  attention: nonLus > 0
      ? IndicateurAttention(nonLus: nonLus)
      : IndicateurAttention.aucun,
  nouveau: nouveau,
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
              'nouveau-fils-liste-${taille.width.toInt()}-'
              '${langue.languageCode}-'
              '${lum == Brightness.dark ? 'sombre' : 'clair'}';
          testWidgets(nom, (WidgetTester tester) async {
            await monterMessages(
              tester,
              port: FauxMessagesMetier(
                resumesEnPlus: <ResumeFil>[
                  _fil(
                    'a',
                    'Amina Diallo',
                    'Candidature',
                    apercu: 'Bonjour, ma piece est prete.',
                    nouveau: true,
                    nonLus: 2,
                    heures: 1,
                  ),
                  _fil(
                    'b',
                    'Omar Benali',
                    'Candidature',
                    nouveau: true,
                    heures: 3,
                  ),
                  _fil(
                    'c',
                    'Fatima Sow',
                    'Candidature',
                    apercu: 'Merci beaucoup pour vos explications.',
                    nonLus: 1,
                    heures: 30,
                  ),
                  _fil(
                    'd',
                    'Youssef Haddad',
                    'Candidature',
                    apercu: 'Je vous envoie le document demain.',
                    heures: 80,
                  ),
                ],
              ),
              taille: taille,
              langue: langue,
              luminosite: lum,
            );
            await tester.pumpAndSettle();
            await capturerVue(tester, 'NOUVEAU-FILS/$nom');
          });
        }
      }
    }
  }, skip: sautSansCapture);
}
