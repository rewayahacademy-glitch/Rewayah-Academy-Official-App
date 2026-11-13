/// SUIVI-ATTENTE (S4) : la carte de l'enseignant, a l'etape 4 seulement.
///
/// Ce que la famille voit : son nom, la langue du cours et, **s'il l'a
/// autorise**, sa photo, son pays d'origine, son pays de residence et son mot
/// de presentation. Rien d'autre : ni ville, ni telephone, ni courriel, ni date
/// de naissance, ni piece. Sans autorisation, la carte ne montre que le nom et
/// la langue du cours (le serveur n'envoie alors rien d'autre).
///
/// Un pays non declare n'est pas rendu : jamais « inconnu » (meme regle que
/// `PaysEnseignant`).
library;

import 'package:flutter/material.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/attente_classe/modele_attente.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/tc_groupe/group_summary_vm.dart';
import '../../core/theme/app_color_pair.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/avatar_tile.dart' show AppAvatar;
import '../../core/widgets/pays_enseignant.dart';
import '../tc_mes_groupes/photo_enseignant.dart';
import 'libelles_attente.dart';

/// La carte de l'enseignant d'un suivi.
class CarteEnseignantAttenteVue extends StatelessWidget {
  /// Cree la carte. [simple] : l'enfant de moins de 10 ans (tutoiement).
  const CarteEnseignantAttenteVue({
    required this.enseignant,
    this.simple = false,
    this.peutSePresenter = true,
    super.key,
  });

  /// L'enseignant, tel que le serveur le montre a cette famille.
  final CarteEnseignantAttente enseignant;

  /// Vrai pour la version simple de l'enfant.
  final bool simple;

  /// Vrai quand la phrase « il peut se presenter par un message » se dit (pas
  /// a l'enfant, qui ne recoit jamais de message).
  final bool peutSePresenter;

  /// La cle de la carte.
  static const Key cle = ValueKey<String>('attente-carte-enseignant');

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final AppInkColor secondaire = palette.encreSecondaireSur(
      palette.surfaceRaised,
    );
    final TextStyle legende = secondaire.applyTo(
      textes.bodySmall ?? const TextStyle(),
    );
    final TextStyle valeur = palette.inkStrong.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    final String? langue = enseignant.langueCours;
    final String? origine = enseignant.paysOrigine;
    final String? residence = enseignant.paysResidence;
    final String? mot = enseignant.mot;
    final String? id = enseignant.enseignantId;

    Widget ligne(String libelle, Widget contenu, Key cle) => Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        key: cle,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(libelle, style: legende),
          contenu,
        ],
      ),
    );

    return AppCard(
      key: cle,
      entete: Semantics(
        header: true,
        child: TexteSansCoupure(
          simple
              ? t.suiviAttente.enseignant.titreSimple
              : t.suiviAttente.enseignant.titre,
          style: textes.titleMedium ?? const TextStyle(),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              if (enseignant.montre && id != null) ...<Widget>[
                _Photo(
                  enseignantId: id,
                  prenom: enseignant.prenom,
                  sayyida: enseignant.titre == 'sayyida',
                ),
                Ecart.hMd,
              ],
              Expanded(
                child: TexteSansCoupure(
                  nomEnseignant(enseignant),
                  key: const ValueKey<String>('attente-enseignant-nom'),
                  style: palette.inkStrong.applyTo(
                    textes.titleSmall ?? const TextStyle(),
                  ),
                ),
              ),
            ],
          ),
          if (langue != null && langue.isNotEmpty)
            ligne(
              t.suiviAttente.enseignant.langue,
              TexteSansCoupure(langue, style: valeur),
              const ValueKey<String>('attente-enseignant-langue'),
            ),
          if (origine != null)
            ligne(
              t.suiviAttente.enseignant.origine,
              PaysEnseignant.parCode(codeIso: origine),
              const ValueKey<String>('attente-enseignant-origine'),
            ),
          if (residence != null)
            ligne(
              t.suiviAttente.enseignant.residence,
              PaysEnseignant.parCode(codeIso: residence),
              const ValueKey<String>('attente-enseignant-residence'),
            ),
          if (mot != null && mot.isNotEmpty)
            ligne(
              t.suiviAttente.enseignant.mot,
              TexteSansCoupure(mot, style: valeur),
              const ValueKey<String>('attente-enseignant-mot'),
            ),
          if (peutSePresenter) ...<Widget>[
            Ecart.vMd,
            Text(
              t.suiviAttente.enseignant.peutSePresenter,
              key: const ValueKey<String>('attente-enseignant-presenter'),
              style: legende,
            ),
          ],
        ],
      ),
    );
  }
}

/// La photo : la source unique des photos (`PhotoEnseignant`, qui lit
/// `photoPersonneProvider`), le serveur dit seul si l'appelant peut la voir ;
/// les initiales tant qu'elle n'a pas repondu, ou quand il n'y en a pas
/// (cote famille, jamais d'avertissement pour une photo manquante).
class _Photo extends StatelessWidget {
  const _Photo({
    required this.enseignantId,
    required this.prenom,
    required this.sayyida,
  });

  final String enseignantId;
  final String prenom;
  final bool sayyida;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      key: const ValueKey<String>('attente-enseignant-photo'),
      child: PhotoEnseignant(
        enseignant: EnseignantVM(
          enseignantId: enseignantId,
          titre: sayyida ? TitreEnseignant.sayyida : TitreEnseignant.sayyid,
          nomAffichage: prenom,
        ),
        diametre: AppAvatar.grand,
        repliInitiales: true,
      ),
    );
  }
}
