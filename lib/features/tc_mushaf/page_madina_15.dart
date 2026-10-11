import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/coran/service_coran.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/tc_coran/layout_madina_15.dart';
import '../../core/tc_coran/page_mushaf_vm.dart';
import '../../core/tc_coran/port_layout_mushaf.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/rosace_verset.dart';

/// La cle de la ligne [numero] d'une page (tests, captures).
ValueKey<String> cleLigneMadina15(int numero) =>
    ValueKey<String>('madina15-ligne-$numero');

/// Le corps de police sur lequel toute la page est composee, puis mise a
/// l'echelle du cadre. Une page est un dessin : sa taille vient de la largeur
/// du cadre, jamais de l'echelle de texte du systeme.
const double _tailleBase = 100;

/// L'ecart minimal entre deux mots, en fraction du corps (la largeur d'un
/// espace de l'edition).
const double _ecartMinimal = 0.22;

/// Le diametre d'une rosace de verset, en fraction du corps.
const double _diametreRosace = 0.9;

/// La hauteur d'une ligne, en fraction du corps.
const double _hauteurLigne = 1.95;

/// Une ligne de texte, avec ses mots et ses rosaces, mesuree au corps de base.
@immutable
class LigneMesureeMadina15 {
  const LigneMesureeMadina15._({
    required this.ligne,
    required this.elements,
    required this.largeurNaturelle,
  });

  /// La ligne de la mise en page.
  final SectionLigne ligne;

  /// Ses elements, de droite a gauche.
  final List<ElementLigneMadina15> elements;

  /// Sa largeur au corps de base, avec l'ecart minimal entre les mots.
  final double largeurNaturelle;
}

/// Un mot ou une rosace de verset, avec le verset auquel il appartient.
@immutable
class ElementLigneMadina15 {
  const ElementLigneMadina15._({
    required this.largeur,
    required this.verset,
    this.mot,
    this.numeroRosace,
  });

  /// Sa largeur au corps de base.
  final double largeur;

  /// Le verset (`sourate:rang`), pour le surlignage.
  final String verset;

  /// Le mot, ou `null` pour une rosace.
  final String? mot;

  /// Le numero du verset, pour une rosace.
  final int? numeroRosace;
}

/// La style du texte de la page au corps de base.
TextStyle styleTexteMadina15(Color encre) =>
    AppTypography.mushaf15L(taille: _tailleBase).copyWith(color: encre);

/// Mesure les lignes de texte d'une page au corps de base. Une mesure par
/// mot : la justification repartit ensuite l'espace restant entre les mots.
@visibleForTesting
List<LigneMesureeMadina15> mesurerLignesMadina15(
  List<SectionLigne> lignes,
  TextStyle style,
) {
  double largeurMot(String mot) {
    final TextPainter tp = TextPainter(
      text: TextSpan(text: mot, style: style),
      textDirection: TextDirection.rtl,
      textScaler: TextScaler.noScaling,
    )..layout();
    final double l = tp.width;
    tp.dispose();
    return l;
  }

  final Map<String, double> memo = <String, double>{};
  return <LigneMesureeMadina15>[
    for (final SectionLigne l in lignes)
      if (l.type == TypeLigneMushaf.texte)
        () {
          final List<ElementLigneMadina15> elements = <ElementLigneMadina15>[];
          for (final SegmentVersetLigne s in l.segments) {
            final String cle = '${s.sourate}:${s.ayah}';
            for (final String mot in s.texte.split(' ')) {
              if (mot.isEmpty) continue;
              elements.add(
                ElementLigneMadina15._(
                  largeur: memo.putIfAbsent(mot, () => largeurMot(mot)),
                  verset: cle,
                  mot: mot,
                ),
              );
            }
            if (s.termineLAyah) {
              elements.add(
                ElementLigneMadina15._(
                  largeur: _tailleBase * _diametreRosace,
                  verset: cle,
                  numeroRosace: s.ayah,
                ),
              );
            }
          }
          final double somme = elements.fold<double>(
            0,
            (double a, ElementLigneMadina15 e) => a + e.largeur,
          );
          return LigneMesureeMadina15._(
            ligne: l,
            elements: elements,
            largeurNaturelle:
                somme + (elements.length - 1) * _tailleBase * _ecartMinimal,
          );
        }(),
  ];
}

/// La page du Mushaf de Medine, composee d'apres l'edition (MUSHAF-15L) :
/// quinze lignes (huit pour les pages 1 et 2), chacune justifiee sur la
/// largeur du cadre par une mise a l'echelle homothetique, le cadre de sourate
/// et la basmala centres, une rosace a chaque fin de verset, et les reperes de
/// juz, de hizb et de page.
///
/// **Aucune couleur n'est ecrite ici** : tout vient de la palette, claire et
/// sombre. La page est un dessin (largeur du cadre, corps de base 100) : son
/// echelle ne suit pas celle du texte du systeme, comme celle d'une page
/// imprimee. L'accessibilite passe par un noeud par verset, dont le texte est
/// celui de Tanzil (le corpus de l'application), pas celui de l'edition.
class PageMadina15 extends StatefulWidget {
  /// Cree la page pour [vue], dans un cadre large de [largeur].
  const PageMadina15({
    required this.vue,
    required this.largeur,
    this.versetsSurlignes = const <String>{},
    super.key,
  });

  /// La page, avec des lignes reelles.
  final PageMushafVM vue;

  /// La largeur du cadre.
  final double largeur;

  /// Les versets surlignes, au format `sourate:rang`.
  final Set<String> versetsSurlignes;

  @override
  State<PageMadina15> createState() => _EtatPageMadina15();
}

class _EtatPageMadina15 extends State<PageMadina15> {
  List<LigneMesureeMadina15>? _mesures;
  int? _page;
  Color? _encre;

  List<LigneMesureeMadina15> _lignesMesurees(Color encre) {
    if (_mesures == null || _page != widget.vue.numero || _encre != encre) {
      _mesures = mesurerLignesMadina15(
        widget.vue.lignes,
        styleTexteMadina15(encre),
      );
      _page = widget.vue.numero;
      _encre = encre;
    }
    return _mesures!;
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final Color encre = palette.surfaceQuran.onBackground;
    final PageMushafVM vue = widget.vue;
    final List<LigneMesureeMadina15> mesures = _lignesMesurees(encre);

    // La largeur logique de la page : celle de la ligne la plus large. Les
    // lignes plus courtes sont justifiees jusqu'a elle, la plus large n'a que
    // l'ecart minimal entre ses mots.
    final double largeurLogique = mesures
        .where(
          (LigneMesureeMadina15 m) =>
              !m.ligne.centree && !m.ligne.termineLaSourate,
        )
        .fold<double>(
          0,
          (double a, LigneMesureeMadina15 m) => math.max(a, m.largeurNaturelle),
        );
    final double reference = largeurLogique > 0
        ? largeurLogique
        : mesures.fold<double>(
            0,
            (double a, LigneMesureeMadina15 m) =>
                math.max(a, m.largeurNaturelle),
          );
    // Le papier garde une marge de 0,45 corps de chaque cote : la largeur du
    // texte est donc la largeur du cadre moins ces deux marges.
    final double echelle =
        widget.largeur / (reference + 2 * _tailleBase * 0.45);
    final double largeurTexte = echelle * reference;
    final double hauteurCadre =
        lignesPageMadina15 * _tailleBase * _hauteurLigne * echelle;
    final double hauteurLigne = hauteurCadre / vue.nombreLignes;

    final Map<int, LigneMesureeMadina15> parNumero =
        <int, LigneMesureeMadina15>{
          for (final LigneMesureeMadina15 m in mesures) m.ligne.numero: m,
        };

    // Une page est un dessin : la rosace elle-meme (son numero) ne suit pas
    // l'echelle de texte du systeme, ou la hauteur d'une ligne changerait.
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: DecoratedBox(
          // Le papier de la page : le parchemin de la palette (creme au clair,
          // brun profond au sombre), jamais une couleur ecrite ici.
          decoration: palette.surfaceQuran.decoration(
            borderRadius: AppRadius.arrondiSm,
            side: palette.borderHairline.asBorderSide(),
          ),
          child: Padding(
            padding: EdgeInsets.all(_tailleBase * echelle * 0.45),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ExcludeSemantics(
                  child: _EntetePage(
                    vue: vue,
                    echelle: echelle,
                    palette: palette,
                  ),
                ),
                SizedBox(height: _tailleBase * echelle * 0.4),
                ExcludeSemantics(
                  child: SizedBox(
                    height: hauteurCadre,
                    child: Column(
                      children: <Widget>[
                        for (final SectionLigne l in vue.lignes)
                          SizedBox(
                            key: cleLigneMadina15(l.numero),
                            height: hauteurLigne,
                            width: largeurTexte,
                            child: switch (l.type) {
                              TypeLigneMushaf.enteteSourate => _CadreSourate(
                                numero: l.sourate!,
                                echelle: echelle,
                                palette: palette,
                              ),
                              TypeLigneMushaf.basmala => _LigneBasmala(
                                echelle: echelle,
                                encre: encre,
                              ),
                              TypeLigneMushaf.texte => _LigneTexte(
                                mesure: parNumero[l.numero]!,
                                largeurLogique: reference,
                                largeur: largeurTexte,
                                echelle: echelle,
                                palette: palette,
                                encre: encre,
                                surlignes: widget.versetsSurlignes,
                              ),
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: _tailleBase * echelle * 0.4),
                ExcludeSemantics(
                  child: _NumeroPage(
                    numero: vue.numero,
                    echelle: echelle,
                    palette: palette,
                  ),
                ),
                _SemantiqueVersets(versets: vue.versets),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Une ligne de texte : justifiee sur la largeur du cadre, ou centree quand
/// c'est une page d'Al-Fatiha ou une fin de sourate qui ne remplit pas le
/// cadre.
class _LigneTexte extends StatelessWidget {
  const _LigneTexte({
    required this.mesure,
    required this.largeurLogique,
    required this.largeur,
    required this.echelle,
    required this.palette,
    required this.encre,
    required this.surlignes,
  });

  final LigneMesureeMadina15 mesure;
  final double largeurLogique;
  final double largeur;
  final double echelle;
  final AppPalette palette;
  final Color encre;
  final Set<String> surlignes;

  /// Une fin de sourate plus courte que ce rapport reste courte et centree.
  static const double _seuilFinDeSourate = 0.88;

  @override
  Widget build(BuildContext context) {
    final bool centree =
        mesure.ligne.centree ||
        (mesure.ligne.termineLaSourate &&
            mesure.largeurNaturelle < largeurLogique * _seuilFinDeSourate);
    final TextStyle style = styleTexteMadina15(encre);
    final List<Widget> enfants = <Widget>[
      for (final ElementLigneMadina15 e in mesure.elements)
        _Element(
          element: e,
          style: style,
          palette: palette,
          surligne: surlignes.contains(e.verset),
        ),
    ];
    final Widget rangee = SizedBox(
      width: largeurLogique,
      child: centree
          ? Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: _tailleBase * _ecartMinimal,
                children: enfants,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: enfants,
            ),
    );
    return Center(
      child: FittedBox(
        // Homothetique : le corps de la ligne suit sa largeur, jamais l'inverse.
        fit: BoxFit.fitWidth,
        child: rangee,
      ),
    );
  }
}

class _Element extends StatelessWidget {
  const _Element({
    required this.element,
    required this.style,
    required this.palette,
    required this.surligne,
  });

  final ElementLigneMadina15 element;
  final TextStyle style;
  final AppPalette palette;
  final bool surligne;

  @override
  Widget build(BuildContext context) {
    if (element.numeroRosace != null) {
      return SizedBox(
        width: element.largeur,
        child: Center(
          child: RosaceVerset(
            numero: element.numeroRosace!,
            // Le diametre d'une rosace est `AppSpacing.xl` fois l'echelle.
            echelle: element.largeur / AppSpacing.xl,
          ),
        ),
      );
    }
    final Text mot = Text(
      element.mot!,
      softWrap: false,
      textScaler: TextScaler.noScaling,
      style: style,
    );
    return surligne
        ? DecoratedBox(
            decoration: BoxDecoration(
              color: palette.washAccent.background,
              borderRadius: AppRadius.arrondiXs,
            ),
            child: mot,
          )
        : mot;
  }
}

/// Le cadre de sourate : un bandeau centre, sur une ligne a lui seul.
class _CadreSourate extends StatelessWidget {
  const _CadreSourate({
    required this.numero,
    required this.echelle,
    required this.palette,
  });

  final int numero;
  final double echelle;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final double corps = _tailleBase * echelle;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: corps * 0.18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.washAccent.background,
          borderRadius: AppRadius.arrondiSm,
          border: Border.fromBorderSide(palette.borderStrong.asBorderSide()),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              t.tc.coran.mushaf.page15.sourate(nom: nomSourateMadina15(numero)),
              textScaler: TextScaler.noScaling,
              style: AppTypography.mushaf15L(
                taille: corps * 1.1,
                interligne: 1.2,
              ).copyWith(color: palette.washAccent.onBackground),
            ),
          ),
        ),
      ),
    );
  }
}

/// La basmala qui ouvre une sourate : centree, a la taille du corps de page.
class _LigneBasmala extends StatelessWidget {
  const _LigneBasmala({required this.echelle, required this.encre});

  final double echelle;
  final Color encre;

  @override
  Widget build(BuildContext context) => Center(
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        basmalaMadina15,
        softWrap: false,
        textScaler: TextScaler.noScaling,
        style: styleTexteMadina15(encre)
            .copyWith(fontSize: _tailleBase * echelle * 1.05),
      ),
    ),
  );
}

/// L'en-tete de la page : le juz, le repere de hizb quand un quart commence
/// sur la page, et le nom de la sourate.
class _EntetePage extends StatelessWidget {
  const _EntetePage({
    required this.vue,
    required this.echelle,
    required this.palette,
  });

  final PageMushafVM vue;
  final double echelle;
  final AppPalette palette;

  String? _reperHizb() {
    if (vue.quartsDebutes.isEmpty) return null;
    final int q = vue.quartsDebutes.first;
    final String hizb = RosaceVerset.enChiffresArabes((q - 1) ~/ 4 + 1);
    return switch ((q - 1) % 4) {
      0 => t.tc.coran.mushaf.page15.hizb(numero: hizb),
      1 => t.tc.coran.mushaf.page15.rubUn(numero: hizb),
      2 => t.tc.coran.mushaf.page15.rubDeux(numero: hizb),
      _ => t.tc.coran.mushaf.page15.rubTrois(numero: hizb),
    };
  }

  @override
  Widget build(BuildContext context) {
    final int? juz = vue.juzNumero;
    final int? sourate = vue.lignes
        .map(
          (SectionLigne l) =>
              l.sourate ??
              (l.segments.isEmpty ? null : l.segments.first.sourate),
        )
        .whereType<int>()
        .firstOrNull;
    final TextStyle style = palette.inkMuted.applyTo(
      AppTypography.mushaf15L(
        taille: _tailleBase * echelle * 0.62,
        interligne: 1.3,
      ),
    );
    final String? hizb = _reperHizb();
    Text texte(String s) => Text(
      s,
      textScaler: TextScaler.noScaling,
      style: style,
      softWrap: false,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        if (sourate != null)
          texte(
            t.tc.coran.mushaf.page15.sourate(nom: nomSourateMadina15(sourate)),
          )
        else
          const SizedBox.shrink(),
        if (hizb != null) texte(hizb) else const SizedBox.shrink(),
        if (juz != null)
          texte(
            t.tc.coran.mushaf.page15.juz(
              numero: RosaceVerset.enChiffresArabes(juz),
            ),
          )
        else
          const SizedBox.shrink(),
      ],
    );
  }
}

/// Le numero de page imprime, en chiffres arabes, centre au pied du cadre.
class _NumeroPage extends StatelessWidget {
  const _NumeroPage({
    required this.numero,
    required this.echelle,
    required this.palette,
  });

  final int numero;
  final double echelle;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) => Center(
    child: RosaceVerset(numero: numero, echelle: echelle * 4.5 * 0.7),
  );
}

/// L'accessibilite de la page : un noeud par verset, dans l'ordre de lecture,
/// dont le texte est celui de Tanzil (le corpus de l'application). Le texte
/// dessine, lui, est exclu de la semantique.
class _SemantiqueVersets extends StatelessWidget {
  const _SemantiqueVersets({required this.versets});

  final List<VersetCoran> versets;

  @override
  Widget build(BuildContext context) {
    if (versets.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 0,
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        child: Column(
          children: <Widget>[
            for (final VersetCoran v in versets)
              Semantics(
                container: true,
                label: v.texte,
                child: const SizedBox.shrink(),
              ),
          ],
        ),
      ),
    );
  }
}
