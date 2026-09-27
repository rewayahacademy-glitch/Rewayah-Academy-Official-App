import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// La sous-navigation d'un domaine admin qui a plusieurs fonctions pairs.
///
/// **Premier domaine a en avoir besoin : Pedagogie**, avec ses cinq
/// fonctions (Diagnostics, Progression, Evaluations, Programmes, Qualite).
/// Operations, Personnes et Securite et audit n'en ont que deux ou trois,
/// atteintes depuis l'Accueil sans chrome de sous-navigation -- voir
/// `docs/archive/2026-09-pre-remise-a-plat/architecture/ADMIN_IA_AUDIT.md`. Ce composant reste generique pour
/// qu'un futur domaine avec plusieurs fonctions pairs le reutilise sans en
/// ecrire un second.
///
/// Se pose dans `PageShell.entete` -- « ce qui suit immediatement le titre
/// et ne defile pas » -- meme emplacement que le `TabBar` de
/// `features/creneaux/creneaux_page.dart`. A la difference de cet ecran,
/// chaque onglet ici est une **route distincte**, pas un panneau local : le
/// `TabController` ne sert qu'a l'indicateur visuel, la navigation passe par
/// `GoRouter`, meme mecanique que `_CoquilleAdmin.aller()`
/// (`core/router/app_router.dart`).
class SousNavigationDomaine extends StatefulWidget {
  /// Cree la sous-navigation.
  const SousNavigationDomaine({
    required this.onglets,
    required this.indexActif,
    super.key,
  });

  /// Les fonctions du domaine, dans l'ordre d'affichage impose.
  final List<({String libelle, String chemin})> onglets;

  /// L'index de l'ecran courant dans [onglets].
  final int indexActif;

  @override
  State<SousNavigationDomaine> createState() => _SousNavigationDomaineEtat();
}

class _SousNavigationDomaineEtat extends State<SousNavigationDomaine>
    with TickerProviderStateMixin {
  late TabController _controleur = _nouveau();

  TabController _nouveau() => TabController(
    length: widget.onglets.length,
    initialIndex: widget.indexActif,
    vsync: this,
  );

  /// Un onglet peut apparaitre apres coup (AD-9 : l'onglet de la politique
  /// n'existe qu'une fois la capacite lue) : le controleur suit le nombre.
  @override
  void didUpdateWidget(SousNavigationDomaine ancien) {
    super.didUpdateWidget(ancien);
    if (ancien.onglets.length != widget.onglets.length ||
        ancien.indexActif != widget.indexActif) {
      _controleur.dispose();
      _controleur = _nouveau();
    }
  }

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_suivreLeFocus);
  }

  /// Critere AD-11 « focus jamais masque » : la barre centre l'onglet actif,
  /// et Tab pouvait laisser un autre onglet hors de la vue. Quand le focus
  /// clavier entre sur un onglet, seule la barre defile pour le montrer,
  /// jamais la page. Rendu inchange.
  void _suivreLeFocus() {
    final BuildContext? cible = FocusManager.instance.primaryFocus?.context;
    if (cible == null || !mounted) return;
    bool dansLaBarre = false;
    cible.visitAncestorElements((Element a) {
      dansLaBarre = identical(a, context);
      return !dansLaBarre;
    });
    if (!dansLaBarre) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !cible.mounted) return;
      final RenderObject? onglet = cible.findRenderObject();
      final ScrollableState? barre = Scrollable.maybeOf(cible);
      if (onglet == null || barre == null) return;
      barre.position.ensureVisible(onglet, alignment: 0.5);
    });
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_suivreLeFocus);
    _controleur.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: _controleur,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      tabs: <Widget>[
        for (final ({String libelle, String chemin}) onglet in widget.onglets)
          Tab(text: onglet.libelle),
      ],
      onTap: (int index) {
        if (index == widget.indexActif) return;
        GoRouter.of(context).go(widget.onglets[index].chemin);
      },
    );
  }
}
