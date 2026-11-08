/// Defaut 1.8 (robot pieges_1, consigne du garde-cap du 06/11/2026) : apres un
/// rechargement, le prenom saisi pendant l'inscription etait perdu.
///
/// Le brouillon de l'inscription vit dans la memoire de l'appareil
/// (`memoire_appareil` : le `localStorage` sur le web, comme le questionnaire et
/// l'invitation en cours) le temps de l'inscription, puis s'efface :
/// a la creation du profil, a l'inscription du candidat acceptee, a la
/// deconnexion depuis l'inscription, et de lui-meme apres
/// [dureeBrouillonInscription].
///
/// On ne garde que ce que la personne a saisi ou choisi pour ses etapes :
/// usage, prenom, nom, nom latin, genre, cours du parent, pays et numero de
/// telephone, « sans code ». Jamais : la case de confidentialite (elle se
/// recoche, a la version affichee), ni ce que le serveur a repondu.
library;

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/domain/enums.dart';
import 'brouillon_inscription.dart';
import 'questionnaire/memoire_appareil.dart';

/// La clef de la memoire de l'appareil.
const String clefBrouillonInscription = 'rewayah.inscription.brouillon';

/// Au-dela, le brouillon est oublie.
const Duration dureeBrouillonInscription = Duration(days: 2);

/// Vrai quand le brouillon se garde sur l'appareil. L'application le pose
/// (`main.dart`) ; les tests l'ouvrent seulement la ou ils le prouvent, pour
/// qu'un test ne retrouve jamais le brouillon d'un autre.
final Provider<bool> persistanceBrouillonProvider = Provider<bool>(
  (Ref _) => false,
);

/// Ecrit le brouillon, ou l'efface s'il est vide.
void ecrireBrouillonInscription(
  BrouillonInscription b, {
  DateTime? maintenant,
}) {
  final Map<String, Object?> j = <String, Object?>{
    'usage': b.usage?.name,
    'prenom': b.prenom,
    'nom': b.nom,
    'nomLatin': b.nomLatin,
    'genre': b.genre?.valeurSql,
    'parentSuitDesCours': b.parentSuitDesCours,
    'paysTelephone': b.paysTelephone,
    'numeroTelephone': b.numeroTelephone,
    'sansCode': b.sansCode,
  };
  final bool vide =
      b.usage == null &&
      b.prenom.isEmpty &&
      b.nom.isEmpty &&
      b.genre == null &&
      b.paysTelephone == null &&
      b.numeroTelephone.isEmpty;
  if (vide) {
    oublierBrouillonInscription();
    return;
  }
  j['depuis'] = (maintenant ?? DateTime.now()).toUtc().toIso8601String();
  ecrireMemoireAppareil(clefBrouillonInscription, jsonEncode(j));
}

/// Le brouillon garde, s'il existe et n'a pas expire ; `null` sinon.
BrouillonInscription? lireBrouillonInscription({DateTime? maintenant}) {
  final String? brut = lireMemoireAppareil(clefBrouillonInscription);
  if (brut == null) return null;
  try {
    final Object? v = jsonDecode(brut);
    if (v is! Map) return null;
    final DateTime? depuis = DateTime.tryParse('${v['depuis']}');
    if (depuis == null ||
        (maintenant ?? DateTime.now()).difference(depuis) >
            dureeBrouillonInscription) {
      oublierBrouillonInscription();
      return null;
    }
    String texte(String cle) => v[cle] is String ? v[cle] as String : '';
    UsageInscription? usage;
    for (final UsageInscription u in UsageInscription.values) {
      if (u.name == v['usage']) usage = u;
    }
    return BrouillonInscription(
      usage: usage,
      prenom: texte('prenom'),
      nom: texte('nom'),
      nomLatin: texte('nomLatin'),
      genre: Genre.depuisSql(v['genre'] as String?),
      parentSuitDesCours: v['parentSuitDesCours'] is bool
          ? v['parentSuitDesCours'] as bool
          : null,
      paysTelephone: v['paysTelephone'] is String
          ? v['paysTelephone'] as String
          : null,
      numeroTelephone: texte('numeroTelephone'),
      sansCode: v['sansCode'] == true,
    );
  } on Object {
    return null;
  }
}

/// Efface le brouillon garde.
void oublierBrouillonInscription() =>
    effacerMemoireAppareil(clefBrouillonInscription);
