import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/admin/service_plan_classe.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/skeleton.dart';
import '../admin_groupes/niveau_classe.dart' show refusPlanClasse;

/// PLAN-DE-CLASSE A : qui n'a pas d'etape, et pourquoi, d'un seul regard, avec
/// le geste de rattachement. Le serveur dit la raison de chaque eleve
/// (`eleves_sans_etape`) ; l'ecran ne la deduit pas.
///
/// Se pose en tete de Diagnostics, qu'il complete : la file des placements
/// (un eleve a la fois) reste dessous, inchangee. Rien ne s'affiche quand tout
/// le monde a son etape, sauf une ligne qui le dit.
class SectionPlacementsAFaire extends ConsumerWidget {
  /// Cree la section.
  const SectionPlacementsAFaire({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<PlacementsAFaire> lecture = ref.watch(
      placementsAFaireProvider,
    );
    final TextTheme textes = Theme.of(context).textTheme;
    final Widget contenu = switch (lecture) {
      AsyncValue<PlacementsAFaire>(hasError: true) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(t.admin.planClasse.sansEtape.erreurLecture),
          Ecart.vMd,
          LienFleche(
            libelle: t.admin.planClasse.sansEtape.relire,
            onPress: () => ref.invalidate(placementsAFaireProvider),
          ),
        ],
      ),
      AsyncValue<PlacementsAFaire>(hasValue: true) =>
        lecture.requireValue.vide
            ? Text(
                t.admin.planClasse.sansEtape.toutPlace,
                style: textes.bodyMedium,
              )
            : _Liste(placements: lecture.requireValue),
      _ => const Skeleton.liste(lignes: 3),
    };
    // WEB-BUREAU B4 : un texte suivi ne depasse pas la largeur de lecture.
    return Align(
      alignment: AlignmentDirectional.topStart,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppPage.largeurLecture),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(t.admin.planClasse.sansEtape.titre, style: textes.titleLarge),
            Ecart.vSm,
            Text(t.admin.planClasse.sansEtape.intro, style: textes.bodyMedium),
            Ecart.vLg,
            contenu,
            Ecart.vXxl,
          ],
        ),
      ),
    );
  }
}

class _Liste extends ConsumerWidget {
  const _Liste({required this.placements});

  final PlacementsAFaire placements;

  String _raison(RaisonSansEtape r) => switch (r) {
    RaisonSansEtape.aucunProgramme =>
      t.admin.planClasse.sansEtape.raisonAucunProgramme,
    RaisonSansEtape.attenteEntretien =>
      t.admin.planClasse.sansEtape.raisonAttente,
    RaisonSansEtape.debutantARattacher =>
      t.admin.planClasse.sansEtape.raisonDebutant,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme textes = Theme.of(context).textTheme;
    // Une seule carte a lignes fines (K-55) : des contenus lies.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (placements.classes.isNotEmpty) ...<Widget>[
                Text(
                  t.admin.planClasse.sansEtape.classesTitre,
                  style: textes.titleMedium,
                ),
                Ecart.vSm,
                for (final ClasseSansEtape c in placements.classes) ...<Widget>[
                  Text(c.nom, style: textes.bodyLarge),
                  Text(
                    t.admin.planClasse.sansEtape.membres(n: c.membres),
                    style: textes.bodySmall,
                  ),
                  Ecart.vSm,
                ],
                Ecart.vMd,
              ],
              if (placements.eleves.isNotEmpty) ...<Widget>[
                Text(
                  t.admin.planClasse.sansEtape.titre,
                  style: textes.titleMedium,
                ),
                Ecart.vSm,
                for (final EleveSansEtape e in placements.eleves) ...<Widget>[
                  Text(e.libelle, style: textes.bodyLarge),
                  Text(
                    '${e.classe}. ${_raison(e.raison)}',
                    style: textes.bodySmall,
                  ),
                  Ecart.vSm,
                ],
              ],
            ],
          ),
        ),
        if (placements.programmePublie &&
            (placements.classes.isNotEmpty ||
                placements.debutants > 0)) ...<Widget>[
          Ecart.vLg,
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: ActionPrincipale(
              key: const ValueKey<String>('placements-rattacher'),
              libelle: t.admin.planClasse.sansEtape.rattacher,
              niveau: NiveauAction.secondaire,
              pleineLargeur: false,
              onPress: () => _ouvrirRattachement(context, ref),
            ),
          ),
        ],
      ],
    );
  }

  void _ouvrirRattachement(BuildContext context, WidgetRef ref) {
    AppBottomSheet.ouvrir<void>(
      context,
      titre: t.admin.planClasse.sansEtape.rattacherTitre,
      constructeur: (BuildContext contexte) => const _FeuilleRattachement(),
    );
  }
}

class _FeuilleRattachement extends ConsumerStatefulWidget {
  const _FeuilleRattachement();

  @override
  ConsumerState<_FeuilleRattachement> createState() =>
      _FeuilleRattachementEtat();
}

class _FeuilleRattachementEtat extends ConsumerState<_FeuilleRattachement> {
  bool _envoi = false;
  bool _fait = false;
  String? _erreur;

  Future<void> _rattacher() async {
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await ref.read(servicePlanClasseProvider).rattacher();
      ref.invalidate(placementsAFaireProvider);
      if (mounted) setState(() => _fait = true);
    } catch (erreur) {
      if (mounted) {
        setState(
          () => _erreur = refusPlanClasse(
            erreur,
            (String brut) =>
                t.admin.planClasse.sansEtape.rattacherErreur(message: brut),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          _fait
              ? t.admin.planClasse.sansEtape.rattacherFait
              : t.admin.planClasse.sansEtape.rattacherDetail,
          style: textes.bodyMedium,
        ),
        if (_erreur != null) ...<Widget>[
          Ecart.vMd,
          Semantics(
            liveRegion: true,
            child: Text(
              _erreur!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
        if (!_fait) ...<Widget>[
          Ecart.vLg,
          ActionPrincipale(
            libelle: t.admin.planClasse.sansEtape.rattacherEnvoyer,
            enCours: _envoi,
            onPress: () => unawaited(_rattacher()),
          ),
        ],
      ],
    );
  }
}
