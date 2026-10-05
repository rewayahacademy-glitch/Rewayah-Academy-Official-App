// La persistance du brouillon d'un champ de saisie (`DraftPersistence`, spec
// section 8.2 ; COM-BR-12).
//
// COM-RC tour 2 (revue COM-R, R-22) : une seule persistance pour tous les
// champs de message. `FilDiscussion` (Messages, canaux du Studio) et le
// composer de reponse de la Communaute la lisent toutes deux, au lieu d'en
// porter chacun une copie : le texte est garde a chaque changement reel, il
// est remis dans un champ encore vide a la reouverture, et un champ vide
// efface le brouillon.

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'port_brouillons.dart';

/// Le brouillon d'un champ, garde dans [PortBrouillons].
///
/// L'ecran (ou le composant) ecoute son controleur et appelle [noter] a
/// chaque changement ; [restaurer] remet le brouillon a l'ouverture.
class PersistanceBrouillon {
  /// Cree la persistance sur [port] ; `null` : rien n'est garde ni remis.
  PersistanceBrouillon(this.port);

  /// Le port lu depuis la portee Riverpod de [context], ou `null` quand il
  /// n'y en a pas (composant monte hors session, galerie) : le champ
  /// fonctionne, rien n'est garde.
  factory PersistanceBrouillon.depuis(BuildContext context) {
    try {
      return PersistanceBrouillon(
        ProviderScope.containerOf(
          context,
          listen: false,
        ).read(portBrouillonsProvider),
      );
    } on Object {
      return PersistanceBrouillon(null);
    }
  }

  /// Le port des brouillons, ou `null`.
  final PortBrouillons? port;

  /// Le dernier texte garde (ou connu), pour n'ecrire qu'un vrai changement.
  String _dernier = '';

  /// Dit a la persistance que [texte] est deja dans le champ et garde (ou
  /// volontairement non garde) : le prochain [noter] du meme texte n'ecrit
  /// rien. Un composer qui vide son champ a l'envoi, sans effacer encore le
  /// brouillon (accuse attendu), appelle `caler('')` avant de vider.
  void caler(String texte) => _dernier = texte;

  /// Garde [texte] pour [cle] s'il a change ; un texte vide efface le
  /// brouillon. Rend vrai quand une ecriture a ete demandee.
  bool noter(CleBrouillon cle, String texte) {
    final PortBrouillons? p = port;
    if (p == null || texte == _dernier) return false;
    _dernier = texte;
    unawaited(
      p.enregistrer(cle, texte).catchError((Object _) {
        // Le brouillon n'est pas garde ; le texte reste dans le champ.
      }),
    );
    return true;
  }

  /// Remet le brouillon de [cle] dans [champ] s'il est encore vide. Rend
  /// vrai quand un texte a ete remis (l'appelant dit « Brouillon restaure »).
  Future<bool> restaurer(
    CleBrouillon cle,
    TextEditingController champ, {
    bool Function()? encoreMonte,
  }) async {
    Brouillon? garde;
    try {
      garde = await port?.lire(cle);
    } on Object {
      garde = null;
    }
    if ((encoreMonte != null && !encoreMonte()) ||
        garde == null ||
        champ.text.isNotEmpty) {
      return false;
    }
    final String texte = garde.texte;
    // Le texte remis est deja garde : l'ecoute ne le reecrit pas.
    _dernier = texte;
    champ.value = TextEditingValue(
      text: texte,
      selection: TextSelection.collapsed(offset: texte.length),
    );
    return true;
  }

  /// Efface le brouillon de [cle] (envoi confirme).
  Future<void> effacer(CleBrouillon cle) async {
    try {
      await port?.effacer(cle);
    } on Object {
      // Rien a effacer, ou memoire indisponible : sans consequence.
    }
  }
}
