import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/port_acces_foyer.dart';
import '../../core/capacites/port_finance_foyer.dart';
import '../../core/finance/format_montant.dart';
import '../../core/foyer/selection_eleve.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/mouvement/apparition_douce.dart';
import '../../core/router/chemin_retour.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/colonnes_fiche.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/ligne_beneficiaire.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/resume_solde.dart';
import '../../core/widgets/skeleton.dart';
import 'carte_rubriques.dart';
import 'donnees_compte.dart';

/// Les soldes du foyer (DB-FIN-01). En production, le port rend
/// `CapaciteIndisponible` : l'ecran le dit, sans aucune action financiere.
final FutureProvider<SoldesFoyer> soldesFoyerProvider =
    FutureProvider<SoldesFoyer>(
      (Ref ref) => ref.watch(portFinanceFoyerProvider).soldes(),
    );

/// Le total du foyer en une ligne, pour l'entree du Foyer : les montants du
/// serveur, « Non disponible » quand la capacite manque, `null` tant que rien
/// n'est lu. Jamais un « 0 » pour un total inconnu.
String? resumeTotalSoldes(AsyncValue<SoldesFoyer> soldes) {
  if (soldes.hasError) {
    return soldes.error is CapaciteIndisponible ? t.compte.nonDisponible : null;
  }
  if (!soldes.hasValue) {
    return null;
  }
  final SoldesFoyer lus = soldes.requireValue;
  if (lus.totaux.isEmpty) {
    return t.finance.aucunTotal;
  }
  final String total = lus.totaux
      .map((TotalSoldes s) => formaterMontant(s.montantMineur, s.devise))
      .join(' · ');
  // Un total partiel se dit comme tel (constat LT-R 5).
  return lus.complet ? total : t.finance.totalPartiel(total: total);
}

/// S01 « Soldes et recharges » (`/tuteur/compte/soldes`, complement Tuteur,
/// section 5 ; planche « Soldes du foyer »).
///
/// Le total par devise, puis une ligne par profil (solde et acces). Aucun
/// calcul : montants et totaux sont ceux du serveur. « Recharger » mene a
/// S03 (LT-7), seulement quand les soldes sont lus ; « Voir les
/// mouvements » mene a S07 (LT-6) ; « Gerer les acces » mene a la page
/// d'acces existante. Le retour suit `?retour=`
/// (depuis le Foyer), sinon le Compte.
class SoldesComptePage extends ConsumerWidget {
  /// Cree la page.
  const SoldesComptePage({super.key});

  /// La ligne « Gerer les acces ».
  static const Key gererAccesKey = Key('soldes.gererAcces');

  /// « Recharger », vers S03 (LT-7).
  static const Key rechargerKey = Key('soldes.recharger');

  Uri? _adresse(BuildContext context) {
    try {
      return GoRouterState.of(context).uri;
    } on Object {
      return null;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter? routeur = GoRouter.maybeOf(context);
    final String retour =
        cheminRetourValide(_adresse(context)?.queryParameters['retour']) ??
        Routes.tuteurCompte;
    final AsyncValue<SoldesFoyer> soldes = ref.watch(soldesFoyerProvider);

    final Widget liste = BlocAsynchrone<SoldesFoyer>(
      valeur: soldes,
      squelette: const Skeleton.liste(lignes: 3),
      onReessayer: () => ref.invalidate(soldesFoyerProvider),
      estVide: (SoldesFoyer s) => s.profils.isEmpty,
      vide: EtatSysteme(
        nature: NatureEtat.aucunResultat,
        titre: t.finance.soldes.aucunProfil,
        phrase: t.finance.soldes.aucunProfilPhrase,
      ),
      construire: _Soldes.new,
    );
    // Les actions : sous la liste sur telephone et tablette, dans la colonne
    // laterale sur bureau (planche « 06 Web sombre, soldes »).
    final List<Widget> actions = <Widget>[
      // « Recharger » (LT-7) seulement sur des soldes lus : en
      // production (DB-FIN-01 absent), aucun bouton financier.
      if (soldes.hasValue &&
          !soldes.hasError &&
          soldes.requireValue.profils.isNotEmpty) ...<Widget>[
        ActionPrincipale(
          key: rechargerKey,
          libelle: t.finance.recharge.action,
          onPress: () => routeur?.go(
            Uri(
              path: Routes.tuteurCompteRecharge,
              queryParameters: <String, String>{
                'retour': Routes.tuteurCompteSoldes,
              },
            ).toString(),
          ),
        ),
        Ecart.vLg,
      ],
      GroupeReglages(
        key: gererAccesKey,
        lignes: <LigneRubrique>[
          LigneRubrique(
            icone: AppIcons.historique,
            libelle: t.finance.mouvements.voir,
            onPress: () => routeur?.go(Routes.tuteurCompteMouvements),
          ),
          LigneRubrique(
            icone: AppIcons.attente,
            libelle: t.finance.soldes.gererAcces,
            onPress: () => routeur?.go(Routes.compteTuteurSousPage('acces')),
          ),
        ],
      ),
    ];

    return PageShell(
      titre: t.finance.soldes.titre,
      sousTitre: t.finance.soldes.sousTitre,
      onRetour: () => routeur?.go(retour),
      child: AppGabarit.de(context) == Gabarit.desktop
          ? ColonnesFiche(
              principal: liste,
              annexe: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: actions,
              ),
            )
          : ColonneSousPage(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[liste, Ecart.vLg, ...actions],
              ),
            ),
    );
  }
}

class _Soldes extends ConsumerWidget {
  const _Soldes(this.soldes);

  final SoldesFoyer soldes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ProfilEleveFoyer>> profils = ref.watch(
      profilsElevesFoyerProvider,
    );
    final AsyncValue<List<AccesBeneficiaire>> acces = ref.watch(
      accesFoyerProvider,
    );
    final Map<String, String> prenoms = <String, String>{
      if (profils.hasValue && !profils.hasError)
        for (final ProfilEleveFoyer p in profils.requireValue)
          p.eleveId: p.prenom,
    };
    final Map<String, String> etats = <String, String>{
      if (acces.hasValue && !acces.hasError)
        for (final AccesBeneficiaire a in acces.requireValue)
          a.eleveId: a.etatAffiche == EtatAccesAffiche.expire
              ? t.compte.tuteur.acces.pastilleExpire
              : t.compte.tuteur.acces.pastilleActif,
    };

    return ListeEchelonnee(
      children: <Widget>[
        ResumeSolde.foyer(totaux: soldes.totaux, complet: soldes.complet),
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.lg),
          child: GroupeReglages(
            titre: t.finance.soldes.profils,
            lignes: <LigneRubrique>[
              for (final SoldeProfil s in soldes.profils)
                LigneBeneficiaire(
                  prenom: prenoms[s.profilId] ?? t.finance.profilSansPrenom,
                  solde: s,
                  acces: etats[s.profilId],
                ).rubrique(context),
            ],
          ),
        ),
      ],
    );
  }
}
