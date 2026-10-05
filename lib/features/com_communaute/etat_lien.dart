// Les quatre etats d'un lien externe dans la Communaute enseignants (spec
// section 5.4 ; contrat serveur COM-BR-07).
//
// Le frontend sait REPRESENTER quatre etats ; il n'en DEDUIT aucun. L'etat
// d'un lien vient toujours du port (`PortGardePromotion`), jamais d'une
// lecture de l'adresse cote client : aucun moteur artisanal de detection
// (spec section 20). Il n'existe pas d'etat « Verifie » : tant qu'aucun
// contrat serveur n'existe, rien ne l'affiche (spec section 5.4), et le
// meilleur etat d'un lien externe reste « Ressource pedagogique externe ».
//
// La pastille porte un mot, jamais la couleur seule (`StatusPill`).

import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/status_pill.dart';

/// L'etat d'un lien, tel que le serveur le donne (spec section 5.4).
enum EtatLien {
  /// Un lien interne Rewayah.
  interne,

  /// Une ressource pedagogique externe.
  ressourceExterne,

  /// Un lien commercial interdit (affilie, boutique, parrainage).
  commercialInterdit,

  /// Un lien que le serveur n'a pas qualifie : l'etat par defaut.
  nonVerifie;

  /// Le libelle de l'etat (`com.communaute.lien.*`).
  String get libelle => switch (this) {
    EtatLien.interne => t.com.communaute.lien.interne,
    EtatLien.ressourceExterne => t.com.communaute.lien.ressourceExterne,
    EtatLien.commercialInterdit => t.com.communaute.lien.commercialInterdit,
    EtatLien.nonVerifie => t.com.communaute.lien.nonVerifie,
  };

  /// Le ton de la pastille. Aucun etat n'a le ton « succes » : un lien n'est
  /// jamais presente comme garanti par le client.
  TonEtat get ton => switch (this) {
    EtatLien.interne => TonEtat.accent,
    EtatLien.ressourceExterne => TonEtat.neutre,
    EtatLien.commercialInterdit => TonEtat.alerte,
    EtatLien.nonVerifie => TonEtat.avertissement,
  };
}

/// Un lien d'une publication et son etat, rendus par le serveur.
@immutable
class LienAnalyse {
  /// Cree le lien.
  const LienAnalyse({required this.adresse, required this.etat});

  /// L'adresse telle que la personne l'a ecrite (jamais une adresse de
  /// stockage : la Communaute n'en montre aucune, spec section 12).
  final String adresse;

  /// L'etat donne par le serveur.
  final EtatLien etat;

  @override
  bool operator ==(Object other) =>
      other is LienAnalyse && other.adresse == adresse && other.etat == etat;

  @override
  int get hashCode => Object.hash(adresse, etat);

  @override
  String toString() => 'LienAnalyse($adresse, ${etat.name})';
}

/// Une ligne : l'adresse, puis la pastille de son etat. L'adresse n'est pas
/// cliquable : la Communaute n'ouvre pas un lien que le serveur n'a pas
/// qualifie.
class LigneEtatLien extends StatelessWidget {
  /// Cree la ligne.
  const LigneEtatLien({required this.lien, super.key});

  /// Le lien.
  final LienAnalyse lien;

  /// La cle de la ligne d'une adresse, pour les tests.
  static ValueKey<String> cle(String adresse) =>
      ValueKey<String>('communaute-lien-$adresse');

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return Semantics(
      key: cle(lien.adresse),
      container: true,
      label: t.com.communaute.lien.semantique(
        adresse: lien.adresse,
        etat: lien.etat.libelle,
      ),
      child: ExcludeSemantics(
        // L'adresse puis l'etat, l'un sous l'autre : une adresse longue ne
        // pousse jamais la pastille hors de la colonne, a 390 comme a texte
        // agrandi.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              lien.adresse,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              // Une adresse se lit de gauche a droite, meme en arabe.
              textDirection: TextDirection.ltr,
              style: palette.inkStrong.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
            Ecart.vXs,
            StatusPill(libelle: lien.etat.libelle, ton: lien.etat.ton),
          ],
        ),
      ),
    );
  }
}
