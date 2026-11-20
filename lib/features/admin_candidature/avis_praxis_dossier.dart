// PRAXIS-VISIBLE : « L'avis de Praxis » dans le dossier d'un candidat, a cote
// des informations du dossier (colonne de gauche au bureau, sous les
// propositions ; dans le fil de la page au telephone).
//
// La carte montre ce que le serveur rend, mot pour mot : l'etiquette, la
// confiance, les criteres notes (eux seuls), la synthese en phrases, le
// contexte (theme, constat, effet, source), le texte court, la date, et la pile
// ou Praxis a range le dossier avec sa raison. Une phrase fixe le rappelle :
// « Un avis de l'assistant, pas une decision. » Rien ne s'y decide.
//
// Etats : chargement (squelette), contenu, « pas encore lu » (phrase calme),
// erreur (phrase vraie et « Reessayer »), hors ligne (l'etat commun). Un refus
// du serveur (lecteur qui n'est pas la direction : un associe) ne rend rien :
// la carte n'est pas pour lui, et une panne ne serait pas vraie.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/agent/travail_praxis.dart';
import '../../core/capacites/permission_insuffisante.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/carte_groupee.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import '../admin_candidatures/libelles_praxis.dart';

/// Les cles de la carte, pour les tests.
abstract final class ClesAvisPraxis {
  /// La carte entiere.
  static const Key carte = ValueKey<String>('avis-praxis-carte');

  /// Le squelette de chargement.
  static const Key chargement = ValueKey<String>('avis-praxis-chargement');

  /// L'etat d'erreur ou hors ligne.
  static const Key erreur = ValueKey<String>('avis-praxis-erreur');

  /// La phrase « Praxis n'a pas encore lu ce dossier ».
  static const Key pasLu = ValueKey<String>('avis-praxis-pas-lu');

  /// La phrase fixe « Un avis de l'assistant, pas une decision ».
  static const Key rappel = ValueKey<String>('avis-praxis-rappel');

  /// La section de la pile.
  static const Key pile = ValueKey<String>('avis-praxis-pile');

  /// La section des criteres.
  static const Key criteres = ValueKey<String>('avis-praxis-criteres');

  /// La section du contexte.
  static const Key contexte = ValueKey<String>('avis-praxis-contexte');

  /// La section de la synthese.
  static const Key synthese = ValueKey<String>('avis-praxis-synthese');
}

/// Les phrases lisibles de la synthese, dans l'ordre du serveur.
List<String> phrasesSynthese(SynthesePraxis s) {
  final a = t.admin.praxis.avis;
  final String? pourquoi = s.videoPourquoi;
  return <String>[
    if (s.utilePour case final String x) a.utilePour(texte: x),
    if (s.situation case final String x) a.situation(texte: x),
    if (s.reserves case final String x) a.reserves(texte: x),
    if (s.video == true)
      pourquoi == null ? a.videoOui : a.videoOuiParce(texte: pourquoi)
    else if (s.video == false)
      pourquoi == null ? a.videoNon : a.videoNonParce(texte: pourquoi)
    else if (pourquoi != null)
      a.videoParce(texte: pourquoi),
  ];
}

/// La carte « L'avis de Praxis » du dossier [reference].
class AvisPraxisDossier extends ConsumerWidget {
  /// Cree la carte.
  const AvisPraxisDossier({required this.reference, super.key});

  /// La reference du dossier (`CAND-...`).
  final String reference;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<PageImpressions> impressions = ref.watch(
      impressionsPraxisProvider,
    );
    final AsyncValue<PageRangements> rangements = ref.watch(
      rangementsPraxisProvider,
    );
    final a = t.admin.praxis.avis;
    // Un refus du serveur : la carte n'est pas pour ce lecteur.
    if (impressions.error is PermissionInsuffisante ||
        rangements.error is PermissionInsuffisante) {
      return const SizedBox.shrink();
    }
    if (impressions.hasError || rangements.hasError) {
      void relire() {
        ref
          ..invalidate(impressionsPraxisProvider)
          ..invalidate(rangementsPraxisProvider);
      }

      final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
      return KeyedSubtree(
        key: ClesAvisPraxis.erreur,
        child: horsLigne
            ? EtatSansDonnees(quoi: a.horsLigne, onAction: relire)
            : EmptyState(
                message: a.erreur,
                icone: AppIcons.avertissement,
                libelleAction: t.commun.reessayer,
                onAction: relire,
              ),
      );
    }
    if (!impressions.hasValue || !rangements.hasValue) {
      return const Skeleton(key: ClesAvisPraxis.chargement, hauteur: 160);
    }
    ImpressionPraxis? impression;
    for (final ImpressionPraxis i in impressions.requireValue.lignes) {
      if (i.reference == reference) impression = i;
    }
    RangementPraxis? rangement;
    for (final RangementPraxis r in rangements.requireValue.lignes) {
      if (r.reference == reference) rangement = r;
    }
    return CarteAvisPraxis(impression: impression, rangement: rangement);
  }
}

/// Le rendu de la carte, une fois les lectures faites (sans lecture : les
/// captures et les tests le montent seul).
class CarteAvisPraxis extends StatelessWidget {
  /// Cree le rendu.
  const CarteAvisPraxis({
    required this.impression,
    required this.rangement,
    super.key,
  });

  /// L'impression courante du dossier, ou `null` : pas encore lu.
  final ImpressionPraxis? impression;

  /// Le rangement courant du dossier, ou `null` : pas encore range.
  final RangementPraxis? rangement;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final a = t.admin.praxis.avis;
    final TextStyle corps = palette.inkStrong.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    final TextStyle attenue = palette.inkMuted.applyTo(
      textes.bodySmall ?? const TextStyle(),
    );
    final TextStyle sousTitre = palette.inkStrong.applyTo(
      textes.titleSmall ?? const TextStyle(),
    );
    final ImpressionPraxis? i = impression;
    final RangementPraxis? r = rangement;

    Widget section(Key? cle, String titre, List<Widget> enfants) => Column(
      key: cle,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        TexteSansCoupure(titre, style: sousTitre),
        Ecart.vSm,
        ...enfants,
      ],
    );

    final Widget tete = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Semantics(
          header: true,
          child: TexteSansCoupure(
            a.titre,
            style: palette.inkStrong.applyTo(
              textes.titleMedium ?? const TextStyle(),
            ),
          ),
        ),
        Ecart.vXs,
        TexteSansCoupure(a.rappel, key: ClesAvisPraxis.rappel, style: attenue),
        Ecart.vMd,
        if (i == null)
          TexteSansCoupure(a.pasLu, key: ClesAvisPraxis.pasLu, style: corps)
        else ...<Widget>[
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              StatusPill(
                libelle: libelleEtiquette(i.etiquette),
                ton: tonEtiquette(i.etiquette),
              ),
              TexteSansCoupure(
                a.confiance(niveau: libelleConfiance(i.confiance)),
                style: corps,
              ),
            ],
          ),
          Ecart.vSm,
          TexteSansCoupure(
            a.notee(date: jourPraxis(i.noteeLe), heure: heurePraxis(i.noteeLe)),
            style: attenue,
          ),
        ],
      ],
    );

    final List<Widget> sections = <Widget>[
      tete,
      section(ClesAvisPraxis.pile, a.rangement, <Widget>[
        if (r == null)
          TexteSansCoupure(a.pasRange, style: corps)
        else ...<Widget>[
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: StatusPill(
              libelle: a.pile(pile: libellePile(r.pile)),
              ton: tonPile(r.pile),
            ),
          ),
          if (r.raison.isNotEmpty) ...<Widget>[
            Ecart.vSm,
            TexteSansCoupure(r.raison, style: corps),
          ],
          Ecart.vXs,
          TexteSansCoupure(
            a.rangeLe(
              date: jourPraxis(r.rangeLe),
              heure: heurePraxis(r.rangeLe),
            ),
            style: attenue,
          ),
        ],
      ]),
      if (i != null && i.notes.isNotEmpty)
        section(ClesAvisPraxis.criteres, a.criteres, <Widget>[
          for (final MapEntry<CriterePraxis, int> n in i.notes.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: TexteSansCoupure(
                a.note(critere: libelleCritere(n.key), note: '${n.value}'),
                style: corps,
              ),
            ),
        ]),
      if (i?.synthese case final SynthesePraxis s)
        section(ClesAvisPraxis.synthese, a.synthese, <Widget>[
          for (final String phrase in phrasesSynthese(s))
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: TexteSansCoupure(phrase, style: corps),
            ),
        ]),
      if (i != null && i.contexte.isNotEmpty)
        section(ClesAvisPraxis.contexte, a.contexte, <Widget>[
          for (int k = 0; k < i.contexte.length; k++) ...<Widget>[
            if (k > 0) Ecart.vMd,
            _ElementContexte(element: i.contexte[k]),
          ],
        ]),
      if (i != null && i.texte.isNotEmpty)
        section(null, a.texte, <Widget>[
          TexteSansCoupure(i.texte, style: corps),
        ]),
    ];
    return CarteGroupee(key: ClesAvisPraxis.carte, sections: sections);
  }
}

class _ElementContexte extends StatelessWidget {
  const _ElementContexte({required this.element});

  final ElementContexte element;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final a = t.admin.praxis.avis;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            TexteSansCoupure(
              element.theme,
              // Plus petit que le titre de la section (HIER-1), plus gras que
              // le constat.
              style: palette.inkStrong.applyTo(
                (textes.bodyMedium ?? const TextStyle()).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            StatusPill(
              libelle: libelleEffet(element.effet),
              ton: tonEffet(element.effet),
            ),
          ],
        ),
        Ecart.vXs,
        TexteSansCoupure(
          element.constat,
          style: palette.inkStrong.applyTo(
            textes.bodyMedium ?? const TextStyle(),
          ),
        ),
        if (element.source.isNotEmpty)
          TexteSansCoupure(
            a.source(source: element.source),
            style: palette.inkMuted.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
      ],
    );
  }
}
