import 'package:flutter/material.dart';

import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../theme/app_color_pair.dart';
import '../theme/app_elevation.dart';
import '../theme/app_metriques.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'pressable.dart';

/// Une option proposee a l'utilisateur.
@immutable
class OptionChoix {
  /// Cree une option.
  const OptionChoix({
    required this.valeur,
    required this.libelle,
    this.icone,
    this.description,
    this.disponible = true,
    this.raisonIndisponible,
    this.cle,
  });

  /// Une cle posee sur la carte de l'option, pour qu'un test la vise sans
  /// dependre du libelle (demande A-5.3).
  final Key? cle;

  /// La valeur transmise a l'appelant.
  final String valeur;

  /// Le libelle affiche.
  final String libelle;

  /// Icone facultative.
  final AppIcon? icone;

  /// Une phrase sous le libelle, qui dit ce que l'option change (style liste
  /// avec description, planches V5 et V6 E1 ; demande B-3).
  final String? description;

  /// Faux pour une option **visible mais indisponible** (K3) : elle reste
  /// lisible, dit pourquoi, et ne se presse pas.
  final bool disponible;

  /// Pourquoi l'option est indisponible, affiche sous elle. A defaut, la
  /// carte dit seulement « Indisponible ».
  final String? raisonIndisponible;
}

/// Ce que l'utilisateur a repondu.
@immutable
class ReponseChoix {
  /// Cree une reponse.
  const ReponseChoix({required this.valeurs, this.saisieLibre});

  /// Les valeurs des cartes retenues.
  final Set<String> valeurs;

  /// Le texte saisi quand la carte « Autre » est retenue.
  final String? saisieLibre;

  /// Vrai quand l'utilisateur a repondu quelque chose d'exploitable.
  bool get renseignee =>
      valeurs.isNotEmpty || (saisieLibre != null && saisieLibre!.isNotEmpty);
}

/// Selection par cartes, avec repli « Autre » en saisie libre.
///
/// **Seul point d'entree pour tout choix propose a l'utilisateur** (ADR-013),
/// dans l'onboarding comme ailleurs. La carte « Autre » est systematique : elle
/// n'est pas une option de l'appelant, parce qu'un parcours qui n'offre aucune
/// issue a celui qui ne se reconnait dans aucune reponse est un parcours qui
/// perd cet utilisateur.
class ChoiceCardGroup extends StatefulWidget {
  /// Cree un groupe de cartes.
  const ChoiceCardGroup({
    required this.options,
    required this.onChange,
    super.key,
    this.selectionMultiple = false,
    this.valeurInitiale,
    this.autoriserSaisieLibre = true,
    this.coteACote = false,
  });

  /// Vrai pour poser les options **cote a cote** (demande A-5.2, maquette
  /// « onboarding Mble d ») : cartes de meme hauteur, contenu centre, icone
  /// dans un disque au-dessus du titre, radio en haut a droite. Faite pour
  /// deux ou trois options courtes ; la carte « Autre », si elle est permise,
  /// reste pleine largeur dessous. Faux par defaut : rendu en liste inchange.
  final bool coteACote;

  /// Les reponses les plus courantes.
  final List<OptionChoix> options;

  /// Appele a chaque changement de reponse.
  final void Function(ReponseChoix reponse) onChange;

  /// Vrai pour autoriser plusieurs reponses.
  final bool selectionMultiple;

  /// Reponse pre-cochee, utile a l'onboarding de confirmation (ADR-014).
  final ReponseChoix? valeurInitiale;

  /// Legacy flows may keep an "Other" text answer. New scheduling choices use
  /// closed administrative proposals and pass false.
  final bool autoriserSaisieLibre;

  /// Valeur interne de la carte « Autre ».
  static const String valeurAutre = r'$autre';

  @override
  State<ChoiceCardGroup> createState() => _ChoiceCardGroupState();
}

class _ChoiceCardGroupState extends State<ChoiceCardGroup> {
  late Set<String> _selection =
      widget.valeurInitiale?.valeurs.toSet() ?? <String>{};
  late final TextEditingController _saisie = TextEditingController(
    text: widget.valeurInitiale?.saisieLibre ?? '',
  );

  bool get _autreRetenu => _selection.contains(ChoiceCardGroup.valeurAutre);

  @override
  void dispose() {
    _saisie.dispose();
    super.dispose();
  }

  void _basculer(String valeur) {
    setState(() {
      if (widget.selectionMultiple) {
        if (!_selection.remove(valeur)) {
          _selection.add(valeur);
        }
      } else {
        _selection = <String>{valeur};
      }
    });
    _notifier();
  }

  void _notifier() {
    widget.onChange(
      ReponseChoix(
        valeurs: Set<String>.unmodifiable(_selection),
        saisieLibre: _autreRetenu ? _saisie.text.trim() : null,
      ),
    );
  }

  Widget _carteOption(OptionChoix option, {required bool verticale}) => _Carte(
    key: option.cle,
    libelle: option.libelle,
    icone: option.icone,
    description: option.description,
    raisonIndisponible: option.disponible
        ? null
        : option.raisonIndisponible ?? t.commun.choix.indisponible,
    retenue: _selection.contains(option.valeur),
    radio: !widget.selectionMultiple,
    verticale: verticale,
    onPress: option.disponible ? () => _basculer(option.valeur) : null,
  );

  @override
  Widget build(BuildContext context) {
    final AppMetriques metriques = AppMetriques.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (widget.selectionMultiple) ...<Widget>[
          Text(
            t.choix.selectionMultiple,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Ecart.vMd,
        ],
        if (widget.coteACote)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  for (int i = 0; i < widget.options.length; i++) ...<Widget>[
                    if (i > 0) Ecart.hMd,
                    Expanded(
                      child: _carteOption(widget.options[i], verticale: true),
                    ),
                  ],
                ],
              ),
            ),
          )
        else
          for (final OptionChoix option in widget.options)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _carteOption(option, verticale: false),
            ),
        if (widget.autoriserSaisieLibre)
          _Carte(
            libelle: t.choix.autre,
            icone: AppIcons.autreChoix,
            retenue: _autreRetenu,
            radio: !widget.selectionMultiple,
            onPress: () => _basculer(ChoiceCardGroup.valeurAutre),
          ),
        if (widget.autoriserSaisieLibre && _autreRetenu) ...<Widget>[
          Ecart.vMd,
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: metriques.cibleTactile),
            child: TextField(
              controller: _saisie,
              onChanged: (String _) => _notifier(),
              decoration: InputDecoration(labelText: t.choix.autreInvite),
            ),
          ),
        ],
      ],
    );
  }
}

class _Carte extends StatelessWidget {
  const _Carte({
    required this.libelle,
    required this.retenue,
    required this.onPress,
    required this.radio,
    super.key,
    this.icone,
    this.description,
    this.raisonIndisponible,
    this.verticale = false,
  });

  /// Vrai pour la disposition cote a cote : contenu centre, icone dans un
  /// disque au-dessus du titre, radio (ou coche) en haut a droite.
  final bool verticale;

  final String libelle;
  final bool retenue;

  /// `null` pour une option indisponible : la carte ne se presse pas.
  final VoidCallback? onPress;

  /// Vrai en selection unique : un radio dessine dit le choix ; en selection
  /// multiple, la coche garde ce role.
  final bool radio;
  final AppIcon? icone;
  final String? description;

  /// Non nul quand l'option est indisponible : la phrase affichee.
  final String? raisonIndisponible;

  bool get _disponible => raisonIndisponible == null;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    // La selection change la PAIRE entiere, pas seulement le fond : le texte
    // suit toujours son fond.
    //
    // **Le lot C la passe au registre doux.** Une carte retenue etait peinte en
    // aplat violet plein : sur une page de parcours qui porte deja son bouton
    // « Continuer » en `surfacePrimary`, deux aplats satures se disputaient
    // l'ecran, ce que la regle de la zone pleine unique interdit
    // (`docs/archive/2026-09-pre-remise-a-plat/design/01-systeme-visuel.md` section 3). La selection se dit
    // maintenant par la teinte douce et par le contour fort, qui est la seule
    // bordure porteuse de sens.
    final AppColorPair paire = retenue
        ? palette.washAccent
        : palette.surfaceRaised;

    final TextStyle styleSecondaire = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    // Le libelle lu : le titre seul tant qu'il n'y a rien d'autre (les
    // usages existants restent lus a l'identique), puis la description et la
    // raison d'indisponibilite.
    final String lu = <String>[
      libelle,
      ?description,
      ?raisonIndisponible,
    ].join('. ');

    return Semantics(
      checked: retenue,
      inMutuallyExclusiveGroup: radio,
      child: Pressable.selon(
        onPress: onPress,
        actif: _disponible,
        libelleSemantique: lu,
        respecterCibleTactile: false,
        constructeur: (BuildContext contexte, EtatPression etat) => Container(
          constraints: BoxConstraints(
            minHeight: verticale
                ? AppPage.hauteurChoix * 2
                : AppPage.hauteurChoix,
          ),
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: AppElevation.avecFilet(
            surface: paire,
            filet: retenue || etat.survole || etat.presse
                ? palette.borderStrong
                : palette.borderResting,
            ombre: palette.ombre,
            arrondi: AppRadius.arrondiLg,
            ombres: AppElevation.niveau0,
          ),
          // Le libelle lu est [lu] : les textes visibles ne sont pas relus
          // une seconde fois a sa suite.
          child: ExcludeSemantics(
            child: verticale
                ? _contenuVertical(palette, paire, textes, styleSecondaire)
                : Row(
                    children: <Widget>[
                      if (icone != null) ...<Widget>[
                        IconTheme(
                          data: _disponible
                              ? IconThemeData(
                                  color: paire.onBackground,
                                  size: AppSpacing.xxl,
                                )
                              : palette.inkMuted.asIconTheme(
                                  size: AppSpacing.xxl,
                                ),
                          child: Icon(icone!.resoudre(selectionne: retenue)),
                        ),
                        Ecart.hMd,
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              libelle,
                              style: _disponible
                                  ? paire.applyTo(
                                      textes.titleMedium ?? const TextStyle(),
                                    )
                                  : palette.inkMuted.applyTo(
                                      textes.titleMedium ?? const TextStyle(),
                                    ),
                            ),
                            if (description != null) ...<Widget>[
                              Ecart.vXs,
                              Text(description!, style: styleSecondaire),
                            ],
                            if (raisonIndisponible != null) ...<Widget>[
                              Ecart.vSm,
                              Text(
                                raisonIndisponible!,
                                style: palette.inkMuted.applyTo(
                                  textes.labelMedium ?? const TextStyle(),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Le radio ou la coche doublent la couleur : une selection qui
                      // ne se lirait qu'a la teinte n'existerait pas pour un
                      // daltonien.
                      if (radio) ...<Widget>[
                        Ecart.hMd,
                        RadioChoix(retenue: retenue, disponible: _disponible),
                      ] else if (retenue)
                        IconTheme(
                          data: IconThemeData(
                            color: paire.onBackground,
                            size: AppSpacing.xxl,
                          ),
                          child: Icon(AppIcons.succes.actif),
                        ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

extension on _Carte {
  /// Le contenu de la carte cote a cote : radio ou coche en haut a droite,
  /// icone dans un disque puis titre, centres.
  Widget _contenuVertical(
    AppPalette palette,
    AppColorPair paire,
    TextTheme textes,
    TextStyle styleSecondaire,
  ) {
    const double disque = AppSpacing.respiration + AppSpacing.sm;
    final AppColorPair fondDisque = retenue
        ? palette.surfaceActionDouce
        : palette.surfaceSunken;
    return Stack(
      children: <Widget>[
        Center(
          child: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (icone != null) ...<Widget>[
                  SizedBox.square(
                    dimension: disque,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: fondDisque.background,
                      ),
                      child: Center(
                        child: IconTheme(
                          data: _disponible
                              ? IconThemeData(
                                  color: fondDisque.onBackground,
                                  size: AppSpacing.xxxl,
                                )
                              : palette.inkMuted.asIconTheme(
                                  size: AppSpacing.xxxl,
                                ),
                          child: Icon(icone!.resoudre(selectionne: retenue)),
                        ),
                      ),
                    ),
                  ),
                  Ecart.vLg,
                ],
                Text(
                  libelle,
                  textAlign: TextAlign.center,
                  style: _disponible
                      ? paire.applyTo(textes.titleMedium ?? const TextStyle())
                      : palette.inkMuted.applyTo(
                          textes.titleMedium ?? const TextStyle(),
                        ),
                ),
                if (description != null) ...<Widget>[
                  Ecart.vXs,
                  Text(
                    description!,
                    textAlign: TextAlign.center,
                    style: styleSecondaire,
                  ),
                ],
                if (raisonIndisponible != null) ...<Widget>[
                  Ecart.vSm,
                  Text(
                    raisonIndisponible!,
                    textAlign: TextAlign.center,
                    style: palette.inkMuted.applyTo(
                      textes.labelMedium ?? const TextStyle(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: radio
              ? RadioChoix(retenue: retenue, disponible: _disponible)
              : retenue
              ? IconTheme(
                  data: IconThemeData(
                    color: paire.onBackground,
                    size: AppSpacing.xxl,
                  ),
                  child: Icon(AppIcons.succes.actif),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

/// Le radio dessine d'une carte de choix : anneau, point plein quand elle est
/// retenue. L'anneau garde au moins 3:1 sur la carte (`borderStrong` au
/// repos, `inkAccent` retenu) ; indisponible, il passe au filet de repos,
/// comme tout controle inactif. Sans semantique propre : la carte porte
/// l'etat coche.
class RadioChoix extends StatelessWidget {
  /// Cree le radio.
  const RadioChoix({required this.retenue, super.key, this.disponible = true});

  /// Vrai quand l'option est retenue.
  final bool retenue;

  /// Faux pour une option indisponible.
  final bool disponible;

  /// La couleur de l'anneau dans [palette].
  AppInkColor anneau(AppPalette palette) => retenue
      ? palette.inkAccent
      : disponible
      ? palette.borderStrong
      : palette.borderResting;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: AppSpacing.xxl,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.fromBorderSide(
              anneau(palette).asBorderSide(width: 2),
            ),
          ),
          child: retenue
              ? Padding(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: palette.surfacePrimary.background,
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
