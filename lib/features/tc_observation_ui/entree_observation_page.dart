import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/domain/enums.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/observabilite/journal_dev.dart';
import '../../core/preferences/preferences_locales.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/session/session_controleur.dart';
import '../../core/session/session_state.dart';
import '../../core/tc_observation/activation_observation.dart';
import '../../core/tc_observation/disponibilite_observation.dart';
import '../../core/tc_observation/echec_observation.dart';
import '../../core/tc_observation/guardian_session_visit.dart';
import '../../core/tc_observation/libelles_observation.dart';
import '../../core/tc_observation/mode_entree_admin.dart';
import '../../core/tc_observation/moteur_visite_observation.dart';
import '../../core/tc_observation/vue_budget_observation.dart';
import '../../core/theme/app_delais.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/video/livekit_session_provider.dart';
import '../../core/video/service_video.dart';
import '../../core/video/video_session_provider.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/confirm_destructive.dart';
import '../../core/widgets/ecran_resultat.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/entete_page.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import 'choix_entree_observation.dart';
import 'contexte_salle_observation.dart';
import 'explication_premiere_visite.dart';
import 'options_entree_observation.dart';
import 'ouverture_observation.dart';
import 'panneau_observation_tuteur.dart';
import 'resultat_visite_page.dart';
import 'verification_prealable.dart';
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
///
/// **Pour le tuteur, la porte commence par un vestibule** (lot O, sous-paquet
/// 1) : verification prealable en lecture seule (budget, politique, presence),
/// puis l'explication de premiere utilisation (maquette V8 M2), ou, quand elle
/// est deja lue et que la classe a transmis le geste
/// ([DemandeEntreeObservation]), directement « Connexion et verification ».
/// Aucune visite ne s'ouvre sans geste ; un rechargement n'en ouvre jamais.
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

  /// Vrai quand la verification d'entree par le serveur tarde.
  bool _connexionProlongee = false;
  Timer? _minuteurConnexion;

  /// Un identifiant de requete : lettres, chiffres, tiret, souligne. Tout le
  /// reste est ignore (jamais une URL, jamais un chemin : `?classe=` sert a
  /// construire le retour, et un `../compte` ne doit mener nulle part).
  static final RegExp _identifiant = RegExp(r'^[A-Za-z0-9_-]{1,64}$');

  /// Le moteur, capture une fois.
  ///
  /// Capture et non relu dans `dispose` : un `ref.read` au demontage arrive
  /// apres que le conteneur a commence a se defaire, et c'est precisement la
  /// que la liberation des pistes doit encore fonctionner.
  late final VideoSessionProvider _moteur = ref.read(moteurSalleProvider);

  StreamSubscription<List<ParticipantSalle>>? _sParticipants;
  List<ParticipantSalle> _participants = const <ParticipantSalle>[];

  /// L'etat du lien avec la salle video, tel que le moteur le publie : la
  /// pastille de la salle le suit (aucun faux direct pendant une
  /// reconnexion).
  StreamSubscription<EtatSalle>? _sEtatSalle;
  late EtatSalle _etatSalle = _moteur.etatCourant;

  /// Vrai pendant que la confirmation de sortie est ouverte : un second appui
  /// n'en ouvre pas une seconde.
  bool _confirmationOuverte = false;

  /// Vrai des que [VideoSessionProvider.rejoindre] a abouti.
  ///
  /// **C'est lui qui autorise le `quitter()` du demontage**, et il n'est pas
  /// une commodite : `moteurSalleProvider` est partage par tout le produit, et
  /// un `quitter()` inconditionnel couperait la salle d'un ecran qui n'est pas
  /// celui-ci.
  bool _enSalle = false;
  bool _entreeSalleEnCours = false;

  /// Vrai quand une sortie a ete demandee PENDANT que la connexion courait.
  ///
  /// **Une demande de sortie ne se perd pas dans une attente.** Entre la
  /// demande de jeton et l'entree effective dans la salle, il y a deux `await`,
  /// et le serveur peut epuiser le budget pendant ce temps : la visite passe a
  /// `terminee`, `_quitterSalle` trouve `_enSalle` encore faux et n'a rien a
  /// fermer, puis la connexion aboutit et ouvre la salle APRES la fin. L'ecran
  /// dirait « visite terminee » pendant que le parent continue de voir et
  /// d'entendre la classe, jusqu'au demontage de la page. Ce drapeau fait
  /// survivre la demande a la connexion en cours.
  bool _sortieDemandee = false;

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
    _sEtatSalle = _moteur.etats.listen((EtatSalle etat) {
      if (!mounted) {
        return;
      }
      setState(() => _etatSalle = etat);
      // **Reconnexion echouee pendant la visite : l'observation est
      // interrompue** (releve V7, N3 -> N6). L'intervalle est referme aupres
      // du serveur plutot que de laisser courir un temps que le parent ne
      // voit plus. Une salle jamais jointe (jeton refuse) n'est pas une
      // interruption : elle garde son message dans la salle.
      if (etat == EtatSalle.echec && _enSalle) {
        unawaited(
          ref
              .read(moteurVisiteObservationProvider(widget.seanceId))
              .interrompre(),
        );
      }
    });
  }

  @override
  void dispose() {
    _minuteurConnexion?.cancel();
    unawaited(_sParticipants?.cancel());
    unawaited(_sEtatSalle?.cancel());
    if (_enSalle) {
      // Quitter au demontage, quelle que soit la raison : sans cela, une visite
      // fermee a l'ecran continuerait a recevoir l'image d'une classe.
      unawaited(_moteur.quitter());
    }
    // **Une visite quittee sans « Quitter » est refermee aussi** (lien direct,
    // navigation du systeme, onglet ferme proprement) : aucun code serveur ne
    // referme l'intervalle a l'expiration du jeton (cartographie C07, fait 8),
    // et un intervalle laisse ouvert compterait et bloquerait la visite
    // suivante (DB-OBS-03, DB-OBS-06). Sans effet hors visite. Un onglet tue
    // ou une coupure reseau restent a la charge du serveur (DB-OBS-03).
    final MoteurVisiteObservation? visite = _moteurVisite;
    if (visite != null && visite.etat.phase == PhaseVisite.enVisite) {
      unawaited(visite.sortir());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SessionState session = ref.watch(sessionProvider);
    final AppRole? role = session.role;
    _lireNavigation(context);

    // **Interrupteur P3 ferme : le tuteur n'appelle aucune porte serveur.**
    // Ni budget, ni presence, ni `entrer_observation`, ni jeton video : la page
    // dit que l'observation n'est pas encore ouverte et ramene a la classe. La
    // valeur est fixee a la compilation, la branche ne bascule donc jamais
    // entre deux constructions. L'administration et le controle qualite ne
    // sont pas concernes.
    if (role == AppRole.guardian &&
        !ref.watch(observationTuteurReelleProvider)) {
      return _cadreTuteur(
        titre: t.tc.observation.entree.titre,
        retourPossible: true,
        child: _etatBloquant(MotifIndisponibilite.garantieServeurAbsente),
      );
    }

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
      (
        AsyncValue<EtatVisiteObservation>? anterieur,
        AsyncValue<EtatVisiteObservation> suivant,
      ) {
        final EtatVisiteObservation? valeur = suivant.value;
        if (valeur == null) {
          return;
        }
        _suivreConnexion(valeur.phase);
        if (valeur.phase == PhaseVisite.terminee &&
            anterieur?.value?.phase != PhaseVisite.terminee) {
          _apresVisite(role);
        }
        if (valeur.phase == PhaseVisite.enVisite) {
          unawaited(_rejoindreSalle(options));
        } else {
          unawaited(_quitterSalle());
        }
      },
    );

    if (role == AppRole.guardian) {
      return _parcoursTuteur(options, etat, session);
    }

    return PageShell(
      titre: t.tc.observation.entree.titre,
      // La salle remplit la hauteur (support dominant) : elle ne defile pas
      // dans la page, elle gere son propre defilement.
      defilante: etat.value?.phase != PhaseVisite.enVisite,
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

  Widget _corps(OptionsEntreeObservation options, EtatVisiteObservation etat) =>
      switch (etat.phase) {
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

  // --- Le parcours du tuteur (lot O, sous-paquet 1 : entree et explication) --

  String? _classeId;
  String? _eleveId;

  /// Vrai quand le geste « Observer la seance » a ete lu dans la navigation.
  /// Lu une seule fois : l'`extra` survit aux reconstructions de la page, pas
  /// le geste.
  bool _gesteLu = false;

  /// Vrai quand une entree est voulue sans nouvelle pression sur cette page :
  /// le geste « Observer la seance » de la classe
  /// ([DemandeEntreeObservation]), ou « Reessayer » apres une connexion
  /// impossible. Consomme par la premiere entree lancee.
  bool _entreeVoulue = false;

  /// Vrai quand l'entree a ete lancee sans l'explication (deja lue) : la page
  /// montre « Connexion et verification » plutot que l'explication.
  bool _modeConnexion = false;

  /// Lit la navigation : `?classe=` et `?eleve=` (le retour a la classe, avec
  /// le contexte de l'enfant) et, une fois, le geste d'entree. **Des
  /// identifiants seulement**, filtres par [_identifiant] : aucun ne vaut
  /// autorisation, la RLS decide.
  void _lireNavigation(BuildContext context) {
    final GoRouterState etat = GoRouterState.of(context);
    final Map<String, String> requete = etat.uri.queryParameters;
    String? identifiant(String cle) {
      final String? valeur = requete[cle];
      return valeur != null && _identifiant.hasMatch(valeur) ? valeur : null;
    }

    _classeId = identifiant('classe');
    _eleveId = identifiant('eleve');
    if (!_gesteLu) {
      _gesteLu = true;
      _entreeVoulue = etat.extra is DemandeEntreeObservation;
    }
  }

  /// « Retour a la classe » quand la classe est connue, sinon « Retour a
  /// l'accueil » : le libelle dit ou l'on va.
  String get _libelleRetour => _classeId != null
      ? t.tc.observation.entree.retourClasse
      : t.commun.etats.actions.retourAccueil;

  /// Le retour, **sans rien consommer** : aucune visite n'est ouverte avant
  /// l'entree. La classe, avec l'eleve, quand l'entree les a donnes ; sinon
  /// l'ecran precedent ; sinon la racine, que la garde renvoie a l'accueil du
  /// role. Aucune impasse.
  void _retour() {
    final GoRouter routeur = GoRouter.of(context);
    final String? classe = _classeId;
    if (classe != null) {
      routeur.go(Routes.classePour(classe, eleveId: _eleveId ?? _enfantVisite));
    } else if (routeur.canPop()) {
      routeur.pop();
    } else {
      routeur.go(Routes.racine);
    }
  }

  /// Arme la phrase « la verification prend plus de temps » pendant la
  /// demande d'entree, et la retire des qu'une reponse arrive.
  void _suivreConnexion(PhaseVisite phase) {
    if (phase == PhaseVisite.demande) {
      _minuteurConnexion ??= Timer(AppDelais.chargementProlonge, () {
        if (mounted) {
          setState(() => _connexionProlongee = true);
        }
      });
      return;
    }
    _minuteurConnexion?.cancel();
    _minuteurConnexion = null;
    if (_connexionProlongee && mounted) {
      setState(() => _connexionProlongee = false);
    }
  }

  DemandeVerification _demande(SessionState session) => DemandeVerification(
    seanceId: widget.seanceId,
    observateurId: session.profileId ?? '',
    classeId: _classeId,
    eleveId: _eleveId,
  );

  /// Le parcours du tuteur, de la verification prealable a la visite.
  ///
  /// **Le compteur ne demarre qu'apres l'entree confirmee** : la verification
  /// prealable et l'explication ne font que lire ; seule l'entree appelle
  /// `entrer_observation()`, et le compte a rebours ne s'affiche que dans la
  /// salle, une fois le serveur d'accord.
  Widget _parcoursTuteur(
    OptionsEntreeObservation options,
    AsyncValue<EtatVisiteObservation> etat,
    SessionState session,
  ) {
    if (!_identifiant.hasMatch(widget.seanceId)) {
      return _cadreTuteur(
        titre: t.tc.observation.entree.titre,
        retourPossible: true,
        child: EtatSysteme(
          nature: NatureEtat.introuvable,
          portee: PorteeEtat.page,
          libelleAction: _libelleRetour,
          onAction: _retour,
        ),
      );
    }
    final DemandeVerification demande = _demande(session);
    final EtatVisiteObservation? valeur = etat.value;
    return switch (valeur?.phase) {
      // La salle (sous-paquet 2) : tache focalisee plein cadre, sans titre de
      // page ni navigation. Le retour du systeme passe par « Quitter » et sa
      // confirmation : jamais une navigation qui laisserait la visite ouverte.
      PhaseVisite.enVisite => PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool fait, Object? _) {
          if (!fait) {
            unawaited(_demanderSortie());
          }
        },
        child: PageShell(
          defilante: false,
          child: _panneau(
            valeur!,
            onQuitter: () => unawaited(_demanderSortie()),
          ),
        ),
      ),
      // La fin de visite (sous-paquet 3, maquette M5 et variantes) : ecran
      // resultat sans en-tete ni navigation, le retour systeme mene a la
      // classe comme l'action dominante.
      PhaseVisite.terminee => PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool fait, Object? _) {
          if (!fait) {
            _retour();
          }
        },
        child: PageShell(
          defilante: false,
          // Telephone : le resultat commence en haut, comme M5. Des la
          // tablette : centre dans la hauteur, jamais colle en haut d'un grand
          // ecran vide. Toujours defilant (texte agrandi, paysage).
          child: LayoutBuilder(
            builder: (BuildContext _, BoxConstraints zone) =>
                SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: zone.maxHeight),
                    child: Align(
                      alignment: zone.maxWidth >= AppPage.largeurDialogue
                          ? Alignment.center
                          : AlignmentDirectional.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                        child: _resultat(valeur!, demande),
                      ),
                    ),
                  ),
                ),
          ),
        ),
      ),
      PhaseVisite.refusee => _cadreTuteur(
        titre: t.tc.observation.entree.titre,
        retourPossible: true,
        child: _etatBloquant(motifDepuisRefus(valeur!.motifRefus)),
      ),
      PhaseVisite.indisponible => _cadreTuteur(
        titre: t.tc.observation.entree.titre,
        retourPossible: true,
        child: _echecEntree(valeur!.echec, demande),
      ),
      PhaseVisite.horsVisite || PhaseVisite.demande || null => _vestibule(
        options,
        demande,
        enCours: valeur?.phase == PhaseVisite.demande,
      ),
    };
  }

  /// La page du tuteur hors salle : en-tete a disque retour (tache focalisee,
  /// hors coquille), colonne de lecture centree et bornee a
  /// [AppPage.largeurDialogue], comme M2 ; sur ordinateur, une colonne de
  /// lecture, jamais la feuille mobile etiree (manifeste section 6.1).
  Widget _cadreTuteur({
    required String titre,
    required bool retourPossible,
    required Widget child,
  }) => PageShell(
    child: Align(
      alignment: AlignmentDirectional.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppPage.largeurDialogue),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            EntetePage(titre: titre, onRetour: retourPossible ? _retour : null),
            Ecart.vXxl,
            child,
          ],
        ),
      ),
    ),
  );

  /// Vrai quand l'explication s'affiche : sans geste d'entree (lien « Comment
  /// ca marche ? », lien direct, rechargement), ou tant qu'elle n'a pas ete
  /// lue. Jamais sans la regle (aucun chiffre invente).
  bool _afficheExplication(VerificationPrealable verification) =>
      verification.regleConnue &&
      !_modeConnexion &&
      (!_entreeVoulue || !verification.explicationVue);

  /// Le vestibule : verification prealable, puis explication, ou connexion
  /// directe quand l'explication est deja lue et l'entree voulue.
  Widget _vestibule(
    OptionsEntreeObservation options,
    DemandeVerification demande, {
    required bool enCours,
  }) {
    final AsyncValue<VerificationPrealable> verification = ref.watch(
      verificationPrealableProvider(demande),
    );
    final VerificationPrealable? lue = verification.value;
    final bool explication = lue == null
        ? !_entreeVoulue && !_modeConnexion
        : _afficheExplication(lue);

    return PopScope(
      // Le retour systeme suit le disque retour : la classe, sans rien
      // consommer. Pendant la demande d'entree, il attend la reponse.
      canPop: false,
      onPopInvokedWithResult: (bool fait, Object? _) {
        if (!fait && !enCours) {
          _retour();
        }
      },
      child: _cadreTuteur(
        titre: explication
            ? t.tc.observation.explication.titre
            : t.tc.observation.entree.titre,
        retourPossible: !enCours,
        child: BlocAsynchrone<VerificationPrealable>(
          valeur: verification,
          squelette: const Skeleton.liste(lignes: 3),
          onReessayer: () =>
              ref.invalidate(verificationPrealableProvider(demande)),
          construire: (VerificationPrealable v) =>
              _contenuVestibule(options, demande, v, enCours: enCours),
        ),
      ),
    );
  }

  Widget _contenuVestibule(
    OptionsEntreeObservation options,
    DemandeVerification demande,
    VerificationPrealable v, {
    required bool enCours,
  }) {
    final DisponibiliteObservation disponibilite = v.disponibilite;
    final ObservationPossible? ouverte =
        v.regleConnue && disponibilite is ObservationPossible
        ? disponibilite
        : null;
    final bool possible = ouverte != null;

    // L'entree voulue, explication deja lue : directement « Connexion et
    // verification » (logigramme V7). Lancee apres cette construction, une
    // seule fois : le drapeau est consomme ici.
    if (possible && _entreeVoulue && v.explicationVue && !enCours) {
      _entreeVoulue = false;
      _modeConnexion = true;
      WidgetsBinding.instance.addPostFrameCallback((Duration _) {
        if (mounted) {
          _entrer(options);
        }
      });
    }
    if (possible && _modeConnexion) {
      return _connexion();
    }

    if (ouverte != null) {
      return ExplicationPremiereVisite(
        regle: regleVisitesObservation(v.visitesMax!, v.dureeParVisite!),
        restantes: ouverte.visitesUtilisees > 0
            ? visitesRestantesLisible(
                restantes: ouverte.visitesRestantes,
                max: ouverte.visitesMax,
              )
            : null,
        afficherRevenir: ouverte.visitesRestantes > 1,
        onObserver: () => _observer(options, demande),
        onPasMaintenant: _retour,
        libelleRetour: _libelleRetour,
        enCours: enCours,
        connexionProlongee: _connexionProlongee ? _prolongee() : null,
      );
    }

    final MotifIndisponibilite motif = switch (disponibilite) {
      ObservationIndisponible(:final MotifIndisponibilite motif) => motif,
      // Possible sans regle lisible (budget incoherent) : rien d'invente.
      ObservationPossible() => MotifIndisponibilite.capaciteAbsente,
    };
    if (_afficheExplication(v)) {
      // L'explication reste lisible quand elle est demandee (« Comment ca
      // marche ? »), meme si l'entree n'est pas possible : le motif prend la
      // place de l'action.
      return ExplicationPremiereVisite(
        regle: regleVisitesObservation(v.visitesMax!, v.dureeParVisite!),
        afficherRevenir: v.visitesRestantes > 1,
        onPasMaintenant: _retour,
        libelleRetour: _libelleRetour,
        indisponibilite: _blocIndisponible(motif, demande),
      );
    }
    return _etatBloquant(motif, demande: demande);
  }

  /// « Connexion et verification » (logigramme V7, noeud N13) : l'entree est
  /// demandee au serveur. Le compteur de visite n'existe pas encore a l'ecran.
  ///
  /// Grammaire de l'ecran resultat (manifeste section 6.3, « M5 ou M2 en
  /// variante attente »), sans action : il n'y a rien a presser, seulement a
  /// attendre, comme l'ecran de demarrage (`etats_routeur.dart`).
  Widget _connexion() {
    final c = t.tc.observation.connexion;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        EcranResultat(
          icone: AppIcons.observationEnCours,
          titre: c.titre,
          phrase: c.phrase,
        ),
        Ecart.vXxl,
        Center(
          child: Semantics(
            label: c.enCours,
            liveRegion: true,
            child: const CircularProgressIndicator.adaptive(),
          ),
        ),
        if (_connexionProlongee) ...<Widget>[Ecart.vXxl, _prolongee()],
      ],
    );
  }

  Widget _prolongee() => EtatSysteme(
    nature: NatureEtat.chargementProlonge,
    phrase: t.tc.observation.connexion.prolongee,
  );

  /// Vrai quand relire la disponibilite peut changer la reponse sans que le
  /// parent fasse autre chose qu'attendre : le reseau, la presence.
  static bool _seReverifie(MotifIndisponibilite motif) =>
      motif == MotifIndisponibilite.reseau ||
      motif == MotifIndisponibilite.presenceEnVerification;

  NatureEtat _natureDe(MotifIndisponibilite motif) {
    if (motif != MotifIndisponibilite.reseau) {
      return NatureEtat.indisponible;
    }
    return (ref.watch(horsLigneProvider).value ?? false)
        ? NatureEtat.horsLigne
        : NatureEtat.echecServeur;
  }

  /// Le titre et la phrase d'un motif. Hors ligne, ceux de l'etat systeme
  /// (« Vous etes hors ligne ») : le motif `reseau` dit « verification
  /// impossible », l'appareil sans reseau dit pourquoi.
  ({String? titre, String? phrase}) _textesDe(MotifIndisponibilite motif) {
    if (_natureDe(motif) == NatureEtat.horsLigne) {
      return (titre: null, phrase: null);
    }
    final ({String titre, String phrase}) textes = textesIndisponibilite(motif);
    return (titre: textes.titre, phrase: textes.phrase);
  }

  /// Ce qui manque cote serveur pour ce motif, pour la trace et les tests :
  /// jamais affiche.
  static String? _dependanceDe(MotifIndisponibilite motif) => switch (motif) {
    MotifIndisponibilite.garantieServeurAbsente ||
    MotifIndisponibilite.capaciteAbsente => 'DB-OBS-01',
    MotifIndisponibilite.presenceEnVerification ||
    MotifIndisponibilite.enfantAbsent => 'DB-OBS-05',
    MotifIndisponibilite.visiteDejaOuverte => 'DB-OBS-06',
    _ => null,
  };

  /// Le motif, en bloc, a la place de l'action d'entree (explication ouverte).
  Widget _blocIndisponible(
    MotifIndisponibilite motif,
    DemandeVerification demande,
  ) {
    final ({String? titre, String? phrase}) textes = _textesDe(motif);
    final bool reverifier = _seReverifie(motif);
    return EtatSysteme(
      nature: _natureDe(motif),
      titre: textes.titre,
      phrase: textes.phrase,
      onAction: reverifier ? () => _reverifier(demande) : null,
      dependance: _dependanceDe(motif),
    );
  }

  /// L'icone du cercle heros d'un motif : ce qui arrive a l'observation, pas
  /// la nature generique « indisponible ».
  static AppIcon _iconeDe(MotifIndisponibilite motif) => switch (motif) {
    MotifIndisponibilite.presenceEnVerification ||
    MotifIndisponibilite.seanceNonCommencee ||
    MotifIndisponibilite.horsFenetre => AppIcons.attente,
    MotifIndisponibilite.seanceTerminee ||
    MotifIndisponibilite.seanceNonTenue => AppIcons.journee,
    MotifIndisponibilite.lienAbsent ||
    MotifIndisponibilite.enfantAbsent => AppIcons.foyer,
    MotifIndisponibilite.visiteDejaOuverte => AppIcons.observationEnCours,
    MotifIndisponibilite.visitesEpuisees ||
    MotifIndisponibilite.tempsEpuise ||
    MotifIndisponibilite.observationDesactivee ||
    MotifIndisponibilite.garantieServeurAbsente ||
    MotifIndisponibilite.capaciteAbsente ||
    MotifIndisponibilite.reseau => AppIcons.observationFermee,
  };

  /// Le motif, en page : ecran resultat (manifeste section 6.3), l'action
  /// qui peut aboutir, et toujours le retour. Une panne (reseau, hors ligne)
  /// passe par l'etat systeme ; un motif de l'observation garde son icone.
  Widget _etatBloquant(
    MotifIndisponibilite motif, {
    DemandeVerification? demande,
  }) {
    final ({String? titre, String? phrase}) textes = _textesDe(motif);
    final bool reverifier = demande != null && _seReverifie(motif);
    if (motif != MotifIndisponibilite.reseau) {
      final ({String titre, String phrase}) dits = textesIndisponibilite(motif);
      return EcranResultat(
        icone: _iconeDe(motif),
        titre: dits.titre,
        phrase: dits.phrase,
        libelleAction: reverifier
            ? t.commun.etats.actions.reessayer
            : _libelleRetour,
        onAction: reverifier ? () => _reverifier(demande) : _retour,
        libelleSecondaire: reverifier ? _libelleRetour : null,
        onSecondaire: reverifier ? _retour : null,
      );
    }
    return EtatSysteme(
      nature: _natureDe(motif),
      portee: PorteeEtat.page,
      titre: textes.titre,
      phrase: textes.phrase,
      libelleAction: reverifier ? null : _libelleRetour,
      onAction: reverifier ? () => _reverifier(demande) : _retour,
      libelleSecondaire: reverifier ? _libelleRetour : null,
      onSecondaire: reverifier ? _retour : null,
      dependance: _dependanceDe(motif),
    );
  }

  /// L'entree a echoue avant la salle : « Connexion impossible » pour une
  /// panne, le motif sinon. Reessayer revient a la verification prealable :
  /// les visites restantes sont relues, jamais supposees.
  Widget _echecEntree(EchecObservation? echec, DemandeVerification demande) {
    final MotifIndisponibilite motif = echec == null
        ? MotifIndisponibilite.capaciteAbsente
        : motifDepuisEchec(echec);
    if (motif != MotifIndisponibilite.reseau) {
      return _etatBloquant(motif);
    }
    final c = t.tc.observation.connexion;
    return EtatSysteme(
      nature: _natureDe(motif),
      portee: PorteeEtat.page,
      titre: c.impossibleTitre,
      phrase: c.impossible,
      onAction: () => _recommencer(demande),
      libelleSecondaire: _libelleRetour,
      onSecondaire: _retour,
    );
  }

  /// Relit la disponibilite, sans rien ouvrir.
  void _reverifier(DemandeVerification demande) =>
      ref.invalidate(verificationPrealableProvider(demande));

  /// « Reessayer » apres une connexion impossible : un moteur neuf (aucune
  /// visite en cours a son sens), un budget relu, puis l'entree relancee si
  /// elle est encore possible. La pression sur « Reessayer » est le geste.
  void _recommencer(DemandeVerification demande) {
    setState(() {
      _entreeVoulue = true;
      _modeConnexion = false;
    });
    ref
      ..invalidate(moteurVisiteObservationProvider(widget.seanceId))
      ..invalidate(verificationPrealableProvider(demande));
  }

  /// « Observer maintenant » : l'explication est retenue comme lue, puis
  /// l'entree est demandee au serveur. C'est, avec le geste de la classe, le
  /// seul geste qui ouvre une visite.
  void _observer(
    OptionsEntreeObservation options,
    DemandeVerification demande,
  ) {
    unawaited(
      marquerExplicationVue(
        ref.read(stockagePreferencesProvider),
        demande.observateurId,
      ),
    );
    _entrer(options);
  }

  // --- La fin de visite (lot O, sous-paquet 3 : maquette M5 et variantes) --

  /// Le prenom de l'enfant tel que la salle l'a publie pendant la visite.
  String? _prenomEnfant;

  /// L'enfant concerne par la visite, selon le serveur : le contexte du
  /// retour a la classe quand l'adresse ne le nommait pas.
  String? _enfantVisite;

  /// A la fin d'une visite : la confirmation de sortie encore ouverte est
  /// refermee (la question n'a plus d'objet), et les visites restantes sont
  /// relues aupres du serveur, jamais deduites du compteur local.
  void _apresVisite(AppRole? role) {
    _fermerConfirmation();
    if (role != AppRole.guardian) {
      return;
    }
    ref.invalidate(
      verificationPrealableProvider(_demande(ref.read(sessionProvider))),
    );
  }

  /// Referme la feuille « Quitter la visite ? » si elle est ouverte : une
  /// visite terminee par le serveur ne laisse pas une question sans objet a
  /// l'ecran.
  void _fermerConfirmation() {
    if (!_confirmationOuverte || !mounted) {
      return;
    }
    Navigator.of(
      context,
      rootNavigator: true,
    ).popUntil((Route<dynamic> route) => route is! PopupRoute<dynamic>);
    Navigator.of(context)
        .popUntil((Route<dynamic> route) => route is! PopupRoute<dynamic>);
  }

  /// L'Historique, segment Observations (maquette D2), pour l'enfant de la
  /// visite quand il est connu.
  void _voirObservations() {
    final String? eleve = _eleveId ?? _enfantVisite;
    GoRouter.of(context).go(
      Uri(
        path: Routes.tuteurSuiviObservations,
        queryParameters: eleve == null
            ? null
            : <String, String>{'eleve': eleve},
      ).toString(),
    );
  }

  /// L'ecran de fin : la fin publiee par le moteur, le rang de la visite
  /// selon le serveur, et les visites restantes relues apres la fermeture.
  Widget _resultat(EtatVisiteObservation etat, DemandeVerification demande) {
    final AsyncValue<VerificationPrealable> relue = ref.watch(
      verificationPrealableProvider(demande),
    );
    final RestantesApresVisite restantes = switch (relue) {
      AsyncValue<VerificationPrealable>(isLoading: true) =>
        const RestantesEnLecture(),
      AsyncValue<VerificationPrealable>(:final VerificationPrealable value?)
          when value.visitesMax != null =>
        RestantesLues(
          nombre: value.visitesRestantes,
          dureeParVisite: value.dureeParVisite,
        ),
      _ => const RestantesInconnues(),
    };
    final int? rang = etat.visite?.visitNumber;
    final int? max = etat.budget?.visitesMax;
    return ResultatVisite(
      fin: etat.fin ?? FinDeVisite.sortieVolontaire,
      restantes: restantes,
      rang: rang == null || rang <= 0 ? null : rang,
      derniere: rang != null && max != null && max > 0 && rang >= max,
      prenomEnfant: _prenomEnfant,
      sortieConfirmee: etat.sortieConfirmee,
      libelleRetour: _libelleRetour,
      onRetour: _retour,
      onObservations: _voirObservations,
    );
  }

  /// Le panneau de visite, alimente par la salle reellement rejointe.
  ///
  /// `VueObservationTuteur.depuis` ne laisse sortir que deux personnes de la
  /// liste complete : l'enseignant et l'enfant que **le serveur** a inscrit
  /// dans l'intervalle. Les camarades ne sont pas masques a l'affichage, ils ne
  /// sortent pas de la fonction -- et c'est pour cela que la liste brute du
  /// moteur peut lui etre passee telle quelle.
  Widget _panneau(EtatVisiteObservation etat, {VoidCallback? onQuitter}) {
    final VueObservationTuteur vue = VueObservationTuteur.depuis(
      participants: _participants,
      enfantProfilId: etat.visite?.enfantConcerneId,
      budget: etat.vueBudget,
    );
    // L'en-tete : la classe et l'enseignant quand la classe du foyer se lit,
    // sinon le titre generique et les noms portes par la salle.
    final String? classe = _classeId;
    final String? eleve = _eleveId ?? etat.visite?.enfantConcerneId;
    final ContexteSalleObservation? contexte = classe == null || eleve == null
        ? null
        : ref
              .watch(
                contexteSalleObservationProvider((
                  classeId: classe,
                  eleveId: eleve,
                )),
              )
              .value;
    final String? enfant = vue.monEnfant?.nom;
    // Retenus pour la fin de visite : la salle est refermee avant que l'ecran
    // de fin ne s'affiche, et ses participants avec elle.
    _prenomEnfant = enfant ?? _prenomEnfant;
    _enfantVisite = etat.visite?.enfantConcerneId ?? _enfantVisite;
    return PanneauObservationTuteur(
      vue: vue,
      onQuitter: onQuitter ?? _quitter,
      titre: contexte?.nomClasse,
      sousTitre: contexte == null
          ? null
          : <String>[?enfant, contexte.enseignant].join(' · '),
      etatSalle: _etatSalle,
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
    // Une entree neuve ne herite pas de la demande de sortie de la precedente.
    _sortieDemandee = false;

    final AccesSalle acces;
    try {
      acces = await ref.read(serviceVideoProvider).acces(widget.seanceId);
    } on EchecSalle catch (echec) {
      journalDev('jeton video d\'observation refuse : ${echec.motif}');
      _poserEchecSalle();
      return;
    }

    if (acces.role != role.valeurSql) {
      journalDev(
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
      journalDev('entree en salle d\'observation impossible : $erreur');
      _poserEchecSalle();
      return;
    }

    if (!mounted) {
      // Le panneau a disparu pendant la connexion : personne ne regarde plus
      // cette salle, et `dispose` est deja passe sans pouvoir la fermer.
      unawaited(_moteur.quitter());
      return;
    }

    // **La visite a pu se terminer pendant la connexion.** Deux temoins, et
    // non un seul : la demande de sortie arrivee entre-temps, et la phase
    // courante du moteur de visite -- la seule autorite sur la fin d'une
    // visite. Entrer en salle ici poserait `_enSalle = true` apres que
    // `_quitterSalle` est deja passe sans rien avoir a fermer, et la salle
    // resterait jointe jusqu'au demontage de la page. Le quota serveur serait
    // tenu sur le papier, jamais a l'ecran ni dans l'oreille du parent.
    if (_sortieDemandee || !_visiteEnCours) {
      setState(() {
        _entreeSalleEnCours = false;
        _participants = const <ParticipantSalle>[];
      });
      await _moteur.quitter();
      return;
    }

    setState(() {
      _entreeSalleEnCours = false;
      _enSalle = true;
      _salleIndisponible = false;
    });
  }

  /// Vrai tant que le moteur de visite dit que la visite court encore.
  ///
  /// Lu au moteur et non a l'etat local : c'est le serveur qui termine une
  /// visite, et l'ecran ne fait que suivre ce qu'il publie.
  bool get _visiteEnCours =>
      ref.read(moteurVisiteObservationProvider(widget.seanceId)).etat.phase ==
      PhaseVisite.enVisite;

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
  ///
  /// **Demandee pendant une connexion, elle est memorisee, jamais perdue** :
  /// il n'y a encore rien a fermer, et c'est `_rejoindreSalle` qui refermera
  /// la salle des qu'elle sera ouverte.
  Future<void> _quitterSalle() async {
    if (_entreeSalleEnCours) {
      _sortieDemandee = true;
      return;
    }
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

  Widget _indisponible(
    OptionsEntreeObservation options,
    EchecObservation? echec,
  ) {
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
    final MoteurVisiteObservation moteur = ref.read(
      moteurVisiteObservationProvider(widget.seanceId),
    );
    _moteurVisite = moteur;
    unawaited(moteur.entrer(sessionId: widget.seanceId, role: role));
  }

  /// Le moteur de la visite lancee par cet ecran, retenu pour la refermer au
  /// demontage (un `ref.read` dans `dispose` arrive trop tard).
  MoteurVisiteObservation? _moteurVisite;

  void _quitter() => unawaited(
    ref.read(moteurVisiteObservationProvider(widget.seanceId)).sortir(),
  );

  /// « Quitter » du tuteur (barre de commandes, retour du systeme) : une
  /// confirmation, parce qu'une visite ecourtee est consommee et n'est pas
  /// reconduite (decision du directeur, `03` section 1 bis-4). Le decompte
  /// continue pendant la question ; une visite terminee entre-temps par le
  /// serveur ne se referme pas deux fois (`sortir` est sans effet hors visite).
  Future<void> _demanderSortie() async {
    if (_confirmationOuverte) {
      return;
    }
    final v = t.tc.observation.visite;
    final VueBudgetObservation? budget = ref
        .read(moteurVisiteObservationProvider(widget.seanceId))
        .etat
        .vueBudget;
    _confirmationOuverte = true;
    final bool confirme = await ConfirmDestructive.demander(
      context,
      question: v.quitterQuestion,
      consequence: budget == null
          ? v.quitterConsequenceSansTemps
          : v.quitterConsequence(
              duree: dureeVisiteLisible(budget.restantAffiche),
            ),
      libelleConfirmer: v.quitterConfirmer,
    );
    _confirmationOuverte = false;
    if (confirme && mounted) {
      _quitter();
    }
  }
}
