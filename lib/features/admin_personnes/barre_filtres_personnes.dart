// PERSONNES-UNE-PAGE, etape (c) : la barre de recherche et de filtre de la
// page « Personnes ». Un seul geste : « Filtrer par », le type, puis la
// valeur ; le filtre pose est une puce qu'on retire ; « Tout effacer » ; un
// compteur (« 37 sur 563 »). Rien ne s'applique derriere une boite : seuls le
// compteur et les puces changent en haut.
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
    super.key,
  });

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
    final List<String> parts = code.split(':');
    if (parts.first == 't') {
      // Le type est choisi : le meme bouton rouvre sa liste sur les valeurs.
      setState(() => _type = parts[1]);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _menu.ouvrir();
        // La liste ouverte garde ses valeurs ; le bouton, lui, revient aux
        // types pour la prochaine fois (meme si on ferme sans choisir).
        setState(() => _type = null);
      });
      return;
    }
    widget.onFiltre(parts[1], parts[2]);
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
    final List<EntreeFiltre<String>> entrees = ouvert == null
        ? <EntreeFiltre<String>>[
            for (final TypeFiltrePersonnes x in widget.types)
              EntreeFiltre<String>(valeur: 't:${x.cle}', libelle: x.libelle),
          ]
        : <EntreeFiltre<String>>[
            for (final ValeurFiltre v in ouvert.valeurs)
              EntreeFiltre<String>(
                valeur: 'v:${ouvert.cle}:${v.code}',
                libelle: p.puce(type: ouvert.libelle, valeur: v.libelle),
              ),
          ];
    final List<FiltreActif> actifs = <FiltreActif>[
      for (final TypeFiltrePersonnes x in widget.types)
        if (x.libelleDe(widget.filtres[x.cle]) case final String valeur)
          FiltreActif(
            libelle: p.puce(type: x.libelle, valeur: valeur),
            onRetirer: () => widget.onFiltre(x.cle, null),
          ),
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
        if (empile) ...<Widget>[
          champ,
          Ecart.vSm,
          Align(alignment: AlignmentDirectional.centerStart, child: menu),
        ] else
          Row(
            children: <Widget>[
              Expanded(child: champ),
              Ecart.hSm,
              menu,
            ],
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
