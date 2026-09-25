import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/capacites/port_acces_foyer.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import 'arret_acces_page.dart';
import 'carte_rubriques.dart';
import 'donnees_compte.dart';

/// L'acces de chaque profil eleve du foyer (`/tuteur/compte/acces`).
///
/// **Jamais « abonnement »** : un acces date n'est pas un paiement recurrent
/// (mandat section 5). Seule l'echeance reelle (`access_until`) est dite ;
/// « Termine » est un calcul d'affichage, jamais un statut serveur, et aucun
/// motif n'est invente (DB-FOY-05). Le titulaire n'a pas d'echeance propre.
///
/// Une ligne par profil eleve : c'est la place reservee au futur solde par
/// enfant (decision du directeur, 24/09, section 1 ter-9), rien n'est construit.
class AccesComptePage extends ConsumerWidget {
  /// Cree la page.
  const AccesComptePage({super.key});

  /// « Arreter l'acces », vers S09 (LT-9).
  static const Key arreterKey = Key('acces.arreter');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final AsyncValue<List<AccesBeneficiaire>> acces = ref.watch(
      accesFoyerProvider,
    );
    // « Arreter l'acces » (S09, LT-9) seulement si le serveur sait en rendre
    // les consequences (DB-FIN-05) ; en production, la lecture reste seule.
    final bool arretPossible = apercuPossible(ref, <String>[
      if (acces.hasValue && !acces.hasError)
        for (final AccesBeneficiaire a in acces.requireValue) a.eleveId,
    ]);

    return PageShell(
      titre: t.compte.tuteur.pageAcces.titre,
      sousTitre: t.compte.tuteur.pageAcces.sousTitre,
      onRetour: () => GoRouter.of(context).go(Routes.tuteurCompte),
      child: ColonneSousPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            BlocAsynchrone<List<AccesBeneficiaire>>(
              valeur: acces,
              squelette: const Skeleton.liste(lignes: 2),
              onReessayer: () => ref.invalidate(accesFoyerProvider),
              vide: EtatSysteme(
                nature: NatureEtat.aucunResultat,
                titre: t.compte.tuteur.pageAcces.aucunTitre,
                phrase: t.compte.tuteur.pageAcces.aucunePhrase,
              ),
              construire: (List<AccesBeneficiaire> acces) => GroupeReglages(
                lignes: <LigneRubrique>[
                  for (final AccesBeneficiaire a in acces)
                    LigneRubrique(
                      icone: AppIcons.profil,
                      libelle: a.prenom,
                      legende: echeanceAcces(a),
                      controle: StatusPill(
                        libelle: a.etatAffiche == EtatAccesAffiche.expire
                            ? t.compte.tuteur.pageAcces.pastilleExpire
                            : t.compte.tuteur.pageAcces.pastilleActif,
                        ton: a.etatAffiche == EtatAccesAffiche.expire
                            ? TonEtat.alerte
                            : TonEtat.succes,
                      ),
                    ),
                ],
              ),
            ),
            if (arretPossible) ...<Widget>[
              Ecart.vLg,
              GroupeReglages(
                key: arreterKey,
                lignes: <LigneRubrique>[
                  LigneRubrique(
                    icone: AppIcons.verrou,
                    libelle: t.finance.arret.action,
                    onPress: () =>
                        GoRouter.of(context).go(Routes.tuteurCompteArretAcces),
                  ),
                ],
              ),
            ],
            Ecart.vLg,
            Text(
              t.compte.tuteur.pageAcces.titulaire,
              style: palette.inkMuted.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// L'echeance d'un acces en mots (`access_until` reel, jamais un motif).
String echeanceAcces(AccesBeneficiaire acces) {
  final DateTime? fin = acces.finAcces;
  if (fin == null) {
    return t.compte.tuteur.pageAcces.sansEcheance;
  }
  return acces.etatAffiche == EtatAccesAffiche.expire
      ? t.compte.tuteur.pageAcces.expire(date: dateLongue(fin))
      : t.compte.tuteur.pageAcces.jusqua(date: dateLongue(fin));
}
