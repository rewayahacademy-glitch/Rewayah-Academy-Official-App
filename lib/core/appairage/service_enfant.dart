import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../cache/secure/stockage_securise.dart';
import 'profils_locaux.dart';

/// Ce qu'un appairage rend a l'appareil de l'enfant.
@immutable
class AppairageReussi {
  /// Cree le resultat d'un appairage.
  const AppairageReussi({
    required this.profilId,
    required this.prenom,
    required this.jetonAppareil,
  });

  /// Le profil auquel l'appareil vient d'etre appaire.
  final String profilId;

  /// Le prenom, pour la tuile de choix de profil.
  final String prenom;

  /// Le jeton emis par le serveur. **Rendu une seule fois** : la base n'en garde
  /// que l'empreinte. Il doit etre ecrit dans le coffre du systeme
  /// immediatement, sinon l'appairage est a refaire.
  final String jetonAppareil;
}

/// Pourquoi le serveur a refuse un code ou un jeton d'appareil.
///
/// Le serveur ne rend pas de code d'erreur stable (DB-APP-06) : la
/// correspondance se fait sur les textes connus de `consommer_code_appairage`
/// et de `profil_du_jeton_appareil` (`0004_inscription_kyc_appairage.sql`,
/// lignes 671-691 et 808), renvoyes tels quels par la fonction Edge
/// `session-enfant` dans `{error}`. Un texte inconnu donne le motif general ;
/// le texte brut n'est jamais affiche.
///
/// Un code **remplace** par un plus recent est efface en base (`deleted_at`,
/// ligne 668) et le serveur le dit `code inconnu` : les deux cas partagent
/// donc un seul motif, et son message le dit.
enum MotifRefusAppairage {
  /// `code inconnu` : faute de frappe, ou code remplace par un plus recent.
  inconnu,

  /// `code expire`.
  expire,

  /// `code deja utilise`.
  dejaUtilise,

  /// `jeton d'appareil inconnu ou revoque` : le tuteur a retire l'appareil.
  revoque,

  /// `plafond d'appareils atteint`.
  plafond,

  /// Reponse 429 : pret pour une limitation de debit (DB-APP-07), declenche
  /// seulement par une reponse du serveur.
  tropDEssais,

  /// Aucune reponse : la requete n'est pas partie.
  horsLigne,

  /// Tout le reste.
  generique;

  /// Le motif d'une reponse de refus de la fonction Edge.
  static MotifRefusAppairage depuisReponse({
    required int statut,
    required Object? details,
  }) {
    if (statut == 429) {
      return tropDEssais;
    }
    final Object? texteBrut = details is Map ? details['error'] : details;
    final String texte = (texteBrut?.toString() ?? '').toLowerCase();
    if (texte.contains('code inconnu')) {
      return inconnu;
    }
    if (texte.contains('code expire')) {
      return expire;
    }
    if (texte.contains('deja utilise')) {
      return dejaUtilise;
    }
    if (texte.contains('revoque')) {
      return revoque;
    }
    if (texte.contains('plafond')) {
      return plafond;
    }
    return generique;
  }

  /// Le motif de n'importe quelle erreur levee pendant un appairage.
  static MotifRefusAppairage depuis(Object erreur) {
    if (erreur is AppairageRefuse) {
      return erreur.motif;
    }
    if (erreur is FunctionsFetchException) {
      return horsLigne;
    }
    if (erreur is FunctionException) {
      return depuisReponse(statut: erreur.status, details: erreur.details);
    }
    return generique;
  }
}

/// Un refus du serveur, deja traduit en motif affichable.
class AppairageRefuse implements Exception {
  /// Cree le refus.
  const AppairageRefuse(this.motif);

  /// Le motif, jamais le texte brut du serveur.
  final MotifRefusAppairage motif;

  @override
  String toString() => 'AppairageRefuse(${motif.name})';
}

/// Le format du code d'appairage, tel que le serveur le tire
/// (`0004_inscription_kyc_appairage.sql`, alphabet
/// `23456789ABCDEFGHJKLMNPQRSTUVWXYZ` : ni `0`, ni `1`, ni `I`, ni `O`).
abstract final class FormatCodeAppairage {
  /// Le nombre de caracteres.
  static const int longueur = 6;

  /// Le motif complet d'un code valide.
  static final RegExp motif = RegExp(r'^[2-9A-HJ-NP-Z]{6}$');

  /// Un caractere admis, pour filtrer la saisie.
  static final RegExp caractere = RegExp('[2-9A-HJ-NP-Z]');

  /// Le code normalise (`trim` puis majuscules) s'il a le bon format, sinon
  /// `null`. **Tout autre contenu, adresse web comprise, est refuse sans etre
  /// ouvert.**
  static String? normaliser(String brut) {
    final String code = brut.trim().toUpperCase();
    return motif.hasMatch(code) ? code : null;
  }
}

/// La connexion de l'eleve, cote appareil de l'enfant.
///
/// L'enfant n'a ni courriel ni mot de passe. Sa ligne `profiles` reference
/// pourtant `auth.users`, et une session Supabase ne se fabrique pas cote
/// client : les deux operations passent donc par une fonction Edge, seule
/// detentrice de la cle de service.
abstract interface class ServiceEnfant {
  /// Echange un code d'appairage contre un jeton d'appareil.
  ///
  /// **N'ouvre pas de session** : elle s'ouvre ensuite par [ouvrirSession],
  /// une fois le jeton range et le code personnel choisi. L'ouvrir ici faisait
  /// quitter `/connexion/eleve` par le routeur avant que le jeton ne soit
  /// ecrit (C05 section 3.1, point 1).
  ///
  /// Leve [AppairageRefuse] sur un refus du serveur ou sans reseau.
  Future<AppairageReussi> appairer({
    required String code,
    required String empreinteAppareil,
    required String plateforme,
  });

  /// Rouvre une session a partir du jeton deja stocke sur l'appareil.
  ///
  /// Leve [AppairageRefuse] sur un refus du serveur ou sans reseau.
  Future<void> ouvrirSession(String jetonAppareil);
}

/// L'implementation reelle.
class ServiceEnfantSupabase implements ServiceEnfant {
  /// Cree le service.
  const ServiceEnfantSupabase(this._client);

  final SupabaseClient _client;

  /// Le nom de la fonction Edge.
  static const String fonction = 'session-enfant';

  @override
  Future<AppairageReussi> appairer({
    required String code,
    required String empreinteAppareil,
    required String plateforme,
  }) async {
    final Map<String, dynamic> corps = await _appeler(<String, dynamic>{
      'code': code,
      'device_fingerprint': empreinteAppareil,
      'platform': plateforme,
    });

    // Le `token_hash` rendu ici n'est pas echange : la session s'ouvre par le
    // jeton d'appareil, apres le code personnel ([ServiceEnfant.appairer]).
    return AppairageReussi(
      profilId: corps['profile_id'] as String,
      prenom: corps['first_name'] as String? ?? '',
      jetonAppareil: corps['device_token'] as String,
    );
  }

  @override
  Future<void> ouvrirSession(String jetonAppareil) async {
    final Map<String, dynamic> corps = await _appeler(<String, dynamic>{
      'device_token': jetonAppareil,
    });
    await _ouvrirDepuis(corps);
  }

  /// Appelle la fonction Edge et traduit ses refus en [AppairageRefuse].
  ///
  /// Un refus arrive en statut non 2xx : `functions.invoke` leve alors
  /// `FunctionsHttpException` avant toute lecture du corps
  /// (`functions_client-2.7.1/lib/src/functions_client.dart:265`), d'ou le
  /// `catch` ; une requete qui n'est pas partie leve `FunctionsFetchException`
  /// (`:207`).
  Future<Map<String, dynamic>> _appeler(Map<String, dynamic> requete) async {
    final FunctionResponse reponse;
    try {
      reponse = await _client.functions.invoke(fonction, body: requete);
    } on FunctionException catch (erreur) {
      throw AppairageRefuse(MotifRefusAppairage.depuis(erreur));
    }
    final Object? donnees = reponse.data;
    if (donnees is! Map<String, dynamic>) {
      throw const AppairageRefuse(MotifRefusAppairage.generique);
    }
    if (donnees['error'] != null) {
      throw AppairageRefuse(
        MotifRefusAppairage.depuisReponse(
          statut: reponse.status,
          details: donnees,
        ),
      );
    }
    return donnees;
  }

  /// Ouvre la session a partir du jeton a usage unique rendu par la fonction.
  ///
  /// La fonction Edge ne rend jamais de jeton d'acces tout fait : elle rend un
  /// jeton de courriel a usage unique, que le client echange lui-meme. Le jeton
  /// d'acces ne transite donc jamais dans un corps de reponse que l'on
  /// pourrait journaliser par accident.
  Future<void> _ouvrirDepuis(Map<String, dynamic> corps) async {
    await _client.auth.verifyOTP(
      type: OtpType.magiclink,
      tokenHash: corps['token_hash'] as String,
    );
  }
}

/// Le service employe par l'application.
final Provider<ServiceEnfant> serviceEnfantProvider = Provider<ServiceEnfant>(
  (Ref ref) => ServiceEnfantSupabase(Supabase.instance.client),
);

/// La plateforme declaree au serveur, parmi les quatre qu'il accepte
/// (`session-enfant/index.ts` : `windows`, `android`, `ios`, `web`).
///
/// macOS et Linux n'ont pas de valeur a eux : ils se declarent `windows`,
/// comme avant (C05 section 3.3, point 17).
String plateformeAppareil() {
  if (kIsWeb) {
    return 'web';
  }
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return 'android';
    case TargetPlatform.iOS:
      return 'ios';
    case TargetPlatform.fuchsia:
    case TargetPlatform.linux:
    case TargetPlatform.macOS:
    case TargetPlatform.windows:
      return 'windows';
  }
}

/// Connecte cet appareil a un profil eleve avec un code deja passe par
/// [FormatCodeAppairage.normaliser].
///
/// Dans cet ordre : le serveur consomme le code et rend le jeton d'appareil ;
/// le jeton est ecrit dans le coffre **avant toute autre chose** (il n'est
/// rendu qu'une fois) ; le profil est retenu localement pour le choix de
/// profil. Aucune session n'est ouverte ici.
///
/// Leve [AppairageRefuse]. Le code n'est ecrit nulle part.
Future<ProfilLocal> connecterCetAppareil({
  required ServiceEnfant service,
  required StockageSecurise coffre,
  required ProfilsLocaux profils,
  required String code,
}) async {
  final AppairageReussi resultat;
  try {
    resultat = await service.appairer(
      code: code,
      empreinteAppareil: await coffre.empreinteAppareil(),
      plateforme: plateformeAppareil(),
    );
  } on AppairageRefuse {
    rethrow;
  } on Object catch (erreur) {
    throw AppairageRefuse(MotifRefusAppairage.depuis(erreur));
  }
  await coffre.enregistrerJetonAppareil(
    resultat.profilId,
    resultat.jetonAppareil,
  );
  final ProfilLocal profil = ProfilLocal(
    id: resultat.profilId,
    prenom: resultat.prenom,
    identifiantImmuable: '',
  );
  // La memoire des profils est un confort (voir `EleveConnexionPage`) : son
  // echec ne defait pas un appairage dont le jeton est deja range. Le profil
  // est passe a l'ecran suivant, qui le montre meme sans base locale.
  try {
    await profils.enregistrer(profil);
  } on Object {
    // Rien de plus a faire ici.
  }
  return profil;
}
