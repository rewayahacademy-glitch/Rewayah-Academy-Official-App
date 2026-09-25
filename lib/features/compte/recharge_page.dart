import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:go_router/go_router.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/port_finance_foyer.dart';
import '../../core/finance/format_montant.dart';
import '../../core/foyer/selection_eleve.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/router/chemin_retour.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/choice_card_group.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/page_etape.dart';
import '../../core/widgets/selecteur_profils.dart';
import '../../core/widgets/selection_profils.dart';
import '../../core/widgets/skeleton.dart';
import 'question_etape.dart';
import 'soldes_page.dart';

// S03 « Pour qui ? » et S04 « Quelle recharge ? » (LT-7, complement Tuteur
// section 5 ; planche « 01 Recharges, remises et acces »). Aucun prix, total
// ni remise calcule ici : les offres sont affichees telles que le serveur les
// rend (DB-FIN-03), et « Verifier » demande le devis au serveur. Le devis est
// indisponible partout pour l'instant : l'ecran le dit, sans rien simuler.

/// Les offres rendues pour des profils, cle = identifiants tries joints par
/// des virgules (une liste n'a pas d'egalite de valeur).
final FutureProviderFamily<List<OffreRecharge>, String> offresRechargeProvider =
    FutureProvider.family<List<OffreRecharge>, String>(
      (Ref ref, String ids) =>
          ref.watch(portFinanceFoyerProvider).offresRecharge(ids.split(',')),
    );

/// S03-S04 « Recharger » (`/tuteur/compte/soldes/recharge`). Deux etapes dans
/// la meme page ; `?profil=` preselectionne un profil, `?retour=` (filtre par
/// `cheminRetourValide`) est la sortie de la premiere etape, S01 a defaut.
class RechargePage extends ConsumerStatefulWidget {
  /// Cree la page.
  const RechargePage({super.key, this.profilInitial, this.retour});

  /// Le profil preselectionne (`?profil=`), s'il fait partie des soldes.
  final String? profilInitial;

  /// Le chemin de sortie, deja filtre.
  final String? retour;

  /// L'action « Continuer » de l'etape 1.
  static const Key continuerKey = Key('recharge.continuer');

  /// L'action « Verifier » de l'etape 2.
  static const Key verifierKey = Key('recharge.verifier');

  /// La carte d'une offre.
  static Key offreKey(String offreId) => Key('recharge.offre.$offreId');

  @override
  ConsumerState<RechargePage> createState() => _RechargePageState();
}

class _RechargePageState extends ConsumerState<RechargePage> {
  int _etape = 1;
  late Set<String> _selection = <String>{?widget.profilInitial};
  final Map<String, String> _offres = <String, String>{};
  bool _enCours = false;
  Object? _echec;

  Map<String, String> _prenoms() {
    final AsyncValue<List<ProfilEleveFoyer>> profils = ref.watch(
      profilsElevesFoyerProvider,
    );
    return <String, String>{
      if (profils.hasValue && !profils.hasError)
        for (final ProfilEleveFoyer p in profils.requireValue)
          p.eleveId: p.prenom,
    };
  }

  Future<void> _verifier(List<String> ids) async {
    // Une demande a la fois (double tap, reessai pendant l'attente).
    if (_enCours) {
      return;
    }
    setState(() {
      _enCours = true;
      _echec = null;
    });
    try {
      final DevisRecharge devis = await ref
          .read(portFinanceFoyerProvider)
          .devisRecharge(<ChoixRecharge>[
            for (final String id in ids)
              ChoixRecharge(profilId: id, offreId: _offres[id]!),
          ]);
      if (!mounted) {
        return;
      }
      setState(() => _enCours = false);
      // S05 (`VerifierRechargePage`) lit le devis dans `extra`.
      GoRouter.of(context)
          .go(Routes.tuteurCompteRechargeVerifier, extra: devis);
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _enCours = false;
          _echec = e;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final GoRouter? routeur = GoRouter.maybeOf(context);
    final Map<String, String> prenoms = _prenoms();
    final AsyncValue<SoldesFoyer> soldes = ref.watch(soldesFoyerProvider);
    // L'ordre des profils est celui du serveur (soldes), jamais la selection.
    final List<String> ids = <String>[
      if (soldes.hasValue && !soldes.hasError)
        for (final SoldeProfil s in soldes.requireValue.profils)
          if (_selection.contains(s.profilId)) s.profilId,
    ];

    if (_etape == 1) {
      return PageEtape(
        numero: 1,
        total: 2,
        onRetour: () => routeur?.go(widget.retour ?? Routes.tuteurCompteSoldes),
        action: ActionPrincipale(
          key: RechargePage.continuerKey,
          libelle: t.finance.recharge.continuer,
          onPress: ids.isEmpty ? null : () => setState(() => _etape = 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            QuestionEtape(
              titre: t.finance.recharge.pourQui,
              phrase: t.finance.recharge.pourQuiPhrase,
            ),
            BlocAsynchrone<SoldesFoyer>(
              valeur: soldes,
              squelette: const Skeleton.liste(lignes: 3),
              onReessayer: () => ref.invalidate(soldesFoyerProvider),
              estVide: (SoldesFoyer s) => s.profils.isEmpty,
              vide: EtatSysteme(
                nature: NatureEtat.aucunResultat,
                titre: t.finance.soldes.aucunProfil,
                phrase: t.finance.soldes.aucunProfilPhrase,
              ),
              construire: (SoldesFoyer lus) => SelectionProfils(
                profils: <ProfilSelectionnable>[
                  for (final SoldeProfil s in lus.profils)
                    ProfilSelectionnable(
                      id: s.profilId,
                      prenom: prenoms[s.profilId] ?? t.finance.profilSansPrenom,
                      etat: switch ((s.montantMineur, s.devise)) {
                        (final int m, final String d) => t.finance.soldeLigne(
                          montant: formaterMontant(m, d),
                        ),
                        _ => t.finance.soldeInconnu,
                      },
                    ),
                ],
                selection: _selection,
                onChange: (Set<String> s) => setState(() => _selection = s),
              ),
            ),
          ],
        ),
      );
    }

    final AsyncValue<List<OffreRecharge>> offres = ref.watch(
      offresRechargeProvider((List<String>.of(ids)..sort()).join(',')),
    );
    final bool complet = ids.isNotEmpty && ids.every(_offres.containsKey);
    final Object? echec = _echec;

    return PageEtape(
      numero: 2,
      total: 2,
      onRetour: () => setState(() {
        _etape = 1;
        _echec = null;
      }),
      action: echec == null
          ? ActionPrincipale(
              key: RechargePage.verifierKey,
              libelle: t.finance.recharge.verifier,
              enCours: _enCours,
              onPress: complet ? () => _verifier(ids) : null,
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          QuestionEtape(
            titre: t.finance.recharge.quelle,
            phrase: t.finance.recharge.quellePhrase,
          ),
          if (echec != null)
            echec is CapaciteIndisponible
                ? EtatSysteme(
                    nature: NatureEtat.indisponible,
                    titre: t.finance.recharge.devisIndisponible,
                    phrase: t.finance.recharge.devisIndisponiblePhrase,
                  )
                : EtatSysteme(
                    nature: NatureEtat.echecServeur,
                    onAction: () => _verifier(ids),
                  )
          else
            BlocAsynchrone<List<OffreRecharge>>(
              valeur: offres,
              squelette: const Skeleton.liste(lignes: 3),
              onReessayer: () => ref.invalidate(offresRechargeProvider),
              construire: (List<OffreRecharge> lues) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  for (final String id in ids)
                    _OffresProfil(
                      prenom: prenoms[id] ?? t.finance.profilSansPrenom,
                      offres: <OffreRecharge>[
                        for (final OffreRecharge o in lues)
                          if (o.profilId == id) o,
                      ],
                      retenue: _offres[id],
                      onChoix: (String offreId) =>
                          setState(() => _offres[id] = offreId),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Les offres d'un profil, en cartes a choix unique.
class _OffresProfil extends StatelessWidget {
  const _OffresProfil({
    required this.prenom,
    required this.offres,
    required this.retenue,
    required this.onChoix,
  });

  final String prenom;
  final List<OffreRecharge> offres;
  final String? retenue;
  final ValueChanged<String> onChoix;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(prenom, style: Theme.of(context).textTheme.titleSmall),
          ),
          Ecart.vSm,
          if (offres.isEmpty)
            EtatSysteme(
              nature: NatureEtat.aucunResultat,
              titre: t.finance.recharge.aucuneOffre,
              phrase: t.finance.recharge.aucuneOffrePhrase(prenom: prenom),
            )
          else
            ChoiceCardGroup(
              autoriserSaisieLibre: false,
              valeurInitiale: retenue == null
                  ? null
                  : ReponseChoix(valeurs: <String>{retenue!}),
              options: <OptionChoix>[
                for (final OffreRecharge o in offres)
                  OptionChoix(
                    cle: RechargePage.offreKey(o.id),
                    valeur: o.id,
                    // ponytail: la quantite est ecrite dans la devise de
                    // l'offre, faute de devise du solde dans `OffreRecharge`
                    // (demande T, LT-7).
                    libelle: t.finance.recharge.offre(
                      quantite: formaterMontant(o.quantiteMineure, o.devise),
                    ),
                    description: t.finance.recharge.prix(
                      prix: formaterMontant(o.prixMineur, o.devise),
                    ),
                  ),
              ],
              onChange: (ReponseChoix r) {
                if (r.valeurs.isNotEmpty) {
                  onChoix(r.valeurs.first);
                }
              },
            ),
        ],
      ),
    );
  }
}

/// Le chemin de retour de la recharge, filtre (`?retour=`).
String? retourRecharge(GoRouterState etat) =>
    cheminRetourValide(etat.uri.queryParameters['retour']);
