import 'package:flutter/material.dart';

import '../../core/appairage/service_appairage.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/lien_fleche.dart';

/// Vrai quand les donnees **confirment** qu'aucun appareil n'est pret pour
/// [eleveId] : la liste des appareils du foyer est lue, et aucun appareil
/// actif (non revoque) n'y est appaire a cet eleve.
///
/// Pure. Une liste illisible ou en cours de lecture ne confirme rien : le
/// blocage n'est alors pas affiche (mandat, Accueil : « seulement si confirme
/// par les donnees »).
bool aucunAppareilPret(List<AppareilAppaire> appareils, String eleveId) =>
    !appareils.any((AppareilAppaire a) => a.actif && a.profilId == eleveId);

/// Le blocage prioritaire de l'Accueil : **un seul**, avec **une seule**
/// action contextualisee (defaut C3 des maquettes, qui en montraient deux).
///
/// Aujourd'hui le seul blocage confirme par les donnees est « aucun appareil
/// pret » ; « photo requise » n'a aucune regle en base (point P6) et le
/// dossier a completer relève du portail d'attente.
///
/// - Telephone ([compact]) : bandeau pleine largeur en registre doux
///   d'avertissement, icone, titre, phrase concrete, action sous le texte
///   (V1 coupait le bouton sur deux lignes).
/// - Tablette et bureau : tete de la colonne de droite, icone d'appareil,
///   titre, phrase et lien fleche (V2).
class BandeauBlocage extends StatelessWidget {
  /// Cree le bandeau.
  const BandeauBlocage({
    required this.prenom,
    required this.compact,
    required this.onConnecter,
    super.key,
  });

  /// Le prenom de l'eleve concerne.
  final String prenom;

  /// Vrai sur telephone.
  final bool compact;

  /// Ouvre l'emetteur de code d'appairage de cet eleve.
  final VoidCallback onConnecter;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    final Widget textesBlocage = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            t.tuteur.accueil.blocageAppareilTitre(prenom: prenom),
            style: palette.inkStrong.applyTo(
              textes.titleSmall ?? const TextStyle(),
            ),
          ),
        ),
        Ecart.vXs,
        Text(
          t.tuteur.accueil.blocageAppareilPhrase(prenom: prenom),
          style: palette.inkMuted.applyTo(
            textes.bodyMedium ?? const TextStyle(),
          ),
        ),
        Ecart.vMd,
        if (compact)
          ActionPrincipale(
            libelle: t.tuteur.accueil.connecterAppareil,
            onPress: onConnecter,
            niveau: NiveauAction.secondaire,
            pleineLargeur: false,
          )
        else
          LienFleche(
            libelle: t.tuteur.accueil.connecterAppareil,
            onPress: onConnecter,
          ),
      ],
    );

    final Widget contenu = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ExcludeSemantics(
          child: IconTheme(
            data: palette.inkWarning.asIconTheme(
              size: compact ? AppSpacing.xxl : AppSpacing.section,
            ),
            child: Icon(
              compact
                  ? AppIcons.avertissement.repos
                  : AppIcons.tabletteOuOrdinateur.repos,
            ),
          ),
        ),
        Ecart.hLg,
        Expanded(child: textesBlocage),
      ],
    );

    if (!compact) {
      return contenu;
    }
    return AppCard(
      surface: palette.washWarning,
      marge: AppSpacing.lg,
      child: contenu,
    );
  }
}
