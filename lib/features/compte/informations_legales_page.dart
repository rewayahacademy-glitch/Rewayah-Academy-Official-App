import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/domain/enums.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/profil/service_acceptations.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import 'carte_rubriques.dart';
import 'donnees_compte.dart';

/// Les informations legales du titulaire
/// (`/tuteur/compte/informations-legales`).
///
/// Ce qui existe reellement : les textes **acceptes** par ce compte
/// (`contract_acceptances`, lecture de soi, `ServiceAcceptations`), avec leur
/// version et leur date ; un texte accepte ne se reecrit jamais. Ce qui
/// n'existe pas : conditions generales completes, politique de
/// confidentialite, mentions legales (DB-CPT-08) ; l'ecran le dit.
///
/// Le consentement aux visites d'observation (`/tuteur/compte/consentements`)
/// est l'ecran du lot A : il n'est pas repris ici.
class InformationsLegalesComptePage extends ConsumerWidget {
  /// Cree la page.
  const InformationsLegalesComptePage({super.key, this.onRetour});

  /// Le retour de l'en-tete ; par defaut, le Compte du tuteur. « Mon
  /// espace » de l'eleve adulte (EA-4) y passe son propre retour.
  final VoidCallback? onRetour;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle phrase = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );

    return PageShell(
      titre: t.compte.tuteur.pageLegal.titre,
      onRetour: onRetour ?? () => GoRouter.of(context).go(Routes.tuteurCompte),
      child: ColonneSousPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Semantics(
              header: true,
              child: Text(
                t.compte.tuteur.pageLegal.documents,
                style: palette.inkStrong.applyTo(
                  textes.titleMedium ?? const TextStyle(),
                ),
              ),
            ),
            Ecart.vSm,
            BlocAsynchrone<List<Acceptation>>(
              valeur: ref.watch(acceptationsProvider),
              squelette: const Skeleton.liste(lignes: 2),
              onReessayer: () => ref.invalidate(acceptationsProvider),
              vide: EtatSysteme(
                nature: NatureEtat.aucunResultat,
                titre: t.compte.tuteur.pageLegal.aucunTitre,
                phrase: t.compte.tuteur.pageLegal.aucun,
              ),
              construire: (List<Acceptation> acceptations) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  GroupeReglages(
                    lignes: <LigneRubrique>[
                      for (final Acceptation a in acceptations)
                        LigneRubrique(
                          icone: AppIcons.journal,
                          libelle: _libelle(a.sorte),
                          legende: t.compte.tuteur.pageLegal.acceptation(
                            version: a.version,
                            date: dateLongue(a.accepteeLe),
                          ),
                        ),
                    ],
                  ),
                  Ecart.vSm,
                  Text(t.compte.tuteur.pageLegal.lectureSeule, style: phrase),
                ],
              ),
            ),
            Ecart.vXxl,
            EtatSysteme(
              nature: NatureEtat.indisponible,
              titre: t.compte.tuteur.pageLegal.textes,
              phrase: t.compte.tuteur.pageLegal.textesIndisponibles,
              dependance: 'DB-CPT-08',
            ),
          ],
        ),
      ),
    );
  }

  static String _libelle(SorteContrat sorte) => switch (sorte) {
    SorteContrat.conditionsTuteur => t.compte.tuteur.pageLegal.conditionsTuteur,
    SorteContrat.contratEnseignant =>
      t.compte.tuteur.pageLegal.contratEnseignant,
    SorteContrat.accuseEnregistrementControle =>
      t.compte.tuteur.pageLegal.accuseEnregistrement,
  };
}
