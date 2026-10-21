// La liste des canaux du Studio (`StudioChannelList`, spec section 9.1,
// section 19 « canaux, sections, non lus » ; COM-M03, COM-W03, colonne
// « Canaux »).
//
// Les canaux sont ranges par section, dans l'ordre de la taxonomie (spec
// section 9.1). Une section sans canal autorise n'est pas rendue, et un
// canal absent n'est jamais rendu : ni ligne, ni cadenas (R-COM-08). Chaque
// section est UNE surface a filets (`GroupeReglages`), jamais une carte par
// canal (K-55) ; deux sections sont detachees par l'ecart de section du
// contrat A : 24 sur telephone, 32 a partir de 600 (UX_REVIEW_COM-STU-1
// point 6, COM-R-4 8.3-3).
//
// Une ligne dit le nom du canal, son statut s'il est restreint ou prive (en
// toutes lettres, `MarqueVisibiliteCanal`) et ce qui attend (badge
// d'attention, en mots et en icone, jamais la couleur seule). Ce que la
// maquette ajoute et que la spec n'a pas (crayon « nouveau canal »,
// « Nouvel espace », favoris, presence) n'est pas repris (UX_REVIEW L0,
// ecart 14).

import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/badge_non_lu.dart';
import '../../core/widgets/groupe_reglages.dart';
import 'port_studio.dart';
import 'visibilite_canal.dart';

/// Le nom d'une section du Studio (spec section 9.1).
String libelleSection(SectionStudio section) {
  final s = t.com.studio.sections;
  return switch (section) {
    SectionStudio.organisation => s.organisation,
    SectionStudio.admissionsFamilles => s.admissionsFamilles,
    SectionStudio.pedagogieQualite => s.pedagogieQualite,
    SectionStudio.planningRemplacements => s.planningRemplacements,
    SectionStudio.finance => s.finance,
    SectionStudio.support => s.support,
    SectionStudio.produitTechnique => s.produitTechnique,
    SectionStudio.direction => s.direction,
  };
}

/// Les canaux rendus, ranges par section dans l'ordre de la taxonomie ; a
/// l'interieur d'une section, l'ordre donne par le serveur est garde. Une
/// section vide n'apparait pas ; un canal absent non plus (R-COM-08).
List<(SectionStudio, List<ResumeCanal>)> canauxParSection(
  List<ResumeCanal> canaux,
) {
  final List<ResumeCanal> rendus = canauxRendus(
    canaux,
    (ResumeCanal c) => c.visibilite,
  );
  return <(SectionStudio, List<ResumeCanal>)>[
    for (final SectionStudio s in SectionStudio.values)
      if (rendus.any((ResumeCanal c) => c.section == s))
        (
          s,
          <ResumeCanal>[
            for (final ResumeCanal c in rendus)
              if (c.section == s) c,
          ],
        ),
  ];
}

/// La liste des canaux (`StudioChannelList`).
///
/// [entete] se pose au-dessus des sections (la recherche du Studio) ; la
/// liste defile sous lui. Sa position est gardee par la cle de stockage
/// ci-dessous, dans la memoire du Studio (`positionsStudioProvider`) que
/// l'espace pose au-dessus d'elle : sans cette memoire, chaque route du
/// Studio recreerait sa page et la liste remonterait en haut.
class ListeCanaux extends StatelessWidget {
  /// Cree la liste.
  const ListeCanaux({
    required this.canaux,
    required this.onOuvrir,
    super.key,
    this.canalSelectionne,
    this.entete,
  });

  /// Les canaux autorises, tels que le port les rend.
  final List<ResumeCanal> canaux;

  /// Ouvre le canal d'identifiant donne.
  final ValueChanged<String> onOuvrir;

  /// Le canal ouvert a cote de la liste (maitre-detail), annonce comme
  /// selectionne ; `null` sur telephone, ou aucun canal n'est a cote.
  final String? canalSelectionne;

  /// Ce qui se pose au-dessus des sections (le champ de recherche).
  final Widget? entete;

  /// La cle du badge d'attention d'un canal, pour les tests.
  static ValueKey<String> cleBadge(String canalId) =>
      ValueKey<String>('studio-badge-$canalId');

  /// La cle du groupe d'une section, pour les tests.
  static ValueKey<String> cleSection(SectionStudio section) =>
      ValueKey<String>('studio-section-${section.name}');

  @override
  Widget build(BuildContext context) {
    final List<(SectionStudio, List<ResumeCanal>)> sections = canauxParSection(
      canaux,
    );
    final Widget? entete = this.entete;
    // La largeur de la fenetre, pas celle de la colonne : la liste garde
    // 256 a 336 sur tablette et ordinateur, ou l'ecart reste de 32.
    final bool telephone = AppGabarit.de(context) == Gabarit.mobile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (entete != null) ...<Widget>[entete, Ecart.vLg],
        Expanded(
          child: ListView(
            // La position de lecture survit a l'aller-retour d'un canal
            // (memoire du Studio, au-dessus des pages routees).
            key: const PageStorageKey<String>('studio-liste-canaux'),
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            children: <Widget>[
              for (final (int i, (SectionStudio, List<ResumeCanal>) s)
                  in sections.indexed) ...<Widget>[
                // 24 sur telephone, 32 au-dela (deux lignes : la revue des cartes
                // lit chaque ecart comme un jeton).
                if (i > 0 && telephone) Ecart.vXxl,
                if (i > 0 && !telephone) Ecart.vXxxl,
                GroupeReglages(
                  key: cleSection(s.$1),
                  titre: libelleSection(s.$1),
                  lignes: <LigneRubrique>[
                    for (final ResumeCanal c in s.$2) _ligne(c),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  LigneRubrique _ligne(ResumeCanal c) {
    final String? selection = canalSelectionne;
    return LigneRubrique(
      libelle: c.nom,
      legende: c.description,
      pastille: c.visibilite.estDit
          ? MarqueVisibiliteCanal(
              key: ValueKey<String>('studio-visibilite-${c.id}'),
              visibilite: c.visibilite,
            )
          : null,
      marque: c.attention.estVisible
          ? KeyedSubtree(
              key: cleBadge(c.id),
              child: BadgeNonLu(indicateur: c.attention, compact: true),
            )
          : null,
      selectionnee: selection == null ? null : c.id == selection,
      onPress: () => onOuvrir(c.id),
    );
  }
}
