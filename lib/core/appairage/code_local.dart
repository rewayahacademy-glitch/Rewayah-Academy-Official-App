import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Le code personnel de l'eleve, et ce qu'on en garde.
///
/// **Le code ne quitte jamais l'appareil** (ADR-005). Il n'existe aucune colonne
/// en base pour le recevoir, aucune fonction pour l'envoyer, et
/// `test/appairage/code_local_test.dart` relit la source des ecrans pour le
/// verifier.
///
/// Ce qui est conserve dans le coffre du systeme est une empreinte salee, pas le
/// code. Il faut nommer precisement ce que cela protege, sinon la mesure passe
/// pour plus forte qu'elle n'est :
///
/// - **Ce que cela protege** : qu'un frere ou une soeur ouvre le profil d'un
///   autre enfant sur la tablette du salon. C'est le risque reel du produit.
/// - **Ce que cela ne protege pas** : quelqu'un qui obtient le contenu du coffre
///   du systeme essaiera les dix mille combinaisons en un instant, quelle que
///   soit la fonction d'empreinte. Un code a quatre chiffres n'a pas d'entropie
///   a defendre.
///
/// La vraie barriere n'est donc pas ici : c'est le jeton d'appareil, emis par le
/// serveur, revocable par le tuteur, et la RLS derriere lui.
abstract final class CodeLocal {
  /// Longueur du code de l'eleve.
  static const int longueur = 4;

  /// Scelle un code : un sel tire au hasard, puis son empreinte.
  ///
  /// Le sel evite qu'un meme code donne la meme empreinte pour deux enfants du
  /// meme appareil, ce qui laisserait deviner qu'ils ont choisi le meme.
  static String sceller(String code) {
    final String sel = _aleatoireBase64(16);
    return '$sel:${_empreinte(code, sel)}';
  }

  /// Verifie une saisie contre une empreinte scellee.
  static bool correspond(String saisie, String? scelle) {
    if (scelle == null) {
      return false;
    }
    final int separateur = scelle.indexOf(':');
    if (separateur <= 0) {
      return false;
    }
    final String sel = scelle.substring(0, separateur);
    final String attendue = scelle.substring(separateur + 1);
    return _comparaisonConstante(_empreinte(saisie, sel), attendue);
  }

  /// Vrai quand la saisie a la forme d'un code.
  static bool formeValide(String code) =>
      code.length == longueur && int.tryParse(code) != null;

  static String _empreinte(String code, String sel) =>
      base64Url.encode(sha256.convert(utf8.encode('$sel|$code')).bytes);

  /// Comparaison a duree constante.
  ///
  /// Le gain est theorique sur un appareil local, mais une comparaison de
  /// chaines qui s'arrete au premier caractere different est le genre de detail
  /// qu'on recopie ensuite dans un contexte ou il compte.
  static bool _comparaisonConstante(String a, String b) {
    if (a.length != b.length) {
      return false;
    }
    int difference = 0;
    for (int i = 0; i < a.length; i++) {
      difference |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return difference == 0;
  }
}

/// Une valeur aleatoire, pour un jeton local ou une empreinte d'appareil.
String jetonAleatoire() => _aleatoireBase64(32);

String _aleatoireBase64(int octets) {
  final Random source = Random.secure();
  final Uint8List valeurs = Uint8List(octets);
  for (int i = 0; i < octets; i++) {
    valeurs[i] = source.nextInt(256);
  }
  return base64Url.encode(valeurs);
}
