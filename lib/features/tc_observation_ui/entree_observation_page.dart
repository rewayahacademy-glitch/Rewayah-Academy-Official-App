import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/domain/enums.dart';
import '../../core/icons/app_icons.dart';
import '../../core/session/session_controleur.dart';
import '../../core/tc_observation/echec_observation.dart';
import '../../core/tc_observation/guardian_session_visit.dart';
import '../../core/tc_observation/libelles_tc_g.dart';
import '../../core/tc_observation/mode_entree_admin.dart';
import '../../core/tc_observation/moteur_visite_observation.dart';
import '../../core/video/video_session_provider.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import 'choix_entree_observation.dart';
import 'options_entree_observation.dart';
import 'panneau_observation_tuteur.dart';
import 'vue_observation_tuteur.dart';

/// La porte d'une seance, pour qui l'observe.
///
/// **Elle n'ouvre pas la salle, elle ouvre le droit d'y entrer.** La demande va
/// au serveur, qui verifie le lien tuteur-enfant, la seance, le groupe, la
/// politique et le quota **avant** d'ouvrir un intervalle. Le jeton video, lui,
/// reste demande par la Classe Live (Agent E) : une seconde porte video serait
/// un second `create-room-token`, et le chantier n'en veut qu'un.
///
/// Les participants et le support partage arrivent de cette meme Classe Live.
/// Tant qu'ils ne sont pas branches, le panneau affiche ses etats vides
/// explicites plutot qu'un cadre noir.
class EntreeObservationPage extends ConsumerStatefulWidget {
  /// Cree l'ecran.
  const EntreeObservationPage({required this.seanceId, super.key});

  /// La seance observee.
  final String seanceId;

  @override
  ConsumerState<EntreeObservationPage> createState() =>
      _EntreeObservationPageEtat();
}

class _EntreeObservationPageEtat extends ConsumerState<EntreeObservationPage> {
  ModeEntreeAdmin? _mode;

  @override
  Widget build(BuildContext context) {
    final AppRole? role = ref.watch(sessionProvider).role;
    final OptionsEntreeObservation options = OptionsEntreeObservation.pour(
      role,
    );
    final AsyncValue<EtatVisiteObservation> etat = ref.watch(
      etatVisiteObservationProvider(widget.seanceId),
    );

    return PageShell(
      titre: LibellesTcG.entreeTitre,
      child: switch (etat) {
        AsyncValue<EtatVisiteObservation>(hasValue: true) => _corps(
          options,
          etat.requireValue,
        ),
        AsyncValue<EtatVisiteObservation>(hasError: true) => const EmptyState(
          message: LibellesTcG.refusIndisponible,
          icone: AppIcons.avertissement,
          registre: RegistreVide.subi,
        ),
        _ => const Skeleton.liste(lignes: 2),
      },
    );
  }

  Widget _corps(
    OptionsEntreeObservation options,
    EtatVisiteObservation etat,
  ) => switch (etat.phase) {
    PhaseVisite.horsVisite => _choix(options),
    PhaseVisite.demande => _choix(options, enCours: true),
    PhaseVisite.enVisite => PanneauObservationTuteur(
      // La liste de participants reste vide tant que la Classe Live ne la
      // fournit pas. Elle n'est pas fabriquee ici : un second moteur de salle
      // serait une seconde `Room`, ce que le chantier interdit.
      vue: VueObservationTuteur.depuis(
        participants: const <ParticipantSalle>[],
        enfantProfilId: etat.visite?.enfantConcerneId,
        budget: etat.vueBudget,
      ),
      onQuitter: _quitter,
      budgetIncertain: etat.budgetIncertain,
    ),
    PhaseVisite.terminee => EmptyState(
      message: LibellesTcG.messageFin(
        etat.fin ?? FinDeVisite.sortieVolontaire,
      ),
      invitation: etat.sortieConfirmee
          ? null
          : LibellesTcG.visiteSortieNonConfirmee,
      icone: AppIcons.pause,
      registre: RegistreVide.subi,
    ),
    PhaseVisite.refusee => EmptyState(
      message: etat.motifRefus == null
          ? LibellesTcG.refusIndisponible
          : LibellesTcG.refus(etat.motifRefus!),
      icone: AppIcons.avertissement,
      registre: RegistreVide.subi,
    ),
    PhaseVisite.indisponible => _indisponible(options, etat.echec),
  };

  Widget _choix(OptionsEntreeObservation options, {bool enCours = false}) =>
      ChoixEntreeObservation(
        options: options,
        modeRetenu: _mode ?? _modeParDefaut(options),
        onMode: (ModeEntreeAdmin mode) => setState(() => _mode = mode),
        onEntrer: () => _entrer(options),
        enCours: enCours,
      );

  Widget _indisponible(OptionsEntreeObservation options, EchecObservation? echec) {
    final bool reessayable = echec?.seReessaye ?? false;
    return EmptyState(
      message: echec?.motif == MotifEchecObservation.capaciteAbsente
          ? LibellesTcG.refusCapaciteAbsente
          : LibellesTcG.refusIndisponible,
      icone: AppIcons.avertissement,
      registre: reessayable ? RegistreVide.actionnable : RegistreVide.subi,
      libelleAction: reessayable ? LibellesTcG.entreeAction : null,
      onAction: reessayable ? () => _entrer(options) : null,
    );
  }

  /// Le mode retenu par defaut, quand un choix est propose.
  static ModeEntreeAdmin? _modeParDefaut(OptionsEntreeObservation options) =>
      options.choisitSonMode ? options.modes.first : null;

  void _entrer(OptionsEntreeObservation options) {
    final RoleObservateur? role = options.roleDemande(
      _mode ?? _modeParDefaut(options),
    );
    if (role == null) {
      return;
    }
    unawaited(
      ref
          .read(moteurVisiteObservationProvider(widget.seanceId))
          .entrer(sessionId: widget.seanceId, role: role),
    );
  }

  void _quitter() => unawaited(
    ref.read(moteurVisiteObservationProvider(widget.seanceId)).sortir(),
  );
}
