// PROFILS P1 (directeur, 11/11/2026 ; verifie par le pilote en production,
// tranche par le garde-cap) : UNE seule langue, celle du compte.
//
// - La ligne « Langue » du Compte ecrit la langue du compte
//   (`ma_langue_communication_regler`, port existant) ET change la langue de
//   l'interface. Elle ne propose que le francais et l'arabe.
// - Au demarrage, la langue du compte prime sur celle de l'appareil. Hors
//   connexion, ou tant qu'elle n'est pas lue, la derniere langue connue reste
//   (preference persistee) : aucun eclair.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../capacites/port_langues_communication.dart';
import '../preferences/preferences_locales.dart';
import '../session/session_controleur.dart';
import '../session/session_state.dart';

/// Les langues proposees par la ligne « Langue », dans l'ordre.
const List<PreferenceLangue> languesDuCompte = <PreferenceLangue>[
  PreferenceLangue.francais,
  PreferenceLangue.arabe,
];

/// Le code serveur d'une langue du compte.
String codeLangueCompte(PreferenceLangue langue) =>
    langue == PreferenceLangue.arabe ? 'ar' : 'fr';

/// La langue du compte depuis son code serveur ; `null` pour une langue que
/// l'interface ne parle pas (elle n'est alors pas appliquee).
PreferenceLangue? langueCompteDepuis(String? code) => switch (code) {
  'ar' => PreferenceLangue.arabe,
  'fr' => PreferenceLangue.francais,
  _ => null,
};

/// Change la langue : l'interface d'abord (instantane, DECISION-FLUIDITE),
/// puis la langue du compte au serveur. Rend `false` si le serveur ne l'a pas
/// enregistree : l'interface garde la langue choisie, l'ecran le dit.
Future<bool> choisirLangueCompte(WidgetRef ref, PreferenceLangue langue) async {
  ref.read(preferencesLocalesProvider.notifier).langue(langue);
  try {
    await ref
        .read(portLanguesCommunicationProvider)
        .regler(codeLangueCompte(langue));
    return true;
  } on Object {
    return false;
  }
}

/// Au demarrage et a chaque nouvelle personne connectee, la langue du compte
/// est lue et adoptee. Une lecture qui echoue ne change rien. **Monte par
/// `RewayahApp`**, comme les autres persistances.
final Provider<void> synchroLangueCompteProvider = Provider<void>((Ref ref) {
  final String? profil = ref.watch(
    sessionProvider.select((SessionState s) => s.profileId),
  );
  if (profil == null) return;
  final PortLanguesCommunication port = ref.watch(
    portLanguesCommunicationProvider,
  );
  Future<void> adopter() async {
    try {
      final PreferenceLangue? langue = langueCompteDepuis(
        await port.maLangue(),
      );
      if (langue != null && ref.mounted) {
        ref
            .read(preferencesLocalesProvider.notifier)
            .adopterLangueDuCompte(langue);
      }
    } on Object {
      // Hors connexion ou capacite absente : la derniere langue connue reste.
    }
  }

  unawaited(adopter());
});
