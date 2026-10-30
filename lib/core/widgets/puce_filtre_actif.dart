import 'package:flutter/material.dart';

import '../i18n/strings.g.dart';
import '../theme/app_spacing.dart';
import 'action_principale.dart';
import 'filter_pill.dart';
import 'rangee_filtres.dart';

/// Un filtre en cours : ce qu'il dit (« Pays : Guinee ») et ce qui le retire.
@immutable
class FiltreActif {
  /// Cree un filtre actif.
  const FiltreActif({required this.libelle, required this.onRetirer});

  /// Le filtre, lisible seul : l'axe et la valeur (« Etat : En examen »).
  final String libelle;

  /// Retire ce filtre, et lui seul.
  final VoidCallback onRetirer;
}

/// La puce d'un **filtre actif**, qu'on touche pour le retirer.
///
/// Promue de `observations_admin_page.dart` (la pastille d'une personne
/// retenue) vers le core par LISTES-1, sans copie : l'ecran des observations la
/// emploie desormais d'ici. C'est une [FilterPill] retenue (la coche et le fond
/// doux disent « en cours », jamais la couleur seule), dont le lecteur d'ecran
/// entend **l'effet du toucher** (« Retirer le filtre : ... »), pas un etat.
///
/// Elle se declare [PuceFiltre] retenue : une [RangeeFiltres] l'amene dans la
/// vue des qu'elle apparait, sinon la seule facon de retirer ce filtre
/// resterait cachee hors de la rangee (FILTRES-1b, reprise).
///
/// Regle LISTES-1 : `docs/current/DECISION-LISTES-2026-10-23.md`
/// (List-first, human-first).
class PuceFiltreActif extends StatelessWidget implements PuceFiltre {
  /// Cree la puce.
  const PuceFiltreActif({
    required this.libelle,
    required this.onRetirer,
    this.libelleRetirer,
    super.key,
  });

  /// Le filtre, lisible seul.
  final String libelle;

  /// Retire le filtre.
  final VoidCallback onRetirer;

  /// Ce que dit le lecteur d'ecran, quand l'ecran a mieux que le mot commun
  /// « Retirer le filtre : {filtre} ».
  final String? libelleRetirer;

  @override
  bool get retenue => true;

  @override
  Widget build(BuildContext context) => Semantics(
    label: libelleRetirer ?? t.commun.listes.retirerFiltre(filtre: libelle),
    excludeSemantics: true,
    child: FilterPill(libelle: libelle, retenue: true, onPress: onRetirer),
  );
}

/// Les filtres en cours d'une liste, **visibles et retirables un a un**, avec
/// « Tout effacer ».
///
/// Une liste filtree dit pourquoi elle est courte : sans cette rangee, un filtre
/// pose depuis la feuille « Plus de filtres » ne se voit plus, et la liste
/// parait vide ou incomplete sans qu'on sache pourquoi. Elle n'est rendue que
/// s'il y a un filtre en cours : une liste sans filtre n'a rien a dire.
///
/// **Une seule rangee** ([RangeeFiltres] sans repli : chaque filtre reste
/// visible, la rangee defile si elle ne tient pas, jamais un `Wrap` de puces) ;
/// « Tout effacer » reste hors de la rangee, a son bout, toujours atteignable.
///
/// Elle **n'est pas** la rangee des filtres possibles : celle-la reste
/// `RangeeFiltres` (trois puces au plus, puis « Plus »). Celle-ci dit ce qui est
/// retenu, y compris ce qui est range sous « Plus ».
///
/// Regle LISTES-1 : `docs/current/DECISION-LISTES-2026-10-23.md`
/// (List-first, human-first).
class FiltresActifs extends StatelessWidget {
  /// Cree la rangee.
  const FiltresActifs({
    required this.filtres,
    required this.onToutEffacer,
    super.key,
  });

  /// Les filtres en cours. Vide : rien n'est rendu.
  final List<FiltreActif> filtres;

  /// Retire tous les filtres a la fois. **Ni la recherche ni le tri** : l'ecran
  /// decide de ce qu'il efface.
  final VoidCallback onToutEffacer;

  /// La cle de « Tout effacer », pour les tests.
  static const Key cleToutEffacer = ValueKey<String>('filtres-actifs-effacer');

  /// En dessous de cette largeur offerte, « Tout effacer » passe sous la
  /// rangee : a cote, il laisserait aux filtres un cran de defilement, et au
  /// texte agrandi il deborderait (424 de large a 200 %).
  static const double largeurCoteACote = 560;

  @override
  Widget build(BuildContext context) {
    if (filtres.isEmpty) return const SizedBox.shrink();
    final Widget rangee = RangeeFiltres(
      replier: false,
      filtres: <Widget>[
        for (final FiltreActif f in filtres)
          PuceFiltreActif(libelle: f.libelle, onRetirer: f.onRetirer),
      ],
    );
    final Widget effacer = ActionPrincipale(
      key: cleToutEffacer,
      libelle: t.commun.listes.toutEffacer,
      niveau: NiveauAction.tertiaire,
      // A la largeur de son libelle : sur telephone, une action prend sinon
      // toute la largeur, ce qu'une rangee ne peut pas lui donner.
      pleineLargeur: false,
      onPress: onToutEffacer,
    );
    return LayoutBuilder(
      builder: (BuildContext contexte, BoxConstraints contraintes) {
        if (contraintes.maxWidth >= largeurCoteACote) {
          return Row(
            children: <Widget>[
              Expanded(child: rangee),
              Ecart.hSm,
              effacer,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            rangee,
            Align(alignment: AlignmentDirectional.centerEnd, child: effacer),
          ],
        );
      },
    );
  }
}
