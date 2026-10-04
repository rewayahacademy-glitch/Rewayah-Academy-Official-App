import 'package:flutter/material.dart';

import '../i18n/strings.g.dart';
import '../theme/accent_profil.dart';
import '../theme/app_palette.dart';
import 'avatar_nom.dart';

/// Le bandeau de couleur d'un profil, derriere son avatar
/// (`ProfileIdentityAvatar`, guide Finance V4 §3 ; decision du directeur du
/// 04/10/2026, K-62 ; maquette 11 « Foyer »).
///
/// Ce que la maquette montre, fixe ici une fois pour toutes :
///
/// - un **rectangle vertical** de la couleur [accent], centre sur le cercle,
///   un peu moins large que lui ([largeurRelative]) ;
/// - dans une carte, il part **du bord haut de la carte, colle a lui**
///   ([remontee] = la marge interne de la carte, revue du directeur du
///   04/10) et descend jusqu'a la moitie du cercle ([recouvrementRelatif]),
///   le reste passant **derriere** le cercle ;
/// - hors carte (galerie), il depasse au-dessus du cercle
///   ([depassementRelatif]) ;
/// - le cercle reste un cercle entier, jamais masque ni deforme ; le bandeau
///   ne sort jamais de la carte.
///
/// Sans [accent] (aucun choix, lecture en cours ou indisponible), le cercle
/// est rendu seul, sans place reservee : jamais une couleur au hasard.
///
/// La couleur n'est **ni un statut, ni une classe, ni une alerte** (guide
/// §3.2) : elle est decorative et toujours posee a cote du prenom, donc
/// exclue de la semantique.
class BandeauProfil extends StatelessWidget {
  /// Habille [avatar], un cercle de [diametre], du bandeau [accent].
  const BandeauProfil({
    required this.avatar,
    required this.diametre,
    required this.accent,
    super.key,
    this.remontee = 0,
  });

  /// La part de la largeur du cercle prise par le bandeau.
  static const double largeurRelative = 0.84;

  /// La part du diametre dont le bandeau depasse au-dessus du cercle.
  static const double depassementRelatif = 0.35;

  /// La part du diametre que le bandeau couvre derriere le cercle : jusqu'a
  /// son milieu, comme sur la maquette 11.
  static const double recouvrementRelatif = 0.5;

  /// La cle du rectangle de couleur, pour les tests.
  static const Key bandeauKey = Key('identiteProfil.bandeau');

  /// Le cercle a habiller.
  final Widget avatar;

  /// Son diametre.
  final double diametre;

  /// L'accent choisi par le tuteur, `null` sans bandeau.
  final AccentProfil? accent;

  /// Dans une carte : la marge interne de la carte au-dessus du cercle. Le
  /// bandeau remonte de cette hauteur pour toucher le bord haut de la carte,
  /// et le cercle reste a sa place (aucun depassement au-dessus de lui).
  /// Zero hors carte.
  final double remontee;

  /// L'enveloppe a passer a `AvatarNom.enveloppeAvatar`.
  static Widget Function(Widget avatar) enveloppe({
    required double diametre,
    required AccentProfil? accent,
    double remontee = 0,
  }) =>
      (Widget avatar) => BandeauProfil(
        avatar: avatar,
        diametre: diametre,
        accent: accent,
        remontee: remontee,
      );

  @override
  Widget build(BuildContext context) {
    final AccentProfil? a = accent;
    if (a == null) return avatar;
    // Dans une carte, le cercle reste en haut du contenu et le bandeau
    // remonte jusqu'au bord ; hors carte, le bandeau depasse au-dessus.
    final double haut = remontee > 0 ? 0 : diametre * depassementRelatif;
    return SizedBox(
      width: diametre,
      height: diametre + haut,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          PositionedDirectional(
            top: -remontee,
            start: diametre * (1 - largeurRelative) / 2,
            width: diametre * largeurRelative,
            height: remontee + haut + diametre * recouvrementRelatif,
            child: ExcludeSemantics(
              child: DecoratedBox(
                key: bandeauKey,
                decoration: AppPalette.of(context).accentProfil(a).decoration(),
              ),
            ),
          ),
          PositionedDirectional(
            top: haut,
            start: 0,
            width: diametre,
            height: diametre,
            child: avatar,
          ),
        ],
      ),
    );
  }
}

/// La taille d'une identite de profil (guide §3.3).
enum TailleIdentite {
  /// Carte de liste ou de bureau.
  carte,

  /// Ligne mobile.
  ligne,

  /// Grand en-tete de profil.
  entete;

  /// Le diametre du cercle, pris dans les jetons [AppAvatar].
  double get diametre => switch (this) {
    TailleIdentite.ligne => AppAvatar.moyen,
    TailleIdentite.carte => AppAvatar.grand,
    TailleIdentite.entete => AppAvatar.grand,
  };
}

/// L'identite d'un profil eleve (`ProfileIdentityRow`, guide §3.2) : le
/// cercle et son bandeau, le prenom, puis une ligne « age · classe » dans cet
/// ordre constant ; l'age seulement s'il est rendu (revue FI-1a E-13).
///
/// Construit sur [AvatarNom] (seul couple avatar + nom de l'application),
/// jamais recompose. Le lecteur d'ecran lit une phrase entiere : « Mariam,
/// profil enfant, Classe An-Nour ».
class IdentiteProfil extends StatelessWidget {
  /// Cree l'identite.
  const IdentiteProfil({
    required this.prenom,
    required this.accent,
    super.key,
    this.estAdulte = false,
    this.age,
    this.classe,
    this.avatar,
    this.taille = TailleIdentite.ligne,
    this.remontee = 0,
  });

  /// Le prenom.
  final String prenom;

  /// L'accent choisi par le tuteur, `null` sans bandeau.
  final AccentProfil? accent;

  /// Vrai pour un profil adulte.
  final bool estAdulte;

  /// L'age, seulement s'il est rendu.
  final int? age;

  /// Le nom propre de la classe (« An-Nour »), seulement s'il est connu.
  final String? classe;

  /// Le portrait (`PhotoEleve`) ; les initiales a defaut.
  final Widget? avatar;

  /// La taille.
  final TailleIdentite taille;

  /// La marge interne de la carte qui porte l'identite : le bandeau remonte
  /// jusqu'au bord haut de la carte ([BandeauProfil.remontee]).
  final double remontee;

  /// La phrase lue par le lecteur d'ecran.
  String get libelleLu {
    final String profil = estAdulte
        ? t.identiteProfil.lecteurAdulte(prenom: prenom)
        : t.identiteProfil.lecteurEnfant(prenom: prenom);
    final String? c = classe;
    return c == null
        ? profil
        : t.identiteProfil.lecteurAvecClasse(
            profil: profil,
            classe: t.identiteProfil.classe(classe: c),
          );
  }

  /// La ligne sous le prenom, `null` sans age ni classe.
  String? get ligneDetail {
    final int? a = age;
    final String? c = classe;
    final String? texteAge = a == null ? null : t.identiteProfil.age(n: a);
    final String? texteClasse = c == null
        ? null
        : t.identiteProfil.classe(classe: c);
    if (texteAge != null && texteClasse != null) {
      return t.identiteProfil.ageEtClasse(age: texteAge, classe: texteClasse);
    }
    return texteAge ?? texteClasse;
  }

  @override
  Widget build(BuildContext context) {
    final double d = taille.diametre;
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    return Semantics(
      label: libelleLu,
      container: true,
      child: ExcludeSemantics(
        child: AvatarNom.enLigne(
          prenom: prenom,
          diametre: d,
          avatar: avatar,
          enveloppeAvatar: BandeauProfil.enveloppe(
            diametre: d,
            accent: accent,
            remontee: remontee,
          ),
          cercleEnHaut: remontee > 0,
          // FI-COUPE-2 : le prenom n'est jamais coupe au milieu d'un mot
          // (« Abdourahmane » sur la page Couleur, 320 px, 200 %).
          nomSansCoupure: true,
          role: ligneDetail,
          styleNom: taille == TailleIdentite.ligne
              ? null
              : palette.inkStrong.applyTo(
                  textes.titleMedium ?? const TextStyle(),
                ),
        ),
      ),
    );
  }
}
