import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/journal/service_journal.dart';
import '../../core/router/routes.dart';
import '../../core/tc_horloge/mon_horloge.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
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
  const ActiviteRecente({super.key});

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
    final List<Widget> corps;
    if (entrees.hasValue) {
      final List<EntreeJournal> lues = entrees.requireValue;
      corps = lues.isEmpty
          ? <Widget>[Text(t.admin.tableau.activite.vide, style: doux)]
          : <Widget>[
              for (final EntreeJournal e in lues.take(lignesActiviteRecente))
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
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
            ];
    } else if (entrees.hasError) {
      corps = <Widget>[
        Text(
          t.admin.tableau.activite.erreur,
          style: palette.inkAlert.applyTo(
            textes.bodySmall ?? const TextStyle(),
          ),
        ),
        LienFleche(
          libelle: t.commun.reessayer,
          fleche: false,
          onPress: () => ref.invalidate(activiteRecenteProvider),
        ),
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
              Ecart.vSm,
              ...corps,
              LienFleche(
                libelle: t.admin.tableau.activite.voirTout,
                onPress: () =>
                    GoRouter.of(context).go(Routes.adminSecuriteAuditJournal),
              ),
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
