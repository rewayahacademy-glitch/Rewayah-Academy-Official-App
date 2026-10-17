import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/identite/port_matricule.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/lien_fleche.dart';

/// Le role en toutes lettres, dans la langue de l'application.
String libelleRoleAffiche(RoleAffiche role) => switch (role) {
  RoleAffiche.eleve => t.commun.roles.eleve,
  RoleAffiche.tuteur => t.commun.roles.tuteur,
  RoleAffiche.enseignant => t.commun.roles.enseignant,
  RoleAffiche.administration => t.commun.roles.administration,
  RoleAffiche.controleur => t.commun.roles.controleur,
  RoleAffiche.comptable => t.commun.roles.comptable,
};

/// « Matricule RA-26-4817 · Élève » avec un geste de copie (IMM-FRONT-1,
/// DECISION-IMMATRICULATION section 1).
///
/// Le role s'ecrit a cote du matricule, jamais dedans. Seule la valeur est
/// isolee de gauche a droite (elle se lit ainsi meme en arabe) ; la phrase
/// garde le sens de l'interface. Matricule indisponible (port a `null`, en
/// cours de lecture ou en erreur) : aucune ligne, pas de bouton grise.
class LigneMatricule extends ConsumerStatefulWidget {
  /// Cree la ligne du profil [profileId].
  const LigneMatricule({required this.profileId, super.key});

  /// Le profil dont le matricule s'affiche.
  final String profileId;

  /// Le geste de copie.
  static const Key copierKey = Key('ligneMatricule.copier');

  /// La valeur isolee de gauche a droite.
  static const Key valeurKey = Key('ligneMatricule.valeur');

  @override
  ConsumerState<LigneMatricule> createState() => _LigneMatriculeState();
}

class _LigneMatriculeState extends ConsumerState<LigneMatricule> {
  /// Marque posee a la place de la valeur dans la phrase traduite, pour y
  /// loger la valeur isolee (un widget LTR).
  static const String _marque = '';

  bool _copie = false;

  Future<void> _copier(String valeur) async {
    await Clipboard.setData(ClipboardData(text: valeur));
    if (!mounted) return;
    setState(() => _copie = true);
  }

  @override
  Widget build(BuildContext context) {
    final Matricule? matricule = ref
        .watch(matriculeProvider(widget.profileId))
        .value;
    if (matricule == null) return const SizedBox.shrink();

    final AppPalette palette = AppPalette.of(context);
    final TextStyle base =
        Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    final TextStyle style = palette.inkMuted.applyTo(base);
    final String phrase = t.compte.matricule(
      valeur: _marque,
      role: libelleRoleAffiche(matricule.role),
    );
    final int coupe = phrase.indexOf(_marque);
    final String avant = coupe < 0 ? phrase : phrase.substring(0, coupe);
    final String apres = coupe < 0
        ? ''
        : phrase.substring(coupe + _marque.length);

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.md,
        children: <Widget>[
          Semantics(
            label: phrase.replaceAll(_marque, matricule.valeur),
            excludeSemantics: true,
            child: Text.rich(
              TextSpan(
                style: style,
                children: <InlineSpan>[
                  TextSpan(text: avant),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        matricule.valeur,
                        key: LigneMatricule.valeurKey,
                        style: palette.inkStrong.applyTo(base),
                      ),
                    ),
                  ),
                  TextSpan(text: apres),
                ],
              ),
            ),
          ),
          LienFleche(
            key: LigneMatricule.copierKey,
            libelle: _copie ? t.compte.matriculeCopie : t.compte.copier,
            libelleSemantique: _copie
                ? t.compte.matriculeCopie
                : t.compte.copierMatricule,
            fleche: false,
            onPress: () => _copier(matricule.valeur),
          ),
        ],
      ),
    );
  }
}
