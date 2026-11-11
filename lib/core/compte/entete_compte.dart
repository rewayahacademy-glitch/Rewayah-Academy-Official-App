// PROFILS P1 (directeur, 11/11/2026) : l'en-tete commun du Compte. On touche
// la photo pour la changer (plus de lien separe) ; on y lit le nom, le role,
// le matricule (avec « Copier ») et le statut.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../i18n/strings.g.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import '../widgets/lien_fleche.dart';
import '../widgets/pressable.dart';

/// L'en-tete du Compte.
class EnteteCompte extends StatefulWidget {
  /// Cree l'en-tete.
  const EnteteCompte({
    required this.avatar,
    required this.nom,
    required this.role,
    super.key,
    this.matricule,
    this.statut,
    this.onChangerPhoto,
  });

  /// La photo ou l'initiale de la personne (par exemple `AvatarCompte`).
  final Widget avatar;

  /// Le nom affiche.
  final String nom;

  /// Le role, en clair (« Tuteur », « Enseignant »).
  final String role;

  /// Le matricule (`RA-26-4817`). Nul : la ligne n'est pas affichee.
  final String? matricule;

  /// Le statut du compte, en clair, ou une pastille. Nul : rien.
  final Widget? statut;

  /// Changer la photo, quand la capacite est servie. Nul : la photo ne se
  /// touche pas.
  final VoidCallback? onChangerPhoto;

  /// La cle de la photo touchable.
  static const Key photoKey = Key('compte.entete.photo');

  /// La cle de « Copier ».
  static const Key copierKey = Key('compte.entete.copier');

  @override
  State<EnteteCompte> createState() => _EnteteCompteEtat();
}

class _EnteteCompteEtat extends State<EnteteCompte> {
  bool _copie = false;

  Future<void> _copier(String matricule) async {
    await Clipboard.setData(ClipboardData(text: matricule));
    if (mounted) setState(() => _copie = true);
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final VoidCallback? changer = widget.onChangerPhoto;
    final Widget photo = changer == null
        ? ExcludeSemantics(child: widget.avatar)
        : Semantics(
            button: true,
            label: t.compte.page.changerPhoto,
            excludeSemantics: true,
            child: Pressable(
              key: EnteteCompte.photoKey,
              onPress: changer,
              child: widget.avatar,
            ),
          );
    final String? matricule = widget.matricule;
    return Column(
      children: <Widget>[
        photo,
        Ecart.vMd,
        Semantics(
          header: true,
          child: Text(
            widget.nom,
            textAlign: TextAlign.center,
            style: palette.inkStrong.applyTo(
              textes.titleLarge ?? const TextStyle(),
            ),
          ),
        ),
        Ecart.vXs,
        Text(
          widget.role,
          textAlign: TextAlign.center,
          style: palette.inkMuted.applyTo(
            textes.bodyMedium ?? const TextStyle(),
          ),
        ),
        if (matricule != null) ...<Widget>[
          Ecart.vXs,
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            children: <Widget>[
              Text(
                matricule,
                style: palette.inkMuted.applyTo(
                  textes.bodyMedium ?? const TextStyle(),
                ),
              ),
              LienFleche(
                key: EnteteCompte.copierKey,
                libelle: _copie ? t.compte.matriculeCopie : t.compte.copier,
                libelleSemantique: t.compte.copierMatricule,
                fleche: false,
                onPress: () => unawaited(_copier(matricule)),
              ),
            ],
          ),
        ],
        if (widget.statut != null) ...<Widget>[Ecart.vSm, widget.statut!],
      ],
    );
  }
}
