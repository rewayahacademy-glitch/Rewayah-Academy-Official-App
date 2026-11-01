import 'package:flutter/material.dart';

import '../theme/app_gabarit.dart';
import '../theme/app_spacing.dart';
import 'controle_segmente.dart';
import 'menu_filtre.dart';

/// Comment [SelecteurSection] rend ses sections, choisi selon leur nombre et la
/// place disponible.
enum ModeSelecteurSection {
  /// Un controle segmente a la largeur de son parent : tous les libelles sont
  /// visibles, un libelle trop long passe a la ligne (telephone, jusqu'a
  /// quatre sections).
  segmenteComplet,

  /// Un controle segmente a sa largeur naturelle, aligne au debut : les
  /// sections tiennent en ligne sur tablette et ordinateur.
  segmenteNaturel,

  /// Un menu deroulant qui affiche la section courante et propose la liste
  /// complete au toucher (cinq sections et plus sur telephone, ou des
  /// libelles qui ne tiennent pas).
  menu,
}

/// **Le seul selecteur de section de l'application** : il remplace les rangees
/// d'onglets qui defilent, les rangees de pilules qui defilent et les groupes
/// de puces qui servent a changer de section.
///
/// Pourquoi (revue du directeur, 01/10/2026, ONGLETS-1) : une rangee qui
/// defile ressemble a des diapositives, on ne devine pas qu'elle cache des
/// sections et on doit defiler de gauche a droite pour les atteindre. La regle
/// est celle des referentiels :
///
///   * **jusqu'a quatre sections sur telephone** : controle segmente, tout est
///     visible d'un coup d'oeil, sans defilement ([ControleSegmente]) ;
///   * **cinq sections et plus sur telephone** : un menu deroulant
///     ([MenuFiltre] en mode `selecteurDeSection`) qui affiche la section
///     courante et ouvre la liste complete au toucher ;
///   * **tablette et ordinateur** : les sections restent en ligne tant
///     qu'elles tiennent (sept au plus), sinon le menu prend le relais ;
///   * **plus de sept sections** : la page est trop chargee, on la signale (le
///     composant rend alors un menu, jamais une rangee qui defile).
///
/// La bascule est automatique : elle mesure les libelles au texte agrandi
/// (`TextScaler`), donc a 200 % un controle qui ne tient plus devient un menu.
/// Jamais de defilement horizontal.
///
/// Ce n'est pas une navigation : le composant rend la main par [onChange], et
/// c'est l'ecran qui decide si le choix change une route
/// (`SousNavigationDomaine`) ou un panneau local.
///
/// Sources : Material Design 3, « Tabs » et « Segmented buttons » (m3.material.io,
/// consulte le 02/10/2026) ; Apple Human Interface Guidelines, « Tab bars » et
/// « Segmented controls » (developer.apple.com/design/human-interface-guidelines,
/// consulte le 02/10/2026) ; `docs/current/REVUE-DIRECTEUR-2026-10.md`.
class SelecteurSection<T> extends StatelessWidget {
  /// Cree un selecteur de section.
  const SelecteurSection({
    required this.libelle,
    required this.sections,
    required this.valeur,
    required this.onChange,
    this.menuAuContenu = false,
    super.key,
  });

  /// Mode opt-in (pilote, 01/11/2026, relecture de la PR 126) : en menu, le
  /// declencheur prend la largeur de son plus long libelle, et non toute la
  /// rangee. Faux par defaut : les autres pages ne changent pas.
  final bool menuAuContenu;

  /// Le nom du groupe de sections (« Sections de la pedagogie »), annonce par
  /// le lecteur d'ecran et porte par l'infobulle du menu.
  final String libelle;

  /// Les sections, dans l'ordre d'affichage : deux au moins, sept au plus.
  final List<Segment<T>> sections;

  /// La section courante.
  final T valeur;

  /// Rappele avec la valeur d'une section qu'on choisit.
  final ValueChanged<T> onChange;

  /// Nombre maximal de sections en controle segmente sur telephone.
  static const int maxSegmentsTelephone = 4;

  /// Nombre maximal de sections en ligne sur tablette et ordinateur. Au-dela,
  /// la page doit etre decoupee : on la signale, on ne la decoupe pas ici.
  static const int maxSectionsEnLigne = 7;

  /// Largeur horizontale d'un segment hors texte : 4 de piste + 12 de
  /// remplissage de chaque cote.
  static const double _margeSegment = 2 * (AppSpacing.xs + AppSpacing.md);

  /// Le mode retenu, fonction pure du nombre de sections, de la largeur
  /// disponible et de la largeur des libelles (au texte agrandi).
  ///
  /// [largeurLibelleMax] : le libelle le plus long sur une seule ligne.
  /// [largeurMotMax] : le mot le plus long de tous les libelles (ce qu'aucun
  /// retour a la ligne ne peut raccourcir).
  static ModeSelecteurSection decider({
    required int nombre,
    required double largeur,
    required double largeurLibelleMax,
    required double largeurMotMax,
  }) {
    if (nombre > maxSectionsEnLigne) return ModeSelecteurSection.menu;
    final bool telephone = largeur < AppGabarit.seuilTablette;
    final double largeurNaturelle =
        nombre * (largeurLibelleMax + _margeSegment);
    final bool enUneLigne = largeurNaturelle <= largeur;

    if (telephone) {
      if (nombre > maxSegmentsTelephone) return ModeSelecteurSection.menu;
      // Quatre au plus : tout est visible, un libelle peut passer a la ligne
      // a condition que le plus long mot tienne dans sa part de largeur.
      return nombre * (largeurMotMax + _margeSegment) <= largeur
          ? ModeSelecteurSection.segmenteComplet
          : ModeSelecteurSection.menu;
    }
    if (enUneLigne) return ModeSelecteurSection.segmenteNaturel;
    if (nombre <= maxSegmentsTelephone &&
        nombre * (largeurMotMax + _margeSegment) <= largeur) {
      return ModeSelecteurSection.segmenteComplet;
    }
    return ModeSelecteurSection.menu;
  }

  /// Hors du libelle, le declencheur du menu de section (`MenuFiltre`) :
  /// son rembourrage, l'ecart et le chevron, sa bordure.
  static const double _margeMenu =
      2 * AppSpacing.lg + AppSpacing.xs + AppSpacing.lg + 2;

  /// Toute la rangee, ou (opt-in) la largeur du plus long libelle, bornee
  /// par la rangee.
  Widget _largeurMenu(double disponible, double libelleMax, Widget menu) {
    if (!menuAuContenu) return SizedBox(width: double.infinity, child: menu);
    final double largeur = libelleMax + _margeMenu;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: SizedBox(
        width: largeur < disponible ? largeur : disponible,
        child: menu,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    assert(sections.length >= 2, 'Un selecteur de section a deux sections.');
    final TextStyle style =
        Theme.of(context).textTheme.labelLarge ?? const TextStyle();
    final TextScaler echelle = MediaQuery.textScalerOf(context);
    final TextDirection direction = Directionality.of(context);

    double mesurer(String texte) {
      final TextPainter peintre = TextPainter(
        text: TextSpan(text: texte, style: style),
        textDirection: direction,
        textScaler: echelle,
      )..layout();
      final double largeur = peintre.width.ceilToDouble();
      peintre.dispose();
      return largeur;
    }

    double libelleMax = 0;
    double motMax = 0;
    for (final Segment<T> section in sections) {
      final double entier = mesurer(section.libelle);
      if (entier > libelleMax) libelleMax = entier;
      for (final String mot in section.libelle.split(RegExp(r'\s+'))) {
        final double largeurMot = mesurer(mot);
        if (largeurMot > motMax) motMax = largeurMot;
      }
    }
    // Une icone au-dessus du libelle ne change pas la largeur ; la marge de
    // `ControleSegmente` est comptee dans `_margeSegment`.

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints contraintes) {
        final double disponible = contraintes.maxWidth.isFinite
            ? contraintes.maxWidth
            : MediaQuery.sizeOf(context).width;
        final ModeSelecteurSection mode = decider(
          nombre: sections.length,
          largeur: disponible,
          largeurLibelleMax: libelleMax,
          largeurMotMax: motMax,
        );

        return Semantics(
          container: true,
          label: libelle,
          child: switch (mode) {
            ModeSelecteurSection.menu => _largeurMenu(
              disponible,
              libelleMax,
              MenuFiltre<T>(
                libelle: libelle,
                valeur: valeur,
                selecteurDeSection: true,
                entrees: <EntreeFiltre<T>>[
                  for (final Segment<T> s in sections)
                    EntreeFiltre<T>(valeur: s.valeur, libelle: s.libelle),
                ],
                onChoix: (T? choix) {
                  if (choix != null && choix != valeur) onChange(choix);
                },
              ),
            ),
            ModeSelecteurSection.segmenteComplet => _segmente(),
            ModeSelecteurSection.segmenteNaturel => Align(
              alignment: AlignmentDirectional.centerStart,
              child: SizedBox(
                width: sections.length * (libelleMax + _margeSegment),
                child: _segmente(),
              ),
            ),
          },
        );
      },
    );
  }

  Widget _segmente() => ControleSegmente<T>(
    segments: sections,
    valeur: valeur,
    onChange: onChange,
  );
}
