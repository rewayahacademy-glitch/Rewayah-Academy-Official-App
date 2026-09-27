import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/enseignant/modeles_enseignant.dart';
import '../../core/enseignant/service_enseignant.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import '../fiche_groupe/fiche_groupe_page.dart' show SortieEspaceClasse;
import 'anomalies_revue.dart';

/// `ENS-08` : la revue courte d'un groupe.
///
/// **Elle n'affiche que les anomalies produites par le systeme.** Aucun rapport
/// narratif n'est demande, aucune echeance ne rappelle : un enseignant a qui
/// l'on reclame un texte chaque mois cesse d'ecrire des textes utiles au
/// troisieme mois. Elle ne resume pas le groupe non plus -- c'est `ENS-07` qui
/// le fait -- et elle ne s'ouvre que depuis la fiche du groupe ou depuis une
/// anomalie de la Journee : ce n'est jamais une destination de la barre basse.
///
/// **Son etat vide est son etat normal et frequent, et il faut le dire.** Les
/// sources des quatre anomalies (programme, progression, evaluations) vivent
/// dans les migrations `0020` a `0024`, et leurs policies de lecture sont
/// reservees a l'administration : aucune lecture bornee a l'enseignant n'existe
/// encore. L'ecran est complet, et il reste vide jusque-la. **Aucune colonne de
/// tirets n'est posee en attendant** : une colonne de tirets promet une donnee a
/// chaque ligne, un bloc absent ne promet rien.
///
/// L'enseignant ne tranche rien ici : `progression_exceptions` et les trois
/// ecritures de progression sont refusees par la base a son role, et c'est
/// voulu. L'ecran ne pose donc aucun bouton de decision -- il ne le grise pas,
/// il ne le rend pas -- et une phrase dit qui decide.
class RevueGroupePage extends ConsumerWidget {
  /// Cree la revue d'un groupe.
  const RevueGroupePage({required this.groupeId, super.key});

  /// Le groupe dont on lit la revue.
  final String groupeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<MembreSeance>> membres = ref.watch(
      membresGroupeEnseignantProvider(groupeId),
    );
    final AsyncValue<List<AnomalieRevue>> lues = ref.watch(
      anomaliesGroupeProvider(groupeId),
    );

    // Le nom de la Classe dans le titre (recette EN-12, decision EN-RC) : sans
    // lui, « Revue de la Classe » ne dit pas laquelle. Tant que la liste des
    // Classes n'est pas lue, le titre d'origine.
    final String? nom = ref
        .watch(groupesEnseignantProvider)
        .value
        ?.where((GroupeEnseignant g) => g.id == groupeId)
        .map((GroupeEnseignant g) => g.libelle.trim())
        .where((String l) => l.isNotEmpty)
        .firstOrNull;
    final String titre = nom == null
        ? t.enseignant.revue.titre
        : t.enseignant.revue.titreClasse(classe: nom);

    // Le meme retour que l'Espace Classe, en haut et au bord de debut ; le
    // titre suit, comme le nom de la Classe dans l'Espace Classe.
    return PageShell(
      entete: const SortieEspaceClasse(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(
              titre,
              style:
                  Theme.of(context).textTheme.headlineLarge ??
                  const TextStyle(),
            ),
          ),
          Ecart.vXxl,
          _corps(ref, membres: membres, anomalies: lues),
        ],
      ),
    );
  }

  /// Les quatre etats de l'ecran, lus par `hasValue` / `hasError`.
  ///
  /// Le cinquieme, hors ligne, est deja porte par le bandeau de `PageShell` : en
  /// poser un second serait le dire deux fois.
  ///
  /// L'erreur n'est pas optionnelle et ce n'est pas une formalite : la lecture
  /// du groupe passe par `mon_groupe_detail`, qui refuse un groupe qui n'est pas
  /// celui de l'enseignant. Une revue ouverte sur un mauvais identifiant doit le
  /// dire, pas afficher « rien ne demande votre attention ».
  Widget _corps(
    WidgetRef ref, {
    required AsyncValue<List<MembreSeance>> membres,
    required AsyncValue<List<AnomalieRevue>> anomalies,
  }) {
    if (!membres.hasValue || !anomalies.hasValue) {
      if (membres.hasError || anomalies.hasError) {
        return EmptyState(
          message: t.enseignant.revue.erreur,
          invitation: t.enseignant.revue.erreurDetail,
          icone: AppIcons.avertissement,
          libelleAction: t.commun.reessayer,
          onAction: () {
            ref.invalidate(membresGroupeEnseignantProvider(groupeId));
            ref.invalidate(anomaliesGroupeProvider(groupeId));
          },
        );
      }
      return const Skeleton.liste(lignes: 3);
    }

    final List<AnomalieRevue> retenues = anomaliesDuGroupe(
      anomalies: anomalies.requireValue,
      membres: membres.requireValue,
    );

    if (retenues.isEmpty) {
      // Registre « bonne nouvelle » et non « subi » : rien a regarder est le
      // resultat normal d'un groupe qui va bien, et l'enseignant voit cet ecran
      // souvent. Ton neutre, aucune felicitation, et surtout aucun bouton -- il
      // n'y a rien a faire, et proposer une action serait inviter a inventer un
      // probleme.
      return EmptyState(
        // Une seule phrase calme (UX_REVIEW_04 ligne 10), sans detail.
        message: t.enseignant.revue.aucuneAnomalie,
        registre: RegistreVide.bonneNouvelle,
      );
    }

    return _Liste(anomalies: retenues);
  }
}

class _Liste extends StatelessWidget {
  const _Liste({required this.anomalies});

  final List<AnomalieRevue> anomalies;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final AnomalieRevue anomalie in anomalies) ...<Widget>[
          _Carte(anomalie: anomalie),
          Ecart.vMd,
        ],
        Ecart.vSm,
        // Qui decide, dit une fois pour la page entiere.
        Text(
          t.enseignant.revue.pasDeDecision,
          style: palette.inkMuted.applyTo(
            textes.bodySmall ?? const TextStyle(),
          ),
        ),
      ],
    );
  }
}

class _Carte extends StatelessWidget {
  const _Carte({required this.anomalie});

  final AnomalieRevue anomalie;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    // Le type se dit par un **mot**, jamais par une couleur seule : la carte
    // reste sur la surface elevee par defaut, et c'est le libelle qui porte le
    // sens.
    final String type = switch (anomalie.type) {
      TypeAnomalieRevue.gateAVenir => t.enseignant.revue.typeGate,
      TypeAnomalieRevue.horsCorridor => t.enseignant.revue.typeCorridor,
      TypeAnomalieRevue.transfertPropose => t.enseignant.revue.typeTransfert,
      TypeAnomalieRevue.reorientationProposee =>
        t.enseignant.revue.typeReorientation,
    };

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(type, style: textes.titleSmall),
          Ecart.vXs,
          Text(anomalie.eleve, style: textes.bodyMedium),
          if (anomalie.detail case final String detail
              when detail.trim().isNotEmpty) ...<Widget>[
            Ecart.vSm,
            Text(
              detail,
              style: palette.inkMuted.applyTo(
                textes.bodySmall ?? const TextStyle(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
