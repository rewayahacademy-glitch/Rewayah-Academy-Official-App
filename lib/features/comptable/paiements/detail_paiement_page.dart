// Detail beneficiaire / paiement (FIN-CPT-W03, M01 ecran 3 ; spec §13.3,
// §31, §40). Posee « en preparation » par CPT-F avec son constructeur
// definitif ; **propriete de la voie CPT-PAY**
// (`20_comptable/02_DECOUPAGE.md`).
//
// Composition (planche H08 W03, layout seulement, K-63) : identite et statut,
// alertes, puis deux colonnes au bureau (a gauche le total et les lignes de
// calcul, a droite la methode masquee, les informations et l'historique),
// une seule colonne sur telephone.
//
// Lignes de calcul avec leur source ; « Signaler un ecart » sans champ de
// correction (R-FIN-17) ; encart permanent §31 ; montant en lecture seule
// (R-FIN-16) ; apres un recalcul a la source, le detail et le total relus
// sont ceux de la nouvelle version (R-FIN-18). Quand le beneficiaire est la
// personne connectee, la source ne permet pas « Payer » et la page dit
// « Traitement par un autre responsable requis » (R-FIN-15, DR-19).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/capacites/capacite_indisponible.dart';
import '../../../core/capacites/port_obligations_payables.dart';
import '../../../core/comptable/modeles_comptable.dart';
import '../../../core/comptable/navigation_comptable.dart';
import '../../../core/comptable/statuts_comptable.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/reseau/service_reseau.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_gabarit.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/action_principale.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/bandeau_attention.dart';
import '../../../core/widgets/bascule_montants.dart';
import '../../../core/widgets/bloc_asynchrone.dart';
import '../../../core/widgets/comptable/ligne_activite.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/etat_systeme.dart';
import '../../../core/widgets/lien_fleche.dart';
import '../../../core/widgets/ligne_cle_valeur.dart';
import '../../../core/widgets/ligne_destination_masquee.dart';
import '../../../core/widgets/montant_argent.dart';
import '../../../core/widgets/montant_sensible.dart';
import '../../../core/widgets/page_shell.dart';
import '../../../core/widgets/pastilles_comptable.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/status_pill.dart';
import 'confirmation/confirmation_payout.dart';
import 'ligne_obligation.dart';
import 'paiements_donnees.dart';
import 'signaler_ecart.dart';

/// Le detail d'une obligation payable, sous l'onglet « A effectuer ».
class DetailPaiementPage extends ConsumerStatefulWidget {
  /// Cree la page pour l'obligation [obligationId] (segment d'adresse).
  const DetailPaiementPage({required this.obligationId, super.key});

  /// L'obligation.
  final String obligationId;

  /// La cle du bouton « Signaler un ecart ».
  static const Key cleSignaler = ValueKey<String>('detail-signaler-ecart');

  /// La cle de l'action principale (« Payer maintenant » ou « Demander
  /// validation »).
  static const Key clePayer = ValueKey<String>('detail-payer');

  /// La cle de l'encart permanent §31.
  static const Key cleEncart = ValueKey<String>('detail-encart-31');

  @override
  ConsumerState<DetailPaiementPage> createState() => _DetailPaiementPageState();
}

class _DetailPaiementPageState extends ConsumerState<DetailPaiementPage> {
  /// Le dernier signalement depose depuis cette page (§13.4).
  SignalementEcart? _signalement;

  Future<void> _signaler(ObligationPayable o) async {
    final SignalementEcart? depose = await ouvrirSignalerEcart(context, o);
    if (depose != null && mounted) {
      setState(() => _signalement = depose);
      ref.invalidate(journalObligationProvider(o.id));
    }
  }

  /// Ouvre la confirmation (CPT-PAY-2), puis relit le detail et le journal :
  /// l'etat affiche est celui que rend la source apres l'envoi.
  Future<void> _payer(ObligationPayable o) async {
    final bool change = await ouvrirConfirmationPayout(
      context,
      <ObligationPayable>[o],
    );
    if (change && mounted) {
      _relire();
      ref.invalidate(obligationsPayablesProvider);
    }
  }

  void _relire() {
    ref
      ..invalidate(obligationPayableProvider(widget.obligationId))
      ..invalidate(journalObligationProvider(widget.obligationId));
  }

  @override
  Widget build(BuildContext context) {
    final p = t.comptable.paiements;
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final AsyncValue<ObligationPayable> valeur = ref.watch(
      obligationPayableProvider(widget.obligationId),
    );
    return PageShell(
      titre: p.detailTitre,
      sousTitre: p.detailSousTitre,
      onRetour: () => retourComptable(context, Routes.comptablePaiements),
      actionsEntete: const <Widget>[BasculeMontants()],
      child: BlocAsynchrone<ObligationPayable>(
        valeur: valeur,
        squelette: const Skeleton.texte(lignes: 8),
        onReessayer: _relire,
        erreurVersEtat: (Object erreur, VoidCallback? _) =>
            _etatErreur(erreur, horsLigne),
        construire: (ObligationPayable o) => _Contenu(
          obligation: o,
          signalement: _signalement,
          horsLigne: horsLigne,
          onPayer: () => _payer(o),
          onSignaler: o.permissions.permet(ActionFinance.signalerEcart)
              ? () => _signaler(o)
              : null,
          onVoirProfil: () =>
              context.push(Routes.comptableBeneficiairePour(o.beneficiaire.id)),
        ),
      ),
    );
  }

  Widget? _etatErreur(Object erreur, bool horsLigne) {
    if (erreur is CapaciteIndisponible) {
      return EmptyState(
        message: t.comptable.commun.enPreparationTitre,
        invitation: t.comptable.commun.enPreparationPhrase,
        registre: RegistreVide.subi,
      );
    }
    if (horsLigne) {
      return EtatSysteme(nature: NatureEtat.horsLigne, onAction: _relire);
    }
    return null;
  }
}

/// Le contenu, une fois l'obligation lue.
class _Contenu extends StatelessWidget {
  const _Contenu({
    required this.obligation,
    required this.signalement,
    required this.horsLigne,
    required this.onPayer,
    required this.onSignaler,
    required this.onVoirProfil,
  });

  final ObligationPayable obligation;
  final SignalementEcart? signalement;
  final bool horsLigne;
  final VoidCallback onPayer;
  final VoidCallback? onSignaler;
  final VoidCallback onVoirProfil;

  @override
  Widget build(BuildContext context) {
    final ObligationPayable o = obligation;
    final bool bureau = AppGabarit.de(context) == Gabarit.desktop;
    final List<Widget> alertes = _alertes(o, onVoirProfil);
    final SignalementEcart? s = signalement;
    final Widget gauche = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _CarteTotal(
          obligation: o,
          action: _ActionPrincipaleDetail(
            obligation: o,
            horsLigne: horsLigne,
            onPayer: onPayer,
            onVoirProfil: onVoirProfil,
          ),
        ),
        Ecart.vLg,
        _CarteLignes(obligation: o, onSignaler: onSignaler),
      ],
    );
    final Widget droite = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _CarteMethode(obligation: o),
        Ecart.vLg,
        _CarteInformations(obligation: o),
        Ecart.vLg,
        _CarteHistorique(obligationId: o.id),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _Identite(obligation: o),
        for (final Widget alerte in alertes) ...<Widget>[Ecart.vLg, alerte],
        if (s != null) ...<Widget>[
          Ecart.vLg,
          BandeauAttention(
            titre: t.comptable.paiements.ecart.titre,
            message: t.comptable.paiements.ecart.envoye(
              date: dateComptable(s.date),
            ),
            ton: TonEtat.accent,
          ),
        ],
        Ecart.vXl,
        if (bureau)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(flex: 3, child: gauche),
              Ecart.hXl,
              Expanded(flex: 2, child: droite),
            ],
          )
        else ...<Widget>[gauche, Ecart.vLg, droite],
      ],
    );
  }
}

/// Les alertes rendues par la source, en phrases (§31 « alertes »).
List<Widget> _alertes(ObligationPayable o, VoidCallback onVoirProfil) {
  final d = t.comptable.paiements.detail;
  final RaisonBlocage? raison = raisonSansPaiement(o);
  final DateTime? modification = o.destination?.derniereModification;
  return <Widget>[
    if (raison == RaisonBlocage.autoPaiement)
      BandeauAttention(
        titre: libelleRaisonBlocage(raison!),
        message: d.autoPaiementPhrase,
        ton: TonEtat.neutre,
      ),
    if (raison == RaisonBlocage.validationRequise && modification != null)
      BandeauAttention(
        titre: libelleRaisonBlocage(RaisonBlocage.validationRequise),
        message: d.alerteMethodeRecente(date: dateComptable(modification)),
      )
    else if (raison == RaisonBlocage.validationRequise &&
        o.beneficiaire.lieALOperateur)
      BandeauAttention(
        titre: libelleRaisonBlocage(RaisonBlocage.validationRequise),
        message: d.alerteLieeOperateur,
      ),
    if (o.etat == EtatPaiementSortant.echoue)
      BandeauAttention(
        titre: libellePaiementSortant(EtatPaiementSortant.echoue),
        message: d.alerteEchec,
        ton: TonEtat.alerte,
      ),
    if (raison == RaisonBlocage.infosManquantes)
      BandeauAttention(
        titre: libelleRaisonBlocage(RaisonBlocage.infosManquantes),
        message: d.alerteInfos,
        action: LienFleche(
          libelle: t.comptable.paiements.actions.voirProfil,
          legende: true,
          onPress: onVoirProfil,
        ),
      ),
    if (raison != null &&
        raison != RaisonBlocage.autoPaiement &&
        raison != RaisonBlocage.validationRequise &&
        raison != RaisonBlocage.infosManquantes)
      BandeauAttention(
        titre: d.alerteTitre,
        message: libelleRaisonBlocage(raison),
      ),
  ];
}

/// L'identite et le statut, en tete.
class _Identite extends StatelessWidget {
  const _Identite({required this.obligation});

  final ObligationPayable obligation;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final ObligationPayable o = obligation;
    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Semantics(
              header: true,
              child: Text(
                o.beneficiaire.nom,
                style: palette.inkStrong.applyTo(
                  textes.headlineSmall ?? const TextStyle(),
                ),
              ),
            ),
            Ecart.vXs,
            Text(
              typeEtPeriode(o),
              style: palette.inkMuted.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
          ],
        ),
        PastillePaiementSortant(o.etat),
      ],
    );
  }
}

/// Le total, en grand, masquable, et l'action principale de la page
/// (CPT-PAY-2) : le montant exact ne s'affiche que dans la confirmation.
class _CarteTotal extends StatelessWidget {
  const _CarteTotal({required this.obligation, required this.action});

  final ObligationPayable obligation;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final d = t.comptable.paiements.detail;
    return AppCard(
      dominante: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            d.total,
            style: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
          Ecart.vSm,
          MontantSensible(obligation.montant, taille: TailleMontant.grand),
          Ecart.vXs,
          Text(
            obligation.periode,
            style: palette.inkMuted.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
          Ecart.vLg,
          action,
        ],
      ),
    );
  }
}

/// L'unique bouton plein de W03, decide par les permissions rendues
/// (DR-19) : « Payer maintenant », « Demander validation » pour un paiement
/// sensible, « Relancer » quand les infos manquent, sinon la raison rendue
/// en phrase (« Traitement par un autre responsable requis », R-FIN-15).
/// Hors ligne, aucun bouton d'envoi : une phrase.
class _ActionPrincipaleDetail extends StatelessWidget {
  const _ActionPrincipaleDetail({
    required this.obligation,
    required this.horsLigne,
    required this.onPayer,
    required this.onVoirProfil,
  });

  final ObligationPayable obligation;
  final bool horsLigne;
  final VoidCallback onPayer;
  final VoidCallback onVoirProfil;

  @override
  Widget build(BuildContext context) {
    final p = t.comptable.paiements;
    final ObligationPayable o = obligation;
    Widget phrase(String texte) => Text(
      texte,
      style: AppPalette.of(context).inkMuted
          .applyTo(Theme.of(context).textTheme.bodyMedium ?? const TextStyle()),
    );
    final ActionLigne action = actionDe(o);
    switch (action) {
      case ActionLigne.payer:
      case ActionLigne.demanderValidation:
        if (horsLigne) return phrase(p.horsLigneCourt);
        return ActionPrincipale(
          key: DetailPaiementPage.clePayer,
          libelle: action == ActionLigne.payer
              ? p.confirmation.payerMaintenant
              : p.actions.demanderValidation,
          onPress: onPayer,
        );
      case ActionLigne.relancer:
        return ActionPrincipale(
          libelle: p.actions.relancer,
          niveau: NiveauAction.secondaire,
          onPress: onVoirProfil,
        );
      case ActionLigne.voir:
        // La raison est deja dite par l'alerte rendue en tete (R-FIN-15).
        return const SizedBox.shrink();
    }
  }
}

/// Les lignes de calcul, chacune avec sa source (§13.3), puis le total et
/// « Signaler un ecart ».
class _CarteLignes extends StatelessWidget {
  const _CarteLignes({required this.obligation, required this.onSignaler});

  final ObligationPayable obligation;
  final VoidCallback? onSignaler;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final d = t.comptable.paiements.detail;
    final VoidCallback? signaler = onSignaler;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SectionHeader(titre: d.lignes),
          Ecart.vSm,
          for (final LigneCalcul ligne in obligation.lignes)
            _LigneDeCalcul(ligne: ligne),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(top: palette.borderHairline.asBorderSide()),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              // A texte agrandi, le total passe sous son libelle (§45).
              child: Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.xs,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  Text(
                    d.ligneTotal,
                    style: palette.inkStrong.applyTo(
                      textes.titleMedium ?? const TextStyle(),
                    ),
                  ),
                  MontantSensible(
                    obligation.montant,
                    taille: TailleMontant.titre,
                  ),
                ],
              ),
            ),
          ),
          if (signaler != null) ...<Widget>[
            Ecart.vLg,
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: ActionPrincipale(
                key: DetailPaiementPage.cleSignaler,
                libelle: t.comptable.paiements.actions.signalerEcart,
                niveau: NiveauAction.secondaire,
                prefixe: Icon(AppIcons.ecartSignale.resoudre()),
                onPress: signaler,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Une ligne de calcul : libelle, source, auteur et validation d'un
/// ajustement (§23), montant masquable au bord de fin.
class _LigneDeCalcul extends StatelessWidget {
  const _LigneDeCalcul({required this.ligne});

  final LigneCalcul ligne;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final d = t.comptable.paiements.detail;
    final TextStyle attenue = palette.inkMuted.applyTo(
      textes.bodySmall ?? const TextStyle(),
    );
    final String? auteur = ligne.auteur;
    final String? validation = ligne.validation;
    final String? route = ligne.route;
    final Widget montant = MontantSensible(
      ligne.montant,
      signe: ligne.montant.mineur < 0,
    );
    // A texte agrandi, le montant passe sous le libelle : jamais un nombre
    // coupe ni une ligne qui deborde a 320 (§45).
    final bool empile = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
    final Widget libelles = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          ligne.libelle,
          style: palette.inkStrong.applyTo(
            textes.bodyLarge ?? const TextStyle(),
          ),
        ),
        Ecart.vXs,
        Text(d.source(source: ligne.source), style: attenue),
        if (auteur != null) ...<Widget>[
          Ecart.vXs,
          Text(d.auteur(auteur: auteur), style: attenue),
        ],
        if (validation != null) ...<Widget>[
          Ecart.vXs,
          Text(validation, style: attenue),
        ],
        if (route != null) ...<Widget>[
          Ecart.vXs,
          LienFleche(
            libelle: d.voirSource,
            legende: true,
            onPress: () => context.push(route),
          ),
        ],
      ],
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: empile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[libelles, Ecart.vXs, montant],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: libelles),
                Ecart.hMd,
                montant,
              ],
            ),
    );
  }
}

/// La methode de paiement masquee et l'encart permanent §31.
class _CarteMethode extends StatelessWidget {
  const _CarteMethode({required this.obligation});

  final ObligationPayable obligation;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final d = t.comptable.paiements.detail;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SectionHeader(titre: d.methode),
          Ecart.vSm,
          LigneDestinationMasquee(destination: obligation.destination),
          Ecart.vLg,
          // L'encart permanent de §31 : toujours rendu, quel que soit
          // l'etat, pour qu'aucune lecture ne laisse croire qu'on peut
          // corriger ici.
          Semantics(
            key: DetailPaiementPage.cleEncart,
            container: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  AppIcons.verrou.resoudre(),
                  size: AppSpacing.lg,
                  color: palette.inkMuted.applyTo(const TextStyle()).color,
                ),
                Ecart.hSm,
                Expanded(
                  child: Text(
                    d.encart,
                    style: palette.inkMuted.applyTo(
                      textes.bodySmall ?? const TextStyle(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Les informations de l'obligation, en lignes cle / valeur.
class _CarteInformations extends StatelessWidget {
  const _CarteInformations({required this.obligation});

  final ObligationPayable obligation;

  @override
  Widget build(BuildContext context) {
    final d = t.comptable.paiements.detail;
    final ObligationPayable o = obligation;
    final String? prestataire = o.prestatairePrevu;
    final String? preuve = o.preuve;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SectionHeader(titre: d.informations),
          Ecart.vSm,
          LigneCleValeur(
            cle: d.type,
            valeur: libelleTypeBeneficiaire(o.beneficiaire.type),
          ),
          LigneCleValeur(cle: d.periode, valeur: o.periode),
          LigneCleValeur(
            cle: d.echeance,
            valeur: dateComptable(o.echeance),
            chiffres: true,
          ),
          LigneCleValeur(
            cle: d.prestataire,
            valeur: prestataire ?? t.comptable.commun.aucuneValeur,
          ),
          if (o.classes.isNotEmpty)
            LigneCleValeur(cle: d.classes, valeur: o.classes.join(', ')),
          LigneCleValeur(
            cle: d.preuve,
            valeur: preuve ?? t.comptable.commun.aucuneValeur,
          ),
          LigneCleValeur(cle: d.version, valeur: o.version, chiffres: true),
        ],
      ),
    );
  }
}

/// L'historique de l'obligation (§48), tel que la source le rend.
class _CarteHistorique extends ConsumerWidget {
  const _CarteHistorique({required this.obligationId});

  final String obligationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = t.comptable.paiements.detail;
    final AsyncValue<List<EntreeJournal>> journal = ref.watch(
      journalObligationProvider(obligationId),
    );
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SectionHeader(titre: d.historique),
          Ecart.vSm,
          BlocAsynchrone<List<EntreeJournal>>(
            valeur: journal,
            squelette: const Skeleton.liste(lignes: 2),
            onReessayer: () =>
                ref.invalidate(journalObligationProvider(obligationId)),
            vide: Text(
              d.historiqueVide,
              style: AppPalette.of(context).inkMuted.applyTo(
                Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
              ),
            ),
            construire: (List<EntreeJournal> entrees) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (final EntreeJournal e in entrees) LigneActivite(e),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
