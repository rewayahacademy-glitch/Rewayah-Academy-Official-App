import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../accessibilite/texte_sans_coupure.dart';
import '../i18n/strings.g.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'avatar_tile.dart';
import 'lien_fleche.dart';
import 'pressable.dart';

/// Ce que l'en-tete du Compte montre de la personne connectee. Des textes
/// deja prets : le role et le statut sont traduits par l'ecran du role, le
/// matricule est la valeur servie (`RA-26-4817`).
@immutable
class IdentiteCompte {
  /// Cree une identite.
  const IdentiteCompte({
    required this.nom,
    this.role,
    this.matricule,
    this.statut,
    this.urlPhoto,
  });

  /// Le nom affiche : « Maryam Benali ».
  final String nom;

  /// Le role en toutes lettres : « Élève ». Nul quand il tient deja lieu de
  /// nom (prenom pas encore lu) : il n'est pas dit deux fois.
  final String? role;

  /// Le matricule, sans le role. Nul : pas de ligne, pas de bouton grise.
  final String? matricule;

  /// Le statut du compte, en une phrase courte. Nul : pas de ligne.
  final String? statut;

  /// L'URL signee de la photo. Nulle : l'initiale du nom.
  final String? urlPhoto;
}

/// L'en-tete commun du Compte (PROFILS P1, pilote du 11/11/2026) : la photo,
/// qu'on touche pour la changer (plus de lien separe), puis le nom, le role,
/// le matricule avec son bouton « Copier », et le statut.
///
/// Parametres purs : aucun port lu ici. L'ecran du role fournit
/// [identite] et le geste [onChangerPhoto] ; sans ce geste, la photo n'est
/// pas un bouton.
class EnteteCompte extends StatefulWidget {
  /// Cree l'en-tete.
  const EnteteCompte({
    required this.identite,
    super.key,
    this.onChangerPhoto,
    this.photo,
    this.pied,
  });

  /// La photo, quand l'ecran la lit lui-meme (photo signee). Nulle : la
  /// photo de [IdentiteCompte.urlPhoto], sinon l'initiale du nom.
  final Widget? photo;

  /// Ce qui se pose sous l'identite : le retour de l'envoi d'une photo.
  final Widget? pied;

  /// La personne connectee.
  final IdentiteCompte identite;

  /// Ouvre le changement de photo. Nul : photo seulement visible.
  final VoidCallback? onChangerPhoto;

  /// La photo pressable.
  static const Key photoKey = Key('enteteCompte.photo');

  /// Le geste de copie du matricule.
  static const Key copierKey = Key('enteteCompte.copier');

  /// La valeur du matricule, isolee de gauche a droite.
  static const Key matriculeKey = Key('enteteCompte.matricule');

  @override
  State<EnteteCompte> createState() => _EnteteCompteState();
}

class _EnteteCompteState extends State<EnteteCompte> {
  /// Marque posee a la place de la valeur dans la phrase traduite, pour y
  /// loger la valeur isolee (comme `LigneMatricule`).
  static const String _marque = '\u0000';

  bool _copie = false;

  @override
  void didUpdateWidget(EnteteCompte ancien) {
    super.didUpdateWidget(ancien);
    if (ancien.identite.matricule != widget.identite.matricule) {
      _copie = false;
    }
  }

  Future<void> _copier(String valeur) async {
    await Clipboard.setData(ClipboardData(text: valeur));
    if (!mounted) return;
    setState(() => _copie = true);
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final IdentiteCompte identite = widget.identite;
    final TextStyle secondaire = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );

    final Widget avatar =
        widget.photo ??
        AvatarTile(
          prenom: identite.nom,
          urlSignee: identite.urlPhoto,
          diametre: AppAvatar.grand,
        );
    final VoidCallback? changer = widget.onChangerPhoto;

    final Widget rangee = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (changer == null)
          ExcludeSemantics(child: avatar)
        else
          Pressable(
            key: EnteteCompte.photoKey,
            onPress: changer,
            libelleSemantique: t.compte.page.changerPhoto,
            arrondiFocus: AppRadius.arrondiFull,
            // Les initiales de l'avatar ne sont pas lues : le bouton se dit
            // par son seul geste, « Changer la photo ».
            child: Tooltip(
              message: t.compte.page.changerPhoto,
              excludeFromSemantics: true,
              child: ExcludeSemantics(child: avatar),
            ),
          ),
        Ecart.hMd,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Semantics(
                header: true,
                child: TexteSansCoupure(
                  identite.nom,
                  style: palette.inkStrong.applyTo(
                    textes.titleLarge ?? const TextStyle(),
                  ),
                ),
              ),
              Ecart.vXs,
              if (identite.role case final String role)
                TexteSansCoupure(role, style: secondaire),
              if (identite.matricule case final String valeur)
                _ligneMatricule(palette, textes, secondaire, valeur),
              if (identite.statut case final String statut) ...<Widget>[
                Ecart.vXs,
                TexteSansCoupure(statut, style: secondaire),
              ],
            ],
          ),
        ),
      ],
    );
    final Widget? pied = widget.pied;
    if (pied == null) return rangee;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[rangee, Ecart.vMd, pied],
    );
  }

  Widget _ligneMatricule(
    AppPalette palette,
    TextTheme textes,
    TextStyle secondaire,
    String valeur,
  ) {
    final String phrase = t.compte.page.matricule(valeur: _marque);
    final int coupe = phrase.indexOf(_marque);
    final String avant = coupe < 0 ? phrase : phrase.substring(0, coupe);
    final String apres = coupe < 0
        ? ''
        : phrase.substring(coupe + _marque.length);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.md,
        children: <Widget>[
          Semantics(
            label: phrase.replaceAll(_marque, valeur),
            excludeSemantics: true,
            child: Text.rich(
              TextSpan(
                style: secondaire,
                children: <InlineSpan>[
                  TextSpan(text: avant),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      // Flutter met deja a l'echelle l'enfant d'un WidgetSpan
                      // avec le texte qui l'entoure : la valeur ne s'y remet
                      // pas une seconde fois (sinon x4 a x2, coupee dans le
                      // mot).
                      child: Text(
                        valeur,
                        key: EnteteCompte.matriculeKey,
                        textScaler: TextScaler.noScaling,
                        style: palette.inkStrong.applyTo(
                          textes.bodyMedium ?? const TextStyle(),
                        ),
                      ),
                    ),
                  ),
                  TextSpan(text: apres),
                ],
              ),
            ),
          ),
          LienFleche(
            key: EnteteCompte.copierKey,
            libelle: _copie ? t.compte.matriculeCopie : t.compte.copier,
            libelleSemantique: _copie
                ? t.compte.matriculeCopie
                : t.compte.copierMatricule,
            fleche: false,
            onPress: () => _copier(valeur),
          ),
        ],
      ),
    );
  }
}
