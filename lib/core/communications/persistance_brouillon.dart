// La persistance du brouillon d'un champ de saisie (`DraftPersistence`, spec
// section 8.2 ; COM-BR-12).
//
// COM-RC tour 2 (revue COM-R, R-22) : une seule persistance pour tous les
// champs de message. `FilDiscussion` (Messages, canaux du Studio) et le
// composer de reponse de la Communaute la lisent toutes deux, au lieu d'en
// porter chacun une copie : le texte est garde a chaque changement reel, il
// est remis dans un champ encore vide a la reouverture, et un champ vide
// efface le brouillon.
//
// COM-RC tour 5 (contre-verification du lot H) : les textes envoyes en
// attente d'accuse sont tenus par port et par [CleBrouillon]
// ([marquerEnAttente]). Un fil rouvert avant l'accuse ne remet pas un
// brouillon dont le texte attend encore : sinon le champ le montrerait,
// pret a partir en double. L'accuse est annonce aux fils montes
// ([ecouterIssues]) : un fil qui montre encore ce texte remis, sans
// modification, vide son champ.

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

  /// Les textes en attente d'accuse, par port puis par cle.
  static final Expando<_EnAttente> _attentes = Expando<_EnAttente>(
    'PersistanceBrouillon.enAttente',
  );

  _EnAttente? get _attente {
    final PortBrouillons? p = port;
    if (p == null) return null;
    return _attentes[p] ??= _EnAttente();
  }

  /// Note que [texte] (le texte brut du champ a l'envoi) est parti pour
  /// [cle] et attend son accuse.
  void marquerEnAttente(CleBrouillon cle, String texte) {
    final _EnAttente? a = _attente;
    if (a == null) return;
    (a.textes[cle] ??= <String>[]).add(texte);
  }

  /// Vrai si [texte] attend encore son accuse pour [cle].
  bool enAttente(CleBrouillon cle, String texte) =>
      _attente?.textes[cle]?.contains(texte) ?? false;

  /// L'envoi de [texte] pour [cle] est termine : [accuse] vrai s'il est
  /// confirme, faux s'il a echoue. Le texte n'attend plus, et les fils qui
  /// ecoutent ([ecouterIssues]) l'apprennent, meme si celui qui a envoye
  /// est ferme.
  void terminerEnvoi(CleBrouillon cle, String texte, {required bool accuse}) {
    final _EnAttente? a = _attente;
    if (a == null) return;
    final List<String>? liste = a.textes[cle];
    if (liste != null) {
      liste.remove(texte);
      if (liste.isEmpty) a.textes.remove(cle);
    }
    for (final void Function(CleBrouillon, String, bool) f
        in List<void Function(CleBrouillon, String, bool)>.of(a.ecoutes)) {
      f(cle, texte, accuse);
    }
  }

  /// Ecoute la fin des envois (accuse ou echec) sur ce port ; rend la
  /// fonction qui arrete l'ecoute.
  VoidCallback ecouterIssues(
    void Function(CleBrouillon cle, String texte, bool accuse) ecoute,
  ) {
    final _EnAttente? a = _attente;
    if (a == null) return () {};
    a.ecoutes.add(ecoute);
    return () => a.ecoutes.remove(ecoute);
  }

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
        champ.text.isNotEmpty ||
        // Un texte deja parti, qui attend son accuse, ne revient pas dans
        // le champ : il partirait en double.
        enAttente(cle, garde.texte)) {
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

  /// Efface le brouillon de [cle] seulement s'il garde encore exactement
  /// [texte] (accuse d'un envoi). COM-RC tour 6 (COM-R-4, 8.3-1) : un
  /// accuse recu par un fil ferme n'efface pas un autre texte saisi depuis
  /// dans le fil rouvert.
  Future<void> effacerSi(CleBrouillon cle, String texte) async {
    final PortBrouillons? p = port;
    if (p == null) return;
    try {
      final Brouillon? garde = await p.lire(cle);
      if (garde == null || garde.texte != texte) return;
      await p.effacer(cle);
    } on Object {
      // Rien a effacer, ou memoire indisponible : sans consequence.
    }
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

/// Les textes en attente d'accuse d'un port, et qui ecoute leur issue.
class _EnAttente {
  final Map<CleBrouillon, List<String>> textes = <CleBrouillon, List<String>>{};
  final List<void Function(CleBrouillon, String, bool)> ecoutes =
      <void Function(CleBrouillon, String, bool)>[];
}
