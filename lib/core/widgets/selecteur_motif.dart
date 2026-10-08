import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import '../i18n/strings.g.dart';
import '../theme/app_metriques.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import 'filter_pill.dart';

/// Le choix d'un motif dans une rangee de puces, « Autre » en dernier
/// (FORM-L1, K-57 : proposer avant de faire saisir).
///
/// Remplace les champs « motif » tapes au clavier des formulaires. Quatre
/// regles :
///
///   * **le motif reste une chaine** : la puce choisie ecrit son texte tel
///     quel dans [controleur], et c'est lui que l'appelant envoie a la RPC,
///     exactement comme avant. Aucun contrat serveur ne change ;
///   * **« Autre » ouvre la saisie libre**, et seulement lui. Tant que le
///     champ est vide, [controleur] est vide : l'appelant voit qu'il manque
///     le motif et le dit (bouton jamais grise, K-56) ;
///   * **les puces ont la meme hauteur sur une rangee**, la rangee passe a la
///     ligne, une puce longue passe a la ligne a l'interieur d'elle-meme et ne
///     deborde jamais (K-54) ;
///   * **une valeur deja presente** dans [controleur] (motif conserve, valeur
///     courante) est reconnue : la puce correspondante est retenue, sinon
///     « Autre » s'ouvre avec ce texte.
///
/// Sans motif propose ([motifs] vide), le champ libre s'affiche seul, y
/// compris quand la liste devient vide en cours de route (categorie « Autre »
/// d'un signalement).
///
/// Le focus : [SelecteurMotifEtat.focaliser] le pose dans la zone du motif,
/// sur la premiere puce, ou dans le champ libre quand « Autre » est ouvert ;
/// [autofocus] le fait des la premiere image.
class SelecteurMotif extends StatefulWidget {
  /// Cree le selecteur.
  const SelecteurMotif({
    required this.motifs,
    required this.controleur,
    super.key,
    this.onChange,
    this.libelleChamp,
    this.aide,
    this.erreur,
    this.focusNode,
    this.lectureSeule = false,
    this.autofocus = false,
    this.lignesMin = 1,
    this.lignesMax = 3,
    this.cleChampLibre,
  });

  /// Les motifs proposes, deja traduits, dans l'ordre d'affichage.
  final List<String> motifs;

  /// Porte le motif retenu : le texte de la puce, ou celui du champ libre.
  final TextEditingController controleur;

  /// Appele a chaque changement du motif retenu.
  final ValueChanged<String>? onChange;

  /// Le libelle du champ libre ; a defaut, « Le motif, en quelques mots ».
  final String? libelleChamp;

  /// Une aide sous le champ libre.
  final String? aide;

  /// Le message de l'appelant quand le motif manque. Si « Autre » est retenu,
  /// le selecteur le precise : c'est le champ libre qu'il faut remplir.
  final String? erreur;

  /// Le noeud de focus du champ libre.
  final FocusNode? focusNode;

  /// Vrai pendant un envoi : rien ne change, le motif envoye reste lisible.
  final bool lectureSeule;

  /// Vrai pour poser le focus dans la zone du motif a l'ouverture
  /// ([SelecteurMotifEtat.focaliser]).
  final bool autofocus;

  /// Nombre minimal de lignes du champ libre.
  final int lignesMin;

  /// Nombre maximal de lignes du champ libre.
  final int lignesMax;

  /// Une cle posee sur le champ libre, pour les tests.
  final Key? cleChampLibre;

  /// La cle de la puce « Autre ».
  static const Key cleAutre = ValueKey<String>('selecteur-motif-autre');

  /// La cle de la puce d'indice [indice].
  static Key clePuce(int indice) => ValueKey<String>('selecteur-motif-$indice');

  /// Le libelle de debogage du noeud de focus de la premiere puce.
  static const String focusPremierePuce = 'selecteur-motif-premiere-puce';

  @override
  State<SelecteurMotif> createState() => SelecteurMotifEtat();
}

/// L'etat de [SelecteurMotif], public pour [focaliser].
class SelecteurMotifEtat extends State<SelecteurMotif> {
  /// L'indice de la puce retenue ; [_autre] pour « Autre », nul sinon.
  int? _retenue;
  static const int _autre = -1;
  final TextEditingController _libre = TextEditingController();
  FocusNode? _focusInterne;
  final FocusNode _focusPuce = FocusNode(
    debugLabel: SelecteurMotif.focusPremierePuce,
  );
  String _ecrit = '';

  FocusNode get _focus =>
      widget.focusNode ?? (_focusInterne ??= FocusNode(debugLabel: 'motif'));

  bool get _sansPuce => widget.motifs.isEmpty;

  @override
  void initState() {
    super.initState();
    _synchroniser();
    widget.controleur.addListener(_surControleur);
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((Duration _) {
        if (mounted) focaliser();
      });
    }
  }

  /// Pose le focus dans la zone du motif : le champ libre si « Autre » est
  /// ouvert (ou s'il n'y a aucune puce), la premiere puce sinon.
  void focaliser() {
    if (_retenue == _autre) {
      _focus.requestFocus();
    } else {
      _focusPuce.requestFocus();
    }
  }

  @override
  void didUpdateWidget(SelecteurMotif oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controleur != widget.controleur) {
      oldWidget.controleur.removeListener(_surControleur);
      widget.controleur.addListener(_surControleur);
      _synchroniser();
    } else if (!listEquals(oldWidget.motifs, widget.motifs)) {
      // La liste a change (une autre categorie) : la puce retenue se relit
      // dans la nouvelle liste ; une liste vide ouvre le champ libre seul. Un
      // « Autre » choisi parmi des puces reste ouvert.
      final bool autreOuvert = _retenue == _autre && oldWidget.motifs.isNotEmpty;
      _synchroniser();
      if (autreOuvert && _retenue == null) _retenue = _autre;
    }
  }

  @override
  void dispose() {
    widget.controleur.removeListener(_surControleur);
    _libre.dispose();
    _focusInterne?.dispose();
    _focusPuce.dispose();
    super.dispose();
  }

  /// Relit [SelecteurMotif.controleur] quand un autre que nous l'a change
  /// (remise a zero apres envoi, abandon).
  void _surControleur() {
    if (widget.controleur.text == _ecrit) return;
    setState(_synchroniser);
  }

  void _synchroniser() {
    final String texte = widget.controleur.text;
    _ecrit = texte;
    final int indice = widget.motifs.indexOf(texte);
    if (texte.isEmpty) {
      _retenue = _sansPuce ? _autre : null;
      _libre.text = '';
    } else if (indice >= 0) {
      _retenue = indice;
    } else {
      _retenue = _autre;
      _libre.text = texte;
    }
  }

  void _ecrire(String motif) {
    _ecrit = motif;
    widget.controleur.text = motif;
    widget.onChange?.call(motif);
  }

  void _choisir(int indice) {
    if (widget.lectureSeule) return;
    setState(() => _retenue = indice);
    if (indice == _autre) {
      _ecrire(_libre.text.trim());
      WidgetsBinding.instance.addPostFrameCallback((Duration _) {
        if (mounted) _focus.requestFocus();
      });
    } else {
      _ecrire(widget.motifs[indice]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool autre = _retenue == _autre;
    final bool autreVide = autre && _libre.text.trim().isEmpty;
    final String? erreur = widget.erreur;
    final TextStyle styleErreur = AppPalette.of(context).inkAlert
        .applyTo(Theme.of(context).textTheme.bodyMedium ?? const TextStyle());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (!_sansPuce)
          RangeePuces(
            libelles: <String>[...widget.motifs, t.choix.autre],
            cles: <Key>[
              for (int i = 0; i < widget.motifs.length; i++)
                SelecteurMotif.clePuce(i),
              SelecteurMotif.cleAutre,
            ],
            focusPremiere: _focusPuce,
            retenue: switch (_retenue) {
              null => null,
              _autre => widget.motifs.length,
              final int i => i,
            },
            onChoix: (int i) =>
                _choisir(i == widget.motifs.length ? _autre : i),
          ),
        // L'aide se lit des l'ouverture : sous les puces tant que le champ
        // libre est ferme, puis sous le champ.
        if (!autre && widget.aide != null) ...<Widget>[
          Ecart.vSm,
          Text(
            widget.aide!,
            style: AppPalette.of(context).inkMuted.applyTo(
              Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
            ),
          ),
        ],
        if (autre) ...<Widget>[
          if (!_sansPuce) Ecart.vMd,
          TextField(
            key: widget.cleChampLibre,
            controller: _libre,
            focusNode: _focus,
            readOnly: widget.lectureSeule,
            minLines: widget.lignesMin,
            maxLines: math.max(widget.lignesMin, widget.lignesMax),
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            onChanged: (String v) => setState(() => _ecrire(v.trim())),
            decoration: InputDecoration(
              // AD-11 (1.4.4) : un `label` texte passe a la ligne en texte
              // agrandi, la ou `labelText` se coupe en ellipse.
              label: Text(widget.libelleChamp ?? t.formulaire.motif.autreChamp),
              helperText: widget.aide,
              helperMaxLines: 8,
              // Sans puce, il n'y a pas de « Autre » a rappeler : le message
              // de l'appelant s'affiche tel quel sous le champ.
              errorText: erreur != null && autreVide
                  ? (_sansPuce ? erreur : t.formulaire.motif.autreVide)
                  : null,
              errorMaxLines: 4,
            ),
          ),
        ],
        if (erreur != null && !autreVide) ...<Widget>[
          Ecart.vSm,
          Semantics(liveRegion: true, child: Text(erreur, style: styleErreur)),
        ],
      ],
    );
  }
}

/// Le choix d'un entier parmi des valeurs proposees, « Autre » ouvrant une
/// saisie libre (FORM-L13).
///
/// Meme rangee que [SelecteurMotif]. Les puces ne sont que des raccourcis :
/// sans [max], « Autre » accepte tout entier a partir de [min]. « Autre »
/// disparait quand les valeurs proposees couvrent deja tout l'intervalle
/// [min]..[max] : il n'y aurait rien d'autre a saisir.
class SelecteurEntier extends StatefulWidget {
  /// Cree le selecteur.
  const SelecteurEntier({
    required this.proposees,
    required this.affichage,
    required this.valeurInitiale,
    required this.onChange,
    super.key,
    this.min = 0,
    this.max,
    this.libelleChamp,
    this.erreur,
  });

  /// Les valeurs proposees, dans l'ordre d'affichage.
  final List<int> proposees;

  /// La plus petite valeur acceptee (0 par defaut).
  final int min;

  /// La plus grande valeur acceptee ; nul : aucun plafond.
  final int? max;

  /// Formate une valeur (unite comprise).
  final String Function(int valeur) affichage;

  /// La valeur courante, retenue d'office.
  final int? valeurInitiale;

  /// Appele a chaque changement : la valeur, ou nul quand la saisie libre est
  /// vide ou n'est pas un entier.
  final ValueChanged<int?> onChange;

  /// Le libelle du champ libre.
  final String? libelleChamp;

  /// Le message d'erreur de l'appelant, sous le selecteur.
  final String? erreur;

  /// La cle de la puce « Autre ».
  static const Key cleAutre = ValueKey<String>('selecteur-entier-autre');

  /// La cle du champ libre.
  static const Key cleChamp = ValueKey<String>('selecteur-entier-champ');

  /// La cle de la puce de la valeur [valeur].
  static Key clePuce(int valeur) =>
      ValueKey<String>('selecteur-entier-$valeur');

  /// Vrai quand les valeurs proposees couvrent tout l'intervalle.
  bool get toutPropose {
    final int? max = this.max;
    if (max == null) return false;
    for (int v = min; v <= max; v++) {
      if (!proposees.contains(v)) return false;
    }
    return true;
  }

  @override
  State<SelecteurEntier> createState() => _SelecteurEntierEtat();
}

class _SelecteurEntierEtat extends State<SelecteurEntier> {
  int? _retenue;
  late final TextEditingController _libre = TextEditingController();
  final FocusNode _focus = FocusNode(debugLabel: 'entier');

  @override
  void initState() {
    super.initState();
    final int? v = widget.valeurInitiale;
    if (v != null) {
      final int i = widget.proposees.indexOf(v);
      if (i >= 0) {
        _retenue = i;
      } else if (!widget.toutPropose) {
        _retenue = widget.proposees.length;
        _libre.text = '$v';
      }
    }
  }

  @override
  void dispose() {
    _libre.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _choisir(int indice) {
    setState(() => _retenue = indice);
    if (indice == widget.proposees.length) {
      widget.onChange(int.tryParse(_libre.text.trim()));
      WidgetsBinding.instance.addPostFrameCallback((Duration _) {
        if (mounted) _focus.requestFocus();
      });
    } else {
      widget.onChange(widget.proposees[indice]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool avecAutre = !widget.toutPropose;
    final bool autre = _retenue == widget.proposees.length;
    final String? erreur = widget.erreur;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        RangeePuces(
          libelles: <String>[
            for (final int v in widget.proposees) widget.affichage(v),
            if (avecAutre) t.choix.autre,
          ],
          cles: <Key>[
            for (final int v in widget.proposees) SelecteurEntier.clePuce(v),
            if (avecAutre) SelecteurEntier.cleAutre,
          ],
          retenue: _retenue,
          onChoix: _choisir,
        ),
        if (autre) ...<Widget>[
          Ecart.vMd,
          TextField(
            key: SelecteurEntier.cleChamp,
            controller: _libre,
            focusNode: _focus,
            keyboardType: TextInputType.number,
            onChanged: (String v) => widget.onChange(int.tryParse(v.trim())),
            decoration: InputDecoration(
              label: Text(widget.libelleChamp ?? t.choix.autreInvite),
              // Le rappel des bornes, seulement quand il y a un plafond.
              helperText: switch (widget.max) {
                final int max => t.formulaire.entier.bornes(
                  min: '${widget.min}',
                  max: '$max',
                ),
                null => null,
              },
              helperMaxLines: 4,
            ),
          ),
        ],
        if (erreur != null) ...<Widget>[
          Ecart.vSm,
          Semantics(
            liveRegion: true,
            child: Text(
              erreur,
              style: AppPalette.of(context).inkAlert.applyTo(
                Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Une rangee de puces a choix unique, qui passe a la ligne, **toutes les
/// puces d'une meme ligne a la meme hauteur** (K-54).
///
/// Chaque puce est mesuree avant d'etre posee : sa largeur naturelle, bornee
/// par la largeur disponible (une puce trop longue passe a la ligne en
/// elle-meme), puis sa hauteur a cette largeur. Les puces sont reparties en
/// lignes comme le ferait un `Wrap`, et chaque ligne prend la hauteur de sa
/// plus haute puce, jamais moins que la cible tactile.
class RangeePuces extends StatelessWidget {
  /// Cree la rangee.
  const RangeePuces({
    required this.libelles,
    required this.retenue,
    required this.onChoix,
    super.key,
    this.cles,
    this.focusPremiere,
  });

  /// Les libelles, dans l'ordre.
  final List<String> libelles;

  /// L'indice retenu, ou nul.
  final int? retenue;

  /// Appele avec l'indice touche.
  final ValueChanged<int> onChoix;

  /// Une cle par puce, facultative.
  final List<Key>? cles;

  /// Le noeud de focus de la premiere puce, pour y ramener le clavier.
  final FocusNode? focusPremiere;

  /// L'ecart entre deux puces, en largeur comme en hauteur.
  static const double ecart = AppSpacing.sm;

  @override
  Widget build(BuildContext context) {
    final TextStyle style =
        Theme.of(context).textTheme.labelLarge ?? const TextStyle();
    final TextScaler echelle = MediaQuery.textScalerOf(context);
    final TextDirection sens = Directionality.of(context);
    final double cible = AppMetriques.of(context).cibleTactile;
    // Le retrait interieur de `FilterPill`.
    const double retraitLargeur = AppSpacing.lg * 2;
    const double retraitHauteur = AppSpacing.sm * 2;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints contraintes) {
        final double disponible = contraintes.maxWidth.isFinite
            ? contraintes.maxWidth
            : 600;
        final List<Size> tailles = <Size>[
          for (final String libelle in libelles)
            _mesurer(
              libelle,
              style: style,
              echelle: echelle,
              sens: sens,
              largeurMax: disponible,
              retraitLargeur: retraitLargeur,
              retraitHauteur: retraitHauteur,
            ),
        ];

        // Repartition en lignes, a la maniere d'un `Wrap`.
        final List<List<int>> lignes = <List<int>>[];
        double x = 0;
        for (int i = 0; i < tailles.length; i++) {
          final double w = tailles[i].width;
          if (lignes.isEmpty || (x > 0 && x + ecart + w > disponible)) {
            lignes.add(<int>[i]);
            x = w;
          } else {
            lignes.last.add(i);
            x += ecart + w;
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (int l = 0; l < lignes.length; l++) ...<Widget>[
              if (l > 0) const SizedBox(height: ecart),
              _ligne(lignes[l], tailles, cible),
            ],
          ],
        );
      },
    );
  }

  Widget _ligne(List<int> indices, List<Size> tailles, double cible) {
    final double hauteur = indices
        .map((int i) => tailles[i].height)
        .fold(cible, math.max);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int k = 0; k < indices.length; k++) ...<Widget>[
          if (k > 0) const SizedBox(width: ecart),
          SizedBox(
            key: cles?[indices[k]],
            width: tailles[indices[k]].width,
            height: hauteur,
            child: FilterPill(
              libelle: libelles[indices[k]],
              retenue: retenue == indices[k],
              focusNode: indices[k] == 0 ? focusPremiere : null,
              onPress: () => onChoix(indices[k]),
            ),
          ),
        ],
      ],
    );
  }

  static Size _mesurer(
    String libelle, {
    required TextStyle style,
    required TextScaler echelle,
    required TextDirection sens,
    required double largeurMax,
    required double retraitLargeur,
    required double retraitHauteur,
  }) {
    final TextPainter peintre = TextPainter(
      text: TextSpan(text: libelle, style: style),
      textDirection: sens,
      textScaler: echelle,
      textAlign: TextAlign.center,
    )..layout(maxWidth: math.max(0, largeurMax - retraitLargeur));
    // Un pixel de marge : l'arrondi du rendu ne doit pas faire passer a la
    // ligne un libelle mesure sur une seule.
    final double largeur = math.min(
      largeurMax,
      peintre.width.ceilToDouble() + retraitLargeur + 1,
    );
    final double hauteur = peintre.height.ceilToDouble() + retraitHauteur;
    peintre.dispose();
    return Size(largeur, hauteur);
  }
}
