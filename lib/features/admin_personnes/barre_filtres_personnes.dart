// PERSONNES-UNE-PAGE, etape (c) : la barre de recherche et de filtre de la
// page « Personnes ». Un seul geste : « Filtrer par », le type, puis la
// valeur ; le filtre pose est une puce qu'on retire ; « Tout effacer » ; un
// compteur (« 37 sur 563 »). Rien ne s'applique derriere une boite : seuls le
// compteur et les puces changent en haut.
//
// Etape (d) : quand les types ont une famille (les 26 filtres des candidats),
// le menu a trois niveaux : la famille, le type, la valeur (codes `f:`, `t:`,
// `v:`). Un type a plusieurs valeurs (les jours) ajoute ou retire la valeur
// touchee ; sa puce les dit toutes.
//
// Composants du core, sans copie : `ChampRecherche`, `MenuFiltre` (le meme
// bouton rouvre sa liste sur les valeurs du type choisi), `FiltresActifs`.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_mouvement.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/champ_recherche.dart';
import '../../core/widgets/menu_commun.dart';
import '../../core/widgets/menu_filtre.dart';
import '../../core/widgets/puce_filtre_actif.dart';
import 'filtres_personnes.dart';
import 'personnes_page.dart' show echelleMaxCoteACote;

/// La barre de recherche et de filtre.
class BarreFiltresPersonnes extends StatefulWidget {
  /// Cree la barre.
  const BarreFiltresPersonnes({
    required this.types,
    required this.filtres,
    required this.recherche,
    required this.onFiltre,
    required this.onRecherche,
    required this.onToutEffacer,
    this.affiches,
    this.total,
    this.tri,
    this.triActif,
    super.key,
  });

  /// Le bouton « Trier par » de la liste, ou `null`.
  final Widget? tri;

  /// Le tri pose, dit en puce comme un filtre (retirable), ou `null` :
  /// l'ordre par defaut.
  final FiltreActif? triActif;

  /// Les types de filtre de l'onglet ouvert.
  final List<TypeFiltrePersonnes> types;

  /// Les filtres poses : type vers valeur.
  final Map<String, String> filtres;

  /// La recherche en cours.
  final String recherche;

  /// Pose ([valeur] non nulle) ou retire ([valeur] nulle) un filtre.
  final void Function(String type, String? valeur) onFiltre;

  /// Le texte cherche a change.
  final ValueChanged<String> onRecherche;

  /// Retire tous les filtres et la recherche.
  final VoidCallback onToutEffacer;

  /// Le nombre de personnes affichees, ou `null` pendant la lecture.
  final int? affiches;

  /// Le nombre de personnes de l'onglet, sans filtre, ou `null`.
  final int? total;

  /// La cle du champ de recherche.
  static const Key cleRecherche = ValueKey<String>('personnes-recherche');

  /// La cle du bouton « Filtrer par ».
  static const Key cleFiltrer = ValueKey<String>('personnes-filtrer-par');

  /// La cle du compteur.
  static const Key cleCompteur = ValueKey<String>('personnes-compteur');

  /// En dessous de cette largeur, le champ, « Filtrer par » et « Trier par »
  /// ne tiennent plus sur une rangee.
  static const double _largeurUneRangee = 340;

  @override
  State<BarreFiltresPersonnes> createState() => _BarreFiltresPersonnesState();
}

class _BarreFiltresPersonnesState extends State<BarreFiltresPersonnes> {
  late final TextEditingController _saisie = TextEditingController(
    text: widget.recherche,
  );
  final MenuAncreControleur _menu = MenuAncreControleur();
  Timer? _attente;

  /// Le type dont le menu montre les valeurs, le temps de sa reouverture.
  String? _type;

  /// La famille dont le menu montre les types, le temps de sa reouverture.
  String? _famille;

  /// Rouvre le menu sur le niveau que [poser] vient de choisir.
  void _rouvrir(VoidCallback poser) {
    setState(poser);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _menu.ouvrir();
      // La liste ouverte garde son niveau ; le bouton, lui, revient au
      // premier niveau pour la prochaine fois (meme si on ferme sans choisir).
      setState(() {
        _type = null;
        _famille = null;
      });
    });
  }

  @override
  void didUpdateWidget(BarreFiltresPersonnes ancien) {
    super.didUpdateWidget(ancien);
    // L'adresse a change sans la saisie (« Tout effacer », autre onglet, lien).
    if (widget.recherche != ancien.recherche &&
        widget.recherche != _saisie.text.trim()) {
      _saisie.text = widget.recherche;
    }
  }

  @override
  void dispose() {
    _attente?.cancel();
    _saisie.dispose();
    super.dispose();
  }

  void _chercher(String texte) {
    _attente?.cancel();
    _attente = Timer(AppMouvement.delaiFrappe, () {
      if (mounted) widget.onRecherche(texte.trim());
    });
  }

  void _choisir(String? code) {
    if (code == null) return;
    final int coupe = code.indexOf(':');
    final String niveau = code.substring(0, coupe);
    final String reste = code.substring(coupe + 1);
    if (niveau == 'f') {
      // La famille est choisie : le meme bouton rouvre sa liste sur ses types.
      _rouvrir(() => _famille = reste);
      return;
    }
    if (niveau == 't') {
      // Le type est choisi : le meme bouton rouvre sa liste sur les valeurs.
      _rouvrir(() => _type = reste);
      return;
    }
    final int coupeValeur = reste.indexOf(':');
    final String cle = reste.substring(0, coupeValeur);
    final String valeur = reste.substring(coupeValeur + 1);
    final TypeFiltrePersonnes? type = widget.types
        .where((TypeFiltrePersonnes x) => x.cle == cle)
        .firstOrNull;
    if (type == null) return;
    widget.onFiltre(cle, type.apresChoix(widget.filtres[cle], valeur));
  }

  @override
  Widget build(BuildContext context) {
    final p = t.admin.personnesPage;
    final AppPalette palette = AppPalette.of(context);
    final TextStyle corps =
        Theme.of(context).textTheme.bodyLarge ?? const TextStyle();
    final TypeFiltrePersonnes? ouvert = widget.types
        .where((TypeFiltrePersonnes x) => x.cle == _type)
        .firstOrNull;
    // Les familles, dans l'ordre de leur premier type ; aucune : deux niveaux.
    final List<String> familles = <String>{
      for (final TypeFiltrePersonnes x in widget.types)
        if (x.famille case final String f) f,
    }.toList(growable: false);
    final List<EntreeFiltre<String>> entrees = ouvert != null
        ? <EntreeFiltre<String>>[
            for (final ValeurFiltre v in ouvert.valeurs)
              EntreeFiltre<String>(
                valeur: 'v:${ouvert.cle}:${v.code}',
                libelle: p.puce(type: ouvert.libelle, valeur: v.libelle),
              ),
          ]
        : _famille == null && familles.isNotEmpty
        ? <EntreeFiltre<String>>[
            for (final String f in familles)
              EntreeFiltre<String>(valeur: 'f:$f', libelle: f),
          ]
        : <EntreeFiltre<String>>[
            for (final TypeFiltrePersonnes x in widget.types)
              if (_famille == null || x.famille == _famille)
                EntreeFiltre<String>(valeur: 't:${x.cle}', libelle: x.libelle),
          ];
    final List<FiltreActif> actifs = <FiltreActif>[
      for (final TypeFiltrePersonnes x in widget.types)
        if (x.libelleDe(widget.filtres[x.cle]) case final String valeur)
          FiltreActif(
            libelle: p.puce(type: x.libelle, valeur: valeur),
            onRetirer: () => widget.onFiltre(x.cle, null),
          ),
      ?widget.triActif,
    ];
    final int? n = widget.affiches;
    final int? total = widget.total;
    // Texte agrandi : le champ puis le bouton, l'un sous l'autre (a 200 %,
    // cote a cote, ils debordent d'un telephone).
    final bool empile =
        MediaQuery.textScalerOf(context).scale(1) > echelleMaxCoteACote;
    final Widget champ = ChampRecherche(
      controleur: _saisie,
      libelle: p.rechercher,
      aide: t.admin.comptes.rechercheAide,
      cleChamp: BarreFiltresPersonnes.cleRecherche,
      compact: true,
      onChange: _chercher,
      onValider: (String texte) {
        _attente?.cancel();
        widget.onRecherche(texte.trim());
      },
    );
    final Widget menu = MenuFiltre<String>(
      key: BarreFiltresPersonnes.cleFiltrer,
      controleur: _menu,
      libelle: p.filtrerPar,
      valeur: null,
      entrees: entrees,
      onChoix: _choisir,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Le champ, « Filtrer par » et « Trier par » sur une rangee ; texte
        // agrandi ou largeur trop courte pour les trois (320 points) : le
        // champ, puis les deux boutons dessous.
        LayoutBuilder(
          builder: (BuildContext _, BoxConstraints c) {
            final Widget? tri = widget.tri;
            final bool dessous =
                empile ||
                (tri != null &&
                    c.maxWidth < BarreFiltresPersonnes._largeurUneRangee);
            if (!dessous) {
              return Row(
                children: <Widget>[
                  Expanded(child: champ),
                  if (widget.types.isNotEmpty) ...<Widget>[Ecart.hSm, menu],
                  if (tri != null) ...<Widget>[Ecart.hSm, tri],
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                champ,
                // Une vue sans type de filtre n'a pas de bouton « Filtrer
                // par ».
                if (widget.types.isNotEmpty || tri != null) ...<Widget>[
                  Ecart.vSm,
                  Row(
                    children: <Widget>[
                      if (widget.types.isNotEmpty) Flexible(child: menu),
                      if (widget.types.isNotEmpty && tri != null) Ecart.hSm,
                      ?tri,
                    ],
                  ),
                ],
              ],
            );
          },
        ),
        Ecart.vSm,
        // Le compteur dit ce qui a change : a la taille du texte courant,
        // toujours a la meme place (sous la recherche, avant les puces), meme
        // pendant la lecture. La liste ne saute pas.
        Semantics(
          liveRegion: true,
          label: n == null || total == null
              ? null
              : p.compteurLu(n: n, total: total),
          child: ExcludeSemantics(
            child: Text(
              n == null || total == null ? ' ' : p.compteur(n: n, total: total),
              key: BarreFiltresPersonnes.cleCompteur,
              style: palette.inkStrong.applyTo(corps),
            ),
          ),
        ),
        if (actifs.isNotEmpty) ...<Widget>[
          Ecart.vSm,
          FiltresActifs(filtres: actifs, onToutEffacer: widget.onToutEffacer),
        ],
        Ecart.vSm,
      ],
    );
  }
}
