import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/capacites/port_acces_foyer.dart';
import '../../core/finance/finances_profil.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/pastille_financiere.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import '../acces_finance/acces_finance.dart';
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
///
/// FI-9a (guide §1.2, §1.7) : un profil dont la finance dit « a
/// regulariser » porte la pastille « À régulariser » et le manque exact en
/// legende (« Il manque 8 $ pour financer octobre. ») ; un profil en essai
/// porte « Essai : n/2 ». Sans finance lue, la ligne reste celle de
/// l'echeance.
class AccesComptePage extends ConsumerWidget {
  /// Cree la page.
  const AccesComptePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    // Lue a cote de l'acces, jamais a sa place : une finance absente ou en
    // echec laisse la ligne de l'echeance (port neutre en production).
    final FinancesFoyer? finances = ref.watch(financesFoyerProvider).value;
    FinancesProfil? financeDe(String eleveId) {
      for (final FinancesProfil p in finances?.profils ?? <FinancesProfil>[]) {
        if (p.profilId == eleveId) return p;
      }
      return null;
    }

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
              valeur: ref.watch(accesFoyerProvider),
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
                    _ligne(a, financeDe(a.eleveId)),
                ],
              ),
            ),
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

  static LigneRubrique _ligne(AccesBeneficiaire a, FinancesProfil? finance) {
    final String? essai = libelleEssai(a);
    final bool regulariser = aRegulariser(finance);
    // La place rendue par la source (FI-BR-08) : liberee, elle passe avant
    // le manque ; reactivee, elle se dit tant qu'aucun manque n'est rendu.
    final bool liberee = a.place == EtatPlace.liberee;
    final String? place = phrasePlace(a, prenom: a.prenom);
    return LigneRubrique(
      icone: AppIcons.profil,
      libelle: a.prenom,
      legende: liberee
          ? place
          : regulariser
          ? messageRegularisation(finance!)
          : place ?? _echeance(a),
      controle: liberee
          ? StatusPill(
              libelle: t.argent.acces.pastilleSuspendu,
              ton: TonEtat.avertissement,
            )
          : regulariser
          ? const PastilleFinanciere(etat: EtatFinancier.aRegulariser)
          : a.place == EtatPlace.reactivee
          ? StatusPill(
              libelle: t.argent.acces.pastilleReactive,
              ton: TonEtat.succes,
            )
          : essai != null
          ? StatusPill(
              libelle: essai,
              ton: PastilleFinanciere.tonDe(EtatFinancier.essai),
            )
          : StatusPill(
              libelle: a.etatAffiche == EtatAccesAffiche.expire
                  ? t.compte.tuteur.pageAcces.pastilleExpire
                  : t.compte.tuteur.pageAcces.pastilleActif,
              ton: a.etatAffiche == EtatAccesAffiche.expire
                  ? TonEtat.alerte
                  : TonEtat.succes,
            ),
    );
  }

  static String _echeance(AccesBeneficiaire acces) {
    final DateTime? fin = acces.finAcces;
    if (fin == null) {
      return t.compte.tuteur.pageAcces.sansEcheance;
    }
    return acces.etatAffiche == EtatAccesAffiche.expire
        ? t.compte.tuteur.pageAcces.expire(date: dateLongue(fin))
        : t.compte.tuteur.pageAcces.jusqua(date: dateLongue(fin));
  }
}
