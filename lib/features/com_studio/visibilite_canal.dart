// La visibilite d'un canal du Studio (`StudioChannelVisibility`, spec
// section 9.2 et section 20 ; R-COM-08 ; contrat COM-BR-08).
//
// Le frontend CONSOMME un statut donne par le serveur, il ne le calcule
// jamais : aucun role n'est lu ici. Quatre statuts :
//
// - visible : ouvert a toute l'equipe, rien n'est ajoute a l'ecran ;
// - restreint : ouvert a une partie de l'equipe, dit en toutes lettres ;
// - prive autorise : prive, et la personne en est membre, dit en toutes
//   lettres ;
// - absent : la personne n'y a pas acces. **Le canal n'est pas rendu** :
//   ni ligne, ni cadenas, ni compte, ni resultat de recherche (spec
//   section 9.2 : « Ne pas afficher une liste de canaux cadenas inutiles »).
//
// Le port de production ne rend deja que les canaux autorises ; l'ecran
// garde en plus une defense de surface ([canauxRendus]) : un statut
// « absent » qui arriverait quand meme n'est jamais montre.

import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/widgets/status_pill.dart';

/// Le statut de visibilite d'un canal, tel que le serveur le donne.
enum VisibiliteCanal {
  /// Ouvert a toute l'equipe interne.
  visible,

  /// Ouvert a une partie de l'equipe, et la personne en fait partie.
  restreint,

  /// Prive, et la personne en est membre.
  priveAutorise,

  /// La personne n'y a pas acces : le canal n'est pas rendu.
  absent;

  /// Vrai si un canal de ce statut peut s'afficher.
  bool get estRendu => this != VisibiliteCanal.absent;

  /// Vrai si le statut merite d'etre dit a l'ecran (restreint ou prive).
  bool get estDit =>
      this == VisibiliteCanal.restreint ||
      this == VisibiliteCanal.priveAutorise;
}

/// Les elements dont la visibilite est rendue, dans le meme ordre.
///
/// Defense de surface (R-COM-08) : le port ne doit rendre que des canaux
/// autorises, mais un statut « absent » n'est jamais affiche, quel que soit
/// le chemin par lequel il arrive.
List<T> canauxRendus<T>(
  Iterable<T> elements,
  VisibiliteCanal Function(T element) visibilite,
) => <T>[
  for (final T e in elements)
    if (visibilite(e).estRendu) e,
];

/// Le mot court d'un statut dit a l'ecran ; `null` pour un canal ouvert a
/// toute l'equipe (rien a dire) ou absent (rien a rendre).
String? libelleVisibilite(VisibiliteCanal visibilite) {
  final v = t.com.studio.visibilite;
  return switch (visibilite) {
    VisibiliteCanal.restreint => v.restreint,
    VisibiliteCanal.priveAutorise => v.prive,
    VisibiliteCanal.visible || VisibiliteCanal.absent => null,
  };
}

/// La phrase qui explique un statut, pour le panneau du canal ; `null` pour
/// un canal absent.
String? phraseVisibilite(VisibiliteCanal visibilite) {
  final v = t.com.studio.visibilite;
  return switch (visibilite) {
    VisibiliteCanal.visible => v.visibleDetail,
    VisibiliteCanal.restreint => v.restreintDetail,
    VisibiliteCanal.priveAutorise => v.priveDetail,
    VisibiliteCanal.absent => null,
  };
}

/// La marque d'un canal restreint ou prive (`StudioChannelVisibility`) : une
/// pastille qui dit le mot (« Restreint », « Prive »), jamais un cadenas ni
/// une couleur seule. Rien n'est rendu pour un canal ouvert a toute
/// l'equipe, ni pour un canal absent.
class MarqueVisibiliteCanal extends StatelessWidget {
  /// Cree la marque du statut [visibilite].
  const MarqueVisibiliteCanal({required this.visibilite, super.key});

  /// Le statut donne par le serveur.
  final VisibiliteCanal visibilite;

  /// La cle de la marque, pour les tests.
  static const ValueKey<String> cle = ValueKey<String>('studio-visibilite');

  @override
  Widget build(BuildContext context) {
    final String? libelle = libelleVisibilite(visibilite);
    if (libelle == null) return const SizedBox.shrink();
    return Semantics(
      container: true,
      label: phraseVisibilite(visibilite),
      excludeSemantics: true,
      child: StatusPill(key: cle, libelle: libelle, ton: TonEtat.neutre),
    );
  }
}
