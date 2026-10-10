// Etat du profil de paiement d'un beneficiaire (FIN-CPT-W07 ; spec §16, §19,
// §27.2-27.3, §35). Constructeur pose par CPT-F ; ecrit par la voie CPT-BEN
// (CPT-BEN-1).
//
// Composee d'apres W03 (aucune planche, UX_REVIEW §5.7) : a gauche la carte
// du profil (`CarteProfilPaiement` : methode masquee, statut, pays, devise,
// derniere modification, verification, capacite de paiement) puis les
// actions ; a droite l'historique des paiements et le journal du profil. Sur
// telephone, une seule colonne dans le meme ordre.
//
// Actions, chacune selon la permission rendue par la source (jamais selon le
// role) : « Relancer » (le seul bouton plein, en bas de sa carte), qui ouvre
// le fil metier « Profil de paiement » de Communications V1 (CPT-COM :
// `PortMessagesMetier.filPourObjet(TypeObjetLie.profilPaiement, id)`), le
// message modele §27.3 prerempli comme brouillon du fil, **aucune messagerie
// Finance** (R-FIN-21) ; « Demander une mise a jour » ; « Suspendre les
// paiements » (motif choisi, feuille) ou « Reprendre ». Un externe sans
// compte n'a pas de fil : l'invitation se renvoie depuis son obligation
// (DR-16, CPT-BR-08). **Aucun « Modifier coordonnees »** (R-FIN-11, 12).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/capacites/capacite_indisponible.dart';
import '../../../core/capacites/port_beneficiaires_paiement.dart';
import '../../../core/communications/port_brouillons.dart';
import '../../../core/comptable/modeles_comptable.dart';
import '../../../core/comptable/navigation_comptable.dart';
import '../../../core/comptable/statuts_comptable.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/reseau/service_reseau.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_gabarit.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/action_principale.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/bascule_montants.dart';
import '../../../core/widgets/bloc_asynchrone.dart';
import '../../../core/widgets/carte_groupee.dart';
import '../../../core/widgets/comptable/ligne_activite.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/etat_systeme.dart';
import '../../../core/widgets/lien_fleche.dart';
import '../../../core/widgets/montant_sensible.dart';
import '../../../core/widgets/page_shell.dart';
import '../../../core/widgets/pastilles_comptable.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/skeleton.dart';
import '../../com_messages/fil_contextuel.dart' show cleBrouillonFil;
import '../../com_messages/port_messages_metier.dart';
import 'carte_profil_paiement.dart';
import 'etat_beneficiaires.dart';
import 'feuille_suspension.dart';
import 'fil_profil_paiement_page.dart';

/// Le profil de paiement d'un beneficiaire, sous l'onglet « Beneficiaires ».
class ProfilPaiementPage extends ConsumerStatefulWidget {
  /// Cree la page pour le beneficiaire [beneficiaireId] (segment d'adresse).
  const ProfilPaiementPage({required this.beneficiaireId, super.key});

  /// Le beneficiaire.
  final String beneficiaireId;

  /// La cle du bouton « Relancer ».
  static const Key relancerKey = ValueKey<String>('cpt-ben-relancer');

  /// La cle du lien « Demander une mise a jour ».
  static const Key miseAJourKey = ValueKey<String>('cpt-ben-mise-a-jour');

  /// La cle du lien « Suspendre les paiements ».
  static const Key suspendreKey = ValueKey<String>('cpt-ben-suspendre');

  /// La cle du lien « Reprendre les paiements ».
  static const Key reprendreKey = ValueKey<String>('cpt-ben-reprendre');

  /// La cle du retour d'une action.
  static const Key retourKey = ValueKey<String>('cpt-ben-retour');

  @override
  ConsumerState<ProfilPaiementPage> createState() => _ProfilPaiementPageEtat();
}

class _ProfilPaiementPageEtat extends ConsumerState<ProfilPaiementPage> {
  /// Le profil tel que la derniere action l'a rendu (le port rend l'etat
  /// apres l'action ; la page ne le devine jamais).
  ProfilPaiementBeneficiaire? _apresAction;
  String? _retour;
  bool _retourEchec = false;
  bool _enCours = false;

  @override
  void didUpdateWidget(ProfilPaiementPage ancien) {
    super.didUpdateWidget(ancien);
    if (ancien.beneficiaireId != widget.beneficiaireId) {
      _apresAction = null;
      _retour = null;
    }
  }

  String _messageEchec(Object erreur) => erreur is CapaciteIndisponible
      ? t.comptable.beneficiaires.profil.erreurIndisponible
      : t.comptable.beneficiaires.profil.erreurAction;

  Future<void> _agir(
    Future<ProfilPaiementBeneficiaire> Function(PortBeneficiairesPaiement port)
    action,
    String Function(String nom) succes,
  ) async {
    if (_enCours) return;
    final PortBeneficiairesPaiement port = ref.read(
      portBeneficiairesPaiementProvider,
    );
    setState(() => _enCours = true);
    try {
      final ProfilPaiementBeneficiaire apres = await action(port);
      if (!mounted) return;
      setState(() {
        _apresAction = apres;
        _retour = succes(apres.identite.nom);
        _retourEchec = false;
      });
      ref.invalidate(beneficiairesProvider);
    } on Object catch (erreur) {
      if (!mounted) return;
      setState(() {
        _retour = _messageEchec(erreur);
        _retourEchec = true;
      });
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  /// « Relancer » (CPT-BR-11) : le fil metier « Profil de paiement » du
  /// beneficiaire, lu ou cree par le serveur, s'ouvre avec le message modele
  /// §27.3 prerempli (brouillon du fil : rien ne part sans « Envoyer »). Un
  /// brouillon deja en cours n'est jamais ecrase. Fil refuse, source absente
  /// ou en echec : la phrase le dit, sous le bouton, et rien ne s'ouvre.
  Future<void> _relancer(String nom) async {
    if (_enCours) return;
    final PortMessagesMetier port = ref.read(portMessagesMetierProvider);
    final PortBrouillons brouillons = ref.read(portBrouillonsProvider);
    final String chemin = ref.read(cheminFilProfilPaiementProvider)(
      widget.beneficiaireId,
    );
    setState(() {
      _enCours = true;
      _retour = null;
    });
    try {
      final FilMetier? fil = await lireFilProfilPaiement(
        port,
        widget.beneficiaireId,
      );
      if (!mounted) return;
      if (fil == null) {
        setState(() {
          _retour = t.comptable.beneficiaires.profil.relanceRefusee(nom: nom);
          _retourEchec = true;
        });
        return;
      }
      final CleBrouillon cle = cleBrouillonFil(fil.id);
      if (await brouillons.lire(cle) == null) {
        await brouillons.enregistrer(
          cle,
          t.comptable.beneficiaires.profil.messageModele,
        );
      }
      if (!mounted) return;
      unawaited(GoRouter.of(context).push<void>(chemin));
    } on Object catch (erreur) {
      if (!mounted) return;
      setState(() {
        _retour = _messageEchec(erreur);
        _retourEchec = true;
      });
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  Future<void> _suspendre(String nom) async {
    if (_enCours) return;
    final String? motif = await demanderMotifSuspension(context, nom: nom);
    if (motif == null || !mounted) return;
    await _agir(
      (PortBeneficiairesPaiement port) =>
          port.suspendre(beneficiaireId: widget.beneficiaireId, motif: motif),
      (String n) => t.comptable.beneficiaires.profil.suspendus(nom: n),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<ProfilPaiementBeneficiaire> lu = ref.watch(
      profilBeneficiaireProvider(widget.beneficiaireId),
    );
    void relire() =>
        ref.invalidate(profilBeneficiaireProvider(widget.beneficiaireId));
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final ProfilPaiementBeneficiaire? local = _apresAction;
    return PageShell(
      titre: t.comptable.beneficiaires.profilTitre,
      onRetour: () => retourComptable(context, Routes.comptableBeneficiaires),
      actionsEntete: const <Widget>[BasculeMontants(avecEtat: true)],
      child: BlocAsynchrone<ProfilPaiementBeneficiaire>(
        valeur: local == null
            ? lu
            : AsyncValue<ProfilPaiementBeneficiaire>.data(local),
        squelette: const Skeleton.liste(lignes: 6),
        onReessayer: relire,
        erreurVersEtat: (Object erreur, VoidCallback? reessayer) {
          // Source absente : l'ecran reste « en preparation ».
          if (erreur is CapaciteIndisponible) {
            return EmptyState(
              message: t.comptable.commun.enPreparationTitre,
              invitation: t.comptable.commun.enPreparationPhrase,
            );
          }
          if (horsLigne) {
            return EtatSysteme(
              nature: NatureEtat.horsLigne,
              onAction: reessayer,
            );
          }
          return null;
        },
        construire: (ProfilPaiementBeneficiaire profil) => _Corps(
          profil: profil,
          actions: _Actions(
            profil: profil,
            retour: _retour,
            retourEchec: _retourEchec,
            enCours: _enCours,
            onRelancer: () => unawaited(_relancer(profil.identite.nom)),
            onMiseAJour: () => unawaited(
              _agir(
                (PortBeneficiairesPaiement port) =>
                    port.demanderMiseAJour(widget.beneficiaireId),
                (String n) =>
                    t.comptable.beneficiaires.profil.miseAJourDemandee(nom: n),
              ),
            ),
            onSuspendre: () => unawaited(_suspendre(profil.identite.nom)),
            onReprendre: () => unawaited(
              _agir(
                (PortBeneficiairesPaiement port) =>
                    port.reprendre(widget.beneficiaireId),
                (String n) => t.comptable.beneficiaires.profil.repris(nom: n),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Deux colonnes sur bureau (carte et actions | historique et journal),
/// une seule ailleurs.
class _Corps extends StatelessWidget {
  const _Corps({required this.profil, required this.actions});

  final ProfilPaiementBeneficiaire profil;
  final Widget actions;

  @override
  Widget build(BuildContext context) {
    final p = t.comptable.beneficiaires.profil;
    final Widget principal = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        CarteProfilPaiement(profil: profil),
        Ecart.vSection,
        SectionHeader(titre: p.actionsTitre),
        actions,
      ],
    );
    final Widget annexe = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SectionHeader(titre: p.historiqueTitre),
        _Historique(paiements: profil.historique),
        Ecart.vSection,
        SectionHeader(titre: p.journalTitre),
        _Journal(beneficiaireId: profil.identite.id),
      ],
    );
    // [RESPONSIVE] Le gabarit decide, jamais une largeur comparee a un nombre.
    if (AppGabarit.de(context) == Gabarit.desktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(flex: 3, child: principal),
          const SizedBox(width: AppSpacing.section),
          Expanded(flex: 2, child: annexe),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[principal, Ecart.vSection, annexe],
    );
  }
}

/// La carte des actions : ce qui est ouvert sur ce profil, le retour de la
/// derniere action, et le bouton plein en bas.
class _Actions extends StatelessWidget {
  const _Actions({
    required this.profil,
    required this.retour,
    required this.retourEchec,
    required this.enCours,
    required this.onRelancer,
    required this.onMiseAJour,
    required this.onSuspendre,
    required this.onReprendre,
  });

  final ProfilPaiementBeneficiaire profil;
  final String? retour;
  final bool retourEchec;
  final bool enCours;
  final VoidCallback onRelancer;
  final VoidCallback onMiseAJour;
  final VoidCallback onSuspendre;
  final VoidCallback onReprendre;

  @override
  Widget build(BuildContext context) {
    final p = t.comptable.beneficiaires.profil;
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle corps = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    final String nom = profil.identite.nom;
    final PermissionsFinance permissions = profil.permissions;
    // Un externe sans compte n'a pas de fil Messages (DR-16, CPT-BR-11).
    final bool externe = profil.etat == EtatProfilPaiement.invitationEnvoyee;
    final bool relancer =
        !externe && permissions.permet(ActionFinance.relancer);
    final bool miseAJour =
        !externe && permissions.permet(ActionFinance.demanderMiseAJour);
    final bool suspendu = profil.etat == EtatProfilPaiement.suspendu;
    // La capacite de suspendre porte aussi la reprise : le contrat n'a pas
    // d'action « reprendre » distincte (CPT-BR-06, `ActionFinance`).
    final bool suspendre =
        !externe && permissions.permet(ActionFinance.suspendre);
    final String? message = retour;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (externe) ...<Widget>[
            Text(p.externe(nom: nom), style: corps),
            Ecart.vSm,
            LienFleche(
              libelle: p.voirContractuels,
              onPress: () => context.go(Routes.comptableContractuels),
            ),
          ] else if (!relancer && !miseAJour && !suspendre)
            Text(p.aucuneAction, style: corps),
          if (message != null) ...<Widget>[
            Semantics(
              liveRegion: true,
              child: Text(
                message,
                key: ProfilPaiementPage.retourKey,
                style: (retourEchec ? palette.inkAlert : palette.inkStrong)
                    .applyTo(textes.bodyMedium ?? const TextStyle()),
              ),
            ),
            Ecart.vMd,
          ],
          if (miseAJour)
            LienFleche(
              key: ProfilPaiementPage.miseAJourKey,
              libelle: p.demanderMiseAJour(nom: nom),
              onPress: onMiseAJour,
            ),
          if (suspendre)
            suspendu
                ? LienFleche(
                    key: ProfilPaiementPage.reprendreKey,
                    libelle: p.reprendre(nom: nom),
                    onPress: onReprendre,
                  )
                : LienFleche(
                    key: ProfilPaiementPage.suspendreKey,
                    libelle: p.suspendre(nom: nom),
                    onPress: onSuspendre,
                  ),
          if (relancer) ...<Widget>[
            Ecart.vMd,
            Text(p.relancerDetail, style: corps),
            Ecart.vMd,
            ActionPrincipale(
              key: ProfilPaiementPage.relancerKey,
              libelle: p.relancer(nom: nom),
              enCours: enCours,
              onPress: onRelancer,
            ),
          ],
        ],
      ),
    );
  }
}

/// L'historique des paiements, dans une seule carte a filets (K-55).
class _Historique extends StatelessWidget {
  const _Historique({required this.paiements});

  final List<PaiementPasse> paiements;

  @override
  Widget build(BuildContext context) {
    if (paiements.isEmpty) {
      return AppCard(
        child: Text(
          t.comptable.beneficiaires.profil.historiqueVide,
          style: AppPalette.of(context).inkMuted.applyTo(
            Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
          ),
        ),
      );
    }
    return CarteGroupee(
      sections: <Widget>[
        for (final PaiementPasse paiement in paiements)
          _LignePaiement(paiement: paiement),
      ],
    );
  }
}

/// Un paiement passe : la periode, « date · reference », le montant
/// **masquable** et son etat en mots.
class _LignePaiement extends StatelessWidget {
  const _LignePaiement({required this.paiement});

  final PaiementPasse paiement;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final String? reference = paiement.reference;
    final String detail = reference == null
        ? dateComptable(paiement.date)
        : '${dateComptable(paiement.date)} · '
              '${t.comptable.commun.activiteReference(reference: reference)}';
    // Texte agrandi : la ligne s'empile, comme `LigneCleValeur`
    // (`AppGabarit.seuilTexteColonne`) ; a 200 %, deux colonnes coupent.
    final bool empiler =
        MediaQuery.textScalerOf(context).scale(AppSpacing.lg) / AppSpacing.lg >=
        AppGabarit.seuilTexteColonne;
    final Widget gauche = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          paiement.periode,
          style: palette.inkStrong.applyTo(
            textes.bodyLarge ?? const TextStyle(),
          ),
        ),
        Text(
          detail,
          style: palette.inkMuted.applyTo(
            AppTypography.tabulaire(textes.bodySmall ?? const TextStyle()),
          ),
        ),
      ],
    );
    final Widget droite = Column(
      crossAxisAlignment: empiler
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        MontantSensible(paiement.montant),
        Ecart.vXs,
        PastillePaiementSortant(paiement.etat),
      ],
    );
    final Key cle = ValueKey<String>(
      'cpt-ben-paiement-${paiement.obligationId}',
    );
    return MergeSemantics(
      child: empiler
          ? Column(
              key: cle,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[gauche, Ecart.vXs, droite],
            )
          : Row(
              key: cle,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: gauche),
                Ecart.hMd,
                droite,
              ],
            ),
    );
  }
}

/// Le journal du profil (§48), lu a part : son absence ne cache pas le
/// profil.
class _Journal extends ConsumerWidget {
  const _Journal({required this.beneficiaireId});

  final String beneficiaireId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<EntreeJournal>> journal = ref.watch(
      journalBeneficiaireProvider(beneficiaireId),
    );
    final Widget vide = AppCard(
      child: Text(
        t.comptable.beneficiaires.profil.journalVide,
        style: AppPalette.of(context).inkMuted.applyTo(
          Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
        ),
      ),
    );
    return BlocAsynchrone<List<EntreeJournal>>(
      valeur: journal,
      squelette: const Skeleton.liste(lignes: 2),
      onReessayer: () =>
          ref.invalidate(journalBeneficiaireProvider(beneficiaireId)),
      vide: vide,
      construire: (List<EntreeJournal> entrees) => CarteGroupee(
        sections: <Widget>[
          for (final EntreeJournal e in entrees) LigneActivite(e),
        ],
      ),
    );
  }
}
