import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/domain/enums.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/tc_outils/annotation_layer.dart';
import '../../core/tc_outils/etat_outils.dart';
import '../../core/tc_outils/libelles_outils.dart';
import '../../core/theme/app_contour.dart';
import '../../core/theme/app_elevation.dart';
import '../../core/theme/app_metriques.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/bouton_outil.dart';
import 'feuille_choix.dart';

/// La barre du stylet : cinq boutons, pas un de plus.
///
/// **Pas de palette type Photoshop** (spec section 8.4). Ni epaisseur, ni
/// opacite, ni nuancier : la couleur derive de l'intention, et l'intention se
/// choisit ailleurs, dans le dock. Ce qui reste ici, c'est ce qu'une main tient
/// pendant qu'elle ecrit : l'encre, le surligneur, la gomme, l'annulation, et
/// le reste sous « Plus ».
///
/// « Plus » ouvre la seule question qui ne se devine pas : **combien de temps
/// cette annotation doit-elle vivre**. C'est la seule decision que le systeme
/// ne peut pas prendre a la place de l'enseignant.
///
/// TB-7b (plan V2 §4.2, §19.1) : la meme barre sert la salle. Dans le
/// panneau « Commandes », sous « Ecrire » : Stylo, Surligner, Gomme,
/// Annuler et « Terminer » (sans « Plus » : la conservation se dit dans le
/// contexte de la seance, TB-9). Panneau ferme, la palette courte
/// ([compacte]) : l'outil actif (qui rouvre les Commandes), Annuler,
/// Terminer, puis l'entree « Commandes » ([onCommandes]) dans la meme
/// rangee : au telephone, la palette prend la place du declencheur au lieu
/// d'ajouter une rangee prise sur la hauteur de la page. Les boutons passent
/// a la ligne plutot que de deborder.
class BarreStylet extends ConsumerWidget {
  /// Cree la barre du stylet.
  const BarreStylet({
    required this.onAnnuler,
    super.key,
    this.peutAnnuler = true,
    this.avecPortee = true,
    this.onTerminer,
    this.compacte = false,
    this.onOutilActif,
    this.surface = true,
    this.onCommandes,
    this.focusCommandes,
    this.outils = OutilTrait.values,
  });

  /// TB-10 (plan V2 §5, §19.3 point 6) : les outils de trace proposes ;
  /// l'eleve autorise n'a que Stylo et Gomme (sans Surligner).
  final List<OutilTrait> outils;

  /// La cle de « Terminer ».
  static const Key cleTerminer = ValueKey<String>('barre-stylet-terminer');

  /// La cle d'« Annuler ».
  static const Key cleAnnuler = ValueKey<String>('barre-stylet-annuler');

  /// La cle de l'entree « Commandes » de la palette courte.
  static const Key cleCommandes = ValueKey<String>('barre-stylet-commandes');

  /// La cle de l'outil actif de la palette courte.
  static const Key cleOutilActif = ValueKey<String>('barre-stylet-actif');

  /// La cle d'un outil de trace.
  static Key cleOutil(OutilTrait outil) =>
      ValueKey<String>('barre-stylet-${outil.name}');

  /// Annule le dernier geste. C'est l'hote qui sait quelle couche est
  /// concernee : la barre ne connait pas les couches.
  final VoidCallback onAnnuler;

  /// Faux quand il n'y a rien a annuler : le bouton n'est pas rendu
  /// (lib/CLAUDE.md : un bouton qui ne peut pas aboutir n'est pas grise).
  final bool peutAnnuler;

  /// « Plus » (la portee) est rendu.
  final bool avecPortee;

  /// TB-7b : « Terminer » sort de l'ecriture ; `null` : pas de bouton.
  final VoidCallback? onTerminer;

  /// TB-7b : la palette courte du telephone (outil actif, Annuler,
  /// Terminer).
  final bool compacte;

  /// TB-7b, palette courte : toucher l'outil actif rouvre les Commandes, ou
  /// reparaissent les autres outils.
  final VoidCallback? onOutilActif;

  /// La barre porte sa propre surface elevee (barre flottante) ; dans un
  /// panneau, elle se pose a plat.
  final bool surface;

  /// TB-7b, palette courte : l'entree « Commandes », derniere de la rangee ;
  /// `null` : pas d'entree.
  final VoidCallback? onCommandes;

  /// Le noeud ou l'hote rend le focus a la fermeture des Commandes.
  final FocusNode? focusCommandes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final EtatOutils etat = ref.watch(etatOutilsProvider);
    // Texte agrandi (plus de 130 %) : l'icone seule, le mot en infobulle et
    // pour le lecteur d'ecran (comme les tuiles d'outils), plutot qu'une
    // palette qui mangerait la page au telephone.
    // TB-10 (MA-CMD-1) : en Mode Accessibilite, icones seules, le mot lu
    // et en infobulle, a toute taille de texte.
    final bool mots =
        MediaQuery.textScalerOf(context).scale(1) <=
            AppContour.seuilTexteAgrandi &&
        AppMetriques.of(context).mode != InterfaceMode.enfant;
    if (!compacte || !mots) return _barre(context, ref, etat, mots: mots);
    // Palette courte : une seule rangee (la hauteur reste a la page). Si les
    // mots ne tiennent pas sur la largeur (320 avec Annuler et Commandes),
    // les icones seules, le mot en infobulle, comme au texte agrandi.
    return LayoutBuilder(
      builder: (BuildContext contexte, BoxConstraints c) => _barre(
        contexte,
        ref,
        etat,
        mots: _largeurAvecMots(contexte, etat) <= c.maxWidth,
      ),
    );
  }

  /// Les libelles de la palette courte, dans l'ordre des boutons. Annuler
  /// compte meme quand il n'est pas encore rendu (rien a defaire) : le choix
  /// mots ou icones ne bascule pas sous la main au premier trait.
  List<String> _libellesCompacts(EtatOutils etat) => <String>[
    libelleOutilTrait(etat.outilTrait),
    t.tc.outils.trait.annuler,
    if (onTerminer != null) t.salle.seance.ecriture.terminer,
    if (onCommandes != null) t.salle.seance.commandes.declencheur,
  ];

  /// La largeur de la palette courte avec ses mots : chaque [BoutonOutil]
  /// (icone ou mot, le plus large, plus sa marge ; au moins la cible
  /// tactile), les ecarts, la marge de la surface.
  double _largeurAvecMots(BuildContext context, EtatOutils etat) {
    final AppMetriques metriques = AppMetriques.of(context);
    final TextStyle style =
        Theme.of(context).textTheme.labelSmall ?? const TextStyle();
    final TextScaler echelle = MediaQuery.textScalerOf(context);
    final double icone = metriques.estEnfant ? AppSpacing.xxxl : AppSpacing.xxl;
    final List<String> libelles = _libellesCompacts(etat);
    double total = AppSpacing.sm * (libelles.length - 1);
    if (surface) total += 2 * AppSpacing.xs;
    for (final String libelle in libelles) {
      final TextPainter mesure = TextPainter(
        text: TextSpan(text: libelle, style: style),
        textDirection: Directionality.of(context),
        textScaler: echelle,
        maxLines: 1,
      )..layout();
      total += math.max(
        metriques.cibleTactile,
        math.max(icone, mesure.width) + 2 * AppSpacing.sm,
      );
      mesure.dispose();
    }
    return total;
  }

  Widget _barre(
    BuildContext context,
    WidgetRef ref,
    EtatOutils etat, {
    required bool mots,
  }) {
    final AppPalette palette = AppPalette.of(context);
    final ControleurOutils controleur = ref.read(etatOutilsProvider.notifier);
    final List<Widget> boutons = <Widget>[
      if (compacte)
        BoutonOutil(
          key: cleOutilActif,
          icone: _icone(etat.outilTrait),
          libelle: libelleOutilTrait(etat.outilTrait),
          avecLibelle: mots,
          retenu: true,
          onPress: onOutilActif,
        )
      else
        for (final OutilTrait outil in outils)
          BoutonOutil(
            key: cleOutil(outil),
            icone: _icone(outil),
            libelle: libelleOutilTrait(outil),
            avecLibelle: !avecPortee && mots,
            retenu: etat.outilTrait == outil,
            onPress: () => controleur.choisirOutilTrait(outil),
          ),
      if (peutAnnuler)
        BoutonOutil(
          key: cleAnnuler,
          icone: AppIcons.annuler,
          libelle: t.tc.outils.trait.annuler,
          avecLibelle: (!avecPortee || compacte) && mots,
          onPress: onAnnuler,
        ),
      if (avecPortee && !compacte)
        BoutonOutil(
          icone: AppIcons.menu,
          libelle: t.tc.outils.trait.plus,
          onPress: () => unawaited(_choisirPortee(context, controleur, etat)),
        ),
      if (onTerminer case final VoidCallback terminer)
        BoutonOutil(
          key: cleTerminer,
          icone: AppIcons.succes,
          libelle: t.salle.seance.ecriture.terminer,
          avecLibelle: mots,
          onPress: terminer,
        ),
      if (onCommandes case final VoidCallback commandes)
        BoutonOutil(
          key: cleCommandes,
          icone: AppIcons.replier,
          libelle: t.salle.seance.commandes.declencheur,
          avecLibelle: mots,
          focusNode: focusCommandes,
          onPress: commandes,
        ),
    ];
    final Widget rangee = Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: boutons,
    );
    if (!surface) return rangee;
    return DecoratedBox(
      decoration: AppElevation.avecFilet(
        surface: palette.surfaceOverlay,
        filet: palette.contourCarte,
        ombre: palette.ombre,
        arrondi: AppRadius.arrondiLg,
        ombres: AppElevation.niveau2(palette.ombre),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: rangee,
      ),
    );
  }

  Future<void> _choisirPortee(
    BuildContext context,
    ControleurOutils controleur,
    EtatOutils etat,
  ) async {
    final PorteeAnnotation? portee = await FeuilleChoix.ouvrirPortee(
      context,
      titre: t.tc.outils.dock.stylet,
      aide: t.tc.outils.portee.aide,
      porteeInitiale: etat.portee,
    );
    if (portee != null) {
      controleur.choisirPortee(portee);
    }
  }

  static AppIcon _icone(OutilTrait outil) => switch (outil) {
    OutilTrait.stylet => AppIcons.stylet,
    OutilTrait.surligneur => AppIcons.surligneur,
    OutilTrait.gomme => AppIcons.effacer,
  };
}
