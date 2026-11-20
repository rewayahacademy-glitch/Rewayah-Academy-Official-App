// LETTRE-CANDIDATS (directeur, 20/11/2026) : le corps d'une partie de la
// lettre aux candidats enseignants.
//
// Le texte vient des traductions (`recrutement.lettre.parties.pN.corps`),
// ecrit dans une forme simple que la direction relit sans outil : un
// paragraphe par bloc, `### ` pour un sous-titre, `- ` pour une puce, `1. `
// pour une etape, `|` pour le tableau de la paie, `**...**` pour le gras.
// Ce fichier lit cette forme ; il n'ecrit aucun mot.
import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/carte_groupee.dart';

/// Un bloc du corps.
sealed class BlocLettre {
  const BlocLettre();
}

/// Un paragraphe.
class ParagrapheLettre extends BlocLettre {
  /// Cree le paragraphe.
  const ParagrapheLettre(this.texte);

  /// Le texte, gras compris (`**...**`).
  final String texte;
}

/// Un sous-titre (`### `).
class SousTitreLettre extends BlocLettre {
  /// Cree le sous-titre.
  const SousTitreLettre(this.texte);

  /// Le texte.
  final String texte;
}

/// Une liste, a puces ou numerotee.
class ListeLettre extends BlocLettre {
  /// Cree la liste.
  const ListeLettre(this.elements, {required this.numerotee});

  /// Les elements.
  final List<String> elements;

  /// Vrai pour des etapes numerotees.
  final bool numerotee;
}

/// Le tableau : une ligne d'en-tete, puis une ligne par sujet.
class TableauLettre extends BlocLettre {
  /// Cree le tableau.
  const TableauLettre(this.entete, this.lignes);

  /// Les en-tetes de colonnes (la premiere, vide, est celle des sujets).
  final List<String> entete;

  /// Les lignes : le sujet, puis une valeur par colonne.
  final List<List<String>> lignes;
}

final RegExp _etape = RegExp(r'^\d+\.\s+');

/// Lit le corps [brut] en blocs.
List<BlocLettre> lireCorps(String brut) {
  final List<String> lignes = brut.split('\n');
  final List<BlocLettre> blocs = <BlocLettre>[];
  int i = 0;
  while (i < lignes.length) {
    final String l = lignes[i].trim();
    if (l.isEmpty) {
      i++;
      continue;
    }
    if (l.startsWith('### ')) {
      blocs.add(SousTitreLettre(l.substring(4).trim()));
      i++;
      continue;
    }
    if (l.startsWith('|')) {
      final List<List<String>> rangs = <List<String>>[];
      while (i < lignes.length && lignes[i].trim().startsWith('|')) {
        final String r = lignes[i].trim();
        final List<String> cases = r
            .substring(1, r.endsWith('|') ? r.length - 1 : r.length)
            .split('|')
            .map((String c) => c.trim())
            .toList();
        final bool separateur = cases.every(
          (String c) => RegExp(r'^:?-+:?$').hasMatch(c),
        );
        if (!separateur) rangs.add(cases);
        i++;
      }
      if (rangs.isNotEmpty) {
        blocs.add(TableauLettre(rangs.first, rangs.skip(1).toList()));
      }
      continue;
    }
    if (l.startsWith('- ') || _etape.hasMatch(l)) {
      final bool numerotee = !l.startsWith('- ');
      final List<String> elements = <String>[];
      while (i < lignes.length) {
        final String e = lignes[i].trim();
        if (numerotee ? !_etape.hasMatch(e) : !e.startsWith('- ')) break;
        elements.add(e.replaceFirst(numerotee ? _etape : '- ', ''));
        i++;
      }
      blocs.add(ListeLettre(elements, numerotee: numerotee));
      continue;
    }
    // Un paragraphe : jusqu'a la prochaine ligne vide ou un autre bloc. Une
    // question en gras et sa reponse, sur deux lignes, font deux paragraphes.
    blocs.add(ParagrapheLettre(l));
    i++;
  }
  return blocs;
}

/// Le texte avec ses espaces insecables : jamais un « : » ou un « ? » seul
/// en debut de ligne (typographie francaise ; sans effet ailleurs).
String insecables(String s) => s
    .replaceAllMapped(RegExp(r' ([:;?!»%$])'), (Match m) => ' ${m[1]}')
    .replaceAll('« ', '« ');

/// Les morceaux de [texte], le gras (`**...**`) en gras.
TextSpan morceaux(String texte, TextStyle style) {
  final List<String> parts = insecables(texte).split('**');
  return TextSpan(
    style: style,
    children: <InlineSpan>[
      for (int k = 0; k < parts.length; k++)
        if (parts[k].isNotEmpty)
          TextSpan(
            text: parts[k],
            style: k.isOdd
                ? AppTypography.graisse(style, FontWeight.w700)
                : null,
          ),
    ],
  );
}

/// Le corps d'une partie, rendu bloc par bloc.
class CorpsLettre extends StatelessWidget {
  /// Cree le corps a partir du texte [brut].
  const CorpsLettre({required this.brut, super.key});

  /// Le texte de la partie.
  final String brut;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle corps = palette.inkStrong.applyTo(
      textes.bodyLarge ?? const TextStyle(),
    );
    final TextStyle muet = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    final List<Widget> enfants = <Widget>[];
    for (final BlocLettre b in lireCorps(brut)) {
      enfants.add(switch (b) {
        ParagrapheLettre(:final String texte) => Text.rich(
          morceaux(texte, corps),
        ),
        SousTitreLettre(:final String texte) => Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: Semantics(
            header: true,
            child: Text(
              insecables(texte),
              style: palette.inkStrong.applyTo(
                textes.titleMedium ?? const TextStyle(),
              ),
            ),
          ),
        ),
        ListeLettre(:final List<String> elements, :final bool numerotee) =>
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.sm,
            children: <Widget>[
              for (int k = 0; k < elements.length; k++)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                      width: AppSpacing.xxl,
                      child: ExcludeSemantics(
                        child: Text(
                          numerotee ? '${k + 1}.' : '•',
                          style: palette.inkAccent.applyTo(corps),
                        ),
                      ),
                    ),
                    Expanded(child: Text.rich(morceaux(elements[k], corps))),
                  ],
                ),
            ],
          ),
        TableauLettre(
          :final List<String> entete,
          :final List<List<String>> lignes,
        ) =>
          // Un tableau a trois colonnes ne tient pas a 320 points : chaque
          // sujet devient une section de la carte, ses valeurs dessous.
          CarteGroupee(
            sections: <Widget>[
              for (final List<String> ligne in lignes)
                Semantics(
                  container: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    spacing: AppSpacing.xs,
                    children: <Widget>[
                      Text.rich(
                        morceaux(
                          ligne.first,
                          palette.inkStrong.applyTo(
                            textes.titleSmall ?? const TextStyle(),
                          ),
                        ),
                      ),
                      for (int c = 1; c < ligne.length; c++) ...<Widget>[
                        if (c < entete.length && entete[c].isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.xs),
                            child: Text(insecables(entete[c]), style: muet),
                          ),
                        Text.rich(morceaux(ligne[c], corps)),
                      ],
                    ],
                  ),
                ),
            ],
          ),
      });
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.md,
      children: enfants,
    );
  }
}
