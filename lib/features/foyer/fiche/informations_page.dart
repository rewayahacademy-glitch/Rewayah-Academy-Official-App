import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/foyer/selection_eleve.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/offres/offre_horaire.dart';
import '../../../core/offres/service_offres.dart' show parcoursFoyerProvider;
import '../../../core/offres/tranche_age.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/groupe_reglages.dart';
import '../fiche_eleve_page.dart';
import '../photo_eleve.dart';

/// Les informations d'un profil eleve (`/tuteur/foyer/:eleveId/informations`).
///
/// Rendu derive des lignes du Compte (manifeste visuel, section 2) : l'identite
/// en un groupe a filets, lue seulement (aucune ecriture du prenom n'est
/// ouverte au tuteur, DB-FOY-07) : le prenom, et la tranche d'age que le
/// serveur a deduite de l'age a la creation (`cohorte`, lue dans le parcours
/// du foyer ; MINEUR-FANTOME, 07/11/2026), puis la photo : selection, apercu, envoi en deux
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
                _Identite(profil: profil),
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

/// Le prenom et la tranche d'age, en lecture.
///
/// La tranche vient de `v_parcours_onboarding` (une ligne par apprenant du
/// foyer). Pendant la lecture la ligne reste sans valeur ; une lecture
/// echouee le dit (« Non lue ») au lieu d'affirmer une absence.
class _Identite extends ConsumerWidget {
  const _Identite({required this.profil});

  final ProfilEleveFoyer profil;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ParcoursApprenant>> parcours = ref.watch(
      parcoursFoyerProvider,
    );
    // Comme la page Inscription : l'erreur d'abord (le fournisseur reste
    // « en lecture » pendant ses nouvelles tentatives), puis la valeur.
    final String? tranche;
    if (parcours.hasError) {
      tranche = t.ficheEleve.informations.trancheNonLue;
    } else if (parcours.hasValue) {
      final String? code = parcours.requireValue
          .where((ParcoursApprenant a) => a.eleveId == profil.eleveId)
          .map((ParcoursApprenant a) => a.cohorteCode)
          .firstOrNull;
      tranche = code == null
          ? t.ficheEleve.informations.trancheInconnue
          : libelleTranche(code);
    } else {
      tranche = null;
    }
    return GroupeReglages(
      titre: t.ficheEleve.informations.identite,
      lignes: <LigneRubrique>[
        LigneRubrique(
          icone: AppIcons.profil,
          libelle: t.ficheEleve.informations.prenom,
          valeur: profil.prenom,
        ),
        LigneRubrique(
          icone: AppIcons.horloge,
          libelle: t.ficheEleve.informations.tranche,
          valeur: tranche,
        ),
      ],
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
