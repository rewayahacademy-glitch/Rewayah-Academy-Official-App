// Un choix dans une longue liste (langues, pays, riwayat, villes).
//
// CANDIDATURE-UX (directeur, 14/11/2026 : « les cartes sont enormes, 5 par
// ecran ») : la recherche est en tete, toujours visible ; dessous, les choix
// courants en lignes compactes (`ChoiceCardGroup(compacte: true)`, 48 a 56).
// Taper filtre toute la liste, dans les memes lignes. Ce qui est retenu hors
// des choix courants s'y ajoute, pour se voir et se retirer.
//
// Les riwayat (meme demande) : d'abord « toutes » (exclusive), puis les plus
// connues, puis « Une autre riwaya » et sa recherche, sous la liste
// ([ChoixAvecRecherche.rechercheEnTete] faux).
//
// Aucune saisie libre : le serveur ne recoit que des codes de la liste.
library;

import 'package:flutter/material.dart';

import '../../core/i18n/pays_iso.dart' show formeDeRecherche;
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/champ_etiquete.dart' show TitreChamp;
import '../../core/widgets/champ_recherche.dart';
import '../../core/widgets/choice_card_group.dart';
import '../../core/widgets/lien_fleche.dart';

/// Un element d'une liste de choix.
class ElementChoix {
  /// Cree l'element.
  const ElementChoix({
    required this.code,
    required this.libelle,
    this.description,
    this.cle,
    this.motsCles,
  });

  /// Des mots que la recherche lit **en plus** du nom : le nom du pays dans
  /// l'autre langue, son indicatif. Jamais affiches.
  final String? motsCles;

  /// Le code que le serveur attend.
  final String code;

  /// Le nom affiche.
  final String libelle;

  /// Une phrase sous le nom (carte et ligne).
  final String? description;

  /// Une cle posee sur la carte, pour les tests.
  final Key? cle;
}

/// Les textes d'un [ChoixAvecRecherche].
class TextesRecherche {
  /// Cree les textes.
  const TextesRecherche({
    required this.recherche,
    required this.aide,
    required this.aucun,
    required this.retour,
    this.autre,
  });

  /// L'etiquette du champ de recherche.
  final String recherche;

  /// L'aide dans le champ vide.
  final String aide;

  /// Quand rien ne correspond.
  final String aucun;

  /// « Revenir aux pays proposes » : vide la recherche.
  final String retour;

  /// « Une autre riwaya » : le titre pose au-dessus de la recherche quand
  /// elle vient sous la liste ([ChoixAvecRecherche.rechercheEnTete] faux).
  final String? autre;
}

/// La recherche en tete, puis les choix courants en lignes compactes.
class ChoixAvecRecherche extends StatefulWidget {
  /// Cree le choix.
  const ChoixAvecRecherche({
    required this.cle,
    required this.courants,
    required this.tous,
    required this.selection,
    required this.onChange,
    required this.textes,
    super.key,
    this.multiple = false,
    this.rechercheEnTete = true,
    this.toutes,
  });

  /// Le prefixe des cles des widgets (tests).
  final String cle;

  /// Les choix courants, en lignes, dans l'ordre.
  final List<ElementChoix> courants;

  /// Tous les choix, pour la recherche.
  final List<ElementChoix> tous;

  /// Les codes retenus.
  final Set<String> selection;

  /// Appele a chaque changement de la selection.
  final ValueChanged<Set<String>> onChange;

  /// Les textes.
  final TextesRecherche textes;

  /// Vrai : plusieurs reponses.
  final bool multiple;

  /// Vrai : la recherche au-dessus des choix courants (langues, pays) ; faux :
  /// sous eux, avec le titre [TextesRecherche.autre] (riwayat).
  final bool rechercheEnTete;

  /// En selection multiple, une premiere ligne exclusive qui retient **tous**
  /// les codes de [tous] (« J'ai maitrise toutes les riwayat »). Le serveur
  /// recoit la liste complete ; son code n'est jamais envoye. Une autre ligne
  /// touchee ensuite la remplace.
  final ElementChoix? toutes;

  /// La valeur interne de la ligne [toutes].
  static const String valeurToutes = r'$toutes';

  /// La cle du champ de recherche.
  static const Key champKey = ValueKey<String>('choix-recherche-champ');

  @override
  State<ChoixAvecRecherche> createState() => _ChoixAvecRechercheState();
}

class _ChoixAvecRechercheState extends State<ChoixAvecRecherche> {
  final TextEditingController _requete = TextEditingController();

  @override
  void dispose() {
    _requete.dispose();
    super.dispose();
  }

  /// Vrai quand la ligne « toutes » est retenue : chaque code de la liste.
  bool get _toutesRetenues =>
      widget.toutes != null &&
      widget.tous.isNotEmpty &&
      widget.tous.every((ElementChoix e) => widget.selection.contains(e.code));

  /// Sans recherche : la ligne « toutes », les choix courants, puis ceux de
  /// la selection qui n'en font pas partie (aucun quand tout est retenu).
  List<ElementChoix> get _courantsEtRetenus {
    final Set<String> courants = <String>{
      for (final ElementChoix e in widget.courants) e.code,
    };
    return <ElementChoix>[
      ?widget.toutes,
      ...widget.courants,
      if (!_toutesRetenues)
        for (final ElementChoix e in widget.tous)
          if (widget.selection.contains(e.code) && !courants.contains(e.code))
            e,
    ];
  }

  /// Avec une recherche : toute la liste filtree, sauf [exclus] ; ceux dont
  /// le nom COMMENCE par ce qui est tape passent d'abord (« ma » : Maroc
  /// avant Allemagne), l'ordre de la liste est garde dans chaque groupe.
  List<ElementChoix> _trouves(String q, Set<String> exclus) {
    final List<ElementChoix> correspondants = <ElementChoix>[
      for (final ElementChoix e in widget.tous)
        if (!exclus.contains(e.code) &&
            (formeDeRecherche(e.libelle).contains(q) ||
                (e.motsCles != null &&
                    formeDeRecherche(e.motsCles!).contains(q))))
          e,
    ];
    return <ElementChoix>[
      ...correspondants.where(
        (ElementChoix e) => formeDeRecherche(e.libelle).startsWith(q),
      ),
      ...correspondants.where(
        (ElementChoix e) => !formeDeRecherche(e.libelle).startsWith(q),
      ),
    ];
  }

  void _vider() => setState(_requete.clear);

  /// Une reponse d'un groupe de lignes, rendue en codes pour le serveur.
  void _repondre(ReponseChoix r, Set<String> affiches) {
    if (!widget.multiple) {
      // Un seul choix : il est fait, la recherche se vide et le choix retenu
      // se voit parmi les choix courants.
      if (_requete.text.isNotEmpty) _vider();
      widget.onChange(r.valeurs);
      return;
    }
    final Set<String> valeurs = r.valeurs.toSet();
    if (widget.toutes != null) {
      final bool avant = _toutesRetenues;
      final bool apres = valeurs.contains(ChoixAvecRecherche.valeurToutes);
      if (apres && !avant) {
        widget.onChange(<String>{
          for (final ElementChoix e in widget.tous) e.code,
        });
        return;
      }
      if (avant) {
        // « Toutes » etait retenue : la retirer vide tout ; toucher une autre
        // ligne ne garde qu'elle.
        valeurs.remove(ChoixAvecRecherche.valeurToutes);
        widget.onChange(valeurs);
        if (_requete.text.isNotEmpty) _vider();
        return;
      }
      valeurs.remove(ChoixAvecRecherche.valeurToutes);
    }
    // Ce qui n'est pas affiche reste retenu.
    widget.onChange(<String>{
      ...widget.selection.difference(affiches),
      ...valeurs,
    });
  }

  /// Un groupe de lignes compactes pour [elements].
  Widget _groupe(List<ElementChoix> elements, String suffixe) {
    final bool toutes = _toutesRetenues;
    final Set<String> codes = <String>{
      for (final ElementChoix e in elements)
        if (e.code != ChoixAvecRecherche.valeurToutes) e.code,
    };
    return ChoiceCardGroup(
      // La liste affichee change : le groupe repart de la selection.
      key: ValueKey<String>(
        '${widget.cle}-$suffixe-${elements.length}-$toutes',
      ),
      compacte: true,
      autoriserSaisieLibre: false,
      selectionMultiple: widget.multiple,
      valeurInitiale: ReponseChoix(
        valeurs: toutes
            ? const <String>{ChoixAvecRecherche.valeurToutes}
            : <String>{
                for (final String c in widget.selection)
                  if (codes.contains(c)) c,
              },
      ),
      options: <OptionChoix>[
        for (final ElementChoix e in elements)
          OptionChoix(
            cle: e.cle,
            valeur: e.code,
            libelle: e.libelle,
            description: e.description,
          ),
      ],
      onChange: (ReponseChoix r) => _repondre(r, codes),
    );
  }

  Widget _aucun(BuildContext context) =>
      Text(widget.textes.aucun, style: Theme.of(context).textTheme.bodyMedium);

  Widget _champ() => ChampRecherche(
    cleChamp: ChoixAvecRecherche.champKey,
    controleur: _requete,
    libelle: widget.textes.recherche,
    aide: widget.textes.aide,
    onChange: (String _) => setState(() {}),
  );

  Widget _retour() => LienFleche(
    libelle: widget.textes.retour,
    alignerEnDebut: true,
    onPress: _vider,
  );

  @override
  Widget build(BuildContext context) {
    final String q = formeDeRecherche(_requete.text);
    final bool enRecherche = q.isNotEmpty;
    final List<ElementChoix> courants = _courantsEtRetenus;
    if (widget.rechercheEnTete) {
      final List<ElementChoix> affiches = enRecherche
          ? _trouves(q, const <String>{})
          : courants;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // La recherche d'abord : qui ne se retrouve pas dans les choix
          // courants n'a pas a les parcourir en entier.
          _champ(),
          if (enRecherche) ...<Widget>[Ecart.vSm, _retour()],
          Ecart.vMd,
          if (affiches.isEmpty)
            _aucun(context)
          else
            _groupe(affiches, enRecherche ? 'q-$q' : 'courants'),
        ],
      );
    }
    // La liste d'abord, puis « Une autre riwaya » et sa recherche : les
    // resultats ne repetent pas une ligne deja visible au-dessus.
    final Set<String> visibles = <String>{
      for (final ElementChoix e in courants) e.code,
    };
    final List<ElementChoix> trouves = enRecherche
        ? _trouves(q, visibles)
        : const <ElementChoix>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _groupe(courants, 'courants'),
        if (widget.textes.autre case final String autre) ...<Widget>[
          TitreChamp(autre, style: Theme.of(context).textTheme.titleSmall),
          Ecart.vSm,
        ],
        _champ(),
        if (enRecherche) ...<Widget>[
          Ecart.vSm,
          _retour(),
          Ecart.vMd,
          if (trouves.isEmpty) _aucun(context) else _groupe(trouves, 'q-$q'),
        ],
      ],
    );
  }
}
