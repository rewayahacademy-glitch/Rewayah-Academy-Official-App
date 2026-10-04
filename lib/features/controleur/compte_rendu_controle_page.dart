// Compte rendu (CTR-03, CT-4) : la sortie de la salle d'observation
// (P-CTR-03 point 12, P-CTR-04).
//
// Decisions du directeur du 27/09/2026 (C2) et UX_REVIEW_08 n° 5, 6 et 9 :
// - la visite et ses faits sont deja transmis a l'administration ; l'ecran ne
//   propose aucun interrupteur de partage, il le dit en une ligne ;
// - les faits automatiques sont en lecture seule, replies par defaut (C4) ;
// - trois cartes sans preselection ; choisir une carte n'envoie rien : le
//   bouton apparait 16 sous le groupe, au bord de fin ;
// - « Rien a signaler » part en une action, sans fenetre de confirmation ni
//   « Annuler » qui s'efface seul : on corrige par « Ajouter un complement »
//   (C10), ce que dit l'ecran de resultat ;
// - aucun succes sans reponse : sans serveur, l'envoi echoue et l'ecran le
//   dit (K-28) ;
// - « Plus tard » ramene au Controle, ou le compte rendu reste « a terminer ».

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/mouvement/apparition_douce.dart';
import '../../core/mouvement/mouvement.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_delais.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/choice_card_group.dart';
import '../../core/widgets/ecran_resultat.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/ligne_cle_valeur.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/status_pill.dart' show TonEtat;
import '../accueil_famille/bloc_seance.dart' show heureDeLAppareil;
import 'compte_rendu_controle.dart';

enum _Etape { choix, envoye }

/// Le compte rendu du controleur : faits, question, trois cartes, envoi.
class CompteRenduControlePage extends ConsumerStatefulWidget {
  /// Cree la page.
  const CompteRenduControlePage({
    super.key,
    this.seanceId,
    this.onRevenir,
    this.onObservation,
    this.onEcrireAdmin,
  });

  /// La visite qui sort de la salle (`?seance=`, revue CT-R B1) : le compte
  /// rendu, sa transmission et son envoi portent sur ELLE, jamais sur la
  /// mission courante. Inconnue : le message generique (C7).
  final String? seanceId;

  /// Le retour au controle ; par defaut, la destination Controle.
  final VoidCallback? onRevenir;

  /// L'entree du parcours d'observation (CTR-03A) pour la visite
  /// [seanceId] ; par defaut, sa route.
  final void Function(ChoixCompteRendu choix, String seanceId)? onObservation;

  /// La discussion avec l'administration (CTR-04) sur la mission de la
  /// visite (nulle si inconnue) ; par defaut, son fil dans Echanges.
  final void Function(String? missionId)? onEcrireAdmin;

  /// La cle de la carte d'un choix.
  static Key cleChoix(ChoixCompteRendu choix) =>
      ValueKey<String>('ctr03-choix-${choix.name}');

  /// La cle du bouton qui envoie ou continue.
  static const Key actionKey = ValueKey<String>('ctr03-action');

  /// La cle de « Plus tard ».
  static const Key plusTardKey = ValueKey<String>('ctr03-plus-tard');

  /// La largeur utile de la colonne.
  static const double largeurMax = 640;

  @override
  ConsumerState<CompteRenduControlePage> createState() =>
      _CompteRenduControlePageState();
}

class _CompteRenduControlePageState
    extends ConsumerState<CompteRenduControlePage> {
  ChoixCompteRendu? _choix;
  _Etape _etape = _Etape.choix;
  bool _enCours = false;
  bool _echec = false;

  /// La visite, retrouvee par sa seance ; nulle si inconnue.
  CompteRenduEnSuspens? _visite;

  @override
  void initState() {
    super.initState();
    // Tant que la reponse n'est pas envoyee, le compte rendu est « a
    // terminer » (doc 08 CTR-01) ; en memoire seulement (C12).
    // La visite et ses faits partent aussitot a l'administration (C2), sans
    // attendre la reponse du controleur : « Plus tard » ne la retient pas.
    // La visite vient de sa seance, jamais de `missionControleProvider` :
    // apres la seance, la mission courante est vide ou deja la suivante
    // (revue CT-R B1).
    final CompteRenduEnSuspens? v = visiteDeSeance(ref, widget.seanceId);
    _visite = v;
    if (v == null) return;
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (!mounted || _etape == _Etape.envoye) return;
      ref.read(compteRenduATerminerProvider.notifier).ouvrir(v);
      unawaited(transmettreVisiteATerminer(ref, v.seanceId));
    });
  }

  void _revenir() => widget.onRevenir == null
      ? GoRouter.of(context).go(Routes.controleur)
      : widget.onRevenir!();

  Future<void> _agir() async {
    final ChoixCompteRendu? choix = _choix;
    final CompteRenduEnSuspens? visite = _visite;
    if (choix == null || visite == null || _enCours) return;
    if (choix != ChoixCompteRendu.rienASignaler) {
      final void Function(ChoixCompteRendu, String)? f = widget.onObservation;
      final String seance = visite.seanceId;
      if (f == null) {
        GoRouter.of(context).go(
          adresseObservation(
            Routes.controleurObservation,
            choix,
            seanceId: seance,
          ),
        );
      } else {
        f(choix, seance);
      }
      return;
    }
    setState(() {
      _enCours = true;
      _echec = false;
    });
    try {
      // Un serveur muet ne bloque pas l'ecran (CTRL-DELAI-1, K-59) : passe
      // le delai maximal, l'envoi est « non confirme », Reessayer et
      // « Plus tard » redeviennent disponibles.
      await ref
          .read(envoiCompteRenduProvider)
          .envoyer(visite.seanceId, choix)
          .timeout(AppDelais.requeteMax);
      if (!mounted) return;
      ref.read(compteRenduATerminerProvider.notifier).terminer(visite.seanceId);
      setState(() {
        _enCours = false;
        _etape = _Etape.envoye;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _enCours = false;
        _echec = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final CompteRenduEnSuspens? visite = _visite;
    if (visite == null) {
      // Seance inconnue (rechargement, lien direct) : la visite n'est plus en
      // memoire, jamais une autre mission (C7, revue CT-R B1). Ni annulation
      // ni changement de controleur : la vraie cause (CTRL-MSG-1, K-59).
      return PageShell(
        titre: t.controleur.compteRendu.titre,
        child: EmptyState(
          message: t.controleur.compteRendu.visiteInconnue,
          invitation: t.controleur.compteRendu.visiteInconnueAide,
          registre: RegistreVide.subi,
          libelleAction: t.controleur.compteRendu.revenir,
          onAction: _revenir,
        ),
      );
    }
    final String sousTitre = t.controleur.compteRendu.sousTitre(
      classe: visite.classe,
      heure: heureDeLAppareil(visite.debut),
    );

    // Une mission devenue indisponible (seance finie) ne bloque pas le
    // compte rendu : il se termine apres la sortie (C1), sur la visite
    // copiee a l'entree en salle. L'acces retire, lui, est garde par
    // GardeControle (C7).

    if (_etape == _Etape.envoye) {
      return PageShell(
        titre: t.controleur.compteRendu.titre,
        sousTitre: sousTitre,
        child: ApparitionDouce(
          child: EcranResultat(
            icone: AppIcons.succes,
            ton: TonEtat.succes,
            titre: t.controleur.compteRendu.envoyeTitre,
            phrase: t.controleur.compteRendu.envoyePhrase,
            libelleAction: t.controleur.compteRendu.revenir,
            onAction: _revenir,
            libelleSecondaire: t.controleur.compteRendu.ecrireAdmin,
            // Le fil de la mission de CETTE visite (P-CTR-06), la liste si
            // son identifiant n'est pas connu ; jamais la mission courante.
            onSecondaire: () => widget.onEcrireAdmin == null
                ? GoRouter.of(context)
                      .go(Routes.controleurEcrireAdmin(visite.missionId))
                : widget.onEcrireAdmin!(visite.missionId),
          ),
        ),
      );
    }

    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle doux = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    final ChoixCompteRendu? choix = _choix;
    final bool envoi = choix == ChoixCompteRendu.rienASignaler;
    final bool compact = AppGabarit.de(context) == Gabarit.mobile;

    return PageShell(
      titre: t.controleur.compteRendu.titre,
      sousTitre: sousTitre,
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: CompteRenduControlePage.largeurMax,
          ),
          child: ApparitionDouce(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _FaitsAutomatiques(seanceId: visite.seanceId),
                Ecart.vMd,
                LigneTransmissionVisite(seanceId: visite.seanceId),
                Ecart.vXxl,
                Semantics(
                  header: true,
                  child: Text(
                    t.controleur.compteRendu.question,
                    style: palette.inkStrong.applyTo(
                      textes.titleLarge ?? const TextStyle(),
                    ),
                  ),
                ),
                Ecart.vSm,
                // Phrase de contexte et lignes « quand · consequence » sous
                // chaque option (K-58) : libelles provisoires (D4), proposes
                // par un agent, a valider par le directeur.
                Text(t.controleur.compteRendu.contexte, style: doux),
                Ecart.vLg,
                ChoiceCardGroup(
                  autoriserSaisieLibre: false,
                  options: <OptionChoix>[
                    for (final ChoixCompteRendu c in ChoixCompteRendu.values)
                      OptionChoix(
                        cle: CompteRenduControlePage.cleChoix(c),
                        valeur: c.name,
                        libelle: switch (c) {
                          ChoixCompteRendu.rienASignaler =>
                            t.controleur.compteRendu.rienASignaler,
                          ChoixCompteRendu.ajouterObservation =>
                            t.controleur.compteRendu.ajouterObservation,
                          ChoixCompteRendu.pointImportant =>
                            t.controleur.compteRendu.pointImportant,
                        },
                        description: switch (c) {
                          ChoixCompteRendu.rienASignaler =>
                            t.controleur.compteRendu.rienASignalerAide,
                          ChoixCompteRendu.ajouterObservation =>
                            t.controleur.compteRendu.ajouterObservationAide,
                          ChoixCompteRendu.pointImportant =>
                            t.controleur.compteRendu.pointImportantAide,
                        },
                        icone: switch (c) {
                          ChoixCompteRendu.rienASignaler => AppIcons.succes,
                          ChoixCompteRendu.ajouterObservation => AppIcons.noter,
                          ChoixCompteRendu.pointImportant => AppIcons.signaler,
                        },
                      ),
                  ],
                  onChange: (ReponseChoix r) => setState(() {
                    _echec = false;
                    _choix = r.valeurs.isEmpty
                        ? null
                        : ChoixCompteRendu.values.byName(r.valeurs.first);
                  }),
                ),
                Ecart.vLg,
                if (envoi) ...<Widget>[
                  // La notice informe AVANT l'action (UX_REVIEW_08 n° 8 d) :
                  // une ligne de texte, jamais une case ni un interrupteur.
                  ApparitionDouce(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        IconTheme(
                          data: palette.inkMuted.asIconTheme(size: 18),
                          child: Icon(AppIcons.info.resoudre()),
                        ),
                        Ecart.hSm,
                        Expanded(
                          child: Text(
                            t.controleur.compteRendu.notice,
                            style: doux,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Ecart.vLg,
                ],
                _Actions(
                  plusTard: ActionPrincipale(
                    key: CompteRenduControlePage.plusTardKey,
                    libelle: t.controleur.compteRendu.plusTard,
                    niveau: NiveauAction.secondaire,
                    pleineLargeur: compact,
                    onPress: _enCours ? null : _revenir,
                  ),
                  dominant: choix == null
                      ? null
                      : ApparitionDouce(
                          child: ActionPrincipale(
                            key: CompteRenduControlePage.actionKey,
                            libelle: envoi
                                ? t.controleur.compteRendu.envoyer
                                : t.commun.continuer,
                            pleineLargeur: compact,
                            enCours: _enCours,
                            onPress: _agir,
                          ),
                        ),
                  compact: compact,
                ),
                Semantics(
                  liveRegion: true,
                  child: _echec
                      ? Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.md),
                          child: Text(
                            // Seul « Rien a signaler » envoie depuis cet
                            // ecran : aucun texte a garder (revue CT-R m1).
                            t.controleur.compteRendu.echecRien,
                            textAlign: TextAlign.end,
                            style: palette.inkStrong.applyTo(
                              textes.bodyMedium ?? const TextStyle(),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// « Plus tard » et le bouton dominant : cote a cote au bord de fin sur
/// ordinateur, le dominant en dernier (K-42) ; empiles en pleine largeur sur
/// mobile, le dominant en premier. Une `Row` et non un `Wrap` : dans un
/// `Wrap`, `ActionPrincipale` s'etire sur toute la largeur.
class _Actions extends StatelessWidget {
  const _Actions({
    required this.plusTard,
    required this.dominant,
    required this.compact,
  });

  final Widget plusTard;
  final Widget? dominant;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final Widget? d = dominant;
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (d != null) ...<Widget>[d, Ecart.vSm],
          plusTard,
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        plusTard,
        if (d != null) ...<Widget>[Ecart.hSm, d],
      ],
    );
  }
}

/// L'etat de la transmission automatique de la visite (C2), dit honnetement :
/// en cours, transmise (seulement apres la reponse du serveur), ou pas encore
/// transmise, avec un nouvel essai.
class LigneTransmissionVisite extends ConsumerWidget {
  /// Cree la ligne.
  const LigneTransmissionVisite({required this.seanceId, super.key});

  /// La visite dont la transmission est dite.
  final String seanceId;

  /// La cle de « Reessayer ».
  static const Key reessayerKey = ValueKey<String>('ctr03-visite-reessayer');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CompteRenduEnSuspens? visite = ref.watch(
      compteRenduATerminerProvider,
    )[seanceId];
    final TransmissionVisite? etat = visite?.transmission;
    if (etat == null) return const SizedBox.shrink();
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final r = t.controleur.compteRendu;
    final (String texte, AppIcon icone) = switch (etat) {
      TransmissionVisite.enCours => (r.visiteEnCours, AppIcons.info),
      TransmissionVisite.transmise => (r.visiteTransmise, AppIcons.succes),
      TransmissionVisite.echec => (r.visiteEchec, AppIcons.signaler),
    };
    return Semantics(
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              IconTheme(
                data: palette.inkMuted.asIconTheme(size: 18),
                child: Icon(icone.resoudre()),
              ),
              Ecart.hSm,
              Expanded(
                child: Text(
                  texte,
                  style:
                      (etat == TransmissionVisite.echec
                              ? palette.inkStrong
                              : palette.inkMuted)
                          .applyTo(textes.bodyMedium ?? const TextStyle()),
                ),
              ),
            ],
          ),
          if (etat == TransmissionVisite.echec) ...<Widget>[
            Ecart.vSm,
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: ActionPrincipale(
                key: reessayerKey,
                libelle: t.commun.reessayer,
                niveau: NiveauAction.secondaire,
                pleineLargeur: false,
                onPress: () =>
                    unawaited(transmettreVisiteATerminer(ref, seanceId)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Les faits automatiques de la visite, en lecture seule, replies par
/// defaut ; les deplier ne quitte pas la page (UX_REVIEW_08 n° 5 a).
class _FaitsAutomatiques extends ConsumerStatefulWidget {
  const _FaitsAutomatiques({required this.seanceId});

  /// La seance de la visite : ses faits, jamais ceux d'une autre Classe
  /// (CTRL-SEANCE-1).
  final String seanceId;

  @override
  ConsumerState<_FaitsAutomatiques> createState() => _FaitsAutomatiquesState();
}

class _FaitsAutomatiquesState extends ConsumerState<_FaitsAutomatiques> {
  bool _deplie = false;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final AsyncValue<FaitsVisite?> faits = ref.watch(
      faitsVisiteProvider(widget.seanceId),
    );
    final TextStyle doux = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );

    return AppCard(
      surface: palette.surfaceRaised,
      marge: AppSpacing.lg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Pressable, jamais un onTap nu : bouton, focus et libelle lu ;
          // l'etat deplie reste annonce.
          Semantics(
            expanded: _deplie,
            child: Pressable(
              onPress: () => setState(() => _deplie = !_deplie),
              libelleSemantique: _deplie
                  ? t.controleur.compteRendu.faitsDeplies
                  : t.controleur.compteRendu.faitsReplies,
              arrondiFocus: BorderRadius.circular(AppSpacing.sm),
              child: ExcludeSemantics(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          t.controleur.compteRendu.faits,
                          style: palette.inkStrong.applyTo(
                            textes.titleMedium ?? const TextStyle(),
                          ),
                        ),
                      ),
                      AnimatedRotation(
                        turns: _deplie ? 0.25 : 0,
                        duration: Mouvement.duree(context, Mouvement.court),
                        curve: Mouvement.entree,
                        child: IconTheme(
                          data: palette.inkMuted.asIconTheme(size: 20),
                          child: Icon(AppIcons.chevron.resoudre()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: Mouvement.duree(context, Mouvement.moyen),
            curve: Mouvement.entree,
            alignment: AlignmentDirectional.topStart,
            child: !_deplie
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: switch (faits) {
                      AsyncData<FaitsVisite?>(:final FaitsVisite? value)
                          when value != null =>
                        LignesFaitsVisite(faits: value),
                      AsyncData<FaitsVisite?>() ||
                      AsyncError<FaitsVisite?>() => Text(
                        t.controleur.compteRendu.faitsAbsents,
                        style: doux,
                      ),
                      _ => Text(
                        t.controleur.compteRendu.faitsChargement,
                        style: doux,
                      ),
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Les faits automatiques d'une visite en lignes cle-valeur (CTR-03, et le
/// detail CTR-06 de l'Historique, CT-7).
class LignesFaitsVisite extends StatelessWidget {
  /// Cree les lignes.
  const LignesFaitsVisite({required this.faits, super.key});

  /// Les faits.

  final FaitsVisite faits;

  @override
  Widget build(BuildContext context) {
    final int retard = faits.minutesDeRetard;
    final String debutReel = heureDeLAppareil(faits.debutReel);
    final DateTime? fin = faits.finReelle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        LigneCleValeur(
          cle: t.controleur.compteRendu.cleHoraire,
          valeur: t.controleur.compteRendu.horaire(
            debut: heureDeLAppareil(faits.debutPrevu),
            fin: heureDeLAppareil(faits.finPrevue),
          ),
          chiffres: true,
        ),
        LigneCleValeur(
          cle: t.controleur.compteRendu.cleDebutReel,
          // L'ecart est ecrit, jamais porte par la couleur seule (C4).
          valeur: retard > 0
              ? t.controleur.compteRendu.debutRetard(
                  heure: debutReel,
                  minutes: retard,
                )
              : t.controleur.compteRendu.debutALHeure(heure: debutReel),
          chiffres: true,
        ),
        LigneCleValeur(
          cle: t.controleur.compteRendu.cleFin,
          valeur: fin == null
              ? t.controleur.compteRendu.enCours
              : heureDeLAppareil(fin),
          chiffres: true,
        ),
        LigneCleValeur(
          cle: t.controleur.compteRendu.clePresents,
          valeur: t.controleur.compteRendu.presents(
            presents: faits.participantsPresents,
            attendus: faits.participantsAttendus,
          ),
          chiffres: true,
        ),
        LigneCleValeur(
          cle: t.controleur.compteRendu.cleReconnexions,
          valeur: '${faits.reconnexions}',
          chiffres: true,
        ),
      ],
    );
  }
}
