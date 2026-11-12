// FUSEAU-IDENTITE-PRO (garde-cap, 12/11/2026) : les ecrans de l'enseignant
// (disponibilites, Identite professionnelle) lisent le fuseau du profil par
// `monHorlogeProvider`. Sans session Supabase, le vrai provider rend `null`
// (un profil sans fuseau) : un test qui monte ces ecrans pose ici le fuseau
// que le faux planning rendait jusque-la (Europe/Paris). Donnees de test.

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:rewayah_academy/core/tc_horloge/fuseaux_interlocuteurs.dart';
import 'package:rewayah_academy/core/tc_horloge/mon_horloge.dart';

/// Le fuseau du profil a [fuseau] (Paris par defaut), decalage fictif.
Override monHorlogeDeTest({
  String fuseau = 'Europe/Paris',
  Duration decalage = const Duration(hours: 1),
}) => monHorlogeProvider.overrideWith(
  (_) async => MonHorloge(
    maintenantServeur: DateTime.utc(2026, 11, 12, 9),
    moi: FuseauVu(fuseau: fuseau, decalage: decalage),
  ),
);
