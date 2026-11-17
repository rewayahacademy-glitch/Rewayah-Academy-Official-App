/// PX-BD-SUPPORT : le lecteur, dans l'application, des textes que Praxis
/// redige avec la direction (Markdown FERME : titres, paragraphes, listes,
/// gras, italique, citation, separateur).
///
///   * **le sens du texte se lit paragraphe par paragraphe** : un paragraphe
///     qui commence par une lettre arabe se lit de droite a gauche, un
///     paragraphe francais de gauche a droite, un texte mixte suit l'algorithme
///     bidirectionnel du moteur (`commenceParArabe`, `dirigerContenuArabe`) ;
///   * **l'arabe se rend dans la police du contenu** (`styleContenuArabe`,
///     UthmanicHafs) : la vocalisation est conservee telle quelle, jamais
///     retouchee ni normalisee ;
///   * **aucun cadre a hauteur fixe, aucun defilement propre** : la page
///     defile avec la page (DECISION-DEFILEMENT-2026-11-01) ;
///   * un texte que l'analyseur refuse n'est jamais « repare » : la phrase le
///     dit.
///
/// ATTENTION, ce lecteur affiche le texte tel qu'il a ete depose. Un verset
/// cite dans un support n'est PAS verifie contre le texte du Mushaf : seule la
/// direction qui le relit avant le depot en repond.
library;

import 'package:flutter/material.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/tc_bibliotheque/contenu_arabe.dart';
import '../../core/tc_bibliotheque/markdown_ferme.dart';
import '../../core/theme/app_spacing.dart';

/// Les cles des widgets du lecteur, pour les tests.
abstract final class ClesLecteurMarkdown {
  /// Le document rendu.
  static const Key document = ValueKey<String>('lecteur-markdown');

  /// Un texte refuse.
  static const Key illisible = ValueKey<String>('lecteur-markdown-illisible');
}

/// Le lecteur de [source].
class LecteurMarkdown extends StatelessWidget {
  /// Cree le lecteur.
  const LecteurMarkdown({required this.source, super.key});

  /// Le texte Markdown ferme, tel que depose.
  final String source;

  @override
  Widget build(BuildContext context) {
    final ResultatMd r = analyserMarkdownFerme(source);
    final TextTheme textes = Theme.of(context).textTheme;
    if (!r.estOk) {
      return Row(
        key: ClesLecteurMarkdown.illisible,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ExcludeSemantics(child: Icon(AppIcons.avertissement.repos)),
          Ecart.hSm,
          Expanded(
            child: TexteSansCoupure(
              t.tc.bibliotheque.rendu.texteIllisible,
              style: textes.bodyMedium,
            ),
          ),
        ],
      );
    }
    final List<BlocMd> blocs = r.blocs!;
    return Column(
      key: ClesLecteurMarkdown.document,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int i = 0; i < blocs.length; i++) ...<Widget>[
          if (i > 0) Ecart.vMd,
          _bloc(context, blocs[i]),
        ],
      ],
    );
  }

  Widget _bloc(BuildContext context, BlocMd bloc) {
    final TextTheme textes = Theme.of(context).textTheme;
    return switch (bloc) {
      TitreMd() => _texte(context, bloc.inlines, switch (bloc.niveau) {
        1 => textes.titleLarge,
        2 => textes.titleMedium,
        _ => textes.titleSmall,
      }, semantique: true),
      ParagrapheMd() => _texte(context, bloc.inlines, textes.bodyLarge),
      CitationMd() => _citation(context, bloc, textes),
      PucesMd() => _liste(
        context,
        bloc.items,
        (int i) => '•',
        textes.bodyLarge,
      ),
      NumeroteeMd() => _liste(
        context,
        bloc.items,
        (int i) => '${bloc.debut + i}.',
        textes.bodyLarge,
      ),
      SeparateurMd() => const Divider(height: AppSpacing.lg),
    };
  }

  String _brut(List<InlineMd> inlines) =>
      inlines.map((InlineMd i) => i.texte).join();

  /// Un texte a styles : le sens se lit sur le texte brut, le style arabe aussi.
  Widget _texte(
    BuildContext context,
    List<InlineMd> inlines,
    TextStyle? base, {
    bool semantique = false,
  }) {
    final String brut = _brut(inlines);
    final TextStyle? style = styleContenuArabe(brut, base);
    final bool arabe = commenceParArabe(brut);
    final Widget texte = Text.rich(
      TextSpan(
        style: style,
        children: <InlineSpan>[
          for (final InlineMd i in inlines)
            TextSpan(
              text: i.texte,
              style: switch (i) {
                // Plus gras que le texte courant, sans nombre pose ici.
                GrasMd() => style?.apply(fontWeightDelta: 2),
                ItaliqueMd() => const TextStyle(fontStyle: FontStyle.italic),
                TexteMd() => null,
              },
            ),
        ],
      ),
      textAlign: TextAlign.start,
    );
    final Widget dirige = arabe
        ? Directionality(textDirection: TextDirection.rtl, child: texte)
        : Directionality(textDirection: TextDirection.ltr, child: texte);
    return semantique ? Semantics(header: true, child: dirige) : dirige;
  }

  Widget _citation(BuildContext context, CitationMd c, TextTheme textes) {
    final ColorScheme couleurs = Theme.of(context).colorScheme;
    final bool arabe = commenceParArabe(_brut(c.inlines));
    return Directionality(
      textDirection: arabe ? TextDirection.rtl : TextDirection.ltr,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: BorderDirectional(
            start: BorderSide(color: couleurs.outline, width: 2),
          ),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.only(start: AppSpacing.md),
          child: _texte(context, c.inlines, textes.bodyLarge),
        ),
      ),
    );
  }

  Widget _liste(
    BuildContext context,
    List<List<InlineMd>> items,
    String Function(int) marque,
    TextStyle? base,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int i = 0; i < items.length; i++) ...<Widget>[
          if (i > 0) Ecart.vXs,
          Directionality(
            textDirection: commenceParArabe(_brut(items[i]))
                ? TextDirection.rtl
                : TextDirection.ltr,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // La marque a la largeur de son signe, a toute echelle de
                // texte : jamais une case fixe (a x2, « 1. » passait a la ligne).
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
                  child: ExcludeSemantics(
                    child: Text(
                      marque(i),
                      softWrap: false,
                      textDirection: TextDirection.ltr,
                      style: base,
                    ),
                  ),
                ),
                Expanded(child: _texte(context, items[i], base)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
