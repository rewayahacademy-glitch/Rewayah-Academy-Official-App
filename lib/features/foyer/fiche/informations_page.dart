import 'package:flutter/material.dart';

import '../../../core/foyer/selection_eleve.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/groupe_reglages.dart';
import '../fiche_eleve_page.dart';
import '../photo_eleve.dart';

/// Les informations d'un profil eleve (`/tuteur/foyer/:eleveId/informations`).
///
/// Rendu derive des lignes du Compte (manifeste visuel, section 2) : l'identite
/// en un groupe a filets, lue seulement (aucune ecriture du prenom n'est
/// ouverte au tuteur, DB-FOY-07 ; l'age et la date de naissance ne sont pas
/// enregistres, DB-ADM-05), puis la photo : selection, apercu, envoi en deux
/// etapes dites, reprise. Sur bureau, l'identite a gauche, la photo a droite.
class InformationsElevePage extends StatelessWidget {
  /// Cree la page.
  const InformationsElevePage({required this.eleveId, super.key});

  /// L'eleve concerne.
  final String eleveId;

  /// Le groupe de l'identite.
  static const Key identiteKey = Key('ficheEleve.informations.identite');

  /// Le bloc de la photo.
  static const Key photoKey = Key('ficheEleve.informations.photo');

  @override
  Widget build(BuildContext context) {
    return PageFiche(
      eleveId: eleveId,
      titre: t.ficheEleve.informations.titre,
      onRetour: retourVersFiche(context, eleveId),
      construire: (BuildContext context, ProfilEleveFoyer profil) =>
          ColonnesFiche(
            principal: Column(
              key: identiteKey,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                GroupeReglages(
                  titre: t.ficheEleve.informations.identite,
                  lignes: <LigneRubrique>[
                    LigneRubrique(
                      icone: AppIcons.profil,
                      libelle: t.ficheEleve.informations.prenom,
                      valeur: profil.prenom,
                    ),
                  ],
                ),
                Ecart.vMd,
                NoteFiche(t.ficheEleve.informations.identiteNote),
                NoteFiche(t.ficheEleve.informations.ageNote),
              ],
            ),
            annexe: Column(
              key: photoKey,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _TitreGroupe(t.ficheEleve.informations.photo),
                Ecart.vSm,
                SurfaceFiche(child: EditeurPhotoEleve(profil: profil)),
              ],
            ),
          ),
    );
  }
}

/// Le titre d'un bloc libre, au meme rang que celui d'un groupe a filets.
class _TitreGroupe extends StatelessWidget {
  const _TitreGroupe(this.texte);

  final String texte;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(
      texte,
      style: AppPalette.of(context).inkStrong.applyTo(
        Theme.of(context).textTheme.titleMedium ?? const TextStyle(),
      ),
    ),
  );
}
