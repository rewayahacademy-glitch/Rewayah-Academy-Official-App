import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/domain/enums.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/session/session_controleur.dart';
import '../../core/tc_observation/echec_observation.dart';
import '../../core/tc_observation/guardian_session_visit.dart';
import '../../core/tc_observation/libelles_observation.dart';
import '../../core/tc_observation/mode_entree_admin.dart';
import '../../core/tc_observation/moteur_visite_observation.dart';
import '../../core/video/livekit_session_provider.dart';
import '../../core/video/service_video.dart';
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
/// **La salle video, elle, s'ouvre ici -- apres l'intervalle, jamais avant.**
/// L'ordre porte la garantie : `entrer_observation()` verifie le lien, la
/// seance, le groupe, la politique et le quota, PUIS inscrit l'appelant dans
/// `session_participants`. C'est cette inscription qui permet a
/// `autoriser_jeton_video()` de lire un role et d'emettre un jeton -- un jeton
/// demande avant aurait recu « non inscrit a cette seance ».
///
/// Le moteur employe est `moteurSalleProvider`, **le seul du produit** : une
/// seconde `Room` doublerait l'audio sans qu'aucune erreur ne s'affiche. Et
/// rien n'est publie a l'entree, pour aucun role : le tuteur n'a ni commande de
/// micro ni commande de camera a l'ecran, et le jeton les lui refuse de toute
/// facon.
///
/// Le support partage, lui, reste vide : aucun ecran du produit ne le remplit
/// encore -- `ContexteClasseLive.support` n'est construit nulle part, pas meme
/// pour l'enseignant. Le panneau le dit en clair plutot que d'ouvrir une
/// seconde surface de rendu.
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

  /// Le moteur, capture une fois.
  ///
  /// Capture et non relu dans `dispose` : un `ref.read` au demontage arrive
  /// apres que le conteneur a commence a se defaire, et c'est precisement la
  /// que la liberation des pistes doit encore fonctionner.
  late final VideoSessionProvider _moteur = ref.read(moteurSalleProvider);

  StreamSubscription<List<ParticipantSalle>>? _sParticipants;
  List<ParticipantSalle> _participants = const <ParticipantSalle>[];

  /// Vrai des que [VideoSessionProvider.rejoindre] a abouti.
  ///
  /// **C'est lui qui autorise le `quitter()` du demontage**, et il n'est pas
  /// une commodite : `moteurSalleProvider` est partage par tout le produit, et
  /// un `quitter()` inconditionnel couperait la salle d'un ecran qui n'est pas
  /// celui-ci.
  bool _enSalle = false;
  bool _entreeSalleEnCours = false;

  /// Vrai quand le jeton video a ete refuse, ou la connexion impossible.
  bool _salleIndisponible = false;

  @override
  void initState() {
    super.initState();
    // On ecoute AVANT d'entrer : le moteur publie sa premiere liste pendant
    // `rejoindre`, et un abonnement pose apres la manquerait.
    _sParticipants = _moteur.participants.listen((
      List<ParticipantSalle> liste,
    ) {
      if (mounted) {
        setState(() => _participants = liste);
      }
    });
  }

  @override
  void dispose() {
    unawaited(_sParticipants?.cancel());
    if (_enSalle) {
      // Quitter au demontage, quelle que soit la raison : sans cela, une visite
      // fermee a l'ecran continuerait a recevoir l'image d'une classe.
      // L'intervalle serveur, lui, n'est PAS referme ici -- une page demontee
      // n'est pas une sortie, et c'est le serveur qui le referme a l'expiration
      // du jeton (contrat 14, invariant 2).
      unawaited(_moteur.quitter());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppRole? role = ref.watch(sessionProvider).role;
    final OptionsEntreeObservation options = OptionsEntreeObservation.pour(
      role,
    );
    final AsyncValue<EtatVisiteObservation> etat = ref.watch(
      etatVisiteObservationProvider(widget.seanceId),
    );

    // **La salle suit la visite, elle ne la precede jamais.** L'entree en salle
    // est declenchee par la phase publiee par le moteur de visite, et la sortie
    // par toute phase qui n'est plus une visite -- y compris `terminee`, que
    // seul le SERVEUR provoque quand le budget tombe a zero. Une minuterie
    // locale ne ferme rien ici : elle ne fait que repeindre un chiffre.
    ref.listen<AsyncValue<EtatVisiteObservation>>(
      etatVisiteObservationProvider(widget.seanceId),
      (AsyncValue<EtatVisiteObservation>? _, AsyncValue<EtatVisiteObservation> suivant) {
        final EtatVisiteObservation? valeur = suivant.value;
        if (valeur == null) {
          return;
        }
        if (valeur.phase == PhaseVisite.enVisite) {
          unawaited(_rejoindreSalle(options));
        } else {
          unawaited(_quitterSalle());
        }
      },
    );

    return PageShell(
      titre: t.tc.observation.entree.titre,
      child: switch (etat) {
        AsyncValue<EtatVisiteObservation>(hasValue: true) => _corps(
          options,
          etat.requireValue,
        ),
        AsyncValue<EtatVisiteObservation>(hasError: true) => EmptyState(
          message: t.tc.observation.refus.indisponible,
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
    PhaseVisite.enVisite => _panneau(etat),
    PhaseVisite.terminee => EmptyState(
      message: libelleFinVisite(etat.fin ?? FinDeVisite.sortieVolontaire),
      invitation: etat.sortieConfirmee
          ? null
          : t.tc.observation.visite.sortieNonConfirmee,
      icone: AppIcons.pause,
      registre: RegistreVide.subi,
    ),
    PhaseVisite.refusee => EmptyState(
      message: etat.motifRefus == null
          ? t.tc.observation.refus.indisponible
          : libelleRefusObservation(etat.motifRefus!),
      icone: AppIcons.avertissement,
      registre: RegistreVide.subi,
    ),
    PhaseVisite.indisponible => _indisponible(options, etat.echec),
  };

  /// Le panneau de visite, alimente par la salle reellement rejointe.
  ///
  /// `VueObservationTuteur.depuis` ne laisse sortir que deux personnes de la
  /// liste complete : l'enseignant et l'enfant que **le serveur** a inscrit
  /// dans l'intervalle. Les camarades ne sont pas masques a l'affichage, ils ne
  /// sortent pas de la fonction -- et c'est pour cela que la liste brute du
  /// moteur peut lui etre passee telle quelle.
  Widget _panneau(EtatVisiteObservation etat) {
    final VueObservationTuteur vue = VueObservationTuteur.depuis(
      participants: _participants,
      enfantProfilId: etat.visite?.enfantConcerneId,
      budget: etat.vueBudget,
    );
    return PanneauObservationTuteur(
      vue: vue,
      onQuitter: _quitter,
      videoEnseignant: _video(vue.enseignant),
      // L'image de l'enfant n'est demandee que si sa camera est ouverte : la
      // politique camera d'un mineur vaut `forbidden` tant que personne ne l'a
      // ouverte, et un cadre noir dirait « panne » la ou il faut lire « pas
      // d'image ».
      videoEnfant: vue.mediaEnfantOuvert ? _video(vue.monEnfant) : null,
      budgetIncertain: etat.budgetIncertain,
      videoIndisponible: _salleIndisponible,
    );
  }

  /// L'image d'un participant, deja montee par le moteur. `null` s'il n'en
  /// publie aucune.
  Widget? _video(ParticipantSalle? personne) =>
      personne == null ? null : _moteur.renduVideo(personne.identite);

  /// Ouvre la salle video de la seance, avec le jeton du role demande.
  ///
  /// **Rien n'est contourne ici.** Le quota, les capacites et la duree du jeton
  /// sont decides par `autoriser_jeton_video()` ; cet ecran ne verifie qu'une
  /// chose, et c'est la seule qu'il puisse verifier : que le jeton rendu porte
  /// bien le role demande. Un jeton d'un autre role ouvrirait une salle dont
  /// les capacites ne sont pas celles de l'observation, et il vaut mieux ne pas
  /// entrer que d'entrer autrement qu'en observateur.
  Future<void> _rejoindreSalle(OptionsEntreeObservation options) async {
    final RoleObservateur? role = options.roleDemande(
      _mode ?? _modeParDefaut(options),
    );
    if (role == null || _enSalle || _entreeSalleEnCours) {
      return;
    }
    _entreeSalleEnCours = true;

    final AccesSalle acces;
    try {
      acces = await ref.read(serviceVideoProvider).acces(widget.seanceId);
    } on EchecSalle catch (echec) {
      debugPrint('jeton video d\'observation refuse : ${echec.motif}');
      _poserEchecSalle();
      return;
    }

    if (acces.role != role.valeurSql) {
      debugPrint(
        'jeton video de role inattendu : ${acces.role}, attendu ${role.valeurSql}',
      );
      _poserEchecSalle();
      return;
    }

    try {
      await _moteur.rejoindre(acces);
    } catch (erreur) {
      // Le moteur a deja pose son etat d'echec et tout libere. Aucun detail
      // technique ne remonte a l'ecran.
      debugPrint('entree en salle d\'observation impossible : $erreur');
      _poserEchecSalle();
      return;
    }

    if (!mounted) {
      // Le panneau a disparu pendant la connexion : personne ne regarde plus
      // cette salle, et `dispose` est deja passe sans pouvoir la fermer.
      unawaited(_moteur.quitter());
      return;
    }
    setState(() {
      _entreeSalleEnCours = false;
      _enSalle = true;
      _salleIndisponible = false;
    });
  }

  void _poserEchecSalle() {
    if (!mounted) {
      return;
    }
    setState(() {
      _entreeSalleEnCours = false;
      _salleIndisponible = true;
    });
  }

  /// Ferme la salle video. Sans effet quand cet ecran ne l'a pas ouverte.
  Future<void> _quitterSalle() async {
    if (!_enSalle) {
      return;
    }
    _enSalle = false;
    await _moteur.quitter();
    if (mounted) {
      setState(() => _participants = const <ParticipantSalle>[]);
    }
  }

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
          ? t.tc.observation.refus.capaciteAbsente
          : t.tc.observation.refus.indisponible,
      icone: AppIcons.avertissement,
      registre: reessayable ? RegistreVide.actionnable : RegistreVide.subi,
      libelleAction: reessayable ? t.tc.observation.entree.entrer : null,
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
    // Une nouvelle demande efface l'echec de la precedente : sans cela, un
    // tuteur qui reessaye lirait encore le mot d'un echec deja passe.
    setState(() => _salleIndisponible = false);
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
