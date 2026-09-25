import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/port_acces_foyer.dart';
import '../../core/capacites/port_finance_foyer.dart';
import '../../core/finance/format_montant.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/router/chemin_retour.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/ecran_resultat.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/ligne_cle_valeur.dart';
import '../../core/widgets/page_etape.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/resultat_par_profil.dart';
import '../../core/widgets/selecteur_profils.dart';
import '../../core/widgets/selection_profils.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import '../foyer/fiche_eleve_page.dart' show ColonnesFiche;
import 'acces_page.dart' show echeanceAcces;
import 'carte_rubriques.dart';
import 'donnees_compte.dart';

// S09 « Arreter l'acces », S10 « Consequences » et S11 « Resultat » (LT-9,
// complement Tuteur section 5 ; planche « 01 Recharges, remises et acces »).
// Aucune regle locale : eligibilite, motif, date d'effet, consequences, solde
// et reprise sont ceux du serveur (DB-FIN-05). La confirmation reste fermee
// tant qu'ils ne sont pas tous connus ; l'arret (DB-FIN-06) est indisponible
// partout pour l'instant, demonstration comprise : jamais un succes simule.

/// L'apercu d'annulation pour des profils, cle = identifiants tries joints
/// par des virgules. Relu a chaque ouverture (jamais un apercu garde).
final FutureProviderFamily<ApercuAnnulation, String> apercuAnnulationProvider =
    FutureProvider.autoDispose.family<ApercuAnnulation, String>(
      (Ref ref, String ids) =>
          ref.watch(portFinanceFoyerProvider).apercuAnnulation(ids.split(',')),
    );

/// La cle de [apercuAnnulationProvider] pour [ids].
String cleApercu(Iterable<String> ids) =>
    (List<String>.of(ids)..sort()).join(',');

/// Vrai quand le serveur sait rendre un apercu pour [ids] (DB-FIN-05) : seule
/// condition pour proposer « Arreter l'acces ». En production, faux.
///
/// ponytail: la disponibilite se lit en demandant l'apercu lui-meme (lecture
/// sans effet), faute d'un indicateur de capacite ; a remplacer si le serveur
/// en rend un.
bool apercuPossible(WidgetRef ref, Iterable<String> ids) {
  if (ids.isEmpty) {
    return false;
  }
  final AsyncValue<ApercuAnnulation> apercu = ref.watch(
    apercuAnnulationProvider(cleApercu(ids)),
  );
  return apercu.hasValue && !apercu.hasError;
}

/// Le motif de non-eligibilite en mots, depuis une liste **fermee** de codes
/// connus. Un code inconnu (ou absent) se dit par une phrase neutre, jamais
/// brut.
///
/// ponytail: seuls les codes de la demonstration sont connus ; la liste reelle
/// sera fixee avec DB-FIN-05 (demande T, LT-9).
String libelleMotif(String? code) => switch (code) {
  'demo_profil_inconnu' => t.finance.arret.motifs.profilInconnu,
  _ => t.finance.arret.motifs.inconnu,
};

/// Une consequence en mots, ou `null` pour un code inconnu (jamais brut).
String? libelleEffet(String code) => switch (code) {
  'demo_seances_futures_retirees' => t.finance.arret.effets.seancesRetirees,
  'demo_solde_conserve' => t.finance.arret.effets.soldeConserve,
  _ => null,
};

/// Vrai si l'apercu dit tout ce que la confirmation engage pour [ids] : une
/// entree par profil demande, et pour chaque profil eligible une date
/// d'effet, un solde conserve et des consequences toutes connues.
bool apercuComplet(ApercuAnnulation apercu, List<String> ids) {
  final Set<String> rendus = <String>{
    for (final ConsequencesAnnulation c in apercu.profils) c.profilId,
  };
  if (!ids.every(rendus.contains)) {
    return false;
  }
  return apercu.profils
      .where((ConsequencesAnnulation c) => c.eligible)
      .every(
        (ConsequencesAnnulation c) =>
            c.dateEffet != null &&
            c.soldeConserve != null &&
            c.consequencesServeur.every((String e) => libelleEffet(e) != null),
      );
}

/// Le chemin de retour de l'arret, filtre (`?retour=`).
String? retourArret(GoRouterState etat) =>
    cheminRetourValide(etat.uri.queryParameters['retour']);

/// S09-S10 (`/tuteur/compte/acces/arreter`). Deux etapes dans la meme page ;
/// `?profil=` preselectionne un profil et ouvre directement S10, `?retour=`
/// (filtre) est la sortie, la page des acces a defaut.
class ArretAccesPage extends ConsumerStatefulWidget {
  /// Cree la page.
  const ArretAccesPage({super.key, this.profilInitial, this.retour});

  /// Le profil preselectionne (`?profil=`).
  final String? profilInitial;

  /// Le chemin de sortie, deja filtre.
  final String? retour;

  /// L'action « Voir les consequences » (S09).
  static const Key continuerKey = Key('arret.continuer');

  /// La case « J'ai compris » (S10).
  static const Key comprisKey = Key('arret.compris');

  /// L'action « Confirmer l'arret » (S10).
  static const Key confirmerKey = Key('arret.confirmer');

  /// La carte des consequences d'un profil.
  static Key profilKey(String id) => Key('arret.profil.$id');

  /// La liste des profils concernes, a cote des consequences (bureau).
  static const Key profilsKey = Key('arret.profils');

  @override
  ConsumerState<ArretAccesPage> createState() => _ArretAccesPageState();
}

class _ArretAccesPageState extends ConsumerState<ArretAccesPage> {
  late int _etape = widget.profilInitial == null ? 1 : 2;
  late Set<String> _selection = <String>{?widget.profilInitial};

  /// Une cle par demande, reprise a chaque nouvelle tentative ; renouvelee
  /// seulement si la selection peut changer (retour a S09).
  String _cle = const Uuid().v4();
  bool _compris = false;
  bool _enCours = false;
  Object? _echec;

  void _sortir() =>
      GoRouter.maybeOf(context)?.go(widget.retour ?? Routes.tuteurCompteAcces);

  Future<void> _confirmer(ApercuAnnulation apercu) async {
    if (_enCours) {
      return;
    }
    setState(() {
      _enCours = true;
      _echec = null;
    });
    try {
      final ResultatAnnulation resultat = await ref
          .read(portFinanceFoyerProvider)
          .annulerAcces(
            referenceApercu: apercu.reference,
            profilIds: <String>[
              for (final ConsequencesAnnulation c in apercu.profils)
                if (c.eligible) c.profilId,
            ],
            cleIdempotence: _cle,
          );
      if (!mounted) {
        return;
      }
      setState(() => _enCours = false);
      // L'arret a pu changer les acces : ils sont relus.
      ref.invalidate(accesFoyerProvider);
      GoRouter.of(context)
          .go(Routes.tuteurCompteArretAccesResultat, extra: resultat);
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
    final AsyncValue<List<AccesBeneficiaire>> acces = ref.watch(
      accesFoyerProvider,
    );
    final List<AccesBeneficiaire> lus = acces.hasValue && !acces.hasError
        ? acces.requireValue
        : const <AccesBeneficiaire>[];
    final Map<String, String> prenoms = <String, String>{
      for (final AccesBeneficiaire a in lus) a.eleveId: a.prenom,
    };

    if (_etape == 1) {
      // L'ordre des profils est celui de la lecture, jamais la selection.
      final List<String> ids = <String>[
        for (final AccesBeneficiaire a in lus)
          if (_selection.contains(a.eleveId)) a.eleveId,
      ];
      return PageEtape(
        numero: 1,
        total: 2,
        onRetour: _sortir,
        action: ActionPrincipale(
          key: ArretAccesPage.continuerKey,
          libelle: t.finance.arret.continuer,
          onPress: ids.isEmpty
              ? null
              : () => setState(() {
                  _selection = ids.toSet();
                  _etape = 2;
                }),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _Question(
              titre: t.finance.arret.pourQui,
              phrase: t.finance.arret.pourQuiPhrase,
            ),
            BlocAsynchrone<List<AccesBeneficiaire>>(
              valeur: acces,
              squelette: const Skeleton.liste(lignes: 2),
              onReessayer: () => ref.invalidate(accesFoyerProvider),
              vide: EtatSysteme(
                nature: NatureEtat.aucunResultat,
                titre: t.compte.tuteur.pageAcces.aucunTitre,
                phrase: t.compte.tuteur.pageAcces.aucunePhrase,
              ),
              construire: (List<AccesBeneficiaire> liste) => SelectionProfils(
                profils: <ProfilSelectionnable>[
                  for (final AccesBeneficiaire a in liste)
                    ProfilSelectionnable(
                      id: a.eleveId,
                      prenom: a.prenom,
                      etat: echeanceAcces(a),
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

    final List<String> ids = List<String>.of(_selection);
    final AsyncValue<ApercuAnnulation> apercu = ref.watch(
      apercuAnnulationProvider(cleApercu(ids)),
    );
    final ApercuAnnulation? lu = apercu.hasValue && !apercu.hasError
        ? apercu.requireValue
        : null;
    final bool complet = lu != null && apercuComplet(lu, ids);
    final bool aucunEligible =
        lu != null && !lu.profils.any((ConsequencesAnnulation c) => c.eligible);
    final Object? echec = _echec;
    final bool indisponible = echec is CapaciteIndisponible;
    final bool confirmable =
        complet && !aucunEligible && _compris && !indisponible && !_enCours;

    return PageEtape(
      numero: 2,
      total: 2,
      onRetour: widget.profilInitial != null
          ? _sortir
          : () => setState(() {
              _etape = 1;
              _compris = false;
              _echec = null;
              _cle = const Uuid().v4();
            }),
      action: indisponible
          ? null
          : ActionPrincipale(
              key: ArretAccesPage.confirmerKey,
              libelle: t.finance.arret.confirmer,
              enCours: _enCours,
              onPress: confirmable ? () => _confirmer(lu) : null,
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _Question(
            titre: t.finance.arret.consequences,
            phrase: t.finance.arret.consequencesPhrase,
          ),
          _AvecProfils(
            profils: <AccesBeneficiaire>[
              for (final AccesBeneficiaire a in lus)
                if (_selection.contains(a.eleveId)) a,
            ],
            consequences: BlocAsynchrone<ApercuAnnulation>(
              valeur: apercu,
              squelette: const Skeleton.liste(lignes: 3),
              onReessayer: () => ref.invalidate(apercuAnnulationProvider),
              construire: (ApercuAnnulation a) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  for (final ConsequencesAnnulation c in a.profils) ...<Widget>[
                    _Consequences(
                      key: ArretAccesPage.profilKey(c.profilId),
                      consequences: c,
                      prenom: prenoms[c.profilId] ?? t.finance.profilSansPrenom,
                    ),
                    Ecart.vMd,
                  ],
                  if (!complet)
                    EtatSysteme(
                      nature: NatureEtat.indisponible,
                      titre: t.finance.arret.incomplet,
                      phrase: t.finance.arret.incompletPhrase,
                      onAction: () => ref.invalidate(apercuAnnulationProvider),
                    )
                  else if (aucunEligible)
                    EtatSysteme(
                      nature: NatureEtat.aucunResultat,
                      titre: t.finance.arret.aucunEligible,
                      phrase: t.finance.arret.aucunEligiblePhrase,
                    )
                  else ...<Widget>[
                    Material(
                      type: MaterialType.transparency,
                      child: CheckboxListTile(
                        key: ArretAccesPage.comprisKey,
                        value: _compris,
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        title: Text(t.finance.arret.compris),
                        onChanged: _enCours || indisponible
                            ? null
                            : (bool? v) =>
                                  setState(() => _compris = v ?? false),
                      ),
                    ),
                    if (echec is CapaciteIndisponible)
                      EtatSysteme(
                        nature: NatureEtat.indisponible,
                        titre: t.finance.arret.annulationIndisponible,
                        phrase: t.finance.arret.annulationIndisponiblePhrase,
                        dependance: echec.dependance,
                      )
                    else if (echec != null)
                      EtatSysteme(
                        nature: NatureEtat.echecServeur,
                        onAction: _enCours ? null : () => _confirmer(a),
                        actionEnCours: _enCours,
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// S10 sur bureau : les profils concernes d'un cote, les consequences
/// rendues par le serveur de l'autre (planche « 06 Web sombre, acces »).
/// Telephone et tablette, ou profils non lus : les consequences seules,
/// comme avant.
class _AvecProfils extends StatelessWidget {
  const _AvecProfils({required this.profils, required this.consequences});

  final List<AccesBeneficiaire> profils;
  final Widget consequences;

  @override
  Widget build(BuildContext context) {
    if (profils.isEmpty || AppGabarit.de(context) != Gabarit.desktop) {
      return consequences;
    }
    return ColonnesFiche(
      principal: GroupeReglages(
        key: ArretAccesPage.profilsKey,
        lignes: <LigneRubrique>[
          for (final AccesBeneficiaire a in profils)
            LigneRubrique(
              icone: AppIcons.profil,
              libelle: a.prenom,
              legende: echeanceAcces(a),
            ),
        ],
      ),
      annexe: consequences,
    );
  }
}

class _Question extends StatelessWidget {
  const _Question({required this.titre, required this.phrase});

  final String titre;
  final String phrase;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(titre, style: textes.headlineSmall),
          ),
          Ecart.vSm,
          Text(phrase, style: textes.bodyMedium),
        ],
      ),
    );
  }
}

/// Les consequences d'un profil, telles que rendues.
class _Consequences extends StatelessWidget {
  const _Consequences({
    required this.consequences,
    required this.prenom,
    super.key,
  });

  final ConsequencesAnnulation consequences;
  final String prenom;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final ConsequencesAnnulation c = consequences;
    final a = t.finance.arret;
    final DateTime? effet = c.dateEffet;
    final SoldeProfil? solde = c.soldeConserve;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            alignment: WrapAlignment.spaceBetween,
            children: <Widget>[
              Semantics(
                header: true,
                child: Text(prenom, style: textes.titleSmall),
              ),
              StatusPill(
                libelle: c.eligible ? a.eligible : a.nonEligible,
                ton: c.eligible ? TonEtat.neutre : TonEtat.alerte,
              ),
            ],
          ),
          Ecart.vSm,
          if (!c.eligible)
            Text(libelleMotif(c.motifServeur), style: textes.bodyMedium)
          else ...<Widget>[
            LigneCleValeur(
              cle: a.dateEffet,
              valeur: effet == null ? a.dateInconnue : dateLongue(effet),
            ),
            LigneCleValeur(
              cle: a.soldeConserve,
              valeur: switch ((solde?.montantMineur, solde?.devise)) {
                (final int m, final String d) => formaterMontant(m, d),
                _ => t.finance.soldeInconnu,
              },
              chiffres: solde?.montantMineur != null,
            ),
            LigneCleValeur(
              cle: a.reprise,
              valeur: c.repriseDisponible ? a.reprisePossible : a.repriseNon,
            ),
            for (final String e in c.consequencesServeur) ...<Widget>[
              Ecart.vSm,
              Text(
                libelleEffet(e) ?? a.effets.inconnu,
                style: textes.bodyMedium,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// S11 (`/tuteur/compte/acces/arreter/resultat`), resultat dans `extra`.
class ResultatArretAccesPage extends ConsumerWidget {
  /// Cree la page.
  const ResultatArretAccesPage({super.key, this.resultat});

  /// Le resultat rendu par le serveur ; `null` s'il n'a pas suivi.
  final ResultatAnnulation? resultat;

  /// L'action « Voir les acces ».
  static const Key accesKey = Key('arret.resultat.acces');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter? routeur = GoRouter.maybeOf(context);
    void versAcces() {
      ref.invalidate(accesFoyerProvider);
      routeur?.go(Routes.tuteurCompteAcces);
    }

    final res = t.finance.arret.resultat;
    final ActionPrincipale action = ActionPrincipale(
      key: accesKey,
      libelle: res.retourAcces,
      onPress: versAcces,
    );
    final ResultatAnnulation? r = resultat;
    if (r == null) {
      return PageShell(
        titre: res.titre,
        onRetour: versAcces,
        actions: action,
        child: EtatSysteme(
          nature: NatureEtat.ressourceExpiree,
          titre: res.perdu,
          phrase: res.perduPhrase,
        ),
      );
    }

    final AsyncValue<List<AccesBeneficiaire>> acces = ref.watch(
      accesFoyerProvider,
    );
    return PageShell(
      titre: res.titre,
      onRetour: versAcces,
      actions: action,
      child: ColonneSousPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Aucune issue globale n'est rendue : l'ecran ne dit que la
            // transmission, puis l'issue de chaque profil.
            EcranResultat(
              icone: AppIcons.attente,
              ton: TonEtat.neutre,
              titre: res.enregistre,
              phrase: res.phrase,
            ),
            Ecart.vXl,
            ResultatParProfil(
              titre: res.parProfil,
              issues: r.profils,
              prenoms: <String, String>{
                if (acces.hasValue && !acces.hasError)
                  for (final AccesBeneficiaire a in acces.requireValue)
                    a.eleveId: a.prenom,
              },
            ),
          ],
        ),
      ),
    );
  }
}
