/// I1 (02/11/2026, UX-013 et UX-017) : une invitation d'enseignant en cours
/// survit au lien de connexion et au rechargement.
///
/// Le lien de l'e-mail (`/connexion?mode=creer&invitation=1&code=...`) et le
/// lien « J'ai un code d'invitation » posent la marque ; le lien de connexion
/// s'ouvre souvent dans un nouvel onglet, et un rechargement vide la memoire
/// de l'application : la marque vit donc dans la memoire de l'appareil
/// (`memoire_appareil`, le `localStorage` sur le web, comme le
/// questionnaire). Au retour, l'inscription reprend sur le code
/// (`/inscription/invitation?code=...`) au lieu de « Pour qui creez-vous ce
/// compte ? ».
///
/// Ce qui est garde : le fait qu'une invitation est en cours, et le code
/// recopie s'il est connu. Le code n'est pas un secret de session : il ne sert
/// qu'une fois, avec l'adresse a laquelle il a ete emis, et le serveur le
/// verifie a nouveau (la verification de l'ecran ne sert qu'a l'affichage).
/// La marque s'efface quand le profil est cree, quand la personne revient
/// volontairement a « Pour qui creez-vous ce compte ? », et d'elle-meme apres
/// [dureeInvitationEnCours].
library;

import 'dart:convert';

import '../../core/router/routes.dart';
import 'questionnaire/memoire_appareil.dart';

/// La clef de la memoire de l'appareil.
const String clefInvitationEnCours = 'rewayah.inscription.invitation_en_cours';

/// Au-dela, la marque est oubliee (un lien de connexion ne vit pas si
/// longtemps ; une invitation, elle, se relit sur le serveur).
const Duration dureeInvitationEnCours = Duration(days: 2);

/// Une invitation en cours : le code recopie, s'il est connu.
class InvitationEnCours {
  /// Cree la marque.
  const InvitationEnCours({this.code});

  /// Le code, tel que porte par le lien ou verifie ; `null` si la personne
  /// n'a encore rien saisi.
  final String? code;

  /// L'adresse de l'ecran du code, avec le code s'il est connu.
  String get route => Uri(
    path: Routes.inscriptionInvitation,
    queryParameters: code == null ? null : <String, String>{'code': code!},
  ).toString();
}

/// Un code plausible (douze signes, avec ou sans tirets ni espaces) ;
/// rien d'autre n'est garde.
String? _codePlausible(String? brut) {
  if (brut == null) return null;
  final String c = brut.trim();
  if (c.isEmpty || c.length > 20) return null;
  return RegExp(r'^[A-Za-z0-9 -]+$').hasMatch(c) ? c : null;
}

/// Pose la marque, avec [code] s'il est connu. Un code deja garde n'est pas
/// efface par une marque sans code.
void retenirInvitationEnCours({String? code, DateTime? maintenant}) {
  final String? garde = _codePlausible(code) ?? lireInvitationEnCours()?.code;
  ecrireMemoireAppareil(
    clefInvitationEnCours,
    jsonEncode(<String, Object?>{
      'code': garde,
      'depuis': (maintenant ?? DateTime.now()).toUtc().toIso8601String(),
    }),
  );
}

/// La marque, si elle existe et n'a pas expire.
InvitationEnCours? lireInvitationEnCours({DateTime? maintenant}) {
  final String? brut = lireMemoireAppareil(clefInvitationEnCours);
  if (brut == null) return null;
  try {
    final Object? v = jsonDecode(brut);
    if (v is! Map) return null;
    final DateTime? depuis = DateTime.tryParse('${v['depuis']}');
    if (depuis == null ||
        (maintenant ?? DateTime.now()).difference(depuis) >
            dureeInvitationEnCours) {
      oublierInvitationEnCours();
      return null;
    }
    return InvitationEnCours(code: _codePlausible(v['code'] as String?));
  } on Object {
    return null;
  }
}

/// Efface la marque.
void oublierInvitationEnCours() =>
    effacerMemoireAppareil(clefInvitationEnCours);

/// Pose la marque si [adresse] est un lien d'invitation
/// (`invitation=1`, avec ou sans `code`).
void retenirInvitationDepuisAdresse(Uri adresse) {
  if (adresse.queryParameters['invitation'] == '1') {
    retenirInvitationEnCours(code: adresse.queryParameters['code']);
  }
}
