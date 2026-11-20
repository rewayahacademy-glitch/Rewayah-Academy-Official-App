// PRAXIS-VISIBLE : les objectifs que Praxis se fixe (`direction_praxis_objectifs`,
// PX-3), en tete de la page « Le travail de Praxis ». Lecture seule : Praxis
// les fixe et les clot lui-meme, la direction les regarde.
//
// Trois parties dans une seule carte : les objectifs du jour ouverts, ceux de
// la semaine ouverts (avec leur cible quand Praxis en a fixe une, et « Periode
// passee » quand le serveur la dit echue), puis les objectifs clos recemment
// (atteint ou abandonne, avec la note de Praxis).
//
// Etats : chargement (squelette), contenu, vide, erreur (« Reessayer »), hors
// ligne ; un refus du serveur ne rend rien (la page dit deja le refus).
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
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import 'libelles_praxis.dart';

/// Les cles du bloc, pour les tests.
abstract final class ClesObjectifsPraxis {
  /// Le bloc entier (contenu).
  static const Key bloc = ValueKey<String>('praxis-objectifs');

  /// Le squelette.
  static const Key chargement = ValueKey<String>('praxis-objectifs-chargement');

  /// L'erreur ou le hors ligne.
  static const Key erreur = ValueKey<String>('praxis-objectifs-erreur');

  /// Aucun objectif.
  static const Key vide = ValueKey<String>('praxis-objectifs-vide');

  /// La ligne d'un objectif.
  static Key objectif(String id) => ValueKey<String>('praxis-objectif-$id');
}

/// Le nombre d'objectifs clos montres au plus.
const int objectifsClosMontres = 5;

/// Le bloc « Objectifs de Praxis ».
class ObjectifsPraxis extends ConsumerWidget {
  /// Cree le bloc.
  const ObjectifsPraxis({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final o = t.admin.praxis.objectifs;
    final AsyncValue<List<ObjectifPraxis>> lus = ref.watch(
      objectifsPraxisProvider,
    );
    if (lus.error is PermissionInsuffisante) return const SizedBox.shrink();
    final TextStyle attenue = AppPalette.of(context).inkMuted
        .applyTo(Theme.of(context).textTheme.bodyMedium ?? const TextStyle());
    final Widget corps;
    if (lus.hasError) {
      void relire() => ref.invalidate(objectifsPraxisProvider);
      final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
      corps = KeyedSubtree(
        key: ClesObjectifsPraxis.erreur,
        child: horsLigne
            ? EtatSansDonnees(quoi: o.horsLigne, onAction: relire)
            : EmptyState(
                message: o.erreur,
                icone: AppIcons.avertissement,
                libelleAction: t.commun.reessayer,
                onAction: relire,
              ),
      );
    } else if (!lus.hasValue) {
      corps = const Skeleton(key: ClesObjectifsPraxis.chargement, hauteur: 120);
    } else if (lus.requireValue.isEmpty) {
      corps = EmptyState(
        key: ClesObjectifsPraxis.vide,
        message: o.aucun,
        invitation: o.aucunDetail,
        icone: AppIcons.rienAAfficher,
        registre: RegistreVide.subi,
      );
    } else {
      corps = _Contenu(objectifs: lus.requireValue);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SectionHeader(titre: o.titre),
        Ecart.vXs,
        TexteSansCoupure(o.intro, style: attenue),
        Ecart.vMd,
        corps,
      ],
    );
  }
}

class _Contenu extends StatelessWidget {
  const _Contenu({required this.objectifs});

  final List<ObjectifPraxis> objectifs;

  @override
  Widget build(BuildContext context) {
    final o = t.admin.praxis.objectifs;
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle sousTitre = palette.inkStrong.applyTo(
      textes.titleSmall ?? const TextStyle(),
    );
    final TextStyle corps = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    List<ObjectifPraxis> ouverts(PeriodeObjectif p) => <ObjectifPraxis>[
      for (final ObjectifPraxis x in objectifs)
        if (x.etat == EtatObjectif.ouvert && x.periode == p) x,
    ];
    final List<ObjectifPraxis> clos =
        <ObjectifPraxis>[
          for (final ObjectifPraxis x in objectifs)
            if (x.etat != EtatObjectif.ouvert) x,
        ]..sort(
          (ObjectifPraxis a, ObjectifPraxis b) =>
              (b.closLe ?? b.creeLe).compareTo(a.closLe ?? a.creeLe),
        );

    Widget partie(String titre, List<ObjectifPraxis> liste, String vide) =>
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TexteSansCoupure(titre, style: sousTitre),
            Ecart.vSm,
            if (liste.isEmpty)
              TexteSansCoupure(vide, style: corps)
            else
              for (int k = 0; k < liste.length; k++) ...<Widget>[
                if (k > 0) Ecart.vMd,
                _LigneObjectif(objectif: liste[k]),
              ],
          ],
        );

    return CarteGroupee(
      key: ClesObjectifsPraxis.bloc,
      sections: <Widget>[
        partie(o.jour, ouverts(PeriodeObjectif.jour), o.aucunJour),
        partie(o.semaine, ouverts(PeriodeObjectif.semaine), o.aucunSemaine),
        if (clos.isNotEmpty)
          partie(o.clos, clos.take(objectifsClosMontres).toList(), ''),
      ],
    );
  }
}

class _LigneObjectif extends StatelessWidget {
  const _LigneObjectif({required this.objectif});

  final ObjectifPraxis objectif;

  @override
  Widget build(BuildContext context) {
    final o = t.admin.praxis.objectifs;
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle attenue = palette.inkMuted.applyTo(
      textes.bodySmall ?? const TextStyle(),
    );
    final ObjectifPraxis x = objectif;
    final String quand = x.periode == PeriodeObjectif.jour
        ? o.pourLe(date: datePraxis(x.debut))
        : o.semaineDu(date: datePraxis(x.debut));
    final bool ouvert = x.etat == EtatObjectif.ouvert;
    final String meta = <String>[
      quand,
      if (x.cible case final int c) o.cible(n: '$c'),
      if (!ouvert && x.closLe != null) o.closLe(date: jourPraxis(x.closLe!)),
    ].join(' · ');
    return Column(
      key: ClesObjectifsPraxis.objectif(x.id),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        TexteSansCoupure(
          x.libelle,
          style: palette.inkStrong.applyTo(
            textes.bodyMedium ?? const TextStyle(),
          ),
        ),
        Ecart.vXs,
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            if (!ouvert)
              StatusPill(
                libelle: x.etat == EtatObjectif.atteint
                    ? o.atteint
                    : o.abandonne,
                ton: x.etat == EtatObjectif.atteint
                    ? TonEtat.succes
                    : TonEtat.neutre,
              )
            else if (x.echu)
              StatusPill(libelle: o.echu, ton: TonEtat.avertissement),
            TexteSansCoupure(meta, style: attenue),
          ],
        ),
        if (x.noteCloture case final String note) ...<Widget>[
          Ecart.vXs,
          TexteSansCoupure(note, style: attenue),
        ],
      ],
    );
  }
}
