/// CPT-SUPPR-EXPORT : les demandes de suppression de compte, cote direction.
///
/// Une carte par demande : qui, depuis quand, le motif, ce qui reste du. Pour
/// une demande en attente, le geste « Traiter la demande » anonymise le compte.
/// Il engage et ne se defait pas : il passe par une confirmation qui le dit, et
/// le solde restant du y figure.
///
/// Le geste n'est rendu que si le serveur dit la demande traitable
/// (`delai_ecoule`) et qu'aucune seance n'est a venir (le serveur refuse
/// sinon) : sinon la raison le remplace, jamais un bouton grise (lib/CLAUDE.md).
/// L'ecran lit une capacite, jamais un role. Aucun delai calcule ici.
/// Etats : chargement, contenu, vide, erreur, hors ligne, port absent.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/admin/admin_domaine.dart';
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/permission_insuffisante.dart';
import '../../core/capacites/port_suppressions_admin.dart';
import '../../core/domain/enums.dart';
import '../../core/finance/format_montant.dart';
import '../../core/i18n/dates_appareil.dart';
import '../../core/i18n/identifiant_insecable.dart';
import '../../core/i18n/isolat_bidi.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/bandeau_attention.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/confirm_destructive.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/ligne_cle_valeur.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/pile_cartes.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/sous_navigation_domaine.dart';
import '../../core/widgets/status_pill.dart';

/// Les demandes de suppression, lues au serveur (`demandes_suppression_lister`).
/// Relues a chaque ouverture de l'ecran et apres chaque decision.
final FutureProvider<List<DemandeSuppressionAdmin>> suppressionsAdminProvider =
    FutureProvider.autoDispose<List<DemandeSuppressionAdmin>>(
      (Ref ref) => ref.watch(portSuppressionsAdminProvider).lister(),
      retry: (int _, Object _) => null,
    );

/// Ce que dit la ligne en haut de l'ecran apres un geste.
enum RetourSuppression {
  /// Le compte est anonymise.
  traitee,

  /// La demande n'est plus en attente.
  dejaTraitee,

  /// Le delai de reflexion court encore.
  delaiNonEcoule,

  /// Des seances sont encore prevues.
  seancesRefus,

  /// La demande n'existe plus.
  introuvable,

  /// Le serveur refuse cette personne (direction sans double verification).
  refuse,

  /// La decision n'est pas confirmee.
  echec,

  /// Pas de reseau : rien n'est parti.
  horsLigne,
}

/// L'ecran « Suppressions de compte ».
class SuppressionsPage extends ConsumerStatefulWidget {
  /// Cree l'ecran.
  const SuppressionsPage({super.key});

  /// La ligne qui dit ce qu'est devenu le dernier geste.
  static const Key retourKey = ValueKey<String>('suppressions-retour');

  /// Le geste « Traiter la demande » de la demande [id].
  static Key traiterKey(String id) =>
      ValueKey<String>('suppression-traiter-$id');

  /// La raison qui remplace le geste, pour la demande [id].
  static Key raisonKey(String id) => ValueKey<String>('suppression-raison-$id');

  @override
  ConsumerState<SuppressionsPage> createState() => _SuppressionsPageState();
}

class _SuppressionsPageState extends ConsumerState<SuppressionsPage> {
  String? _enCours;
  RetourSuppression? _retour;

  bool get _horsLigne => ref.read(horsLigneProvider).value ?? false;

  Future<void> _traiter(DemandeSuppressionAdmin d) async {
    if (_enCours != null) return;
    final a = t.admin.suppressions;
    final SituationSuppressionAdmin? s = d.situation;
    final String consequence = <String>[
      a.confirmerConsequence,
      if (s != null && s.soldeDu)
        a.confirmerSolde(
          montant: enchainer(s.montantsDus.map<String>(formaterMontant), ' · '),
        ),
    ].join(' ');
    final bool oui = await ConfirmDestructive.demander(
      context,
      question: a.confirmerQuestion(nom: _nomComplet(d)),
      consequence: consequence,
      libelleConfirmer: a.confirmerAction,
      libelleAnnuler: a.confirmerRester,
      irreversible: true,
    );
    if (!oui || !mounted) return;
    // Hors ligne, rien ne part.
    if (_horsLigne) {
      setState(() => _retour = RetourSuppression.horsLigne);
      return;
    }
    setState(() {
      _enCours = d.id;
      _retour = null;
    });
    RetourSuppression retour;
    try {
      retour = switch (await ref
          .read(portSuppressionsAdminProvider)
          .traiter(d.id)) {
        ResultatTraitementSuppression.traitee => RetourSuppression.traitee,
        ResultatTraitementSuppression.dejaTraitee =>
          RetourSuppression.dejaTraitee,
        ResultatTraitementSuppression.delaiEnCours =>
          RetourSuppression.delaiNonEcoule,
        ResultatTraitementSuppression.seancesAVenir =>
          RetourSuppression.seancesRefus,
        ResultatTraitementSuppression.introuvable =>
          RetourSuppression.introuvable,
      };
    } on PermissionInsuffisante {
      retour = RetourSuppression.refuse;
    } on Object {
      // La reponse a pu se perdre apres l'effacement : la liste est relue.
      retour = _horsLigne
          ? RetourSuppression.horsLigne
          : RetourSuppression.echec;
    }
    // Dans tous les cas la liste est relue : une decision dont la reponse s'est
    // perdue doit y apparaitre traitee, jamais « non envoyee ».
    ref.invalidate(suppressionsAdminProvider);
    if (!mounted) return;
    setState(() {
      _enCours = null;
      _retour = retour;
    });
  }

  @override
  Widget build(BuildContext context) {
    final a = t.admin.suppressions;
    final AsyncValue<List<DemandeSuppressionAdmin>> valeur = ref.watch(
      suppressionsAdminProvider,
    );
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final RetourSuppression? retour = _retour;
    return PageShell(
      titre: a.titre,
      sousTitre: a.sousTitre,
      entete: SousNavigationDomaine(onglets: ongletsPersonnes(), indexActif: 5),
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppPage.largeurReglages),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (retour != null)
                Semantics(
                  liveRegion: true,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Text(
                      _message(retour),
                      key: SuppressionsPage.retourKey,
                      style:
                          (retour == RetourSuppression.traitee
                                  ? palette.inkStrong
                                  : palette.inkAlert)
                              .applyTo(textes.bodyMedium ?? const TextStyle()),
                    ),
                  ),
                ),
              BlocAsynchrone<List<DemandeSuppressionAdmin>>(
                key: const ValueKey<String>('suppressions-bloc'),
                valeur: valeur,
                squelette: const Skeleton.liste(lignes: 3),
                onReessayer: () => ref.invalidate(suppressionsAdminProvider),
                vide: EmptyState(
                  key: const ValueKey<String>('suppressions-vide'),
                  message: a.vide,
                  icone: AppIcons.rienAAfficher,
                  registre: RegistreVide.subi,
                ),
                erreurVersEtat: (Object e, VoidCallback? reessayer) {
                  if (e is CapaciteIndisponible) {
                    return EtatSysteme(
                      key: const ValueKey<String>('suppressions-indisponible'),
                      nature: NatureEtat.indisponible,
                      titre: a.indisponibleTitre,
                      phrase: a.indisponiblePhrase,
                      dependance: e.dependance,
                    );
                  }
                  if (e is PermissionInsuffisante) {
                    return EtatSysteme(
                      key: const ValueKey<String>('suppressions-refuse'),
                      nature: NatureEtat.echecServeur,
                      phrase: a.refuse,
                    );
                  }
                  return horsLigne
                      ? EtatSansDonnees(
                          key: const ValueKey<String>(
                            'suppressions-sans-donnees',
                          ),
                          quoi: a.sansDonnees,
                          onAction: reessayer,
                        )
                      : EtatSysteme(
                          key: const ValueKey<String>('suppressions-erreur'),
                          nature: NatureEtat.echecServeur,
                          phrase: a.erreur,
                          onAction: reessayer,
                        );
                },
                construire: (List<DemandeSuppressionAdmin> lues) {
                  final int attendent = lues
                      .where((DemandeSuppressionAdmin d) => d.enAttente)
                      .length;
                  return Column(
                    key: const ValueKey<String>('suppressions-contenu'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      if (attendent > 0) ...<Widget>[
                        Text(
                          a.attente(n: attendent),
                          style: textes.titleMedium,
                        ),
                        Ecart.vLg,
                      ],
                      PileCartes(
                        children: <Widget>[
                          for (final DemandeSuppressionAdmin d in lues)
                            _CarteSuppression(
                              demande: d,
                              enCours: _enCours == d.id,
                              occupe: _enCours != null,
                              onTraiter: () => unawaited(_traiter(d)),
                            ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _message(RetourSuppression r) {
    final a = t.admin.suppressions;
    return switch (r) {
      RetourSuppression.traitee => a.traitee,
      RetourSuppression.dejaTraitee => a.dejaTraitee,
      RetourSuppression.delaiNonEcoule => a.delaiNonEcoule,
      RetourSuppression.seancesRefus => a.seancesRefus,
      RetourSuppression.introuvable => a.introuvable,
      RetourSuppression.refuse => a.refuse,
      RetourSuppression.echec => a.echec,
      RetourSuppression.horsLigne => a.horsLigne,
    };
  }
}

String _nomComplet(DemandeSuppressionAdmin d) => '${d.prenom} ${d.nom}'.trim();

String _nomRole(AppRole? role) => switch (role) {
  AppRole.admin => t.admin.comptes.roleAdmin,
  AppRole.accountant => t.admin.comptes.roleComptable,
  AppRole.controller => t.admin.comptes.roleControleur,
  AppRole.teacher => t.admin.comptes.roleEnseignant,
  AppRole.guardian => t.admin.comptes.roleTuteur,
  AppRole.student => t.admin.comptes.roleEleve,
  null => t.admin.comptes.roleInconnu,
};

class _CarteSuppression extends StatelessWidget {
  const _CarteSuppression({
    required this.demande,
    required this.enCours,
    required this.occupe,
    required this.onTraiter,
  });

  final DemandeSuppressionAdmin demande;
  final bool enCours;
  final bool occupe;
  final VoidCallback onTraiter;

  @override
  Widget build(BuildContext context) {
    final a = t.admin.suppressions;
    final DemandeSuppressionAdmin d = demande;
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final TextStyle corps = palette.inkStrong.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    final SituationSuppressionAdmin? s = d.situation;
    final String? motif = d.motif;
    final DateTime? annulee = d.annuleeLe;
    final DateTime? traitee = d.traiteeLe;
    final String nom = _nomComplet(d);
    return AppCard(
      key: ValueKey<String>('suppression-${d.id}'),
      entete: OverflowBar(
        alignment: MainAxisAlignment.spaceBetween,
        overflowAlignment: OverflowBarAlignment.start,
        spacing: AppSpacing.sm,
        overflowSpacing: AppSpacing.sm,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(isolerSens(nom), style: textes.titleMedium),
          ),
          switch (d.statut) {
            StatutSuppression.enAttente when d.delaiEcoule => StatusPill(
              libelle: a.etat.aTraiter,
              ton: TonEtat.accent,
            ),
            StatutSuppression.enAttente => StatusPill(
              libelle: a.etat.enAttente,
              ton: TonEtat.avertissement,
            ),
            StatutSuppression.annulee => StatusPill(
              libelle: a.etat.annulee,
              ton: TonEtat.neutre,
            ),
            StatutSuppression.traitee => StatusPill(
              libelle: a.etat.traitee,
              ton: TonEtat.succes,
            ),
          },
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          LigneCleValeur(
            cle: a.matricule,
            valeur: identifiantInsecable(d.matricule),
          ),
          Ecart.vSm,
          LigneCleValeur(cle: a.role, valeur: _nomRole(d.role)),
          Ecart.vSm,
          LigneCleValeur(
            cle: a.demandeeLe,
            valeur: dateDeLAppareil(d.demandeeLe),
          ),
          if (annulee != null) ...<Widget>[
            Ecart.vSm,
            LigneCleValeur(cle: a.annuleeLe, valeur: dateDeLAppareil(annulee)),
          ],
          if (traitee != null) ...<Widget>[
            Ecart.vSm,
            LigneCleValeur(cle: a.traiteeLe, valeur: dateDeLAppareil(traitee)),
          ],
          if (motif != null && motif.trim().isNotEmpty) ...<Widget>[
            Ecart.vSm,
            LigneCleValeur(cle: a.motif, valeur: motif.trim()),
          ],
          if (d.enAttente) ...<Widget>[
            // Ce qui reste est dit avant le geste, jamais apres.
            if (s != null && s.soldeDu) ...<Widget>[
              Ecart.vLg,
              BandeauAttention(
                titre: a.soldeTitre,
                message: a.soldeDetail(
                  montant: enchainer(
                    s.montantsDus.map<String>(formaterMontant),
                    ' · ',
                  ),
                ),
              ),
            ],
            if (s != null && s.seancesAVenir > 0) ...<Widget>[
              Ecart.vLg,
              BandeauAttention(
                titre: a.seancesTitre,
                message: a.seancesDetail(n: s.seancesAVenir),
              ),
            ],
            if (d.elevesDuFoyer > 0) ...<Widget>[
              Ecart.vLg,
              BandeauAttention(
                titre: a.foyerTitre,
                message: a.foyerDetail(n: d.elevesDuFoyer),
              ),
            ],
            Ecart.vLg,
            // Pendant une decision, les autres gestes ne sont pas rendus.
            if (d.traitable && (enCours || !occupe))
              ActionPrincipale(
                key: SuppressionsPage.traiterKey(d.id),
                libelle: a.traiter,
                niveau: NiveauAction.secondaire,
                enCours: enCours,
                onPress: enCours ? null : onTraiter,
              )
            else if (!d.delaiEcoule)
              Text(
                a.delaiEnCours(date: dateDeLAppareil(d.echeanceLe)),
                key: SuppressionsPage.raisonKey(d.id),
                style: corps,
              ),
          ],
        ],
      ),
    );
  }
}
