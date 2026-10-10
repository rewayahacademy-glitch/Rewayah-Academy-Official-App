// « Recevoir mes paiements » (spec §17, §18, §19, §20, §27.1, §38) : la
// surface personnelle de tout beneficiaire avec compte (enseignant,
// Comptable lui-meme, tout role paye), route partagee
// `/compte/paiements-recus` dans la coquille du role connecte
// (`_CoquilleSecondaire`). Constructeur pose par CPT-F ; ecrit par la voie
// CPT-BEN (CPT-BEN-2).
//
// Le beneficiaire **seul** ajoute, remplace, supprime, choisit sa methode
// preferee (R-FIN-13) ; le personnel n'a aucun acces a cette surface pour
// autrui (§17) : elle ne prend aucun identifiant, elle lit « moi » par le
// port. Dans l'ordre : la notice « Informations de paiement a completer »
// quand il manque quelque chose (R-FIN-19), la suspension temporaire pendant
// une verification (§19), l'etat en mots (§38), mes methodes masquees par la
// source, l'historique de mes changements. Un seul bouton plein, en bas :
// « Configurer mes paiements » quand la notice est la, sinon « Ajouter une
// methode de paiement ».
//
// **Aucune coordonnee ne passe par l'app** : l'ajout choisit un type, puis
// la saisie securisee rend un jeton opaque (`SaisieSecurisee`), seul porte
// par le brouillon. Cinq etats : chargement, contenu, (aucun moyen = etat
// metier avec sa notice), erreur, hors ligne ; source absente en production :
// « Pas encore disponible » (CPT-BR-16).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/port_mes_moyens_paiement.dart';
import '../../core/comptable/modeles_comptable.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/bandeau_attention.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/carte_groupee.dart';
import '../../core/widgets/comptable/ligne_activite.dart';
import '../../core/widgets/confirm_destructive.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/ligne_destination_masquee.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/pastilles_comptable.dart';
import '../../core/widgets/pile_cartes.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import '../comptable/beneficiaires/etat_beneficiaires.dart'
    show texteDestination;
import 'etat_mes_moyens.dart';
import 'feuille_ajout_moyen.dart';

/// Mes moyens de paiement, geres par moi seul.
class RecevoirPaiementsPage extends ConsumerStatefulWidget {
  /// Cree la page.
  const RecevoirPaiementsPage({super.key});

  /// La cle du bouton plein.
  static const Key actionKey = ValueKey<String>('recevoir-action');

  /// La cle de la notice §27.1.
  static const Key noticeKey = ValueKey<String>('recevoir-notice');

  /// La cle du retour d'une action.
  static const Key retourKey = ValueKey<String>('recevoir-retour');

  @override
  ConsumerState<RecevoirPaiementsPage> createState() =>
      _RecevoirPaiementsPageEtat();
}

class _RecevoirPaiementsPageEtat extends ConsumerState<RecevoirPaiementsPage> {
  /// L'etat tel que la derniere action l'a rendu : la source le dit, la page
  /// ne le devine jamais.
  EtatMesMoyensPaiement? _apresAction;
  String? _retour;
  bool _retourEchec = false;
  bool _enCours = false;

  String _messageEchec(Object erreur) => erreur is CapaciteIndisponible
      ? t.comptable.beneficiaires.recevoir.erreurIndisponible
      : t.comptable.beneficiaires.recevoir.erreurAction;

  Future<void> _agir(
    Future<EtatMesMoyensPaiement> Function(PortMesMoyensPaiement port) action,
    String succes,
  ) async {
    if (_enCours) return;
    final PortMesMoyensPaiement port = ref.read(portMesMoyensPaiementProvider);
    setState(() => _enCours = true);
    try {
      final EtatMesMoyensPaiement apres = await action(port);
      if (!mounted) return;
      setState(() {
        _apresAction = apres;
        _retour = succes;
        _retourEchec = false;
      });
      // La rubrique de Compte et du Profil relit l'etat a jour.
      ref
        ..invalidate(mesMoyensPaiementProvider)
        ..invalidate(journalMesMoyensProvider);
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

  /// Ajouter (ou, avec [remplace], remplacer) : choisir le type, passer par
  /// la saisie securisee, n'envoyer que son jeton.
  Future<void> _saisir(
    EtatMesMoyensPaiement etat, {
    MoyenPaiementPersonnel? remplace,
  }) async {
    if (_enCours) return;
    final r = t.comptable.beneficiaires.recevoir;
    final String? type = await choisirTypeMoyen(
      context,
      titre: remplace == null
          ? r.ajoutTitre
          : r.remplacementTitre(
              methode: texteDestination(remplace.destination),
            ),
      types: etat.corridorsProposes,
    );
    if (type == null || !mounted) return;
    await _agir((PortMesMoyensPaiement port) async {
      final SaisieSecurisee saisie = await port.ouvrirSaisieSecurisee(type);
      final BrouillonMoyenPaiement brouillon = BrouillonMoyenPaiement(
        type: type,
        operateur: saisie.operateur,
        pays: saisie.pays,
        devise: saisie.devise,
        jetonSaisie: saisie.jeton,
      );
      return remplace == null
          ? port.ajouter(brouillon)
          : port.remplacer(moyenId: remplace.id, brouillon: brouillon);
    }, remplace == null ? r.ajoutee : r.remplacee);
  }

  Future<void> _supprimer(MoyenPaiementPersonnel moyen) async {
    if (_enCours) return;
    final r = t.comptable.beneficiaires.recevoir;
    final String methode = texteDestination(moyen.destination);
    final bool confirme = await ConfirmDestructive.demander(
      context,
      question: r.supprimerQuestion(methode: methode),
      consequence: r.supprimerConsequence,
      libelleConfirmer: r.supprimer(methode: methode),
    );
    if (!confirme || !mounted) return;
    await _agir(
      (PortMesMoyensPaiement port) => port.supprimer(moyen.id),
      r.supprimee,
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = t.comptable.beneficiaires.recevoir;
    final AsyncValue<EtatMesMoyensPaiement> lu = ref.watch(
      mesMoyensPaiementProvider,
    );
    void relire() => ref.invalidate(mesMoyensPaiementProvider);
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final EtatMesMoyensPaiement? local = _apresAction;
    final AsyncValue<EtatMesMoyensPaiement> valeur = local == null
        ? lu
        : AsyncValue<EtatMesMoyensPaiement>.data(local);
    final EtatMesMoyensPaiement? etat = valeur.hasValue ? valeur.value : null;
    return PageShell(
      titre: r.titre,
      sousTitre: r.sousTitre,
      onRetour: () {
        final GoRouter routeur = GoRouter.of(context);
        if (routeur.canPop()) {
          routeur.pop();
        } else {
          routeur.go(Routes.compte);
        }
      },
      // Le bouton plein, en bas, seulement quand l'ajout est accepte.
      actions: etat == null || !etat.peutAjouter
          ? null
          : ActionPrincipale(
              key: RecevoirPaiementsPage.actionKey,
              libelle: infosACompleter(etat) ? r.configurer : r.ajouter,
              enCours: _enCours,
              onPress: () => unawaited(_saisir(etat)),
            ),
      child: BlocAsynchrone<EtatMesMoyensPaiement>(
        valeur: valeur,
        squelette: const Skeleton.liste(lignes: 5),
        onReessayer: relire,
        erreurVersEtat: (Object erreur, VoidCallback? reessayer) =>
            horsLigne && erreur is! CapaciteIndisponible
            ? EtatSysteme(nature: NatureEtat.horsLigne, onAction: reessayer)
            : null,
        construire: (EtatMesMoyensPaiement e) => _Corps(
          etat: e,
          retour: _retour,
          retourEchec: _retourEchec,
          onPreferee: (MoyenPaiementPersonnel m) => unawaited(
            _agir(
              (PortMesMoyensPaiement port) => port.choisirPreferee(m.id),
              r.prefereeChoisie,
            ),
          ),
          onRemplacer: (MoyenPaiementPersonnel m) =>
              unawaited(_saisir(e, remplace: m)),
          onSupprimer: (MoyenPaiementPersonnel m) => unawaited(_supprimer(m)),
        ),
      ),
    );
  }
}

/// Le corps : notice, suspension temporaire, etat, methodes, journal.
class _Corps extends StatelessWidget {
  const _Corps({
    required this.etat,
    required this.retour,
    required this.retourEchec,
    required this.onPreferee,
    required this.onRemplacer,
    required this.onSupprimer,
  });

  final EtatMesMoyensPaiement etat;
  final String? retour;
  final bool retourEchec;
  final ValueChanged<MoyenPaiementPersonnel> onPreferee;
  final ValueChanged<MoyenPaiementPersonnel> onRemplacer;
  final ValueChanged<MoyenPaiementPersonnel> onSupprimer;

  @override
  Widget build(BuildContext context) {
    final r = t.comptable.beneficiaires.recevoir;
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle attenue = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    final String? message = retour;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // L'alerte d'abord (une alerte va toujours en tete).
        if (infosACompleter(etat)) ...<Widget>[
          BandeauAttention(
            key: RecevoirPaiementsPage.noticeKey,
            titre: r.notice,
            message: r.noticeDetail,
          ),
          Ecart.vLg,
        ],
        if (etat.payoutSuspenduTemporairement) ...<Widget>[
          BandeauAttention(
            titre: t.comptable.statuts.profil.enVerification,
            message: r.suspenduTemporairement,
            ton: TonEtat.accent,
          ),
          Ecart.vLg,
        ],
        if (message != null) ...<Widget>[
          Semantics(
            liveRegion: true,
            child: Text(
              message,
              key: RecevoirPaiementsPage.retourKey,
              style: (retourEchec ? palette.inkAlert : palette.inkStrong)
                  .applyTo(textes.bodyMedium ?? const TextStyle()),
            ),
          ),
          Ecart.vLg,
        ],
        AppCard(
          dominante: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              PastilleProfilPaiement(etat.etat),
              Ecart.vMd,
              Text(
                phraseEtatMesMoyens(etat.etat),
                style: palette.inkStrong.applyTo(
                  textes.bodyLarge ?? const TextStyle(),
                ),
              ),
              Ecart.vMd,
              Text(r.seulVous, style: attenue),
            ],
          ),
        ),
        if (etat.moyens.isNotEmpty) ...<Widget>[
          Ecart.vSection,
          SectionHeader(titre: r.mesMethodes),
          PileCartes(
            children: <Widget>[
              for (final MoyenPaiementPersonnel m in etat.moyens)
                _CarteMoyen(
                  moyen: m,
                  onPreferee: () => onPreferee(m),
                  onRemplacer: () => onRemplacer(m),
                  onSupprimer: () => onSupprimer(m),
                ),
            ],
          ),
        ],
        Ecart.vSection,
        SectionHeader(titre: r.journalTitre),
        const _Journal(),
      ],
    );
  }
}

/// Une methode : sa destination masquee, son role (preferee, inactive) et
/// les gestes que seul le beneficiaire a.
class _CarteMoyen extends StatelessWidget {
  const _CarteMoyen({
    required this.moyen,
    required this.onPreferee,
    required this.onRemplacer,
    required this.onSupprimer,
  });

  final MoyenPaiementPersonnel moyen;
  final VoidCallback onPreferee;
  final VoidCallback onRemplacer;
  final VoidCallback onSupprimer;

  @override
  Widget build(BuildContext context) {
    final r = t.comptable.beneficiaires.recevoir;
    final String methode = texteDestination(moyen.destination);
    return AppCard(
      key: ValueKey<String>('recevoir-moyen-${moyen.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (moyen.preferee || !moyen.active) ...<Widget>[
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: StatusPill(
                libelle: moyen.preferee ? r.preferee : r.inactive,
                ton: moyen.preferee ? TonEtat.accent : TonEtat.neutre,
              ),
            ),
            Ecart.vSm,
          ],
          LigneDestinationMasquee(destination: moyen.destination),
          Ecart.vSm,
          if (moyen.active && !moyen.preferee)
            LienFleche(
              key: ValueKey<String>('recevoir-preferee-${moyen.id}'),
              libelle: r.choisirPreferee(methode: methode),
              onPress: onPreferee,
            ),
          if (moyen.active)
            LienFleche(
              key: ValueKey<String>('recevoir-remplacer-${moyen.id}'),
              libelle: r.remplacer(methode: methode),
              onPress: onRemplacer,
            ),
          LienFleche(
            key: ValueKey<String>('recevoir-supprimer-${moyen.id}'),
            libelle: r.supprimer(methode: methode),
            onPress: onSupprimer,
          ),
        ],
      ),
    );
  }
}

/// L'historique de mes changements (§48), lu a part.
class _Journal extends ConsumerWidget {
  const _Journal();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<EntreeJournal>> journal = ref.watch(
      journalMesMoyensProvider,
    );
    return BlocAsynchrone<List<EntreeJournal>>(
      valeur: journal,
      squelette: const Skeleton.liste(lignes: 2),
      onReessayer: () => ref.invalidate(journalMesMoyensProvider),
      vide: AppCard(
        child: Text(
          t.comptable.beneficiaires.recevoir.journalVide,
          style: AppPalette.of(context).inkMuted.applyTo(
            Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
          ),
        ),
      ),
      construire: (List<EntreeJournal> entrees) => CarteGroupee(
        sections: <Widget>[
          for (final EntreeJournal e in entrees) LigneActivite(e),
        ],
      ),
    );
  }
}
