// #Ra_staff (decision du directeur, 14/11/2026) : captures avant / apres de
// l'equipe dans les Messages de trois roles (candidat, enseignant, tuteur),
// par l'adaptateur reel (`filMetierJson`, parties « equipe »), 390 et 1440,
// francais et arabe. Donnees de test seulement. Jamais sans `CAPTURE_DIR`.
// `CAPTURE_PHASE` (avant, apres) prefixe les fichiers.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/communications/libelles_communication_slang.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/com_messages/messages_metier_supabase.dart';
import 'package:rewayah_academy/features/com_messages/port_messages_metier.dart';

import '../features/com_messages/support_messages.dart';
import 'outil_capture.dart';

const String _fil = '7c700000-0000-4000-8000-0000000000f1';

Map<String, dynamic> _equipe({bool soi = false}) => <String, dynamic>{
  'id': 'equipe',
  'nature': 'equipe',
  if (soi) 'est_soi': true,
};

/// Le fil d'un role avec l'equipe, tel que `com_lire_fil` le rend.
Map<String, dynamic> _filPour(String role, bool arabe) {
  final Map<String, dynamic> moi = switch (role) {
    'candidat' => <String, dynamic>{
      'id': 'p-cand',
      'nature': 'profil',
      'fonction': 'enseignant',
      'prenom': 'Salma',
      'nom': 'Benali',
      'est_soi': true,
    },
    'enseignant' => <String, dynamic>{
      'id': 'p-ens',
      'nature': 'profil',
      'fonction': 'enseignant',
      'prenom': 'Hafsa',
      'titre': 'sayyida',
      'est_soi': true,
    },
    _ => <String, dynamic>{
      'id': 'f-1',
      'nature': 'foyer',
      'eleves': <String>['Yusuf'],
      'est_soi': true,
    },
  };
  final Map<String, dynamic> objet = switch (role) {
    'candidat' => <String, dynamic>{
      'type': 'candidature',
      'id': '7c700000-0000-4000-8000-000000000101',
    },
    'enseignant' => <String, dynamic>{
      'type': 'classe',
      'id': '7c700000-0000-4000-8000-000000000102',
      'classe': 'An-Nour',
    },
    _ => <String, dynamic>{
      'type': 'dossier',
      'id': '7c700000-0000-4000-8000-000000000103',
    },
  };
  return <String, dynamic>{
    'id': _fil,
    'objet': objet,
    'accessible': true,
    'parties': <Map<String, dynamic>>[moi, _equipe()],
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
        'auteur': _equipe(),
        'texte': arabe
            ? 'وعليكم السلام، نحن هنا للإجابة.'
            : 'Bonjour, nous vous répondons ici.',
        'envoye_le': '2026-10-04T09:05:00Z',
      },
    ],
    'non_lus': 0,
    'peut_ecrire': true,
  };
}

void main() {
  final String phase = Platform.environment['CAPTURE_PHASE'] ?? 'apres';
  group('Capture : #Ra_staff ($phase)', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);

    for (final String role in <String>['candidat', 'enseignant', 'tuteur']) {
      for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
        for (final Size taille in <Size>[
          const Size(390, 844),
          const Size(1440, 900),
        ]) {
          final String s = '${taille.width.toInt()}x${taille.height.toInt()}';
          testWidgets('$role ${langue.name} $s', (WidgetTester tester) async {
            await tester.runAsync(() => LocaleSettings.setLocale(langue));
            final FilMetier fil = filMetierJson(
              _filPour(role, langue == AppLocale.ar),
              const LibellesCommunicationSlang(),
            );
            await monterMessages(
              tester,
              port: FauxMessagesMetier(fils: <FilMetier>[fil]),
              depart: cheminFilTest(_fil),
              taille: taille,
              langue: langue,
            );
            debugPrint(
              'PNG ${await capturerVue(tester, 'ra-staff/${phase}_${role}_${langue.name}_$s')}',
            );
          });
        }
      }
    }
  });
}
