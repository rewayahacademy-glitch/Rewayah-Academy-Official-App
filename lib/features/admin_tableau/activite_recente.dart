import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/journal/service_journal.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/carte_lignes.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/setting_row.dart';
import '../../core/widgets/skeleton.dart';
import '../admin_journal/journal_page.dart' show libelleEvenement;

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

/// La colonne « Activite recente » de l'Accueil.
///
/// Titre de section, une carte de trois lignes (`CarteLignes`, contenus
/// lies), puis « Voir tout le journal » au bord de fin. Ses etats sont ceux de
/// [BlocAsynchrone] : squelette de trois lignes, vide, erreur avec
/// « Reessayer », indisponible (demonstration sans journal). Une erreur ici
/// n'emporte que cette colonne : les tuiles restent justes (D11).
class ActiviteRecente extends ConsumerWidget {
  /// Cree la colonne.
  const ActiviteRecente({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AsyncValue<List<EntreeJournal>> entrees = ref.watch(
      activiteRecenteProvider,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SectionHeader(titre: t.admin.tableau.activite.titre),
        Ecart.vSm,
        BlocAsynchrone<List<EntreeJournal>>(
          valeur: entrees,
          squelette: const Skeleton.liste(lignes: lignesActiviteRecente),
          titreEchec: t.admin.tableau.activite.erreur,
          onReessayer: () => ref.invalidate(activiteRecenteProvider),
          vide: Text(t.admin.tableau.activite.vide, style: textes.bodyMedium),
          construire: (List<EntreeJournal> lues) => CarteLignes(
            lignes: <Widget>[
              for (final EntreeJournal e in lues.take(lignesActiviteRecente))
                SettingRow(
                  title: libelleEvenement(e.typeEvenement),
                  description: t.admin.tableau.activite.ligne(
                    qui: _qui(e),
                    quand: t.admin.journal.horodatage(
                      date: _date(e.survenuLe),
                      heure: _heure(e.survenuLe),
                    ),
                  ),
                ),
            ],
          ),
        ),
        // « Voir tout » apres les trois lignes (D6) : dans une colonne de
        // 336, le titre et le lien ne tiennent pas sur une rangee.
        Ecart.vSm,
        LienFleche(
          libelle: t.admin.tableau.activite.voirTout,
          alignerEnFin: true,
          onPress: () =>
              GoRouter.of(context).go(Routes.adminSecuriteAuditJournal),
        ),
      ],
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

String _heure(DateTime quand) => '${_deux(quand.hour)}:${_deux(quand.minute)}';
