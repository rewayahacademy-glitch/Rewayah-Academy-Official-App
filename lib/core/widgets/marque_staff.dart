// #Ra_staff (decision du directeur, 14/11/2026) : partout ou l'administration
// ou la direction apparait dans une interaction avec quelqu'un (messages,
// fils, en-tetes de conversation, echanges), l'expediteur s'affiche avec
// l'icone de l'application comme avatar et le nom exact « #Ra_staff »,
// identique dans toutes les langues, jamais le nom de la personne de l'equipe
// qui a ecrit, jamais « Administration » ni « Direction ».
//
// **Seul point d'entree** de cette identite : un ecran ne recompose ni le
// logo ni le nom. Le logo passe par `BrandLogo` (symbole, la variante
// « avatar » du README du logo), le couple avatar + nom par `AvatarNom`.

import 'package:flutter/material.dart';

import '../i18n/strings.g.dart';
import 'avatar_nom.dart';
import 'brand_logo.dart';

/// L'identite de l'equipe : l'icone de l'application et « #Ra_staff ».
class MarqueStaff extends StatelessWidget {
  /// L'identite complete, en ligne : l'icone au bord de debut, le nom
  /// centre verticalement sur elle ([AvatarNom.enLigne]).
  const MarqueStaff({
    super.key,
    this.diametre = AppAvatar.moyen,
    this.role,
    this.styleNom,
  }) : _avatarSeul = false;

  /// L'icone seule, a la place d'un avatar de personne (liste, en-tete) :
  /// le nom est ecrit a cote par l'appelant, avec [designation].
  const MarqueStaff.avatar({super.key, this.diametre = AppAvatar.moyen})
    : _avatarSeul = true,
      role = null,
      styleNom = null;

  /// Le diametre du cercle de l'avatar (jetons `AppAvatar`).
  final double diametre;

  /// La ligne sous le nom (au plus une), ou rien.
  final String? role;

  /// Le style du nom, ou celui d'`AvatarNom`.
  final TextStyle? styleNom;

  final bool _avatarSeul;

  /// Le nom de l'equipe, identique dans toutes les langues. Isole de gauche
  /// a droite (U+2066 ... U+2069) : en arabe, sans isolement, le « # » passait
  /// a la fin (« Ra_staff# »).
  static String get designation => '\u2066${t.commun.staff.designation}\u2069';

  @override
  Widget build(BuildContext context) {
    // Le symbole du logo occupe le cercle, zone de protection comprise ; il
    // est decoratif : le nom est toujours ecrit a cote (README du logo).
    final Widget icone = SizedBox.square(
      dimension: diametre,
      child: Center(
        child: BrandLogo(variante: VarianteLogo.symbole, hauteur: diametre),
      ),
    );
    if (_avatarSeul) return ExcludeSemantics(child: icone);
    return AvatarNom.enLigne(
      prenom: designation,
      role: role,
      diametre: diametre,
      avatar: icone,
      styleNom: styleNom,
    );
  }
}
