// ACCUEIL-CANDIDAT (directeur, 20/11/2026) : la troisieme rubrique de
// l'onglet Messages du candidat (nom propose : « A savoir », a valider par le
// directeur). Elle deviendra plus tard le formulaire de l'entretien ; POUR
// L'INSTANT elle range les informations que les candidats n'ont pas (la paie
// d'un enseignant, le deroulement des cours, l'organisation des entretiens).
//
// INTERFACE SEULEMENT : des emplacements nommes, chacun dans l'etat
// « s'affichera ici quand la direction le rendra public ». Aucun contenu de
// fond n'est ecrit ici (ni montant, ni regle, ni promesse) : aucune source
// publiee par la direction n'existe encore. Quand elle existera, chaque
// emplacement lira son texte au serveur ; la liste [EmplacementSavoir] est le
// seul endroit a completer.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/carte_groupee.dart';
import '../../core/widgets/lien_fleche.dart';

/// Un emplacement nomme de la rubrique.
enum EmplacementSavoir {
  /// La paie d'un enseignant.
  paie,

  /// Le deroulement des cours.
  cours,

  /// L'organisation des entretiens.
  entretiens;

  /// Le nom de l'emplacement.
  String get nom {
    final a = t.recrutement.accueil.academie;
    return switch (this) {
      EmplacementSavoir.paie => a.remuneration,
      EmplacementSavoir.cours => a.cours,
      EmplacementSavoir.entretiens => a.entretiens,
    };
  }

  /// L'icone de l'emplacement.
  AppIcon get icone => switch (this) {
    EmplacementSavoir.paie => AppIcons.paiements,
    EmplacementSavoir.cours => AppIcons.cours,
    EmplacementSavoir.entretiens => AppIcons.discussion,
  };
}

/// La rubrique « A savoir ».
class ASavoirCandidat extends StatelessWidget {
  /// Cree la rubrique.
  const ASavoirCandidat({super.key});

  /// La cle de la carte des emplacements.
  static const Key cle = ValueKey<String>('a-savoir-candidat');

  /// La cle de l'entree de la lettre aux candidats.
  static const Key cleLettre = ValueKey<String>('a-savoir-lettre');

  /// La cle de l'emplacement [e].
  static Key cleEmplacement(EmplacementSavoir e) =>
      ValueKey<String>('a-savoir-${e.name}');

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle muet = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    final a = t.recrutement.accueil.academie;
    // Un texte tres agrandi : l'icone cede sa place, aucun mot ne se coupe.
    final bool agrandi = MediaQuery.textScalerOf(context).scale(14) / 14 > 1.3;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(t.recrutement.accueil.messages.savoir.intro, style: muet),
        Ecart.vLg,
        // LETTRE-CANDIDATS (directeur, 20/11/2026) : la lettre aux candidats,
        // seule entree de la page depuis l'accueil du candidat.
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: LienFleche(
            key: ASavoirCandidat.cleLettre,
            alignerEnDebut: true,
            libelle: t.recrutement.lettre.entree,
            onPress: () => GoRouter.of(context).push(Routes.lettreEnseignants),
          ),
        ),
        Text(t.recrutement.lettre.entreeLegende, style: muet),
        Ecart.vLg,
        // Des contenus lies : UNE carte a lignes fines (K-55).
        CarteGroupee(
          key: ASavoirCandidat.cle,
          sections: <Widget>[
            for (final EmplacementSavoir e in EmplacementSavoir.values)
              Semantics(
                key: ASavoirCandidat.cleEmplacement(e),
                container: true,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (!agrandi) ...<Widget>[
                      ExcludeSemantics(
                        child: IconTheme(
                          data: palette.inkAccent.asIconTheme(
                            size: AppSpacing.xxl,
                          ),
                          child: Icon(e.icone.repos),
                        ),
                      ),
                      Ecart.hMd,
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            e.nom,
                            style: palette.inkStrong.applyTo(
                              textes.bodyLarge ?? const TextStyle(),
                            ),
                          ),
                          Ecart.vXs,
                          Text(a.bientot, style: muet),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}
