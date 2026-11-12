import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/priere/libelle_priere.dart';
import '../../core/priere/lieu_priere.dart';
import '../../core/priere/service_priere.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/carte_lignes.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/setting_row.dart';
import '../../core/widgets/skeleton.dart';
import '../creneaux/plages.dart' show jourCapitalise;

/// Ce que les creneaux d'une classe croisent, lu par la direction.
final FutureProviderFamily<List<LectureCreneauPriere>, String>
lectureClassePriereProvider =
    FutureProvider.family<List<LectureCreneauPriere>, String>(
      (Ref ref, String groupeId) =>
          ref.watch(servicePriereProvider).lectureClasse(groupeId),
    );

/// « Prieres et creneau » : le bloc en lecture seule de la fiche d'une classe
/// (PRIERE-1, P8 et P9).
///
/// Pour chaque creneau de la classe, sur les 12 mois a venir : quelles prieres
/// de l'enseignant il croise, sur quelles periodes, combien de seances ; le
/// chevauchement de la priere du vendredi ; les heures de debut sans priere ce
/// jour-la. **Un avertissement, jamais un blocage.** Tout vient du serveur,
/// changement d'heure de la classe compris.
///
/// Cinq etats : chargement, contenu, vide (l'enseignant n'a pas de lieu),
/// erreur, hors ligne (la lecture en echec le dit).
class BlocPriereClasse extends ConsumerWidget {
  /// Cree le bloc.
  const BlocPriereClasse({required this.classeId, super.key});

  /// La classe.
  final String classeId;

  /// La cle du bloc.
  static const Key cle = ValueKey<String>('bloc-priere-classe');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<LectureCreneauPriere>> lecture = ref.watch(
      lectureClassePriereProvider(classeId),
    );
    final TextTheme textes = Theme.of(context).textTheme;

    final Widget corps;
    if (lecture.hasError) {
      corps = EmptyState(
        message: t.priere.classe.erreur,
        icone: AppIcons.avertissement,
        libelleAction: t.commun.reessayer,
        onAction: () => ref.invalidate(lectureClassePriereProvider(classeId)),
      );
    } else if (!lecture.hasValue) {
      corps = const Skeleton.liste(lignes: 2);
    } else if (lecture.requireValue.isEmpty ||
        lecture.requireValue.every((LectureCreneauPriere c) => c.sansLieu)) {
      corps = Text(t.priere.classe.sansLieu, style: textes.bodyMedium);
    } else {
      corps = CarteLignes(
        lignes: <Widget>[
          for (final LectureCreneauPriere c in lecture.requireValue)
            SettingRow(
              title: t.priere.classe.creneau(
                jour: jourCapitalise(c.jour),
                heure: '${c.heure}',
                duree: '${c.dureeMinutes}',
              ),
              description: _lignes(context, c).join('\n'),
              icon: c.vendrediSeances > 0
                  ? AppIcons.avertissement
                  : AppIcons.priere,
            ),
        ],
      );
    }

    return Column(
      key: cle,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(t.priere.classe.titre, style: textes.titleMedium),
        Ecart.vSm,
        Text(t.priere.classe.intro, style: textes.bodyMedium),
        Ecart.vMd,
        corps,
      ],
    );
  }

  /// Les phrases d'un creneau, en mots simples.
  List<String> _lignes(BuildContext context, LectureCreneauPriere c) {
    final MaterialLocalizations dates = MaterialLocalizations.of(context);
    return <String>[
      if (c.croisements.isEmpty && !c.indefini) t.priere.classe.aucun,
      for (final CroisementPriere x in c.croisements)
        t.priere.classe.croise(
          priere: libellePriere(x.priere),
          du: dates.formatMediumDate(x.du),
          au: dates.formatMediumDate(x.au),
          seances: '${x.nbSeances}',
          pause: '${x.nbPause}',
          apres: '${x.nbApresCours}',
        ),
      if (c.indefini) t.priere.classe.indefini,
      if (c.vendrediAssiste && c.vendrediSeances > 0)
        t.priere.classe.vendredi(
          debut: c.vendrediDebut,
          fin: c.vendrediFin,
          n: '${c.vendrediSeances}',
        ),
      switch (c.heuresSansPriere) {
        null => t.priere.classe.libresInconnues,
        final List<int> h when h.isEmpty => t.priere.classe.libresAucune,
        final List<int> h => t.priere.classe.libres(
          heures: h
              .map((int x) => t.priere.classe.heureCourte(h: '$x'))
              .join(', '),
        ),
      },
    ];
  }
}
