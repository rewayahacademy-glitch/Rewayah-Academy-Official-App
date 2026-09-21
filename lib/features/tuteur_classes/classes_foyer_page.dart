import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/appairage/service_appairage.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/planning/service_planning.dart';
import '../../core/presence/service_presence.dart';
import '../../core/presence/vue_presence.dart';
import '../../core/router/routes.dart';
import '../../core/suivi/service_suivi.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/ligne_presence.dart';
import '../../core/widgets/local_feedback.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skeleton.dart';
import '../classes/carte_classe.dart';
import '../classes/domaine/classe_vm.dart';
import '../classes/domaine/conformite.dart';
import '../classes/domaine/erreur_domaine.dart';
import '../classes/domaine/providers.dart';
import '../classes/grille_classes.dart';
import '../classes/libelles_classes.dart';
import '../classes/rappel_kyc.dart';
import '../classes/selecteur_membre.dart';
import '../disponibilites/grille_semaine.dart';

/// Les Classes du foyer, celles qui restent ouvertes, et le planning.
///
/// **Le tuteur choisit d'abord le membre du foyer**, puis voit les Classes
/// compatibles et s'y inscrit d'un geste. Un eleve adulte autonome est un
/// foyer d'une personne : le selecteur ne se rend pas, tout le reste est
/// identique. Le produit dit « membres du foyer », jamais « enfants ».
///
/// Quand aucune Classe ne convient, la personne propose un creneau ; l'academie
/// agrege les demandes compatibles et ouvre une Classe au seuil.
///
/// Le planning montre l'etat de presence **tel que le serveur le rend**,
/// jamais un etat calcule ici. Une presence indisponible se lit « Etat
/// inconnu », jamais « Absence ».
class ClassesFoyerPage extends ConsumerStatefulWidget {
  /// Cree l'ecran.
  const ClassesFoyerPage({super.key, this.horloge = DateTime.now});

  /// D'ou vient l'instant courant, pour **dater** une presence, jamais pour la
  /// decider. Injectable pour que les tests ne dependent pas de l'heure de la
  /// machine.
  final DateTime Function() horloge;

  @override
  ConsumerState<ClassesFoyerPage> createState() => _ClassesFoyerPageEtat();
}

class _ClassesFoyerPageEtat extends ConsumerState<ClassesFoyerPage> {
  String? _membreId;
  final Set<String> _inscriptionsFaites = <String>{};
  String? _enVol;
  String? _retour;

  Future<void> _inscrire(ClasseVM classe, EleveDuFoyer membre) async {
    setState(() {
      _enVol = classe.id;
      _retour = null;
    });
    try {
      await ref
          .read(portMarketplaceProvider)
          .inscrire(classeId: classe.id, membreId: membre.id);
      if (mounted) {
        setState(() {
          _inscriptionsFaites.add('${classe.id}:${membre.id}');
          _retour = t.classes.foyer.inscriptionFaite(prenom: membre.prenom);
        });
        ref.invalidate(mesClassesProvider);
      }
    } on Object catch (erreur) {
      if (mounted) {
        setState(() => _retour = messageHumain(erreur));
      }
    } finally {
      if (mounted) {
        setState(() => _enVol = null);
      }
    }
  }

  Future<void> _proposer(EleveDuFoyer membre, String fuseau) async {
    final bool? envoye = await AppBottomSheet.ouvrir<bool>(
      context,
      titre: t.classes.foyer.proposerCreneauTitre(prenom: membre.prenom),
      constructeur: (BuildContext _) => _FeuilleProposition(
        membre: membre,
        fuseau: fuseau,
        onEnvoyer: (CreneauClasse creneau) => ref
            .read(portMarketplaceProvider)
            .proposerCreneau(membreId: membre.id, creneau: creneau),
      ),
    );
    if (envoye == true && mounted) {
      setState(() => _retour = t.classes.foyer.propositionEnvoyee);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<EleveDuFoyer>> membres = ref.watch(
      elevesDuFoyerProvider,
    );

    return PageShell(
      titre: t.classes.foyer.titre,
      entete: Align(
        alignment: AlignmentDirectional.centerStart,
        child: ActionPrincipale(
          libelle: t.commun.retour,
          niveau: NiveauAction.tertiaire,
          pleineLargeur: false,
          onPress: () => GoRouter.of(context).go(Routes.tuteurAccueil),
        ),
      ),
      child: switch (membres) {
        AsyncValue<List<EleveDuFoyer>>(hasValue: true) =>
          membres.requireValue.isEmpty
              ? EmptyState(
                  message: t.classes.foyer.aucunMembre,
                  invitation: t.classes.foyer.aucunMembreDetail,
                  icone: AppIcons.foyer,
                  libelleAction: t.classes.foyer.ajouterMembre,
                  onAction: () =>
                      GoRouter.of(context).go(Routes.tuteurAjouterEnfant),
                )
              : _Corps(
                  membres: membres.requireValue,
                  membreId: _membreId ?? membres.requireValue.first.id,
                  onChoisirMembre: (String id) =>
                      setState(() => _membreId = id),
                  inscriptionsFaites: _inscriptionsFaites,
                  enVol: _enVol,
                  retour: _retour,
                  maintenant: widget.horloge(),
                  onInscrire: (ClasseVM c, EleveDuFoyer m) =>
                      unawaited(_inscrire(c, m)),
                  onProposer: (EleveDuFoyer m, String fuseau) =>
                      unawaited(_proposer(m, fuseau)),
                ),
        AsyncValue<List<EleveDuFoyer>>(hasError: true) => EmptyState(
          message: t.tuteur.accueil.erreur,
          icone: AppIcons.avertissement,
          libelleAction: t.commun.reessayer,
          onAction: () => ref.invalidate(elevesDuFoyerProvider),
        ),
        _ => const Skeleton.liste(lignes: 3),
      },
    );
  }
}

/// Le corps : le membre, ses Classes, celles qui restent ouvertes, son planning.
class _Corps extends ConsumerWidget {
  const _Corps({
    required this.membres,
    required this.membreId,
    required this.onChoisirMembre,
    required this.inscriptionsFaites,
    required this.enVol,
    required this.retour,
    required this.maintenant,
    required this.onInscrire,
    required this.onProposer,
  });

  final List<EleveDuFoyer> membres;
  final String membreId;
  final void Function(String id) onChoisirMembre;
  final Set<String> inscriptionsFaites;
  final String? enVol;
  final String? retour;
  final DateTime maintenant;
  final void Function(ClasseVM classe, EleveDuFoyer membre) onInscrire;
  final void Function(EleveDuFoyer membre, String fuseau) onProposer;

  EleveDuFoyer get _membre => membres.firstWhere(
    (EleveDuFoyer m) => m.id == membreId,
    orElse: () => membres.first,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final EleveDuFoyer membre = _membre;
    final AsyncValue<List<ClasseVM>> miennes = ref.watch(mesClassesProvider);
    final AsyncValue<List<ClasseVM>> disponibles = ref.watch(
      classesDisponiblesProvider(membre.id),
    );
    final String fuseau =
        ref.watch(monFuseauProvider).value ?? 'Europe/Paris';
    // Le rappel de la piece : propose, jamais impose (contrat, section 5.1).
    // Seulement quand le KYC est facultatif et pas commence ; une lecture en
    // echec ou en cours n'affiche rien, l'ecran reste le meme.
    final ConformiteCompte? conformite = ref.watch(maConformiteProvider).value;
    final bool rappelKyc =
        conformite != null &&
        conformite.exigence == ExigenceKyc.optionnelle &&
        conformite.etat == EtatKyc.nonCommence;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (rappelKyc) ...<Widget>[
          RappelKyc(
            onDeposer: () => GoRouter.of(context).go(Routes.attentePiece),
          ),
          Ecart.vXl,
        ],
        SelecteurMembre(
          membres: <MembreChoix>[
            for (final EleveDuFoyer m in membres)
              MembreChoix(id: m.id, prenom: m.prenom),
          ],
          selectionne: membre.id,
          onChoisir: onChoisirMembre,
        ),
        if (membres.length > 1) Ecart.vXl,
        SectionHeader(
          titre: t.classes.foyer.classesDuFoyer,
          compteur: miennes.value?.length,
        ),
        Ecart.vLg,
        switch (miennes) {
          AsyncValue<List<ClasseVM>>(hasValue: true) =>
            miennes.requireValue.isEmpty
                ? EmptyState(
                    message: t.tc.groupe.mesGroupes.aucun,
                    invitation: t.tc.groupe.mesGroupes.aucunDetail,
                    icone: AppIcons.rienAAfficher,
                    registre: RegistreVide.subi,
                  )
                : GrilleClasses(
                    cartes: <Widget>[
                      for (final ClasseVM classe in miennes.requireValue)
                        CarteClasse(
                          classe: classe,
                          fuseauUtilisateur: fuseau,
                          onOuvrir: () => GoRouter.of(
                            context,
                          ).go(Routes.tcEspaceGroupe(classe.id)),
                        ),
                    ],
                  ),
          AsyncValue<List<ClasseVM>>(hasError: true) => EmptyState(
            message: t.classes.commun.erreurLecture,
            icone: AppIcons.avertissement,
            libelleAction: t.commun.reessayer,
            onAction: () => ref.invalidate(mesClassesProvider),
          ),
          _ => const Skeleton.liste(lignes: 2),
        },
        Ecart.vSection,
        SectionHeader(
          titre: t.classes.foyer.disponiblesPour(prenom: membre.prenom),
          compteur: disponibles.value?.length,
        ),
        Ecart.vLg,
        switch (disponibles) {
          AsyncValue<List<ClasseVM>>(hasValue: true) =>
            disponibles.requireValue.isEmpty
                ? _aucuneDisponible(membre, fuseau)
                : GrilleClasses(
                    cartes: <Widget>[
                      for (final ClasseVM classe in disponibles.requireValue)
                        _carteDisponible(classe, membre, fuseau),
                    ],
                  ),
          AsyncValue<List<ClasseVM>>(hasError: true) =>
            EchecDomaine.depuis(disponibles.error!).motif ==
                    MotifEchec.capaciteAbsente
                ? _aucuneDisponible(
                    membre,
                    fuseau,
                    detail: t.classes.commun.capaciteAbsente,
                  )
                : EmptyState(
                    message: t.classes.commun.erreurLecture,
                    invitation: messageHumain(disponibles.error!),
                    icone: AppIcons.avertissement,
                    libelleAction: t.commun.reessayer,
                    onAction: () => ref.invalidate(
                      classesDisponiblesProvider(membre.id),
                    ),
                  ),
          _ => const Skeleton.liste(lignes: 2),
        },
        Ecart.vLg,
        LocalFeedback(message: retour),
        Ecart.vSection,
        SectionHeader(titre: t.classes.foyer.planning(prenom: membre.prenom)),
        Ecart.vLg,
        _Planning(membre: membre, maintenant: maintenant),
      ],
    );
  }

  Widget _aucuneDisponible(
    EleveDuFoyer membre,
    String fuseau, {
    String? detail,
  }) => EmptyState(
    message: t.classes.foyer.aucuneDisponible,
    invitation: detail ?? t.classes.foyer.aucuneDisponibleDetail,
    icone: AppIcons.creneaux,
    libelleAction: t.classes.foyer.proposerCreneau,
    onAction: () => onProposer(membre, fuseau),
  );

  Widget _carteDisponible(ClasseVM classe, EleveDuFoyer membre, String fuseau) {
    final bool faite =
        classe.inscrit || inscriptionsFaites.contains('${classe.id}:${membre.id}');
    final ClasseVM affichee = faite && !classe.inscrit
        ? classe.inscrite()
        : classe;
    return CarteClasse(
      classe: affichee,
      fuseauUtilisateur: fuseau,
      // Une Classe complete ou deja rejointe n'a pas de bouton : la pastille
      // le dit, et un bouton qui echouerait apres le geste coute plus cher
      // qu'un bouton absent.
      action: faite || affichee.complete
          ? null
          : ActionCarte(
              libelle: t.classes.foyer.inscrire(prenom: membre.prenom),
              enCours: enVol == classe.id,
              onPress: enVol == null ? () => onInscrire(classe, membre) : null,
            ),
    );
  }
}

/// Le planning d'un membre : ses seances, avec l'etat de presence du serveur.
class _Planning extends ConsumerWidget {
  const _Planning({required this.membre, required this.maintenant});

  final EleveDuFoyer membre;
  final DateTime maintenant;

  /// Combien de seances a venir le planning montre. Une borne, pas une
  /// pagination : le planning repond a « quand est le prochain cours ».
  static const int plafond = 6;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Seance>> seances = ref.watch(seancesProvider);
    final AsyncValue<List<PresenceParticipant>?> presences = ref.watch(
      presenceDuSuiviProvider,
    );
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);

    if (seances.hasError) {
      return EmptyState(
        message: t.classes.commun.erreurLecture,
        icone: AppIcons.avertissement,
        libelleAction: t.commun.reessayer,
        onAction: () => ref.invalidate(seancesProvider),
      );
    }
    if (!seances.hasValue) {
      return const Skeleton.ligneTimeline(lignes: 3);
    }

    final List<Seance> miennes =
        seances.requireValue
            .where((Seance s) => s.eleveId == membre.id)
            .where((Seance s) => !s.fin.isBefore(maintenant))
            .toList()
          ..sort((Seance a, Seance b) => a.debut.compareTo(b.debut));

    if (miennes.isEmpty) {
      return EmptyState(
        message: t.classes.foyer.planningVide(prenom: membre.prenom),
        invitation: t.classes.foyer.planningVideDetail,
        icone: AppIcons.journee,
        registre: RegistreVide.subi,
      );
    }

    // Une lecture de presence en echec ou en cours rend `null` : l'inconnu,
    // jamais une absence. C'est l'invariant J3, et il tient ici sans un `if`
    // de plus, parce que `VuePresence.depuis` le porte.
    final List<PresenceParticipant>? lignes = presences.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final Seance seance in miennes.take(plafond))
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    t.classes.foyer.seance(
                      jour: LibellesClasses.jour(seance.debut.weekday),
                      date: _date(seance.debut),
                      heure: _hhmm(seance.debut),
                    ),
                    style: textes.titleSmall,
                  ),
                  Ecart.vXs,
                  Text(
                    t.tuteur.accueil.enCours(prenom: seance.enseignantPrenom),
                    style: palette.inkMuted.applyTo(
                      textes.bodySmall ?? const TextStyle(),
                    ),
                  ),
                  Ecart.vSm,
                  LignePresence(
                    nom: membre.prenom,
                    vue: VuePresence.depuis(
                      ligne: _lignePour(lignes, seance),
                      maintenant: maintenant,
                    ),
                    afficherConsolide: false,
                  ),
                ],
              ),
            ),
          ),
        Text(
          t.classes.presence.source,
          style: palette.inkMuted.applyTo(
            textes.bodySmall ?? const TextStyle(),
          ),
        ),
      ],
    );
  }

  PresenceParticipant? _lignePour(
    List<PresenceParticipant>? lignes,
    Seance seance,
  ) {
    if (lignes == null) {
      return null;
    }
    for (final PresenceParticipant l in lignes) {
      if (l.seanceId == seance.id && l.profilId == membre.id) {
        return l;
      }
    }
    return null;
  }
}

/// La feuille « Proposer un creneau » : une grille, une case, un envoi.
class _FeuilleProposition extends StatefulWidget {
  const _FeuilleProposition({
    required this.membre,
    required this.fuseau,
    required this.onEnvoyer,
  });

  final EleveDuFoyer membre;
  final String fuseau;
  final Future<void> Function(CreneauClasse creneau) onEnvoyer;

  @override
  State<_FeuilleProposition> createState() => _FeuillePropositionEtat();
}

class _FeuillePropositionEtat extends State<_FeuilleProposition> {
  Creneau? _choisi;
  bool _envoi = false;
  String? _erreur;

  Future<void> _envoyer() async {
    final Creneau? choisi = _choisi;
    if (choisi == null) {
      return;
    }
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await widget.onEnvoyer(
        CreneauClasse(
          jourIso: choisi.jour,
          heure: choisi.heure,
          fuseauIana: choisi.fuseau,
        ),
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on Object catch (erreur) {
      if (mounted) {
        setState(() => _erreur = messageHumain(erreur));
      }
    } finally {
      if (mounted) {
        setState(() => _envoi = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(t.classes.foyer.proposerCreneauAide, style: textes.bodyMedium),
        Ecart.vLg,
        // La meme grille que `TUT-04` et `ENS-06`, et c'est le point : une
        // case, un jour et une heure, jamais un chiffre de jour a saisir.
        GrilleSemaine(
          creneaux: <Creneau>[?_choisi],
          fuseau: widget.fuseau,
          enCours: _envoi,
          onBasculer: (Creneau creneau, bool posee) =>
              setState(() => _choisi = posee ? null : creneau),
        ),
        if (_erreur != null) ...<Widget>[
          Ecart.vMd,
          Semantics(
            liveRegion: true,
            child: Text(
              _erreur!,
              style: palette.inkAlert.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
          ),
        ],
        Ecart.vLg,
        ActionPrincipale(
          libelle: t.classes.foyer.proposerEnvoyer,
          enCours: _envoi,
          onPress: _choisi == null ? null : () => unawaited(_envoyer()),
        ),
      ],
    );
  }
}

String _hhmm(DateTime quand) =>
    '${quand.hour.toString().padLeft(2, '0')}:'
    '${quand.minute.toString().padLeft(2, '0')}';

String _date(DateTime quand) =>
    '${quand.day.toString().padLeft(2, '0')}/'
    '${quand.month.toString().padLeft(2, '0')}';
