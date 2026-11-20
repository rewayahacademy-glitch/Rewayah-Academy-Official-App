import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/journal/service_journal.dart';
import '../../core/router/routes.dart';
import '../../core/tc_horloge/mon_horloge.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/avatar_nom.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/skeleton.dart';
import '../admin_journal/journal_page.dart' show libelleEvenement;
import 'bento_vivant.dart';

/// Combien d'entrees l'Accueil montre : une liste de tableau de bord est
/// bornee a trois lignes, puis « Voir tout » (DASH_STRATEGIE, D6).
const int lignesActiviteRecente = 3;

/// Les dernieres entrees du journal d'audit, pour l'Accueil (AD-X, colonne
/// « Activite recente » d'ADMIN-SHELL-01).
///
/// **Une source reelle, pas un decor** : `journal_audit()`, la meme lecture
/// que le Journal (`ADM-04`), bornee a trois entrees. Aucune relance
/// automatique : une erreur reste une erreur jusqu'a « Reessayer ».
final FutureProvider<List<EntreeJournal>> activiteRecenteProvider =
    FutureProvider<List<EntreeJournal>>(
      (Ref ref) => ref
          .watch(serviceJournalProvider)
          .entrees(limite: lignesActiviteRecente),
      retry: (int retryCount, Object error) => null,
    );

/// La case large « Ce qui a changé » de l'accueil (VIVANT, 20/11/2026).
///
/// Une case du bento, comme les autres : son titre, trois lignes au plus,
/// puis « Voir tout le journal ». Ses etats tiennent dans la case : forme de
/// trois lignes pendant la lecture, une phrase quand rien n'a change, une
/// phrase et « Réessayer » quand la lecture echoue (aucune relance
/// automatique). Une erreur ici n'emporte que cette case : les nombres
/// restent justes (D11).
class ActiviteRecente extends ConsumerWidget {
  /// Cree la case.
  const ActiviteRecente({super.key, this.deuxColonnes = false});

  /// La case est large : les lignes vont sur deux colonnes.
  final bool deuxColonnes;

  /// La cle de la phrase d'echec.
  static const Key cleEchec = ValueKey<String>('vivant-activite-echec');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // HEURES-PROFIL H2 (12/11/2026) : la page ecoute le fuseau du profil ;
    // quand il arrive apres son premier rendu, ses heures se redessinent.
    ref.watch(monHorlogeProvider);
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final AsyncValue<List<EntreeJournal>> entrees = ref.watch(
      activiteRecenteProvider,
    );
    final TextStyle doux = palette.inkMuted.applyTo(
      textes.bodySmall ?? const TextStyle(),
    );
    final Widget voirTout = LienFleche(
      libelle: t.admin.tableau.activite.voirTout,
      onPress: () => GoRouter.of(context).go(Routes.adminSecuriteAuditJournal),
    );
    // Une ligne : qui (son visage), ce qui a change, quand.
    Widget ligne(EntreeJournal e) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AvatarNom(
            prenom: _qui(e),
            disposition: DispositionAvatar.vertical,
            diametre: AppAvatar.petit,
            afficherNom: false,
          ),
          Ecart.hMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  libelleEvenement(e.typeEvenement),
                  style: textes.bodyMedium,
                ),
                Text(
                  t.admin.tableau.activite.ligne(
                    qui: _qui(e),
                    quand: t.admin.journal.horodatage(
                      date: _date(chezMoi(e.survenuLe)),
                      heure: _heure(e.survenuLe),
                    ),
                  ),
                  style: doux,
                ),
              ],
            ),
          ),
        ],
      ),
    );
    final List<Widget> corps;
    if (entrees.hasValue) {
      final List<EntreeJournal> lues = entrees.requireValue
          .take(lignesActiviteRecente)
          .toList();
      if (lues.isEmpty) {
        corps = <Widget>[
          Text(t.admin.tableau.activite.vide, style: doux),
          voirTout,
        ];
      } else if (deuxColonnes && lues.length > 1) {
        // Deux colonnes : la seconde finit par le lien vers le journal.
        final int moitie = (lues.length + 1) ~/ 2;
        corps = <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    for (final EntreeJournal e in lues.take(moitie)) ligne(e),
                  ],
                ),
              ),
              Ecart.hXl,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    for (final EntreeJournal e in lues.skip(moitie)) ligne(e),
                    voirTout,
                  ],
                ),
              ),
            ],
          ),
        ];
      } else {
        corps = <Widget>[
          for (final EntreeJournal e in lues) ligne(e),
          voirTout,
        ];
      }
    } else if (entrees.hasError) {
      // Calme : une phrase vraie, dans l'encre douce, et « Réessayer ». Une
      // erreur ici n'emporte que cette case ; ce n'est pas une alerte.
      corps = <Widget>[
        Text(
          t.admin.tableau.activite.erreur,
          key: ActiviteRecente.cleEchec,
          style: doux,
        ),
        LienFleche(
          libelle: t.commun.reessayer,
          fleche: false,
          onPress: () => ref.invalidate(activiteRecenteProvider),
        ),
        voirTout,
      ];
    } else {
      corps = const <Widget>[Skeleton.liste(lignes: lignesActiviteRecente)];
    }
    return CaseVivante(
      paire: palette.surfaceRaised,
      // Une ligne de texte suivi ne depasse jamais la largeur de lecture,
      // meme quand la case prend toute la page (garde du bureau, B4).
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: CaseVivante.largeurLecture,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                t.admin.tableau.vivant.activiteTitre,
                style: textes.titleMedium,
              ),
              Ecart.vMd,
              ...corps,
            ],
          ),
        ),
      ),
    );
  }
}

/// Qui a fait le geste : son nom, « Le systeme » sans auteur, « Compte
/// supprime » quand le profil n'est plus lisible (memes mots que le Journal).
String _qui(EntreeJournal e) {
  if (e.parLeSysteme) {
    return t.admin.journal.acteurSysteme;
  }
  final String? nom = e.nomActeur;
  return nom == null || nom.trim().isEmpty
      ? t.admin.journal.acteurInconnu
      : nom;
}

String _deux(int n) => n.toString().padLeft(2, '0');

String _date(DateTime quand) =>
    '${_deux(quand.day)}/${_deux(quand.month)}/${quand.year}';

// HEURES-PROFIL H2 : a l'heure du profil.
String _heure(DateTime quand) => heureChezMoi(quand);
