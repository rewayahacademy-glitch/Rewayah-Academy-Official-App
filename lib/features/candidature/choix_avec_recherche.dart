// Un choix dans une longue liste (langues, pays, riwayat, villes), sans clavier
// tant que ce n'est pas inevitable : d'abord les choix courants en cartes
// (`ChoiceCardGroup`), puis « Autre ... » qui ouvre une recherche proposant des
// lignes a toucher. Ce qui est retenu hors des cartes courantes s'y ajoute en
// carte, pour se voir et se retirer.
//
// Aucune saisie libre : le serveur ne recoit que des codes de la liste.
library;

import 'package:flutter/material.dart';

import '../../core/i18n/pays_iso.dart' show formeDeRecherche;
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/carte_lignes.dart';
import '../../core/widgets/champ_recherche.dart';
import '../../core/widgets/choice_card_group.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/setting_row.dart';

/// Un element d'une liste de choix.
class ElementChoix {
  /// Cree l'element.
  const ElementChoix({
    required this.code,
    required this.libelle,
    this.description,
    this.cle,
  });

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
    required this.autre,
    required this.recherche,
    required this.aide,
    required this.aucun,
    required this.retour,
  });

  /// « Un autre pays » : ouvre la recherche.
  final String autre;

  /// L'etiquette du champ de recherche.
  final String recherche;

  /// L'aide dans le champ vide.
  final String aide;

  /// Quand rien ne correspond.
  final String aucun;

  /// « Revenir aux pays proposes ».
  final String retour;
}

/// Cartes courantes, puis recherche.
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
    this.icone,
  });

  /// Le prefixe des cles des widgets (tests).
  final String cle;

  /// Les choix courants, en cartes, dans l'ordre.
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

  /// L'icone des cartes, s'il y en a une.
  final AppIcon? icone;

  /// La cle du lien « Autre ... ».
  static const Key autreKey = ValueKey<String>('choix-recherche-autre');

  /// La cle du champ de recherche.
  static const Key champKey = ValueKey<String>('choix-recherche-champ');

  /// La cle de la ligne de recherche d'un code.
  static Key ligneKey(String code) => ValueKey<String>('choix-recherche-$code');

  @override
  State<ChoixAvecRecherche> createState() => _ChoixAvecRechercheState();
}

class _ChoixAvecRechercheState extends State<ChoixAvecRecherche> {
  final TextEditingController _requete = TextEditingController();
  bool _enRecherche = false;

  /// Change quand la selection change hors des cartes (retour de la
  /// recherche) : le groupe de cartes se reconstruit avec la nouvelle.
  int _revision = 0;

  @override
  void dispose() {
    _requete.dispose();
    super.dispose();
  }

  /// Les cartes : les choix courants, puis ceux de la selection qui n'en font
  /// pas partie.
  List<ElementChoix> get _cartes {
    final Set<String> courants = <String>{
      for (final ElementChoix e in widget.courants) e.code,
    };
    return <ElementChoix>[
      ...widget.courants,
      for (final ElementChoix e in widget.tous)
        if (widget.selection.contains(e.code) && !courants.contains(e.code)) e,
    ];
  }

  void _choisir(String code) {
    setState(() {
      _enRecherche = false;
      _requete.clear();
      _revision++;
    });
    widget.onChange(
      widget.multiple ? <String>{...widget.selection, code} : <String>{code},
    );
  }

  @override
  Widget build(BuildContext context) =>
      _enRecherche ? _recherche(context) : _cartesEtLien(context);

  Widget _cartesEtLien(BuildContext context) {
    final List<ElementChoix> cartes = _cartes;
    final Set<String> visibles = <String>{
      for (final ElementChoix e in cartes) e.code,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Le lien est avant les cartes : qui ne se retrouve pas dans la liste
        // courante n'a pas a la parcourir en entier.
        LienFleche(
          key: ChoixAvecRecherche.autreKey,
          libelle: widget.textes.autre,
          alignerEnDebut: true,
          onPress: () => setState(() => _enRecherche = true),
        ),
        Ecart.vMd,
        ChoiceCardGroup(
          key: ValueKey<String>('${widget.cle}-$_revision-${cartes.length}'),
          autoriserSaisieLibre: false,
          selectionMultiple: widget.multiple,
          valeurInitiale: ReponseChoix(
            valeurs: <String>{
              for (final String c in widget.selection)
                if (visibles.contains(c)) c,
            },
          ),
          options: <OptionChoix>[
            for (final ElementChoix e in cartes)
              OptionChoix(
                cle: e.cle,
                valeur: e.code,
                libelle: e.libelle,
                description: e.description,
                icone: widget.icone,
              ),
          ],
          onChange: (ReponseChoix r) => widget.onChange(r.valeurs),
        ),
      ],
    );
  }

  Widget _recherche(BuildContext context) {
    final String q = formeDeRecherche(_requete.text);
    final List<ElementChoix> trouves = <ElementChoix>[
      for (final ElementChoix e in widget.tous)
        if (q.isEmpty || formeDeRecherche(e.libelle).contains(q)) e,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        LienFleche(
          libelle: widget.textes.retour,
          alignerEnDebut: true,
          onPress: () => setState(() {
            _enRecherche = false;
            _requete.clear();
          }),
        ),
        Ecart.vMd,
        ChampRecherche(
          cleChamp: ChoixAvecRecherche.champKey,
          controleur: _requete,
          libelle: widget.textes.recherche,
          aide: widget.textes.aide,
          onChange: (String _) => setState(() {}),
        ),
        Ecart.vLg,
        if (trouves.isEmpty)
          Text(
            widget.textes.aucun,
            style: Theme.of(context).textTheme.bodyMedium,
          )
        else
          CarteLignes(
            lignes: <Widget>[
              for (final ElementChoix e in trouves)
                SettingRow(
                  key: ChoixAvecRecherche.ligneKey(e.code),
                  title: e.libelle,
                  description: e.description,
                  onPress: () => _choisir(e.code),
                ),
            ],
          ),
      ],
    );
  }
}
