import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:go_router/go_router.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/port_finance_foyer.dart';
import '../../core/finance/format_montant.dart';
import '../../core/foyer/selection_eleve.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/mouvement/apparition_douce.dart';
import '../../core/router/chemin_retour.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/filter_pill.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/ligne_cle_valeur.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/resume_solde.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import '../suivi_foyer/filtres_historique.dart' show dateCourte, heureMinute;
import 'carte_rubriques.dart';
import 'soldes_page.dart' show soldesFoyerProvider;

// S07 « Mouvements de solde » et S08 « Detail d'un mouvement » (LT-6,
// complement Tuteur section 5 ; planche « 01 Recharges, remises et acces »).
// DB-FIN-02 : en production le port rend `CapaciteIndisponible`, l'ecran le
// dit sans aucune action financiere. Aucun calcul : montants et signes sont
// ceux du serveur.

/// Les mouvements du foyer, filtres par profil (`null` = tous).
final FutureProviderFamily<List<MouvementSolde>, String?> mouvementsProvider =
    FutureProvider.family<List<MouvementSolde>, String?>(
      (Ref ref, String? profilId) =>
          ref.watch(portFinanceFoyerProvider).mouvements(profilId: profilId),
    );

/// Un mouvement precis.
final FutureProviderFamily<MouvementSolde?, String> mouvementProvider =
    FutureProvider.family<MouvementSolde?, String>(
      (Ref ref, String id) => ref.watch(portFinanceFoyerProvider).mouvement(id),
    );

/// La nature d'un mouvement en mots, depuis une liste **fermee** de codes
/// connus. Un code inconnu se dit « Mouvement », jamais brut.
///
/// ponytail: seuls les codes de la demonstration sont connus ; la liste reelle
/// sera fixee avec DB-FIN-02 (demande T, LT-6).
String libelleNature(String code) => switch (code) {
  'demo_recharge' => t.finance.mouvements.natures.recharge,
  'demo_consommation' => t.finance.mouvements.natures.seance,
  'demo_remise_seance' => t.finance.mouvements.natures.remiseSeance,
  _ => t.finance.mouvements.natures.inconnue,
};

/// Le statut en mots, ou `null` pour un code inconnu (jamais affiche brut).
String? libelleStatut(String code) => switch (code) {
  'demo_confirme' => t.finance.mouvements.statuts.confirme,
  _ => null,
};

/// Le montant signe : « +10,00 XTS », « −1,00 XTS » (signe du serveur).
String montantSigne(MouvementSolde m) {
  final String montant = formaterMontant(m.montantSigneMineur, m.devise);
  return m.montantSigneMineur > 0 ? '+$montant' : montant;
}

String _dateHeure(DateTime date) {
  final DateTime local = date.toLocal();
  return t.finance.mouvements.detail.dateHeure(
    date: dateCourte(local),
    heure: heureMinute(local),
  );
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

String? _retour(BuildContext context) {
  try {
    return cheminRetourValide(
      GoRouterState.of(context).uri.queryParameters['retour'],
    );
  } on Object {
    return null;
  }
}

String? _adresse(BuildContext context) {
  try {
    return GoRouterState.of(context).uri.toString();
  } on Object {
    return null;
  }
}

/// S07 « Mouvements de solde » (`/tuteur/compte/soldes/mouvements`).
class MouvementsComptePage extends ConsumerStatefulWidget {
  /// Cree la page.
  const MouvementsComptePage({super.key});

  /// La cle du filtre d'un profil (`null` = tous).
  static Key filtreKey(String? profilId) =>
      Key('mouvements.filtre.${profilId ?? '*'}');

  @override
  ConsumerState<MouvementsComptePage> createState() =>
      _MouvementsComptePageState();
}

class _MouvementsComptePageState extends ConsumerState<MouvementsComptePage> {
  // Sans routeur (ecran monte seul) : le filtre reste un etat local.
  String? _profilLocal;

  Uri? _ici(BuildContext context) {
    try {
      return GoRouterState.of(context).uri;
    } on Object {
      return null;
    }
  }

  /// Le filtre vit dans `?profil=` : il survit au retour du detail.
  void _filtrer(GoRouter? routeur, Uri? ici, String? profil) {
    if (routeur == null || ici == null) {
      setState(() => _profilLocal = profil);
      return;
    }
    final Map<String, String> requete = <String, String>{...ici.queryParameters}
      ..remove('profil');
    if (profil != null) {
      requete['profil'] = profil;
    }
    routeur.go(
      Uri(
        path: ici.path,
        queryParameters: requete.isEmpty ? null : requete,
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final GoRouter? routeur = GoRouter.maybeOf(context);
    final Uri? ici = _ici(context);
    final String retour = _retour(context) ?? Routes.tuteurCompteSoldes;
    final Map<String, String> prenoms = _prenoms(ref);
    final String? demande = ici == null
        ? _profilLocal
        : ici.queryParameters['profil'];
    // Un profil hors du foyer lu ne filtre pas : « Tous ».
    final String? profil = prenoms.containsKey(demande) ? demande : null;
    final AsyncValue<List<MouvementSolde>> mouvements = ref.watch(
      mouvementsProvider(profil),
    );
    final bool indisponible =
        mouvements.hasError && mouvements.error is CapaciteIndisponible;

    return PageShell(
      titre: t.finance.mouvements.titre,
      sousTitre: t.finance.mouvements.sousTitre,
      onRetour: () => routeur?.go(retour),
      child: ColonneSousPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (!indisponible && prenoms.isNotEmpty) ...<Widget>[
              Semantics(
                header: true,
                child: Text(
                  t.finance.mouvements.filtre,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Ecart.vSm,
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: <Widget>[
                  for (final MapEntry<String?, String> e
                      in <MapEntry<String?, String>>[
                        MapEntry<String?, String>(
                          null,
                          t.finance.mouvements.tous,
                        ),
                        for (final MapEntry<String, String> p
                            in prenoms.entries)
                          MapEntry<String?, String>(p.key, p.value),
                      ])
                    FilterPill(
                      key: MouvementsComptePage.filtreKey(e.key),
                      libelle: e.value,
                      retenue: profil == e.key,
                      onPress: () => _filtrer(routeur, ici, e.key),
                    ),
                ],
              ),
              Ecart.vLg,
            ],
            BlocAsynchrone<List<MouvementSolde>>(
              valeur: mouvements,
              squelette: const Skeleton.liste(lignes: 3),
              onReessayer: () => ref.invalidate(mouvementsProvider(profil)),
              estVide: (List<MouvementSolde> l) => l.isEmpty,
              vide: EtatSysteme(
                nature: NatureEtat.aucunResultat,
                titre: t.finance.mouvements.aucun,
                phrase: t.finance.mouvements.aucunPhrase,
              ),
              construire: (List<MouvementSolde> lus) => ListeEchelonnee(
                children: <Widget>[
                  GroupeReglages(
                    lignes: <LigneRubrique>[
                      for (final MouvementSolde m in lus)
                        LigneRubrique(
                          icone: AppIcons.finance,
                          libelle: libelleNature(m.natureServeur),
                          valeur: montantSigne(m),
                          legende: t.finance.mouvements.legende(
                            prenom:
                                prenoms[m.profilId] ??
                                t.finance.profilSansPrenom,
                            date: _dateHeure(m.date),
                          ),
                          onPress: () => routeur?.go(
                            Uri(
                              path: Routes.mouvementPour(m.id),
                              queryParameters: <String, String>{
                                'retour':
                                    ici?.toString() ??
                                    Routes.tuteurCompteMouvements,
                              },
                            ).toString(),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// S08 « Detail du mouvement »
/// (`/tuteur/compte/soldes/mouvements/:mouvementId`).
class DetailMouvementPage extends ConsumerWidget {
  /// Cree la page.
  const DetailMouvementPage({required this.mouvementId, super.key});

  /// L'identifiant du mouvement, tel que rendu par le serveur.
  final String mouvementId;

  /// Le lien vers la seance liee.
  static const Key voirSeanceKey = Key('mouvement.voirSeance');

  /// Le lien « Obtenir de l'aide ».
  static const Key aideKey = Key('mouvement.aide');

  /// Le solde actuel du profil concerne, s'il se lit.
  static const Key soldeKey = Key('mouvement.solde');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter? routeur = GoRouter.maybeOf(context);
    final String retour = _retour(context) ?? Routes.tuteurCompteMouvements;
    final Map<String, String> prenoms = _prenoms(ref);
    final AsyncValue<SoldesFoyer> soldes = ref.watch(soldesFoyerProvider);
    // L'adresse de cet ecran, pour que l'aide y ramene.
    final String? ici = _adresse(context);

    return PageShell(
      titre: t.finance.mouvements.detail.titre,
      onRetour: () => routeur?.go(retour),
      child: ColonneSousPage(
        child: BlocAsynchrone<MouvementSolde?>(
          valeur: ref.watch(mouvementProvider(mouvementId)),
          squelette: const Skeleton.liste(lignes: 4),
          onReessayer: () => ref.invalidate(mouvementProvider(mouvementId)),
          estVide: (MouvementSolde? m) => m == null,
          vide: EtatSysteme(
            nature: NatureEtat.introuvable,
            titre: t.finance.mouvements.detail.introuvable,
            phrase: t.finance.mouvements.detail.introuvablePhrase,
          ),
          construire: (MouvementSolde? lu) {
            final MouvementSolde m = lu!;
            final String? statut = libelleStatut(m.statutServeur);
            final String? seance = m.seanceId;
            // Le solde actuel du profil, en tete comme sur la maquette S08 :
            // seulement s'il se lit et porte ce profil, jamais un « 0 ».
            SoldeProfil? solde;
            if (soldes.hasValue && !soldes.hasError) {
              for (final SoldeProfil s in soldes.requireValue.profils) {
                if (s.profilId == m.profilId) {
                  solde = s;
                }
              }
            }
            final String? prenom = prenoms[m.profilId];
            return ListeEchelonnee(
              children: <Widget>[
                if (solde != null && prenom != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: ResumeSolde.profil(
                      key: soldeKey,
                      prenom: prenom,
                      solde: solde,
                    ),
                  ),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      LigneCleValeur(
                        cle: t.finance.mouvements.detail.nature,
                        valeur: libelleNature(m.natureServeur),
                      ),
                      LigneCleValeur(
                        cle: t.finance.mouvements.detail.montant,
                        valeur: montantSigne(m),
                        chiffres: true,
                      ),
                      LigneCleValeur(
                        cle: t.finance.mouvements.detail.date,
                        valeur: _dateHeure(m.date),
                      ),
                      LigneCleValeur(
                        cle: t.finance.mouvements.detail.profil,
                        valeur: prenom ?? t.finance.profilSansPrenom,
                      ),
                      if (statut != null)
                        LigneCleValeur(
                          cle: t.finance.mouvements.detail.statut,
                          valeur: '',
                          // Liste fermee : seul un statut confirme est connu.
                          complement: StatusPill(
                            libelle: statut,
                            ton: TonEtat.succes,
                          ),
                        ),
                    ],
                  ),
                ),
                if (seance != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.lg),
                    child: LienFleche(
                      key: voirSeanceKey,
                      libelle: t.finance.mouvements.detail.voirSeance,
                      // L'eleve du mouvement : une seance de groupe du foyer
                      // s'ouvre sur la bonne ligne.
                      onPress: () => routeur?.go(
                        Uri(
                          path: Routes.seancePour(seance),
                          queryParameters: <String, String>{
                            'eleve': m.profilId,
                          },
                        ).toString(),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: LienFleche(
                    key: aideKey,
                    libelle: t.finance.mouvements.detail.aide,
                    onPress: () => routeur?.go(
                      Uri(
                        path: Routes.compteTuteurSousPage('aide'),
                        queryParameters: ici == null
                            ? null
                            : <String, String>{'retour': ici},
                      ).toString(),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
