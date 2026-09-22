import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/tc_bibliotheque/vue_catalogue.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import 'surface_bibliotheque.dart';

/// La Bibliotheque ouverte **pendant un cours**.
///
/// Surface reutilisable, et non ecran : c'est ce qui permet a la Classe Live
/// d'Agent E de l'accueillir en panneau lateral sur tablette et en feuille sur
/// telephone, sans que la Bibliotheque sache quoi que ce soit de la classe.
///
/// **Elle ne connait pas LiveKit, et c'est une garantie, pas une intention.**
/// Ni ce fichier ni [SurfaceBibliotheque] n'importent quoi que ce soit de
/// `lib/core/video/` : choisir une ressource ici ne peut donc pas appeler
/// `disconnect`, ni toucher la `Room`, ni meme la voir. Le seul effet d'un
/// choix est l'appel de [onChoisir]. Un test relit les imports des deux
/// fichiers pour que cela le reste.
///
/// **C'est la meme bibliotheque.** Aucun catalogue parallele, aucun etat hors
/// ligne separe, aucune regle de droit differente : seul l'ordre de decouverte
/// change, et il est decide dans `VueCatalogue.depuis` (spec section 6.2 :
/// Recents, puis Ce groupe, puis Tous les supports, puis Recherche).
class ClassLibraryPicker extends StatelessWidget {
  /// Cree le selecteur.
  const ClassLibraryPicker({
    required this.onChoisir,
    super.key,
    this.groupeId,
    this.hauteurMaximale,
  });

  /// Le groupe en cours de cours.
  ///
  /// `null` quand la seance a ete rejointe sans groupe connu (billet sans
  /// groupe) : la section « Ce groupe » n'est alors pas proposee, le reste de
  /// la decouverte ne change pas.
  final String? groupeId;

  /// Ce qui se passe quand un support est choisi.
  ///
  /// **L'appelant reste maitre de la suite.** Le selecteur ne ferme rien, ne
  /// navigue nulle part et ne touche pas a la session : remplacer le support
  /// actif est une decision de la Classe Live, pas de la Bibliotheque.
  final ChoixRessource onChoisir;

  /// La hauteur maximale de la surface. Par defaut, celle d'une feuille
  /// quasi plein ecran sur telephone.
  final double? hauteurMaximale;

  /// Ouvre le selecteur en feuille de bas d'ecran.
  ///
  /// La feuille est le rendu telephone de la spec section 6.2. Sur tablette et
  /// desktop, la Classe Live pose plutot [ClassLibraryPicker] directement dans
  /// un panneau lateral : c'est pour cela que le widget et son ouverture sont
  /// deux choses separees.
  ///
  /// **Aucune deconnexion.** `showModalBottomSheet` pousse une route modale
  /// par-dessus la page de classe ; la page reste montee, donc le moteur de
  /// salle reste connecte.
  static Future<void> ouvrirEnFeuille(
    BuildContext context, {
    required ChoixRessource onChoisir,
    String? groupeId,
  }) => AppBottomSheet.ouvrir<void>(
    context,
    titre: t.tc.bibliotheque.classe.titre,
    constructeur: (BuildContext contexte) =>
        ClassLibraryPicker(groupeId: groupeId, onChoisir: onChoisir),
  );

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    // La feuille de `AppBottomSheet` est un `Column(mainAxisSize: min)` : la
    // surface, qui defile en slivers, a besoin d'une hauteur bornee. Sans
    // cette borne, la mesure echoue.
    final double hauteur =
        hauteurMaximale ?? MediaQuery.sizeOf(context).height * _fraction;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: hauteur),
      child: SurfaceBibliotheque(
        contexte: ContexteDecouverte.enClasse,
        groupeId: groupeId,
        onChoisir: onChoisir,
        enTete: Text(
          t.tc.bibliotheque.classe.sousTitre,
          style: palette.inkMuted.applyTo(
            textes.bodySmall ?? const TextStyle(),
          ),
        ),
      ),
    );
  }

  /// La part de la hauteur d'ecran occupee par defaut.
  ///
  /// « Quasi plein ecran » sur telephone (spec section 6.2) : assez haut pour
  /// que la liste soit utile, assez bas pour qu'on voie qu'on est toujours en
  /// classe, ce qui est exactement l'information rassurante a garder.
  static const double _fraction = 0.85;
}
