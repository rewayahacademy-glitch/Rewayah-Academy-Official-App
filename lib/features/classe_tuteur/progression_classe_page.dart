import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Comme partout ailleurs : le type d'une famille de providers n'est pas exporte
// par l'entree principale de Riverpod 3, il vit dans `misc.dart`.
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:go_router/go_router.dart';

import '../../core/capacites/port_progression_famille.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/ligne_cle_valeur.dart';
import '../accueil_famille/bloc_seance.dart';
import 'contexte_classe.dart';

/// La progression partageable d'un eleve (contrat K6).
///
/// Leve `CapaciteIndisponible('DB-CRS-11')` en production : aucune source
/// famille n'existe (`progression_historique` est lisible par
/// l'administration seule). **Jamais `lesson_reports`** (DB-TRV-02).
final FutureProviderFamily<ProgressionEleve, String> progressionEleveProvider =
    FutureProvider.family<ProgressionEleve, String>(
      (Ref ref, String eleveId) =>
          ref.watch(portProgressionFamilleProvider).progression(eleveId),
    );

/// Vrai quand une progression ne porte rien a montrer.
bool progressionVide(ProgressionEleve progression) {
  final String? niveau = progression.niveauHumain;
  return (niveau == null || niveau.trim().isEmpty) &&
      progression.jalons.isEmpty;
}

/// La progression d'un eleve dans sa classe
/// (`/tuteur/classes/:classeId/progression`).
///
/// Derive de la ligne « Derniere seance » et des lignes du Compte (#1, #6) :
/// le niveau en mots (jamais un code), puis les etapes franchies que
/// l'enseignant partage, redigees par le serveur.
class ProgressionClassePage extends ConsumerWidget {
  /// Cree la page.
  const ProgressionClassePage({
    required this.classeId,
    super.key,
    this.eleveId,
  });

  /// La classe concernee.
  final String classeId;

  /// L'eleve concerne, s'il est donne.
  final String? eleveId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => CadreClasse(
    cle: (classeId: classeId, eleveId: eleveId),
    titre: t.classe.progression,
    sousTitre: sousTitreSousPage,
    onRetour: () =>
        GoRouter.of(context).go(Routes.classePour(classeId, eleveId: eleveId)),
    construire: (ContexteClasse c) => _Progression(contexte: c),
  );
}

class _Progression extends ConsumerWidget {
  const _Progression({required this.contexte});

  final ContexteClasse contexte;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String eleveId = contexte.eleveId;
    return LectureClasse<ProgressionEleve>(
      valeur: ref.watch(progressionEleveProvider(eleveId)),
      phraseIndisponible: t.classe.pageProgression.indisponible(
        prenom: contexte.eleve.prenom,
      ),
      onReessayer: () => ref.invalidate(progressionEleveProvider(eleveId)),
      construire: (ProgressionEleve progression) => progressionVide(progression)
          ? EtatSysteme(
              nature: NatureEtat.aucunResultat,
              titre: t.classe.pageProgression.aucune,
              phrase: t.classe.pageProgression.aucuneDetail,
            )
          : _Contenu(progression: progression),
    );
  }
}

class _Contenu extends StatelessWidget {
  const _Contenu({required this.progression});

  final ProgressionEleve progression;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final String? niveau = progression.niveauHumain;
    // Bureau : largeur de lecture, jamais une fiche etiree sur 1 100 px.
    return ColonnesSousPage(
      principal: AppCard(
        marge: AppSpacing.lg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (niveau != null && niveau.trim().isNotEmpty)
              LigneCleValeur(
                cle: t.classe.pageProgression.niveau,
                valeur: niveau,
              ),
            if (progression.jalons.isNotEmpty) ...<Widget>[
              if (niveau != null && niveau.trim().isNotEmpty) ...<Widget>[
                Ecart.vSm,
                const FiletHorizontal(),
                Ecart.vMd,
              ],
              Semantics(
                header: true,
                child: Text(
                  t.classe.pageProgression.jalons,
                  style: palette.inkStrong.applyTo(
                    textes.titleSmall ?? const TextStyle(),
                  ),
                ),
              ),
              for (final String jalon in progression.jalons)
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: AppTouchTarget.standard,
                  ),
                  child: Row(
                    children: <Widget>[
                      ExcludeSemantics(
                        child: IconTheme(
                          data: palette.inkAccent.asIconTheme(
                            size: AppSpacing.xl,
                          ),
                          child: Icon(AppIcons.succes.repos),
                        ),
                      ),
                      Ecart.hMd,
                      Expanded(
                        child: Text(
                          jalon,
                          style: palette.inkStrong.applyTo(
                            textes.bodyMedium ?? const TextStyle(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
