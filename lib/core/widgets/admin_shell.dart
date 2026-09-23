import 'dart:async';

import 'package:flutter/material.dart';

import '../admin/admin_domaine.dart';
import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../theme/app_gabarit.dart';
import '../theme/app_metriques.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'app_bottom_sheet.dart';
import 'empty_state.dart';
import 'pressable.dart';

/// La coquille de navigation du panneau admin : huit domaines, jamais plus
/// granulaire (gel d'architecture, `docs/archive/2026-09-pre-remise-a-plat/architecture/ADMIN_IA_AUDIT.md`).
///
/// **Distincte de `NavShell`**, qui plafonne a quatre destinations pour les
/// autres roles (`03-architecture-information.md` section 5) -- une limite
/// pensee pour le MVP. L'operateur a tranche que le panneau admin grandira
/// avec un RBAC a plusieurs roles, et qu'une barre a quatre entrees n'y
/// suffit plus. La regle qui reste absolue n'est plus « quatre » mais
/// « jamais plus granulaire que les huit domaines eux-memes » -- voir
/// [maxDomaines], qui la tient par un `assert` vivant, pas par une relecture.
///
/// **Un domaine sans fonction livree reste visible mais inerte** : l'audit
/// interdit explicitement de construire un ecran vide pour remplir le
/// chrome (`AdminDomaine.chemin` est alors nul). Le libelle et l'icone sont
/// rendus attenues, et un tap n'y declenche aucune navigation -- le meme
/// traitement qu'un compteur d'`ADM-01` sans destination, jamais un bouton
/// grise qui mentirait sur ce que la personne peut obtenir.
///
/// Trois formes, une seule liste de domaines : tiroir sous 600, rail replie
/// de 600 a 1199, barre laterale permanente a partir de 1200. **Jamais de
/// barre basse ici** : la mission l'interdit explicitement pour l'admin,
/// huit domaines n'y tiendraient pas.
///
/// Porte aussi la barre superieure (recherche, notifications, compte) : elle
/// ne contient que ces trois elements generiques, jamais un reglage, un
/// eleve, un groupe ou un bouton metier isole.
class AdminShell extends StatelessWidget {
  /// Cree la coquille admin.
  ///
  /// **Volontairement non `const`**, meme raison que `NavShell` : l'assertion
  /// porte sur la longueur d'une liste, qui n'est pas une expression
  /// constante.
  // ignore: prefer_const_constructors_in_immutables
  AdminShell({
    required this.domaines,
    required this.domaineActif,
    required this.onAller,
    required this.onCompte,
    required this.child,
    super.key,
  }) : assert(
         domaines.length <= maxDomaines,
         'La sidebar admin ne contient jamais plus de $maxDomaines domaines '
         '(gel d\'architecture, regle absolue).',
       );

  /// Les domaines visibles, dans l'ordre impose.
  final List<AdminDomaine> domaines;

  /// Le domaine actif, pour le surligner.
  final AdminDomaine? domaineActif;

  /// Ce qui se passe quand un domaine actif ou un resultat de recherche est
  /// choisi. Recoit une route, jamais un domaine : la recherche peut mener a
  /// un ecran qu'aucun libelle de domaine ne nomme.
  final void Function(String chemin) onAller;

  /// Ouvre « Mon compte », partage par tous les roles.
  final VoidCallback onCompte;

  /// L'ecran affiche.
  final Widget child;

  /// Le nombre maximal de domaines. **Huit, pas quatre** : la regle du gel
  /// d'architecture, distincte de `NavShell.maxDestinations`.
  static const int maxDomaines = 8;

  /// Cles stables pour verifier les trois presentations adaptatives.
  static const Key tiroirKey = ValueKey<String>('admin-shell-tiroir');
  static const Key railKey = ValueKey<String>('admin-shell-rail');
  static const Key barreLateraleKey = ValueKey<String>(
    'admin-shell-barre-laterale',
  );

  /// Largeur de la barre laterale permanente.
  ///
  /// **Plus large que `AppGabarit.largeurBarreLaterale` (256)**, et
  /// volontairement independante de ce jeton partage par les quatre autres
  /// roles : leurs libelles tiennent en un mot (« Journee », « Profil »), les
  /// huit domaines admin comptent plusieurs libelles a deux ou trois mots
  /// (« Sécurité et audit », « Configuration »), qui debordent a 256. Poser
  /// ici une largeur propre a `AdminShell` evite d'elargir la barre des
  /// quatre autres roles pour un besoin qui n'est que le sien.
  static const double largeurBarreLaterale = 288;

  @override
  Widget build(BuildContext context) {
    final int trouve = domaineActif == null
        ? -1
        : domaines.indexOf(domaineActif!);
    final int? actif = trouve == -1 ? null : trouve;

    final ChromeNavigation chrome = AppGabarit.de(context).chrome;

    void choisir(int index) {
      final String? chemin = domaines[index].chemin;
      // Un domaine inerte ne navigue nulle part : construire un ecran vide
      // pour l'occasion est exactement ce que l'audit interdit.
      if (chemin != null) {
        onAller(chemin);
      }
    }

    // **Un seul `Scaffold`, quel que soit le gabarit.** `_BarreSuperieure`
    // porte un `TextField`, qui exige un ancetre `Material` -- absent d'un
    // simple `Row`. Le mobile a de toute facon besoin d'un `Scaffold` pour
    // son tiroir ouvrable.
    return Scaffold(
      drawer: chrome == ChromeNavigation.barreBasse
          ? _Tiroir(domaines: domaines, indexActif: actif, onChoisir: choisir)
          : null,
      body: switch (chrome) {
        ChromeNavigation.barreBasse => Column(
          children: <Widget>[
            _BarreSuperieure(
              avecTiroir: true,
              onRecherche: onAller,
              onCompte: onCompte,
            ),
            Expanded(child: child),
          ],
        ),
        ChromeNavigation.rail => Row(
          children: <Widget>[
            _Rail(domaines: domaines, indexActif: actif, onChoisir: choisir),
            Expanded(
              child: Column(
                children: <Widget>[
                  _BarreSuperieure(
                    avecTiroir: false,
                    onRecherche: onAller,
                    onCompte: onCompte,
                  ),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
        ChromeNavigation.barreLaterale => Row(
          children: <Widget>[
            _Sidebar(
              domaines: domaines,
              indexActif: actif,
              onChoisir: choisir,
            ),
            Expanded(
              child: Column(
                children: <Widget>[
                  _BarreSuperieure(
                    avecTiroir: false,
                    onRecherche: onAller,
                    onCompte: onCompte,
                  ),
                  // Un panneau contextuel pourra prendre place ici, a droite
                  // du contenu, le jour ou un ecran en aura besoin. Rien n'en
                  // a besoin aujourd'hui : ce commentaire tient la place, pas
                  // un widget vide.
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
      },
    );
  }
}

/// Une entree de navigation, libelle sur une seule ligne, jamais debordant.
///
/// Attenuee quand le domaine est inerte (aucune fonction livree) : ni gris de
/// bouton desactive, ni ecran vide derriere -- juste une encre plus discrete
/// pour dire « pas encore », comme un compteur d'`ADM-01` sans destination.
Widget _libelleEntree(AppPalette palette, AdminDomaine domaine) => Text(
  domaine.libelle,
  overflow: TextOverflow.ellipsis,
  maxLines: 1,
  softWrap: false,
  style: domaine.actif
      ? null
      : TextStyle(color: palette.inkFaint.asBorderSide().color),
);

Widget _iconeEntree(
  AppPalette palette,
  AdminDomaine domaine, {
  required bool selectionnee,
}) {
  final Color? couleur = domaine.actif
      ? null
      : palette.inkFaint.asBorderSide().color;
  return Icon(
    selectionnee ? domaine.icone.actif : domaine.icone.repos,
    color: couleur,
  );
}

/// Le tiroir mobile : les huit domaines, dans une vraie modale ouvrable.
class _Tiroir extends StatelessWidget {
  const _Tiroir({
    required this.domaines,
    required this.indexActif,
    required this.onChoisir,
  });

  final List<AdminDomaine> domaines;
  final int? indexActif;
  final void Function(int index) onChoisir;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return NavigationDrawerTheme(
      data: NavigationDrawerThemeData(
        labelTextStyle: _stylesLibelleNav(context, palette),
        iconTheme: _stylesIconeNav(palette),
      ),
      child: NavigationDrawer(
        key: AdminShell.tiroirKey,
        selectedIndex: indexActif,
        backgroundColor: palette.surfaceRaised.background,
        indicatorColor: palette.washAccent.background,
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: AppRadius.arrondiSm,
        ),
        onDestinationSelected: (int index) {
          Navigator.of(context).pop();
          onChoisir(index);
        },
        children: <Widget>[
          for (final AdminDomaine domaine in domaines)
            NavigationDrawerDestination(
              icon: _iconeEntree(palette, domaine, selectionnee: false),
              selectedIcon: _iconeEntree(palette, domaine, selectionnee: true),
              label: _libelleEntree(palette, domaine),
            ),
        ],
      ),
    );
  }
}

/// Le rail replie, de 600 a 1199 : icone et libelle court.
class _Rail extends StatelessWidget {
  const _Rail({
    required this.domaines,
    required this.indexActif,
    required this.onChoisir,
  });

  final List<AdminDomaine> domaines;
  final int? indexActif;
  final void Function(int index) onChoisir;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextStyle base =
        Theme.of(context).textTheme.labelMedium ?? const TextStyle();

    return SizedBox(
      key: AdminShell.railKey,
      width: AppGabarit.largeurRail,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.surfaceRaised.background,
          border: BorderDirectional(
            end: palette.borderHairline.asBorderSide(),
          ),
        ),
        child: SafeArea(
          child: NavigationRail(
            selectedIndex: indexActif,
            onDestinationSelected: onChoisir,
            backgroundColor: palette.surfaceRaised.background,
            minWidth: AppGabarit.largeurRail,
            labelType: NavigationRailLabelType.all,
            scrollable: true,
            groupAlignment: -1,
            useIndicator: true,
            indicatorColor: palette.washAccent.background,
            indicatorShape: const RoundedRectangleBorder(
              borderRadius: AppRadius.arrondiSm,
            ),
            selectedLabelTextStyle: base.copyWith(
              color: palette.inkAccent.asBorderSide().color,
            ),
            unselectedLabelTextStyle: base.copyWith(
              color: palette.inkMuted.asBorderSide().color,
            ),
            selectedIconTheme: palette.inkAccent.asIconTheme(
              size: AppSpacing.xxl,
            ),
            unselectedIconTheme: palette.inkMuted.asIconTheme(
              size: AppSpacing.xxl,
            ),
            destinations: <NavigationRailDestination>[
              for (final AdminDomaine domaine in domaines)
                NavigationRailDestination(
                  icon: _iconeEntree(palette, domaine, selectionnee: false),
                  selectedIcon: _iconeEntree(palette, domaine, selectionnee: true),
                  label: _libelleEntree(palette, domaine),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// La barre laterale permanente, a partir de 1200 : libelles complets.
class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.domaines,
    required this.indexActif,
    required this.onChoisir,
  });

  final List<AdminDomaine> domaines;
  final int? indexActif;
  final void Function(int index) onChoisir;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return SizedBox(
      key: AdminShell.barreLateraleKey,
      width: AdminShell.largeurBarreLaterale,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.surfaceRaised.background,
          border: BorderDirectional(
            end: palette.borderHairline.asBorderSide(),
          ),
        ),
        child: SafeArea(
          child: NavigationDrawerTheme(
            data: NavigationDrawerThemeData(
              tileHeight: AppMetriques.of(context).cibleTactile,
              labelTextStyle: _stylesLibelleNav(context, palette),
              iconTheme: _stylesIconeNav(palette),
            ),
            child: NavigationDrawer(
              selectedIndex: indexActif,
              backgroundColor: palette.surfaceRaised.background,
              indicatorColor: palette.washAccent.background,
              indicatorShape: const RoundedRectangleBorder(
                borderRadius: AppRadius.arrondiSm,
              ),
              onDestinationSelected: onChoisir,
              children: <Widget>[
                for (final AdminDomaine domaine in domaines)
                  NavigationDrawerDestination(
                    icon: _iconeEntree(palette, domaine, selectionnee: false),
                    selectedIcon: _iconeEntree(palette, domaine, selectionnee: true),
                    label: _libelleEntree(palette, domaine),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

WidgetStateProperty<TextStyle?> _stylesLibelleNav(
  BuildContext context,
  AppPalette palette,
) {
  final TextStyle base =
      Theme.of(context).textTheme.labelMedium ?? const TextStyle();
  return WidgetStateProperty.resolveWith<TextStyle?>(
    (Set<WidgetState> states) => states.contains(WidgetState.selected)
        ? base.copyWith(color: palette.inkAccent.asBorderSide().color)
        : base.copyWith(color: palette.inkMuted.asBorderSide().color),
  );
}

WidgetStateProperty<IconThemeData?> _stylesIconeNav(AppPalette palette) {
  return WidgetStateProperty.resolveWith<IconThemeData?>(
    (Set<WidgetState> states) => states.contains(WidgetState.selected)
        ? palette.inkAccent.asIconTheme(size: AppSpacing.xxl)
        : palette.inkMuted.asIconTheme(size: AppSpacing.xxl),
  );
}

/// La barre superieure : recherche globale, notifications, compte.
///
/// **Rien d'autre n'y vit** : ni reglage, ni eleve, ni groupe, ni bouton
/// metier isole.
class _BarreSuperieure extends StatefulWidget {
  const _BarreSuperieure({
    required this.avecTiroir,
    required this.onRecherche,
    required this.onCompte,
  });

  /// Vrai sur telephone : affiche le bouton qui ouvre le tiroir.
  final bool avecTiroir;

  final void Function(String chemin) onRecherche;
  final VoidCallback onCompte;

  @override
  State<_BarreSuperieure> createState() => _BarreSuperieureState();
}

class _BarreSuperieureState extends State<_BarreSuperieure> {
  final TextEditingController _recherche = TextEditingController();

  @override
  void dispose() {
    _recherche.dispose();
    super.dispose();
  }

  /// Une recherche de navigation, pas une recherche metier.
  ///
  /// ponytail : correspondance simple, premiere sous-chaine trouvee dans une
  /// liste fixe de moins de dix libelles. Pas de classement ni de tolerance
  /// aux fautes de frappe -- une liste de cette taille n'en a pas besoin, et
  /// aucune donnee n'est interrogee, seulement des libelles et leurs routes.
  void _lancer(String saisie) {
    final String requete = saisie.trim().toLowerCase();
    if (requete.isEmpty) {
      return;
    }
    for (final ({String libelle, String chemin}) cible
        in ciblesRechercheAdmin(voitDirection: false)) {
      if (cible.libelle.toLowerCase().contains(requete)) {
        widget.onRecherche(cible.chemin);
        _recherche.clear();
        return;
      }
    }
  }

  void _ouvrirNotifications() {
    unawaited(
      AppBottomSheet.ouvrir<void>(
        context,
        titre: t.admin.notifications.titre,
        constructeur: (BuildContext _) => EmptyState(
          message: t.admin.notifications.vide,
          invitation: t.admin.notifications.videDetail,
          icone: AppIcons.notifications,
          registre: RegistreVide.subi,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surfaceRaised.background,
        border: Border(bottom: palette.borderHairline.asBorderSide()),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: <Widget>[
              if (widget.avecTiroir) ...<Widget>[
                Builder(
                  builder: (BuildContext contexte) => Pressable(
                    onPress: () => Scaffold.of(contexte).openDrawer(),
                    libelleSemantique: t.nav.admin.menu,
                    child: Icon(AppIcons.menu.repos),
                  ),
                ),
                Ecart.hMd,
              ],
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppPage.largeurFormulaire,
                  ),
                  child: TextField(
                    controller: _recherche,
                    onSubmitted: _lancer,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: t.nav.admin.rechercheIndication,
                      prefixIcon: Icon(AppIcons.recherche.repos),
                    ),
                  ),
                ),
              ),
              Ecart.hMd,
              Pressable(
                onPress: _ouvrirNotifications,
                libelleSemantique: t.nav.admin.notificationsTitre,
                child: Icon(AppIcons.notifications.repos),
              ),
              Ecart.hSm,
              Pressable(
                onPress: widget.onCompte,
                libelleSemantique: t.nav.compte,
                child: Icon(AppIcons.profil.repos),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
