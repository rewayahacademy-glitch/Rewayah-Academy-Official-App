import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/domain/enums.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/theme/app_color_pair.dart';
import '../../../core/theme/app_elevation.dart';
import '../../../core/theme/app_gabarit.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/action_principale.dart';
import '../../../core/widgets/section_header.dart';
import 'catalogue_galerie.dart';

/// Banc d'essai des jetons et des composants partages.
///
/// **Compile uniquement avec `--dart-define=GALERIE=true`.** Une version de
/// production ne contient pas cette route : `Env.galerieActive` est faux par
/// defaut et la route n'est alors pas enregistree.
///
/// Trois regles a tenir pour que ce banc ne devienne pas une seconde source de
/// verite : il n'est lie depuis aucun ecran, il ne definit aucun style en
/// propre, et `tool/verifier_jetons.dart` le verifie comme le reste de `lib/`.
///
/// **Le lot C en fait la preuve du catalogue** et non plus une page de
/// demonstration (`docs/archive/2026-09-pre-remise-a-plat/design/07-catalogue-composants.md` section 5). Les
/// cinq axes que la section exige sont les cinq bascules de la barre de
/// reglages : largeur, langue, taille de texte, mouvement, mode d'interface.
///
/// Les libelles d'echantillon (« Une carte », « Aicha ») sont en dur, et c'est
/// volontaire : ce sont des donnees de banc d'essai, pas des libelles de
/// produit. Les libelles que le produit affiche vraiment, eux, viennent tous de
/// slang, pour que la galerie montre la vraie longueur des mots.
class GaleriePage extends StatefulWidget {
  /// Cree la galerie.
  const GaleriePage({super.key});

  @override
  State<GaleriePage> createState() => _GaleriePageState();
}

class _GaleriePageState extends State<GaleriePage> {
  Gabarit _gabarit = Gabarit.mobile;
  InterfaceMode _mode = InterfaceMode.standard;
  TextDirection _direction = TextDirection.ltr;
  bool _grandTexte = false;
  bool _mouvementReduit = false;
  bool _jetons = true;
  bool _sombre = false;

  /// La largeur simulee du gabarit choisi.
  ///
  /// Une valeur au milieu de chaque plage, et non sa borne : un composant qui
  /// ne tiendrait qu'a 599 ou a 1025 passerait sinon pour bon.
  double get _largeur => switch (_gabarit) {
    Gabarit.mobile => 390,
    Gabarit.tablette => 768,
    Gabarit.desktop => 1440,
  };

  @override
  Widget build(BuildContext context) {
    if (kReleaseMode) {
      return const Scaffold(
        body: Center(child: Text('Galerie indisponible en production')),
      );
    }
    final List<EntreeGalerie> entrees = catalogueGalerie();

    return Scaffold(
      appBar: AppBar(title: Text(t.galerie.titre)),
      body: Column(
        children: <Widget>[
          _BarreReglages(
            gabarit: _gabarit,
            mode: _mode,
            direction: _direction,
            grandTexte: _grandTexte,
            mouvementReduit: _mouvementReduit,
            sombre: _sombre,
            jetons: _jetons,
            onGabarit: (Gabarit g) => setState(() => _gabarit = g),
            onMode: (InterfaceMode m) => setState(() => _mode = m),
            onDirection: (TextDirection d) => setState(() => _direction = d),
            onGrandTexte: (bool v) => setState(() => _grandTexte = v),
            onMouvement: (bool v) => setState(() => _mouvementReduit = v),
            onSombre: (bool v) => setState(() => _sombre = v),
            onJetons: (bool v) => setState(() => _jetons = v),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              // Une entree de plus quand les jetons sont affiches : ils
              // ouvrent la liste, comme au lot T.
              itemCount: entrees.length + (_jetons ? 1 : 0),
              itemBuilder: (BuildContext contexte, int index) {
                if (_jetons && index == 0) {
                  return _Encadre(
                    largeur: _largeur,
                    child: _sousConditions(const _Jetons()),
                  );
                }
                final EntreeGalerie entree = entrees[index - (_jetons ? 1 : 0)];
                return _Composant(
                  entree: entree,
                  largeur: _largeur,
                  enveloppe: _sousConditions,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Rend un widget sous les cinq conditions choisies.
  ///
  /// Le theme est remonte entierement plutot que bricole : c'est exactement ce
  /// que fait l'application quand le profil change de mode. Et la taille comme
  /// la preference de mouvement passent par `MediaQuery`, c'est-a-dire par la
  /// meme porte que le systeme d'exploitation.
  Widget _sousConditions(Widget enfant) {
    // Toujours le theme clair : le catalogue de composants
    // (`07-catalogue-composants.md` section 5) ne liste que cinq axes de
    // verification (largeur, langue, taille de texte, mouvement, mode
    // d'interface), pas la luminosite. Ajouter un sixieme axe releve d'une
    // decision de doc, pas de ce lot.
    return Theme(
      data: AppTheme.pour(_mode, _sombre ? Brightness.dark : Brightness.light),
      child: Builder(
        builder: (BuildContext contexte) => MediaQuery(
          data: MediaQuery.of(contexte).copyWith(
            size: Size(_largeur, MediaQuery.sizeOf(contexte).height),
            textScaler: TextScaler.linear(_grandTexte ? 2 : 1),
            disableAnimations: _mouvementReduit,
          ),
          child: Directionality(
            textDirection: _direction,
            child: SizedBox(width: _largeur, child: enfant),
          ),
        ),
      ),
    );
  }
}

/// Les cinq axes de verification, plus la bascule des jetons.
class _BarreReglages extends StatelessWidget {
  const _BarreReglages({
    required this.gabarit,
    required this.mode,
    required this.direction,
    required this.grandTexte,
    required this.mouvementReduit,
    required this.sombre,
    required this.jetons,
    required this.onGabarit,
    required this.onMode,
    required this.onDirection,
    required this.onGrandTexte,
    required this.onMouvement,
    required this.onSombre,
    required this.onJetons,
  });

  final Gabarit gabarit;
  final InterfaceMode mode;
  final TextDirection direction;
  final bool grandTexte;
  final bool mouvementReduit;
  final bool sombre;
  final bool jetons;
  final void Function(Gabarit) onGabarit;
  final void Function(InterfaceMode) onMode;
  final void Function(TextDirection) onDirection;
  final void Function(bool) onGrandTexte;
  final void Function(bool) onMouvement;
  final void Function(bool) onSombre;
  final void Function(bool) onJetons;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surfaceRaised.background,
        border: Border(bottom: palette.borderHairline.asBorderSide()),
        boxShadow: AppElevation.niveau2(palette.ombre),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            for (final Gabarit g in Gabarit.values)
              _Bascule(
                libelle: g.name,
                active: gabarit == g,
                onPress: () => onGabarit(g),
              ),
            _Bascule(
              libelle: 'ar / rtl',
              active: direction == TextDirection.rtl,
              onPress: () => onDirection(
                direction == TextDirection.rtl
                    ? TextDirection.ltr
                    : TextDirection.rtl,
              ),
            ),
            _Bascule(
              libelle: 'texte 200 %',
              active: grandTexte,
              onPress: () => onGrandTexte(!grandTexte),
            ),
            _Bascule(
              libelle: 'mouvement reduit',
              active: mouvementReduit,
              onPress: () => onMouvement(!mouvementReduit),
            ),
            _Bascule(
              libelle: 'thème sombre',
              active: sombre,
              onPress: () => onSombre(!sombre),
            ),
            _Bascule(
              libelle: t.galerie.modeEnfant,
              active: mode == InterfaceMode.enfant,
              onPress: () => onMode(
                mode == InterfaceMode.enfant
                    ? InterfaceMode.standard
                    : InterfaceMode.enfant,
              ),
            ),
            _Bascule(
              libelle: t.galerie.paires,
              active: jetons,
              onPress: () => onJetons(!jetons),
            ),
          ],
        ),
      ),
    );
  }
}

/// Une bascule de la barre de reglages.
class _Bascule extends StatelessWidget {
  const _Bascule({
    required this.libelle,
    required this.active,
    required this.onPress,
  });

  final String libelle;
  final bool active;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    return ActionPrincipale(
      libelle: libelle,
      onPress: onPress,
      niveau: active ? NiveauAction.principale : NiveauAction.secondaire,
      pleineLargeur: false,
    );
  }
}

/// Un composant du catalogue, avec tous ses etats nommes.
class _Composant extends StatelessWidget {
  const _Composant({
    required this.entree,
    required this.largeur,
    required this.enveloppe,
  });

  final EntreeGalerie entree;
  final double largeur;
  final Widget Function(Widget) enveloppe;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.section),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SectionHeader(titre: entree.nom, compteur: entree.etats.length),
          Ecart.vXs,
          Text(
            entree.famille.name,
            style: AppPalette.of(context).inkMuted.applyTo(
              Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
            ),
          ),
          Ecart.vLg,
          for (final EtatGalerie etat in entree.etats)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    etat.nom,
                    style: AppPalette.of(context).inkFaint.applyTo(
                      AppTypography.capitales(
                        Theme.of(context).textTheme.labelSmall ??
                            const TextStyle(),
                      ),
                    ),
                  ),
                  Ecart.vSm,
                  _Encadre(
                    largeur: largeur,
                    child: enveloppe(Builder(builder: etat.construire)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Le cadre qui borne un rendu a la largeur du gabarit choisi.
///
/// Il defile horizontalement : sur un poste etroit, un rendu desktop de 1440
/// doit rester consultable au lieu de deborder.
class _Encadre extends StatelessWidget {
  const _Encadre({required this.largeur, required this.child});

  final double largeur;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.surfaceCanvas.background,
          border: Border.fromBorderSide(palette.borderResting.asBorderSide()),
          borderRadius: AppRadius.arrondiSm,
        ),
        child: SizedBox(width: largeur, child: child),
      ),
    );
  }
}

/// Les jetons, tels que le lot T les a poses.
///
/// Ils restent dans la galerie parce que **aucun test Flutter ne prouve qu'une
/// police se charge** : en test, le moteur rend tout en Ahem. Seul un rendu
/// reel montre que les deux familles francaises rendent, et rendent
/// differemment l'une de l'autre.
class _Jetons extends StatelessWidget {
  const _Jetons();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SectionHeader(titre: t.galerie.paires),
          Ecart.vLg,
          const _Paires(),
          Ecart.vSection,
          SectionHeader(titre: t.galerie.elevation),
          Ecart.vLg,
          const _Elevation(),
          Ecart.vSection,
          SectionHeader(titre: t.galerie.typographie),
          Ecart.vLg,
          const _Typographie(),
          Ecart.vSection,
          SectionHeader(titre: t.galerie.polices),
          Ecart.vLg,
          const _Polices(),
        ],
      ),
    );
  }
}

class _Paires extends StatelessWidget {
  const _Paires();

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextStyle base =
        Theme.of(context).textTheme.titleMedium ?? const TextStyle();

    // Les trois registres de la palette, dans l'ordre ou ils se lisent : la
    // rampe qui porte la hierarchie, les aplats reserves a l'action, les
    // teintes douces qui portent tout le reste.
    final Map<String, AppColorPair> rampe = <String, AppColorPair>{
      'surfaceRaised': palette.surfaceRaised,
      'surfaceCanvas': palette.surfaceCanvas,
      'surfaceSunken': palette.surfaceSunken,
    };
    final Map<String, AppColorPair> pleines = <String, AppColorPair>{
      'surfacePrimary': palette.surfacePrimary,
      'surfaceSuccess': palette.surfaceSuccess,
      'surfaceWarning': palette.surfaceWarning,
      'surfaceAlert': palette.surfaceAlert,
      'surfaceInverse': palette.surfaceInverse,
    };
    final Map<String, AppColorPair> douces = <String, AppColorPair>{
      'washAccent': palette.washAccent,
      'washSuccess': palette.washSuccess,
      'washWarning': palette.washWarning,
      'washAlert': palette.washAlert,
      'washFamily': palette.washFamily,
      'surfaceQuran': palette.surfaceQuran,
    };
    final Map<String, AppInkColor> encres = <String, AppInkColor>{
      'inkStrong': palette.inkStrong,
      'inkMuted': palette.inkMuted,
      'inkFaint': palette.inkFaint,
      'inkAccent': palette.inkAccent,
      'inkSuccess': palette.inkSuccess,
      'inkWarning': palette.inkWarning,
      'inkAlert': palette.inkAlert,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final Map<String, AppColorPair> groupe
            in <Map<String, AppColorPair>>[rampe, pleines, douces])
          for (final MapEntry<String, AppColorPair> e in groupe.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: DecoratedBox(
                decoration: AppElevation.avecFilet(
                  surface: e.value,
                  filet: palette.borderHairline,
                  ombre: palette.ombre,
                  arrondi: AppRadius.arrondiMd,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(e.key, style: e.value.applyTo(base)),
                ),
              ),
            ),
        // Les encres se montrent posees sur le fond general : c'est la que se
        // joue leur lisibilite, et c'est la que le piege de l'encre blanche
        // avait rendu un message d'erreur invisible.
        for (final MapEntry<String, AppInkColor> e in encres.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(e.key, style: e.value.applyTo(base)),
          ),
        Ecart.vMd,
        // Les trois bordures, cote a cote : seule la troisieme porte du sens.
        for (final MapEntry<String, AppInkColor> e in <String, AppInkColor>{
          'borderHairline': palette.borderHairline,
          'borderResting': palette.borderResting,
          'borderStrong': palette.borderStrong,
        }.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: AppRadius.arrondiSm,
                border: Border.fromBorderSide(e.value.asBorderSide(width: 2)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(e.key),
              ),
            ),
          ),
      ],
    );
  }
}

/// Les quatre niveaux d'elevation et les cinq rayons, cote a cote.
///
/// Ils se montrent ensemble parce qu'ils se lisent ensemble : une surface
/// elevee porte un filet ET une ombre, jamais l'un des deux seul.
class _Elevation extends StatelessWidget {
  const _Elevation();

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final Map<String, List<BoxShadow>> niveaux = <String, List<BoxShadow>>{
      'elevation0': AppElevation.niveau0,
      'elevation1': AppElevation.niveau1(palette.ombre),
      'elevation2': AppElevation.niveau2(palette.ombre),
      'elevation3': AppElevation.niveau3(palette.ombre),
    };
    final Map<String, BorderRadius> rayons = <String, BorderRadius>{
      'radiusXs': AppRadius.arrondiXs,
      'radiusSm': AppRadius.arrondiSm,
      'radiusMd': AppRadius.arrondiMd,
      'radiusLg': AppRadius.arrondiLg,
      'radiusFull': AppRadius.arrondiFull,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final MapEntry<String, List<BoxShadow>> e in niveaux.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            child: DecoratedBox(
              decoration: AppElevation.avecFilet(
                surface: palette.surfaceRaised,
                filet: palette.borderHairline,
                ombre: palette.ombre,
                arrondi: AppRadius.arrondiMd,
                ombres: e.value,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(e.key),
              ),
            ),
          ),
        for (final MapEntry<String, BorderRadius> e in rayons.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: DecoratedBox(
              decoration: palette.surfaceSunken.decoration(
                borderRadius: e.value,
                side: palette.borderResting.asBorderSide(),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(e.key),
              ),
            ),
          ),
      ],
    );
  }
}

class _Typographie extends StatelessWidget {
  const _Typographie();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: _EchelleTexte(
            titre: t.galerie.modeStandard,
            echelle: AppTypography.standard,
          ),
        ),
        Ecart.hLg,
        Expanded(
          child: _EchelleTexte(
            titre: t.galerie.modeEnfant,
            echelle: AppTypography.enfant,
          ),
        ),
      ],
    );
  }
}

class _EchelleTexte extends StatelessWidget {
  const _EchelleTexte({required this.titre, required this.echelle});

  final String titre;
  final TextTheme echelle;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final Map<String, TextStyle?> roles = <String, TextStyle?>{
      'displaySmall': echelle.displaySmall,
      'headlineMedium': echelle.headlineMedium,
      'titleLarge': echelle.titleLarge,
      'bodyLarge': echelle.bodyLarge,
      'bodyMedium': echelle.bodyMedium,
      'labelSmall': echelle.labelSmall,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(titre, style: Theme.of(context).textTheme.titleMedium),
        Ecart.vSm,
        for (final MapEntry<String, TextStyle?> e in roles.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              '${e.key} ${e.value?.fontSize?.round()}',
              style: palette.surfaceCanvas.applyTo(
                e.value ?? const TextStyle(),
              ),
            ),
          ),
      ],
    );
  }
}

class _Polices extends StatelessWidget {
  const _Polices();

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextStyle base =
        Theme.of(context).textTheme.titleLarge ?? const TextStyle();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'InstrumentSans : les Makharij se corrigent a l’oreille',
          style: palette.surfaceCanvas
              .applyTo(base)
              .copyWith(fontFamily: AppFontFamily.corps),
        ),
        Ecart.vMd,
        Text(
          'BricolageGrotesque : Prochain cours jeudi',
          style: palette.surfaceCanvas
              .applyTo(base)
              .copyWith(fontFamily: AppFontFamily.titre),
        ),
        Ecart.vMd,
        // Les chiffres tabulaires ne se voient que compares : deux lignes de
        // chiffres differents doivent aligner leurs colonnes.
        Text(
          '11 111\n00 000',
          style: AppTypography.tabulaire(palette.surfaceCanvas.applyTo(base)),
        ),
        Ecart.vMd,
        // L'echantillon mixte. C'est la seule facon de juger si la hauteur d'x
        // et la graisse d'Instrument Sans s'accordent a Noto Sans Arabic : les
        // deux polices doivent se lire sur UNE ligne, pas cote a cote sur deux.
        // C'est une intention de conception, pas une mesure : elle se tranche
        // a l'oeil (question ouverte 21 du registre).
        Text(
          'Sourate الفاتحة, verset 5 : اهدنا الصراط المستقيم',
          style: palette.surfaceCanvas.applyTo(base),
        ),
        Ecart.vMd,
        Directionality(
          textDirection: TextDirection.rtl,
          child: Text(
            'نوتو عربي',
            style: palette.surfaceCanvas
                .applyTo(base)
                .copyWith(fontFamily: AppFontFamily.arabeInterface),
          ),
        ),
        Ecart.vMd,
        Directionality(
          textDirection: TextDirection.rtl,
          child: Text(
            'الحمد لله '
            'رب العالمين',
            style: palette.surfaceCanvas.applyTo(AppTypography.document()),
          ),
        ),
      ],
    );
  }
}
