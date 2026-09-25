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
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/ligne_beneficiaire.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/resume_solde.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import '../suivi_foyer/filtres_historique.dart' show dateCourte;
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
class SoldesComptePage extends ConsumerStatefulWidget {
  /// Cree la page.
  const SoldesComptePage({super.key});

  /// La ligne « Gerer les acces ».
  static const Key gererAccesKey = Key('soldes.gererAcces');

  /// « Recharger », vers S03 (LT-7).
  static const Key rechargerKey = Key('soldes.recharger');

  /// Sur bureau, la ligne d'un profil, qui le selectionne.
  static Key ligneKey(String profilId) => Key('soldes.ligne.$profilId');

  /// Sur bureau, le panneau « Profil selectionne ».
  static const Key panneauKey = Key('soldes.panneau');

  /// « Recharger pour (prenom) », dans le panneau.
  static const Key rechargerProfilKey = Key('soldes.rechargerProfil');

  /// « Voir les mouvements de (prenom) », dans le panneau.
  static const Key mouvementsProfilKey = Key('soldes.mouvementsProfil');

  @override
  ConsumerState<SoldesComptePage> createState() => _SoldesComptePageState();
}

class _SoldesComptePageState extends ConsumerState<SoldesComptePage> {
  // Sans routeur (ecran monte seul) : la selection reste un etat local.
  String? _profilLocal;

  Uri? _adresse(BuildContext context) {
    try {
      return GoRouterState.of(context).uri;
    } on Object {
      return null;
    }
  }

  /// La selection vit dans `?profil=`, comme le filtre de S07 : elle survit
  /// a un aller-retour par la recharge ou les mouvements.
  void _selectionner(GoRouter? routeur, Uri? ici, String profil) {
    if (routeur == null || ici == null) {
      setState(() => _profilLocal = profil);
      return;
    }
    routeur.go(
      Uri(
        path: ici.path,
        queryParameters: <String, String>{
          ...ici.queryParameters,
          'profil': profil,
        },
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final GoRouter? routeur = GoRouter.maybeOf(context);
    final Uri? ici = _adresse(context);
    final String retour =
        cheminRetourValide(ici?.queryParameters['retour']) ??
        Routes.tuteurCompte;
    final AsyncValue<SoldesFoyer> soldes = ref.watch(soldesFoyerProvider);
    final bool bureau = AppGabarit.de(context) == Gabarit.desktop;
    final SoldesFoyer? lus = soldes.hasValue && !soldes.hasError
        ? soldes.requireValue
        : null;

    // Sur bureau, le profil selectionne (planche « 06 Web sombre, soldes ») :
    // celui de `?profil=` s'il figure dans les soldes lus, sinon le premier.
    final String? demande = ici == null
        ? _profilLocal
        : ici.queryParameters['profil'];
    SoldeProfil? selection;
    for (final SoldeProfil s in lus?.profils ?? const <SoldeProfil>[]) {
      if (s.profilId == demande) {
        selection = s;
      }
    }
    if (selection == null && lus != null && lus.profils.isNotEmpty) {
      selection = lus.profils.first;
    }

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
      construire: (SoldesFoyer s) => _Soldes(
        s,
        selectionId: bureau ? selection?.profilId : null,
        onSelection: bureau
            ? (String id) => _selectionner(routeur, ici, id)
            : null,
      ),
    );
    final SoldeProfil? retenu = selection;
    // Les actions : sous la liste sur telephone et tablette, dans la colonne
    // laterale sur bureau (planche « 06 Web sombre, soldes »).
    final List<Widget> actions = <Widget>[
      // « Recharger » (LT-7) seulement sur des soldes lus : en
      // production (DB-FIN-01 absent), aucun bouton financier.
      if (soldes.hasValue &&
          !soldes.hasError &&
          soldes.requireValue.profils.isNotEmpty) ...<Widget>[
        ActionPrincipale(
          key: SoldesComptePage.rechargerKey,
          libelle: t.finance.recharge.action,
          // Un seul bouton principal par ecran : sur bureau, « Recharger pour
          // (prenom) » du panneau l'est deja.
          niveau: bureau && retenu != null
              ? NiveauAction.secondaire
              : NiveauAction.principale,
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
        key: SoldesComptePage.gererAccesKey,
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
      child: bureau
          ? ColonnesFiche(
              principal: liste,
              annexe: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (retenu != null) ...<Widget>[
                    _Panneau(
                      solde: retenu,
                      // Recharge et mouvements ramenent ici, selection comprise.
                      ici: Uri(
                        path: Routes.tuteurCompteSoldes,
                        queryParameters: <String, String>{
                          ...?ici?.queryParameters,
                          'profil': retenu.profilId,
                        },
                      ).toString(),
                    ),
                    Ecart.vXl,
                  ],
                  ...actions,
                ],
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

Map<String, String> _prenoms(WidgetRef ref) {
  final AsyncValue<List<ProfilEleveFoyer>> profils = ref.watch(
    profilsElevesFoyerProvider,
  );
  return <String, String>{
    if (profils.hasValue && !profils.hasError)
      for (final ProfilEleveFoyer p in profils.requireValue)
        p.eleveId: p.prenom,
  };
}

class _Soldes extends ConsumerWidget {
  const _Soldes(this.soldes, {this.selectionId, this.onSelection});

  final SoldesFoyer soldes;

  /// Sur bureau, le profil montre dans le panneau ; `null` ailleurs.
  final String? selectionId;

  /// Sur bureau, selectionne un profil ; `null` ailleurs (lignes inertes).
  final ValueChanged<String>? onSelection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<AccesBeneficiaire>> acces = ref.watch(
      accesFoyerProvider,
    );
    final Map<String, String> prenoms = _prenoms(ref);
    final ValueChanged<String>? selectionner = onSelection;
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
                _ligne(
                  context,
                  LigneBeneficiaire(
                    prenom: prenoms[s.profilId] ?? t.finance.profilSansPrenom,
                    solde: s,
                    acces: etats[s.profilId],
                  ).rubrique(context),
                  retenue: s.profilId == selectionId,
                  onPress: selectionner == null
                      ? null
                      : () => selectionner(s.profilId),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// La ligne d'un profil ; sur bureau, elle le selectionne, et la ligne
  /// retenue porte la pastille « Selectionne » (un mot, pas une couleur).
  static LigneRubrique _ligne(
    BuildContext context,
    LigneRubrique r, {
    required bool retenue,
    required VoidCallback? onPress,
  }) => LigneRubrique(
    libelle: r.libelle,
    meneur: r.meneur,
    legende: r.legende,
    onPress: onPress,
    controle: retenue
        ? StatusPill(libelle: t.finance.soldes.selectionne, ton: TonEtat.accent)
        : null,
  );
}

/// Sur bureau, le panneau « Profil selectionne » : son solde, sa derniere
/// remise liee a une seance, « Recharger pour » et ses mouvements. Les
/// montants sont ceux du serveur ; un solde inconnu se dit en mots.
class _Panneau extends ConsumerWidget {
  const _Panneau({required this.solde, required this.ici});

  final SoldeProfil solde;

  /// L'adresse de S01 avec cette selection, sortie de la recharge et des
  /// mouvements.
  final String ici;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter? routeur = GoRouter.maybeOf(context);
    final String prenom =
        _prenoms(ref)[solde.profilId] ?? t.finance.profilSansPrenom;
    final MouvementSolde? remise = solde.derniereRemise;

    return Column(
      key: SoldesComptePage.panneauKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            t.finance.soldes.profilSelectionne,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        Ecart.vSm,
        ResumeSolde.profil(
          prenom: prenom,
          solde: solde,
          legende: remise == null || remise.seanceId == null
              ? null
              : t.finance.soldes.derniereRemise(
                  montant: formaterMontant(
                    remise.montantSigneMineur,
                    remise.devise,
                  ),
                  date: dateCourte(remise.date.toLocal()),
                ),
          action: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ActionPrincipale(
                key: SoldesComptePage.rechargerProfilKey,
                libelle: t.finance.soldes.rechargerPour(prenom: prenom),
                onPress: () => routeur?.go(
                  Uri(
                    path: Routes.tuteurCompteRecharge,
                    queryParameters: <String, String>{
                      'profil': solde.profilId,
                      'retour': ici,
                    },
                  ).toString(),
                ),
              ),
              Ecart.vSm,
              LienFleche(
                key: SoldesComptePage.mouvementsProfilKey,
                libelle: t.finance.soldes.mouvementsDe(prenom: prenom),
                onPress: () => routeur?.go(
                  Uri(
                    path: Routes.tuteurCompteMouvements,
                    queryParameters: <String, String>{
                      'profil': solde.profilId,
                      'retour': ici,
                    },
                  ).toString(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
