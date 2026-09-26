import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/coran/service_coran.dart';
import '../../core/coran/vue_lecteur.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/tc_coran/etat_lecture_coran.dart';
import '../../core/tc_coran/moteur_mushaf.dart';
import '../../core/tc_coran/page_mushaf_vm.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/empty_state.dart';
import 'vue_verset_agrandi.dart';

/// Le rendu « focus », pret pour la classe.
///
/// Trois gestes, et rien d'autre : la plage active est **mise au centre**, le
/// chrome est **reduit**, et le texte est **grossi** si la place le permet.
///
/// **Le focus ne modifie jamais la source.** Il ne cree aucune copie du
/// support, il n'ecrit rien : c'est une lentille posee sur les memes versets
/// que les deux autres rendus. La plage vient de l'etat partage de la classe
/// quand il y en a un ; hors classe, il centre la page ouverte.
class VueFocusClasse extends ConsumerWidget {
  /// Cree le rendu focus.
  const VueFocusClasse({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final EtatLectureCoran etat = ref.watch(lectureCoranProvider);
    final AsyncValue<PageMushafVM> page = ref.watch(
      pageMushafProvider(etat.page),
    );

    if (!page.hasValue || page.value == null) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
    final PageMushafVM vue = page.value!;

    if (vue.etat == EtatLecteur.indisponible) {
      return Center(
        child: EmptyState(
          message: t.eleve.coran.indisponible,
          invitation: t.eleve.coran.indisponibleDetail,
          icone: AppIcons.horsLigne,
          libelleAction: t.eleve.coran.reessayer,
          onAction: () => ref.invalidate(pageCorpusProvider(vue.numero)),
        ),
      );
    }
    if (vue.etat != EtatLecteur.lecture) {
      return Center(
        child: EmptyState(
          message: t.eleve.coran.absent,
          invitation: t.eleve.coran.absentDetail,
          icone: AppIcons.rienAAfficher,
        ),
      );
    }

    final List<VersetCoran> retenus = versetsDansPlage(
      vue.versets,
      etat.plageFocus,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (etat.plageFocus == null) const _SansPlage(),
        Expanded(
          // Le passage retenu occupe le centre de l'ecran : c'est la seule
          // difference visible entre focus et lecture agrandie, et c'est celle
          // qui compte quand un enseignant dit « regardez ici ».
          child: Center(
            child: ColonneVersetsReflow(
              versets: retenus,
              zoom: etat.zoomLocal,
              sections: vue.sections,
            ),
          ),
        ),
      ],
    );
  }
}

/// Le mot discret qui explique un focus sans plage designee.
class _SansPlage extends StatelessWidget {
  const _SansPlage();

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Text(
        '${t.tc.coran.focus.aucunePlage}. '
        '${t.tc.coran.focus.aucunePlageDetail}',
        textAlign: TextAlign.center,
        style: palette.inkMuted.applyTo(
          textes.labelSmall ?? const TextStyle(),
        ),
      ),
    );
  }
}
