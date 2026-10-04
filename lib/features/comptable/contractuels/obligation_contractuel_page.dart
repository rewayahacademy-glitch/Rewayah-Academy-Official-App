// Detail d'une obligation de contractuel (FIN-CPT-W06 ; spec §22.3, §22.4,
// §23). **Propriete de la voie CPT-CTR** (`20_comptable/02_DECOUPAGE.md`).
//
// « Karim Studio - Facture #024 - 350 USD » → « Payer » : le montant ne se
// modifie nulle part, ni ici ni au paiement ; il est defini a la creation et
// fige a l'approbation. « Payer » navigue vers
// `Routes.comptablePaiementObligationPour(obligationPayableId)` : aucun
// composant de paiement dans ce dossier (DR-12). « Approuver » n'existe que
// si la source le permet ; sinon la raison rendue s'affiche (DR-19). Les
// lignes du montant (source, auteur, validation) se lisent, le Comptable n'en
// invente aucune (§23). Le beneficiaire est externe : invitation et
// « Renvoyer l'invitation », jamais un fil de messages (DR-16).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/capacites/capacite_indisponible.dart';
import '../../../core/capacites/port_obligations_contractuels.dart';
import '../../../core/comptable/modeles_comptable.dart';
import '../../../core/comptable/navigation_comptable.dart';
import '../../../core/comptable/statuts_comptable.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/reseau/service_reseau.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_gabarit.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/action_principale.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/bascule_montants.dart';
import '../../../core/widgets/bloc_asynchrone.dart';
import '../../../core/widgets/carte_groupee.dart';
import '../../../core/widgets/comptable/ligne_activite.dart';
import '../../../core/widgets/etat_systeme.dart';
import '../../../core/widgets/ligne_cle_valeur.dart';
import '../../../core/widgets/montant_argent.dart';
import '../../../core/widgets/montant_sensible.dart';
import '../../../core/widgets/page_shell.dart';
import '../../../core/widgets/pastilles_comptable.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/status_pill.dart';
import 'contractuels_commun.dart';
import 'contractuels_page.dart' show libelleTypeObligation;

/// Le detail d'une obligation de contractuel, sous l'onglet « Contractuels ».
class ObligationContractuelPage extends ConsumerStatefulWidget {
  /// Cree la page pour l'obligation [obligationId] (segment d'adresse).
  const ObligationContractuelPage({required this.obligationId, super.key});

  /// L'obligation.
  final String obligationId;

  @override
  ConsumerState<ObligationContractuelPage> createState() =>
      _ObligationContractuelPageState();
}

class _ObligationContractuelPageState
    extends ConsumerState<ObligationContractuelPage> {
  bool _approbationEnCours = false;
  bool _invitationEnCours = false;
  String? _erreur;
  bool _invitationRenvoyee = false;

  void _relire() {
    ref.invalidate(obligationContractuelProvider(widget.obligationId));
    ref.invalidate(journalObligationContractuelProvider(widget.obligationId));
  }

  /// Approuve : le montant se fige, une obligation payable naitra. Le port
  /// rend l'etat reel ; l'ecran relit, il ne devine rien.
  Future<void> _approuver() async {
    setState(() {
      _approbationEnCours = true;
      _erreur = null;
    });
    try {
      await ref
          .read(portObligationsContractuelsProvider)
          .approuver(widget.obligationId);
      ref.invalidate(obligationsContractuelsProvider);
      _relire();
      if (mounted) setState(() => _approbationEnCours = false);
    } on Object {
      if (mounted) {
        setState(() {
          _approbationEnCours = false;
          _erreur = t.comptable.contractuels.erreurApprobation;
        });
      }
    }
  }

  Future<void> _renvoyerInvitation() async {
    setState(() {
      _invitationEnCours = true;
      _erreur = null;
      _invitationRenvoyee = false;
    });
    try {
      await ref
          .read(portObligationsContractuelsProvider)
          .inviterBeneficiaire(widget.obligationId);
      _relire();
      if (mounted) {
        setState(() {
          _invitationEnCours = false;
          _invitationRenvoyee = true;
        });
      }
    } on Object {
      if (mounted) {
        setState(() {
          _invitationEnCours = false;
          _erreur = t.comptable.contractuels.erreurInvitation;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = t.comptable.contractuels;
    final AsyncValue<ObligationContractuel> lecture = ref.watch(
      obligationContractuelProvider(widget.obligationId),
    );
    final Object? erreur = lecture.hasError ? lecture.error : null;
    final bool echecHorsLigne =
        erreur != null &&
        erreur is! CapaciteIndisponible &&
        (ref.watch(horsLigneProvider).value ?? false);
    final ObligationContractuel? o = lecture.value;
    final _ActionDetail? action = o == null ? null : _actionDe(context, o);

    return PageShell(
      titre: c.detailTitre,
      onRetour: () => retourComptable(context, Routes.comptableContractuels),
      actionsEntete: const <Widget>[BasculeMontants()],
      actions: action == null
          ? null
          : _ZoneAction(
              action: action,
              erreur: _erreur,
              enCours: _approbationEnCours,
            ),
      child: echecHorsLigne
          ? EtatSysteme(nature: NatureEtat.horsLigne, onAction: _relire)
          : BlocAsynchrone<ObligationContractuel>(
              valeur: lecture,
              squelette: const Skeleton.liste(lignes: 6),
              onReessayer: _relire,
              construire: (ObligationContractuel o) => _Corps(
                obligation: o,
                erreur: action == null ? _erreur : null,
                invitationEnCours: _invitationEnCours,
                invitationRenvoyee: _invitationRenvoyee,
                onRenvoyer: _renvoyerInvitation,
              ),
            ),
    );
  }

  /// L'action principale que la source permet sur [o], ou nulle : « Payer »
  /// (W03) pour une obligation approuvee, « Approuver » pour une obligation
  /// qui attend. Jamais deduite d'un role.
  _ActionDetail? _actionDe(BuildContext context, ObligationContractuel o) {
    final c = t.comptable.contractuels;
    final String? payable = o.obligationPayableId;
    if (o.etat == EtatObligationContractuel.approuvee &&
        o.permissions.permet(ActionFinance.payer) &&
        payable != null) {
      return _ActionDetail(
        libelle: c.payer,
        aide: c.payerAide,
        onPress: () =>
            context.push(Routes.comptablePaiementObligationPour(payable)),
      );
    }
    if (o.etat == EtatObligationContractuel.aApprouver &&
        o.permissions.permet(ActionFinance.approuver)) {
      return _ActionDetail(
        libelle: c.approuver,
        aide: c.approuverAide,
        onPress: _approuver,
        enCours: true,
      );
    }
    return null;
  }
}

/// Une action principale : son mot, sa phrase d'aide, son geste.
class _ActionDetail {
  const _ActionDetail({
    required this.libelle,
    required this.aide,
    required this.onPress,
    this.enCours = false,
  });

  final String libelle;
  final String aide;
  final VoidCallback onPress;

  /// Vrai quand le geste est une ecriture qui peut etre en cours.
  final bool enCours;
}

/// La zone collee en bas : l'erreur eventuelle, la phrase d'aide, l'unique
/// bouton plein de l'ecran.
class _ZoneAction extends StatelessWidget {
  const _ZoneAction({
    required this.action,
    required this.erreur,
    required this.enCours,
  });

  final _ActionDetail action;
  final String? erreur;
  final bool enCours;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (erreur != null) ...<Widget>[
          Semantics(
            liveRegion: true,
            child: Text(
              erreur!,
              style: palette.inkAlert.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
          ),
          Ecart.vSm,
        ],
        Text(
          action.aide,
          style: palette.inkMuted.applyTo(
            textes.bodySmall ?? const TextStyle(),
          ),
        ),
        Ecart.vSm,
        ActionPrincipale(
          key: const ValueKey<String>('action-obligation'),
          libelle: action.libelle,
          enCours: action.enCours && enCours,
          onPress: action.onPress,
        ),
      ],
    );
  }
}

/// Le corps : une colonne sur telephone, deux sur bureau.
class _Corps extends ConsumerWidget {
  const _Corps({
    required this.obligation,
    required this.erreur,
    required this.invitationEnCours,
    required this.invitationRenvoyee,
    required this.onRenvoyer,
  });

  final ObligationContractuel obligation;
  final String? erreur;
  final bool invitationEnCours;
  final bool invitationRenvoyee;
  final VoidCallback onRenvoyer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = t.comptable.contractuels;
    final ObligationContractuel o = obligation;
    final Widget gauche = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _Resume(obligation: o),
        if (o.lignes.isNotEmpty) ...<Widget>[
          Ecart.vSection,
          SectionHeader(titre: c.sectionLignes),
          CarteGroupee(
            sections: <Widget>[
              for (final LigneCalcul l in o.lignes) _LigneMontant(ligne: l),
            ],
          ),
        ],
      ],
    );
    final Widget droite = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionHeader(titre: c.sectionInfos),
        _Informations(obligation: o),
        if (o.profilBeneficiaire == EtatProfilPaiement.invitationEnvoyee &&
            o.etat != EtatObligationContractuel.payee &&
            o.etat != EtatObligationContractuel.annulee) ...<Widget>[
          Ecart.vLg,
          _Invitation(
            enCours: invitationEnCours,
            renvoyee: invitationRenvoyee,
            onRenvoyer: onRenvoyer,
          ),
        ],
        Ecart.vSection,
        SectionHeader(titre: c.sectionHistorique),
        _Journal(obligationId: o.id),
      ],
    );
    final RaisonBlocage? raison = _raisonAffichee(o);
    final Widget alerte = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (raison != null) ...<Widget>[
          _Phrase(texte: libelleRaisonBlocage(raison), fort: true),
          Ecart.vLg,
        ],
        if (erreur != null) ...<Widget>[
          Semantics(
            liveRegion: true,
            child: _Phrase(texte: erreur!, alerte: true),
          ),
          Ecart.vLg,
        ],
      ],
    );
    if (AppGabarit.de(context) == Gabarit.desktop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          alerte,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(flex: 3, child: gauche),
              const SizedBox(width: AppSpacing.section),
              Expanded(flex: 2, child: droite),
            ],
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[alerte, gauche, Ecart.vSection, droite],
    );
  }

  /// La raison rendue pour l'action attendue de l'etat courant : « Payer »
  /// d'une obligation approuvee, « Approuver » d'une obligation en attente.
  /// Rien si l'action existe ou si la source ne dit rien (DR-19).
  static RaisonBlocage? _raisonAffichee(ObligationContractuel o) {
    final PermissionsFinance p = o.permissions;
    return switch (o.etat) {
      EtatObligationContractuel.approuvee =>
        p.permet(ActionFinance.payer) ? null : p.raisonDe(ActionFinance.payer),
      EtatObligationContractuel.aApprouver =>
        p.permet(ActionFinance.approuver)
            ? null
            : p.raisonDe(ActionFinance.approuver),
      _ => null,
    };
  }
}

/// Une phrase d'etat sous le titre : la raison d'un blocage, une erreur.
class _Phrase extends StatelessWidget {
  const _Phrase({required this.texte, this.fort = false, this.alerte = false});

  final String texte;
  final bool fort;
  final bool alerte;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle base =
        (fort ? textes.titleSmall : textes.bodyMedium) ?? const TextStyle();
    return Text(
      texte,
      style: (alerte ? palette.inkAlert : palette.inkStrong).applyTo(base),
    );
  }
}

/// Le resume : l'objet, le beneficiaire, l'etat, le type, et le montant avec
/// la phrase qui dit s'il est deja fige.
class _Resume extends StatelessWidget {
  const _Resume({required this.obligation});

  final ObligationContractuel obligation;

  @override
  Widget build(BuildContext context) {
    final c = t.comptable.contractuels;
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final ObligationContractuel o = obligation;
    final bool fige =
        o.etat == EtatObligationContractuel.approuvee ||
        o.etat == EtatObligationContractuel.payee;
    final TextStyle attenue = palette.inkMuted.applyTo(
      textes.bodySmall ?? const TextStyle(),
    );
    return AppCard(
      dominante: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(
              o.objet,
              style: palette.inkStrong.applyTo(
                textes.titleLarge ?? const TextStyle(),
              ),
            ),
          ),
          Ecart.vXs,
          Text(
            o.beneficiaire.nom,
            style: palette.inkMuted.applyTo(
              textes.bodyLarge ?? const TextStyle(),
            ),
          ),
          Ecart.vMd,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              StatusPill(
                libelle: libelleObligationContractuel(o.etat),
                ton: tonObligationContractuel(o.etat),
              ),
              StatusPill(
                libelle: libelleTypeObligation(o.type),
                ton: TonEtat.neutre,
              ),
            ],
          ),
          Ecart.vLg,
          MergeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  c.montantTitre,
                  style: palette.inkMuted.applyTo(
                    textes.bodyMedium ?? const TextStyle(),
                  ),
                ),
                MontantSensible(o.montant, taille: TailleMontant.grand),
                Ecart.vXs,
                Text(fige ? c.montantFige : c.montantDefini, style: attenue),
              ],
            ),
          ),
          if (o.motifRefus != null) ...<Widget>[
            Ecart.vMd,
            Text(
              '${c.champMotifRefus} : ${o.motifRefus}',
              style: palette.inkStrong.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Une ligne du montant : son libelle, sa source, son auteur et sa
/// validation (§13.3, §23), et son montant masque par defaut.
class _LigneMontant extends StatelessWidget {
  const _LigneMontant({required this.ligne});

  final LigneCalcul ligne;

  @override
  Widget build(BuildContext context) {
    final c = t.comptable.contractuels;
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle attenue = palette.inkMuted.applyTo(
      textes.bodySmall ?? const TextStyle(),
    );
    final Widget texte = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          ligne.libelle,
          style: palette.inkStrong.applyTo(
            textes.bodyLarge ?? const TextStyle(),
          ),
        ),
        Ecart.vXs,
        Text(c.ligneSource(source: ligne.source), style: attenue),
        if (ligne.auteur != null)
          Text(c.ligneAuteur(auteur: ligne.auteur!), style: attenue),
        if (ligne.validation != null)
          Text(
            c.ligneValidation(validation: ligne.validation!),
            style: attenue,
          ),
        if (ligne.date != null)
          Text(dateComptable(ligne.date!), style: attenue),
      ],
    );
    final bool empiler =
        MediaQuery.textScalerOf(context).scale(AppSpacing.lg) / AppSpacing.lg >=
        AppGabarit.seuilTexteColonne;
    return MergeSemantics(
      child: empiler
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                texte,
                Ecart.vSm,
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: MontantSensible(ligne.montant, signe: true),
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: texte),
                Ecart.hMd,
                MontantSensible(ligne.montant, signe: true),
              ],
            ),
    );
  }
}

/// Les champs de §22.3 : beneficiaire, type, echeance, centre de cout,
/// justificatif, auteur, approbateur, etat du paiement du beneficiaire.
class _Informations extends StatelessWidget {
  const _Informations({required this.obligation});

  final ObligationContractuel obligation;

  @override
  Widget build(BuildContext context) {
    final c = t.comptable.contractuels;
    final ObligationContractuel o = obligation;
    return CarteGroupee(
      sections: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            LigneCleValeur(
              cle: c.champBeneficiaire,
              valeur: o.beneficiaire.nom,
            ),
            LigneCleValeur(
              cle: c.champType,
              valeur: libelleTypeObligation(o.type),
            ),
            LigneCleValeur(
              cle: c.champEcheance,
              valeur: dateComptable(o.echeance),
              chiffres: true,
            ),
            LigneCleValeur(
              cle: c.champCentreCout,
              valeur: o.centreCout ?? c.nonRenseigne,
            ),
            LigneCleValeur(
              cle: c.champJustificatif,
              valeur: o.justificatif ?? c.aucunJustificatif,
            ),
            LigneCleValeur(cle: c.champAuteur, valeur: o.auteur),
            if (o.approbateur != null)
              LigneCleValeur(cle: c.champApprobateur, valeur: o.approbateur!),
            if (o.profilBeneficiaire != null)
              LigneCleValeur(
                cle: c.champProfilPaiement,
                valeur: libelleProfilPaiement(o.profilBeneficiaire!),
              ),
          ],
        ),
      ],
    );
  }
}

/// Le beneficiaire externe sans compte : l'invitation est partie, il saisit
/// lui-meme sa methode ; le Comptable peut la renvoyer (§18, DR-16).
class _Invitation extends StatelessWidget {
  const _Invitation({
    required this.enCours,
    required this.renvoyee,
    required this.onRenvoyer,
  });

  final bool enCours;
  final bool renvoyee;
  final VoidCallback onRenvoyer;

  @override
  Widget build(BuildContext context) {
    final c = t.comptable.contractuels;
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            c.invitationAide,
            style: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
          Ecart.vMd,
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ActionPrincipale(
              key: const ValueKey<String>('renvoyer-invitation'),
              libelle: c.renvoyerInvitation,
              niveau: NiveauAction.secondaire,
              pleineLargeur: false,
              enCours: enCours,
              onPress: onRenvoyer,
            ),
          ),
          if (renvoyee) ...<Widget>[
            Ecart.vSm,
            Semantics(
              liveRegion: true,
              child: Text(
                c.invitationRenvoyee,
                style: palette.inkStrong.applyTo(
                  textes.bodyMedium ?? const TextStyle(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Le journal de l'obligation (CPT-BR-17) : ce que la source rend, rien
/// d'invente.
class _Journal extends ConsumerWidget {
  const _Journal({required this.obligationId});

  final String obligationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = t.comptable.contractuels;
    final AsyncValue<List<EntreeJournal>> lecture = ref.watch(
      journalObligationContractuelProvider(obligationId),
    );
    return BlocAsynchrone<List<EntreeJournal>>(
      valeur: lecture,
      squelette: const Skeleton.texte(lignes: 3),
      onReessayer: () =>
          ref.invalidate(journalObligationContractuelProvider(obligationId)),
      estVide: (List<EntreeJournal> l) => l.isEmpty,
      vide: _Phrase(texte: c.historiqueVide),
      construire: (List<EntreeJournal> l) => CarteGroupee(
        sections: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (final EntreeJournal e in l) LigneActivite(e),
            ],
          ),
        ],
      ),
    );
  }
}
