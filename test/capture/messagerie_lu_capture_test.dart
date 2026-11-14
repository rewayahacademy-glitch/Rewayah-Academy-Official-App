// MESSAGERIE-LU (directeur, 14/11/2026) : les signes sous les messages de soi,
// « Envoye » (une coche, pale) et « Lu » (deux coches, foncees), avec la date ;
// fr et ar, 390 et 1440, clair et sombre. Jamais sans `CAPTURE_DIR`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/communications/libelles_communication_slang.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/ouvreur_onglet.dart';
import 'package:rewayah_academy/features/com_messages/messages_metier_supabase.dart';
import 'package:rewayah_academy/features/com_messages/port_messages_metier.dart';

import '../features/com_messages/support_messages.dart';
import 'outil_capture.dart';

const String _fil = '7c800000-0000-4000-8000-0000000000f1';

Map<String, dynamic> _filJson(bool arabe) {
  const Map<String, dynamic> moi = <String, dynamic>{
    'id': 'p-cand',
    'nature': 'profil',
    'fonction': 'enseignant',
    'prenom': 'Salma',
    'nom': 'Benali',
    'est_soi': true,
  };
  const Map<String, dynamic> equipe = <String, dynamic>{
    'id': 'equipe',
    'nature': 'equipe',
  };
  return <String, dynamic>{
    'id': _fil,
    'objet': <String, dynamic>{
      'type': 'candidature',
      'id': '7c800000-0000-4000-8000-000000000101',
    },
    'accessible': true,
    'parties': <Map<String, dynamic>>[moi, equipe],
    'messages': <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 'm-1',
        'auteur': moi,
        'texte': arabe
            ? 'السلام عليكم، لدي سؤال.'
            : 'Bonjour, j\'ai une question.',
        'envoye_le': '2026-10-04T09:00:00Z',
      },
      <String, dynamic>{
        'id': 'm-2',
        'auteur': equipe,
        'texte': arabe
            ? 'وعليكم السلام، تجدون الإطار هنا: https://rewayahacademy.com/ar/cadre'
            : 'Bonjour, le cadre est ici : https://rewayahacademy.com/fr/cadre',
        'envoye_le': '2026-10-04T09:05:00Z',
      },
      <String, dynamic>{
        'id': 'm-3',
        'auteur': moi,
        'texte': arabe ? 'شكرًا، قرأته.' : 'Merci, je le lis.',
        'envoye_le': '2026-10-04T09:12:00Z',
      },
    ],
    'non_lus': 0,
    'peut_ecrire': true,
    // La direction a lu jusqu'a 09:06 : le premier message est lu, le
    // dernier seulement envoye.
    'lu_par_autres_le': '2026-10-04T09:06:00Z',
  };
}

void main() {
  group('Capture : envoye et lu', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);

    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      for (final Size taille in <Size>[
        const Size(390, 844),
        const Size(1440, 900),
      ]) {
        for (final Brightness lum in Brightness.values) {
          final String s =
              '${taille.width.toInt()}x${taille.height.toInt()}_${lum.name}';
          testWidgets('${langue.name} $s', (WidgetTester tester) async {
            await tester.runAsync(() => LocaleSettings.setLocale(langue));
            final FilMetier fil = filMetierJson(
              _filJson(langue == AppLocale.ar),
              const LibellesCommunicationSlang(),
            );
            await monterMessages(
              tester,
              port: FauxMessagesMetier(fils: <FilMetier>[fil]),
              depart: cheminFilTest(_fil),
              taille: taille,
              langue: langue,
              luminosite: lum,
              // Comme dans un navigateur : les liens de #Ra_staff s'ouvrent.
              surcharges: <Override>[
                ouvreurOngletProvider.overrideWithValue((Uri _) => true),
              ],
            );
            debugPrint(
              'PNG ${await capturerVue(tester, 'messagerie-lu/${langue.name}_$s')}',
            );
          });
        }
      }
    }
  });
}
